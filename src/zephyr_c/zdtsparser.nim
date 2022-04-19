import tables, streams, strutils, strformat
import json, macros, os
import parsecfg, tables
import npeg

# add_custom_target(devicetree_target)
# set_target_properties(devicetree_target PROPERTIES "DT_CHOSEN|zephyr,entropy" "/soc/random@400cc000")

let parser = peg("props", d: Table[string, string]):
  props <- *propline
  propline <- proptarget * +'\n'
  proptarget <- >(targetProps | customTarget):
    echo "proptarget: ", $1

  # customTarget <- "add_custom_target(" * +1 * ")"
  # customTarget <- "add_custom_target(devicetree_target)"
  customTarget <- "add_custom_target(" * +word * ")"

  targetProps <- "set_target_properties(devicetree_target PROPERTIES " * >dtProps * ")":
    echo "targetProps: ", $1

  allLessParen <- 1 - ' '
  ps <- '"' * +path * '"'
  dtParams <- dtParams3 | dtParams2 | dtParams1 | E"params error"
  dtParams1 <- '"' * +path * '|' * '/' * '"'
  dtParams2 <- '"' * +path * '|' * +path * '"'
  dtParams3 <- '"' * +path * '|' * +path * '|' * +path * '"'

  dtProps <- dtNode | dtProperty | E"dt prop error"
  dtNode <- dtParams * +Space * "TRUE"
  dtProperty <- dtParams * +Space * '"' * +path * '"'

  dtKind <- "DT_NODE_LABEL" | "DT_NODE" | "DT_PROP" | "DT_REG" | "DT_CHOOSEN"
  dtPath <- +Alnum
  dtValue <- +Alnum

  word <- Alpha | {'_', '-'}
  path <- Alnum | {'_', '-', '/', ',', '@'}

proc parseCmakeDts*(file: string) =
  echo fmt"Parsing cmake dts: {file=}"
  let cmakeData = file.readFile()
  echo "cmakeData: ", cmakeData[158..200].repr

  var words: Table[string, string]
  doAssert parser.match(cmakeData[0..600], words).ok
  echo words

when isMainModule:
  echo "\n\n"
  parseCmakeDts(file="tests/data/example_dts.cmake")
  echo ""
