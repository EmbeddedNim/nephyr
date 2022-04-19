import tables, streams, strutils, strformat
import json, macros, os
import parsecfg, tables
import npeg

# add_custom_target(devicetree_target)
# set_target_properties(devicetree_target PROPERTIES "DT_CHOSEN|zephyr,entropy" "/soc/random@400cc000")

let parser = peg("props", d: Table[string, string]):
  props <- +propline
  propline <- >(+'\n' | proptarget):
    echo "propline: ", repr($1)

  proptarget <- targetProps | customTarget

  customTarget <- "add_custom_target(" * +word * ")"

  targetProps <- "set_target_properties(devicetree_target PROPERTIES " * >dtProps * ")":
    echo "targetProps: ", $1
    discard

  allLessParen <- 1 - ' '
  ps <- '"' * +path * '"'
  dtParams <- dtParams3 | dtParams2 | dtParams1 | E"params error"
  dtParams1 <- '"' * dtKind * '|' * '/' * '"'
  dtParams2 <- '"' * dtKind * '|' * +path * '"'
  dtParams3 <- '"' * dtKind * '|' * +path * '|' * +path * '"'

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
    var words: Table[string, string]
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
