
## Example usage of NVS
## license: Apache-2.0

import std/[strutils, hashes, options, strformat, tables]
import std/[macros, macrocache]

import mcu_utils/logging

## Module for getting and setting global constants that need to be 
## written or read from flash memory. This uses the "NVS" flash library 
## from the esp-idf. 
import ../drivers/nvs

type
  ConfigSettings*[T] = ref object
    store*: NvsConfig
    values*: T

## The code below handles mangling field names to unique id's
## for types like ints, floats, strings, etc
## 

template setField[V](val: var V, input: V) =
  val = input

proc mangleFieldName*(name: string): NvsId =
  var nh = hash(name)
  static: assert sizeof(nh) >= sizeof(result)
  copyMem(result.addr, nh.addr, sizeof(result))

template implSetObjectField[V](obj: object, field: string, val: V) =
  block fieldFound:
    for objField, objVal in fieldPairs(obj):
      if objField == field:
        when objVal is typeof(val):
          setField(objVal, val)
        # objVal = val
        break fieldFound
    raise newException(ValueError, "unexpected field: " & field)

proc setObjectField*[T: object, V](obj: var T, field: string, val: V) =
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

proc loadField*[T, V](settings: var ConfigSettings[T], name: string, typ: typedesc[V]): V =
  var mname = mangleFieldName(name)
  try:
    var rval = settings.store.read(mname, typ)
    logDebug(fmt"CFG name: {name} => {rval}")
    setObjectField(settings.values, name, rval)
  except KeyError:
    logDebug("CFG", "skipping name: %s", $name)

proc saveField*[T](
    settings: var ConfigSettings[T],
    name: string,
    val: int32,
    oldVal = none(int32)
) =
  var mName = mangleFieldName(name)
  var shouldWrite = if oldVal.isSome(): val != oldVal.get()
                    else: true

  if shouldWrite:
    logDebug("CFG", fmt"save setting field: {name}({$mName}) => {oldVal=} -> {val=}")
    settings.store.write(mName, val)
  else:
    logDebug("CFG", fmt"skipping setting field: {name}({$mName}) => {oldVal=} -> {val=}")

proc loadAll*[T](settings: var ConfigSettings[T]) =
  for name, valTyp in settings.values.fieldPairs():
    discard settings.loadField(name, typeof valTyp)

proc saveAll*[T](ns: var ConfigSettings[T]) =
  logDebug("CFG", "saving settings ")
  for name, val in ns.values.fieldPairs():
    ns.saveField(name, cast[int32](val))

proc newConfigSettings*[T](nvs: NvsConfig, config: T): ConfigSettings[T] =
  new(result)
  result.store = nvs
  result.values = config