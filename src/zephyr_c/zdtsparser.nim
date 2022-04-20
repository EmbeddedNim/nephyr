import tables, streams, strutils, strformat
import json, macros, os
import parsecfg, tables
import npeg
import patty

# add_custom_target(devicetree_target)
# set_target_properties(devicetree_target PROPERTIES "DT_CHOSEN|zephyr,entropy" "/soc/random@400cc000")

type
  DtKind = enum
    DT_NODELABEL, DT_NODE, DT_PROP, DT_REG, DT_CHOSEN

  DtAttrs* = ref object
    name: string
    value: string
    kind: DtKind

  DtsProps* = seq[DtAttrs]
  DtsNodes* = TableRef[string, DtsProps]

  ParserState* = object
    key*: string
    curr*: DtAttrs
    nodes*: DtsNodes

proc `$`*(dts: DtAttrs): string =
  let name = dts.name
  let kind = dts.kind
  let value = dts.value
  result = fmt"DtAttr({name=}, {kind=}, {value=})"


let parser = peg("props", state: ParserState):
  props <- +propline
  propline <- (+'\n' | proptarget)

  proptarget <- targetProps | customTarget

  customTarget <- "add_custom_target(" * +word * ")"

  targetProps <- "set_target_properties(devicetree_target PROPERTIES " * >dtProps * ")":
    discard

  dtParams <- dtParams3 | dtParams2 | E"params error"
  dtParams2 <- '"' * >dtKind * '|' * >+path * '"':
    state.key = $2
    state.curr = DtAttrs(name: $2, kind: parseEnum[DtKind]($1))
  dtParams3 <- '"' * >dtKind * '|' * >+path * '|' * >+path * '"':
    state.key = $2
    state.curr = DtAttrs(name: $3, kind: parseEnum[DtKind]($1))

  dtProps <- dtNode | dtProperty | E"dt prop error"
  dtNode <- dtParams * +Space * "TRUE"
  dtProperty <- dtParams * +Space * (>"\"\"" | '"' * >+path * '"'):
    let curr = move state.curr
    curr.value = $1
    state.nodes.mgetOrPut(state.key, newSeq[DtAttrs]()).add curr

  dtKind <- ("DT_NODELABEL" | "DT_NODE" | "DT_PROP" | "DT_REG" | "DT_CHOSEN" | E"unsupported dt tag")

  word <- Alpha | {'_', '-'}
  path <- Alnum | {'_', '-', '/', ',', '@', ';', '.', ' '}

proc process*(dts: var ParserState): string =
  echo "process: dts: "
  # result = newTable[string, DNode]()
  for k, v in dts.nodes.pairs():
    echo fmt"node: {k=}"
    for d in v:
      echo fmt"  {d=}"
    echo ""

proc parseCmakeDts*(file: string) =
  echo fmt"Parsing cmake dts: {file=}"
  let cmakeData = file.readFile()

  try:
    var state = ParserState(nodes: DtsNodes())
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
