## Mock for NVS using just a table 

import std/[tables, strformat]

import nephyr/zephyr/zkernel_fixes
import nephyr/zephyr/zdevice
# import nephyr/zephyr/drivers/zflash


type
  nValue[T] = object
    len: int32
    data: T

  nvs_fs* = object
    flash_device*: pointer
    offset*: off_t
    sector_size*: uint16
    sector_count*: uint16
    ready*: bool
    data*: Table[uint16, array[128, byte]]

proc nvs_init*(fs: ptr nvs_fs; dev_name: cstring): cint =
  result = 0

proc initNvsMock*[T](): T =
  result = T()
  discard nvs_init(result.fs.addr, "flash_mock")

proc nvs_mount*(fs: ptr nvs_fs): cint =
  result = 0

proc nvs_write*(fs: ptr nvs_fs; id: uint16; data: pointer; len: cint): cint =
  echo fmt"nvs_write: {fs.pointer.repr=} {id=} {data.repr=} {len=}"
  var buf: array[128, byte]
  copyMem(buf[0].addr, len.unsafeAddr, 1)
  copyMem(buf[1].addr, data, len)
  fs.data[id] = buf
  echo fmt"nvs_write: {fs.pointer.repr=} {id=} {data.repr=} {len=}"

proc nvs_read*(fs: ptr nvs_fs; id: uint16; data: pointer; len: cint): cint =
  var buf = fs.data[id]
  copyMem(result.addr, buf[0].addr, 1)
  copyMem(data, buf[1].addr, len)
  echo fmt"nvs_read: {fs.pointer.repr=} {id=} {data.repr=} {len=} {result=}"

