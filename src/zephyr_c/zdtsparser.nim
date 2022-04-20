import tables, streams, strutils, strformat
import sequtils
import options
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

  DtsNode* = object
    properties: seq[DtAttrs]
    num: int
    addrs: seq[string]
    size: seq[string]

  DtsNodes* = TableRef[string, DtsNode]

  ParserState* = object
    key*: string
    curr*: DtAttrs
    nodes*: DtsNodes

proc `$`*(dts: DtAttrs): string =
  let name = dts.name
  let kind = dts.kind
  let value = dts.value
  result = fmt"DtAttr({name=}, {kind=}, {value=})"

proc regs*(node: DtsNode): seq[DtAttrs] =
  result = node.properties.filterIt(it.kind == DT_REG)
proc regs*(node: DtsNode, name: string): Option[DtAttrs] =
  let r = node.regs().filterIt(it.name == name)
  if r.len() > 0: result = some(r[0])
proc props*(node: DtsNode): seq[DtAttrs] =
  result = node.properties.filterIt(it.kind == DT_PROP)
proc props*(node: DtsNode, name: string): Option[DtAttrs] =
  let r = node.props().filterIt(it.name == name)
  if r.len() > 0: result = some(r[0])

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
    state.nodes.mgetOrPut(state.key, DtsNode()).properties.add(curr)

  dtKind <- ("DT_NODELABEL" | "DT_NODE" | "DT_PROP" | "DT_REG" | "DT_CHOSEN" | E"unsupported dt tag")

  word <- Alpha | {'_', '-'}
  path <- Alnum | {'_', '-', '/', ',', '@', ';', '.', ' '}

proc process*(dts: var ParserState): string =
  echo "process: dts: "
  # result = newTable[string, DNode]()
  for key, node in dts.nodes.mpairs():
    if node.regs("NUM").isSome:
      node.num = node.regs("NUM").get().value.parseInt()
    if node.regs("ADDR").isSome:
      node.addrs = node.regs("ADDR").get().value.split(';').filterIt(it.isEmptyOrWhitespace)
    if node.regs("SIZE").isSome:
      node.size = node.regs("SIZE").get().value.split(';').filterIt(it.isEmptyOrWhitespace)
    echo fmt"node: {key=}"
    echo fmt"  {node.num=}"
    echo fmt"  {node.addrs=}"
    echo fmt"  {node.size=}"
    for attr in node.properties:
      echo fmt"  {attr=}"
    echo "  props: ", node.props()
    echo "  regs: ", node.regs()
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
