## Mock for NVS using just a table 

import std/[tables, strformat]

type
  NvsId* = distinct uint16
  NvsConfig* = ref object
    fs*: Table[NvsId, array[128, byte]]

proc `==`*(a, b: NvsId): bool {.borrow.}
proc `$`*(a: NvsId): string {.borrow.}

proc read*[T](nvs: NvsConfig, id: NvsId, item: var T) =
  var buf = nvs.fs[id]
  copyMem(item.addr, buf[0].addr, item.sizeof())

proc read*[T](nvs: NvsConfig, id: NvsId, tp: typedesc[T]): T =
  read(nvs, id, result)

proc write*[T](nvs: NvsConfig, id: NvsId, item: T) =
  var buf: array[128, byte]
  var val = item
  copyMem(buf[0].addr, val.addr, item.sizeof())
  nvs.fs[id] = buf
