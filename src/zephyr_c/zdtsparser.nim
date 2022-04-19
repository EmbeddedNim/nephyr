import tables, streams, strutils, strformat
import json, macros, os
import parsecfg, tables
import npeg

# add_custom_target(devicetree_target)
# set_target_properties(devicetree_target PROPERTIES "DT_CHOSEN|zephyr,entropy" "/soc/random@400cc000")

let parser = peg("props", d: TableRef[string, TableRef[string, string]]):
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
  dtParams <- dtParams1 | dtParams2 | dtParams3 | E"params error"
  dtParams1 <- '"' * >dtKind * '|' * '/' * '"':
    echo "dtKind1: ", $1
    d[$1] = newTable[string, string]()
  dtParams2 <- '"' * >dtKind * '|' * >+path * '"':
    # echo "dtKind2: ", $1
    echo "dtKind3: parent: ", $1, " path: ", $2
    d.getOrDefault($1, newTable[string, string]())[$2] = $2
    discard
  dtParams3 <- '"' * >dtKind * '|' * >+path * '|' * >+path * '"':
    # echo "dtKind3: parent: ", $1, " path: ", $2, " field: ", $3
    discard

  dtProps <- dtNode | dtProperty | E"dt prop error"
  dtNode <- dtParams * +Space * "TRUE"
  dtProperty <- dtParams * +Space * ("\"\"" | '"' * +path * '"')

  dtKind <- ("DT_NODELABEL" | "DT_NODE" | "DT_PROP" | "DT_REG" | "DT_CHOSEN" | E"unsupported dt tag")

  word <- Alpha | {'_', '-'}
  path <- Alnum | {'_', '-', '/', ',', '@', ';', '.', ' '}

proc parseCmakeDts*(file: string) =
  echo fmt"Parsing cmake dts: {file=}"
  let cmakeData = file.readFile()

  try:
    var words = TableRef[string, TableRef[string, string]]()
    let res = parser.match(cmakeData, words)
    echo res.repr
    echo "words: ", $words
  except NPegException as res:
    echo "Parsing failed at position ", res.matchMax
    echo "cmakeData: ", cmakeData[res.matchMax ..< min(res.matchMax+100, cmakeData.len())].repr

when isMainModule:
  echo "\n\n"
  parseCmakeDts(file="tests/data/example_dts.cmake")
  echo ""
