import tables, streams, strutils, strformat
import json, macros, os
import parsecfg, tables
import npeg

# add_custom_target(devicetree_target)
# set_target_properties(devicetree_target PROPERTIES "DT_CHOSEN|zephyr,entropy" "/soc/random@400cc000")
type
  DtsProps* = TableRef[string, TableRef[string, string]]
  ParserState* = object
    curr*: string
    props*: DtsProps

let parser = peg("props", state: ParserState):
  props <- +propline
  propline <- >(+'\n' | proptarget):
    # echo "propline: ", repr($1)
    discard

  proptarget <- targetProps | customTarget

  customTarget <- "add_custom_target(" * +word * ")"

  targetProps <- "set_target_properties(devicetree_target PROPERTIES " * >dtProps * ")":
    # echo "targetProps: ", $1
    discard

  allLessParen <- 1 - ' '
  ps <- '"' * +path * '"'
  dtParams <- dtParams3 | dtParams2 | E"params error"
  dtParams2 <- '"' * >dtKind * '|' * >+path * '"':
    # if $1 == "DT_NODELABEL":
      # echo "dtKind2: parent: ", $1, " path: ", $2
    state.curr = $2
    state.props.mgetOrPut($2, newTable[string, string]())[$1] = $2
    discard
  dtParams3 <- '"' * >dtKind * '|' * >+path * '|' * >+path * '"':
    # echo "dtKind3: parent: ", $1, " path: ", $2, " label: ", $3
    state.curr = $2
    state.props.mgetOrPut($2, newTable[string, string]())[$1] = $3
    discard

  dtProps <- dtNode | dtProperty | E"dt prop error"
  dtNode <- dtParams * +Space * "TRUE"
  dtProperty <- dtParams * +Space * ("\"\"" | '"' * +path * '"'):
    echo "DT_PROP: ", state.curr

  dtKind <- ("DT_NODELABEL" | "DT_NODE" | "DT_PROP" | "DT_REG" | "DT_CHOSEN" | E"unsupported dt tag")

  word <- Alpha | {'_', '-'}
  path <- Alnum | {'_', '-', '/', ',', '@', ';', '.', ' '}

type
  DNode* = object
    label*: string

proc process*(dts: var ParserState): TableRef[string, DNode] =
  echo "process: dts: "
  result = newTable[string, DNode]()
  for k, v in dts.props.pairs():
    echo fmt"words: {k=} => {v=}"

proc parseCmakeDts*(file: string) =
  echo fmt"Parsing cmake dts: {file=}"
  let cmakeData = file.readFile()

  try:
    var state = ParserState(props: TableRef[string, TableRef[string, string]]())
    let res = parser.match(cmakeData, state)
    discard process(state)
    echo res.repr
  except NPegException as res:
    echo "Parsing failed at position ", res.matchMax
    echo "cmakeData: ", cmakeData[res.matchMax ..< min(res.matchMax+100, cmakeData.len())].repr

when isMainModule:
  echo "\n\n"
  parseCmakeDts(file="tests/data/example_dts.cmake")
  echo ""
