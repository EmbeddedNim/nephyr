
## Example usage of NVS
## license: Apache-2.0

import std/[strutils, md5, options, strformat]
import std/[macros, macrocache]

import mcu_utils/logging

# import nephyr
# import nephyr/drivers/nvs

## Module for getting and setting global constants that need to be 
## written or read from flash memory. This uses the "NVS" flash library 
## from the esp-idf. 

type
  ConfigSettings*[S, T] = object
    store*: S
    values*: T

## The code below handles mangling field names to unique id's
## for types like ints, floats, strings, etc
## 

template setField[T: int](val: var T, input: int32) =
  val = input

template setField[T: float](val: var T, input: int32) =
  val = cast[float32](input)

proc mangleFieldName*(name: string): int =
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

## Primary "SETTINGS" API
## 

proc loadField*[S, T](settings: var ConfigSettings[S, T], name: string): int32 =
  var mname = mangleFieldName(name)
  try:
    var rval = settings.nvs.read(mname, int32)
    logDebug(fmt"CFG name: {name} => {rval}")
    setObjectField(settings, name, rval)
  except KeyError:
    logDebug("CFG", "skipping name: %s", $name)

proc saveField*[S, T](settings: var ConfigSettings[S, T], name: string, val: int32) =
  var mName = mangleFieldName(name)
  var oldVal = getObjectField(settings, name)
  var currVal = val
  if currVal != oldVal:
    logDebug("CFG", fmt"save setting field: {name}({$mName}) => {oldVale=} -> {currVal=}")
    settings.store.write(mName, val)
  else:
    logDebug("CFG", fmt"skip setting field: {name}({$mName}) => {oldVale=} -> {currVal=}")


proc loadSettings*[S, T](settings: var ConfigSettings[S, T]) =
  for name, val in settings.fieldPairs:
    discard settings.loadField(name)

proc saveSettings*[S, T](ns: var ConfigSettings[S, T]) =
  logDebug("CFG", "saving settings ")
  for name, val in ns.fieldPairs:
    ns.saveField(name, cast[int32](val))

when isMainModule:
  import unittest

  suite "nvs config object":
  
    
    test "essential truths":
      # give up and stop if this fails
      echo "hi"
    