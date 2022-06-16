
## Example usage of NVS
## license: Apache-2.0

import macros, strutils, md5, options

import nephyr
import nephyr/drivers/nvs

import std/macrocache

## Module for getting and setting global constants that need to be 
## written or read from flash memory. This uses the "NVS" flash library 
## from the esp-idf. 

type
  SerialNumber* = object
    board_major*: int
    board_minor*: int
    number*: int

  ConfigSettings*[T] = object

proc `$`*(serial: SerialNumber): string =
  let 
    bmajor = serial.board_major.int.intToStr(3)
    bminor = serial.board_minor.int.intToStr(1)
    number = serial.number.int.intToStr(4)
  
  result = "" & bmajor & bminor & number

proc parseSerialNumber*(serno: int): SerialNumber =
  serno.toHex(8).parseSerialNumber()

proc toInt*(serial: SerialNumber): int32 =
  let serstr: string = $serial
  serstr.parseHexInt().int32


## The code below handles mangling field names to unique id's
## for types like ints, floats, strings, etc
## 

template setField[T: int](val: var T, input: int32) =
  val = input

template setField[T: float](val: var T, input: int32) =
  val = cast[float32](input)

proc mangleFieldName*(name: string): NvsId =
  let nh: string = $toMD5(name)
  copyMem(result.addr, nh.cstring, sizeof(result))

template implSetObjectField(obj: object, field: string, val: int32): untyped =
  block fieldFound:
    for objField, objVal in fieldPairs(obj):
      if objField == field:
        setField(objVal, val)
        # objVal = val
        break fieldFound
    raise newException(ValueError, "unexpected field: " & field)

proc setObjectField*[T: object](obj: var T, field: string, val: int32) =
  # inside a generic proc to avoid side-effects and reduce code size.
  expandMacros: # to see what it generates
    implSetObjectField(obj, field, val)

template implGetObjectField(obj: object, field: string): untyped =
  block fieldFound:
    for objField, objVal in fieldPairs(obj):
      if objField == field:
        # return objVal
        return cast[int32](objVal)
    raise newException(ValueError, "unexpected field: " & field)

proc getObjectField*[T: object](obj: var T, field: string): int32 =
  implGetObjectField(obj, field)

## Primary "SETTINGS" API
## 

proc loadField*(settings: var ConfigSettings, name: string): int32 =
  var mname = mangleFieldName(name)
  try:
    var rval = store.read(mname, int32)
    logi("CFG", "name: %s => %s", name, $rval)
    setObjectField(settings, name, rval)
  except KeyError:
    logi("CFG", "skipping name: %s", $name)

proc saveField*(settings: var ConfigSettings, name: string, val: int32) =
  logi("CFG", "saving settings ")
  var mName = mangleFieldName(name)
  var oldVal = getObjectField(settings, name)
  var currVal = val
  if currVal != oldVal:
    logi("CFG", "save setting field: %s(%s) => %d => %d", name.cstring, mName, oldVal, currVal)
    store.write(mName, val)
  else:
    logi("CFG", "skip setting field: %s(%s) => %d => %d", name.cstring, mName, oldVal, currVal)


proc loadSettings*(settings: var ConfigSettings) =
  for name, val in settings.fieldPairs:
    discard settings.load_field(name)

proc saveSettings*(ns: var ConfigSettings) =
  logi("CFG", "saving settings ")
  for name, val in ns.fieldPairs:
    ns.save_field(name, cast[int32](val))

proc cfg_settings*() =
  logi("CFG", "cfg settings")
  SETTINGS = config_settings_default()
