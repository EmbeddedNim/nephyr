
## Example usage of NVS
## license: Apache-2.0

import std/[strutils, md5, options, strformat, tables]
import std/[macros, macrocache]

import mcu_utils/logging

## Module for getting and setting global constants that need to be 
## written or read from flash memory. This uses the "NVS" flash library 
## from the esp-idf. 
when defined(testing):
  type
    NvsId* = distinct uint16
    NvsConfig* = ref object
      fs*: Table[NvsId, array[128, byte]]

  proc `==`*(a, b: NvsId): bool {.borrow.}

else:
  import nephyr
  import nephyr/drivers/nvs


type
  ConfigSettings*[T] = ref object
    store*: NvsConfig
    values*: T

## The code below handles mangling field names to unique id's
## for types like ints, floats, strings, etc
## 

template setField[T: int](val: var T, input: int32) =
  val = input

template setField[T: float](val: var T, input: int32) =
  val = cast[float32](input)

proc mangleFieldName*(name: string): NvsId =
  var nh = toMD5(name)
  copyMem(result.addr, nh.addr, sizeof(result))

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

## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
## Public API
## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

proc loadField*[T](settings: var ConfigSettings[T], name: string): int32 =
  var mname = mangleFieldName(name)
  try:
    var rval = settings.store.read(mname, int32)
    logDebug(fmt"CFG name: {name} => {rval}")
    setObjectField(settings.values, name, rval)
  except KeyError:
    logDebug("CFG", "skipping name: %s", $name)

proc saveField*[T](settings: var ConfigSettings[T], name: string, val: int32) =
  var mName = mangleFieldName(name)
  var oldVal = getObjectField(settings, name)
  var currVal = val
  if currVal != oldVal:
    logDebug("CFG", fmt"save setting field: {name}({$mName}) => {oldVale=} -> {currVal=}")
    settings.store.write(mName, val)
  else:
    logDebug("CFG", fmt"skip setting field: {name}({$mName}) => {oldVale=} -> {currVal=}")


proc loadAll*[T](settings: var ConfigSettings[T]) =
  for name, val in settings.values.fieldPairs():
    discard settings.loadField(name)

proc saveAll*[T](ns: var ConfigSettings[T]) =
  logDebug("CFG", "saving settings ")
  for name, val in ns.values.fieldPairs():
    ns.saveField(name, cast[int32](val))

proc newConfigSettings*[T](nvs: NvsConfig, config: T): ConfigSettings[T] =
  new(result)
  result.store = nvs
  result.values = config

## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
## Unit Tests
## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
##

when isMainModule:
  import unittest

  type 
    ExampleConfigs* = object
      dac_calib_gain*: int32 
      dac_calib_offset*: int32 

      adc_calib_gain*: float32
      adc_calib_offset*: int32

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

  suite "nvs config object":
  
    test "essential truths":
      # give up and stop if this fails
      var nvs = NvsConfig()

      let id1 = 1234'i32
      nvs.write(1.NvsId, id1)
      let id1res = nvs.read(1.NvsId, int32)
      check id1 == id1res

    test "essential truths":
      var nvs = NvsConfig()

      # pre-make fields to simulate flash values
      let fld1 = mangleFieldName("dac_calib_gain")
      let fld2 = mangleFieldName("dac_calib_offset")
      nvs.write(fld1, 31415)
      nvs.write(fld2, 2718)

      var exCfg = ExampleConfigs()
      var settings = newConfigSettings(nvs, exCfg)

      # check default 0
      check settings.values.dac_calib_gain == 0
      check settings.values.dac_calib_offset == 0

      # check loaded
      settings.loadAll()
      check settings.values.dac_calib_gain == 31415
      check settings.values.dac_calib_offset == 2718
