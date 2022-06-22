
## Example usage of NVS
## license: Apache-2.0

import std/[strutils, hashes, options, strformat, tables]
import std/[macros, macrocache]

import cdecl/cdeclapi
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

proc mangleFieldName*(name: string): Hash {.compileTime.} =
  result = hashIgnoreStyle(name)
proc toNvsid*(hs: Hash, index: int = 0): NvsId =
  let hn = int(hs !& index)
  result = NvsId(cast[uint16](hn mod high(int16)))


## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
## Public API
## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

template loadField*[T, V](
    obj: var T,
    name: string,
    index: int,
    field: V,
) =
  const baseHash: Hash = mangleFieldName(base, name)
  let keyId = NvsId(baseid.uint16 !& index)
  try:
    let rval = settings.store.read(keyId, typeof(field))
    logDebug("CFG name:", name, keyId, " => ", rval)
    field = rval
  except KeyError:
    logDebug("CFG", "skipping name: ", keyId, name)

proc loadAll*[T](settings: var ConfigSettings[T], index: int = 0) =
  for field, value in settings.values.fieldPairs():
    loadField(settings.values, index, field, value)

proc saveAll*[T](ns: var ConfigSettings[T]) =
  discard
  # logDebug("CFG", "saving settings ")
  # for name, val in ns.values.fieldPairs():
    # ns.saveField(name, cast[int32](val))

proc newConfigSettings*[T](nvs: NvsConfig, config: T): ConfigSettings[T] =
  new(result)
  result.store = nvs
  result.values = config

when false:
  proc saveField*[T](
      settings: var ConfigSettings[T],
      name: string,
      val: int32,
      oldVal = none(int32)
  ) =
    expandMacros:
      var mName = mangleFieldName(name)
      var shouldWrite = if oldVal.isSome(): val != oldVal.get()
                        else: true

      if shouldWrite:
        logDebug("CFG", fmt"save setting field: {name}({$mName}) => {oldVal=} -> {val=}")
        settings.store.write(mName, val)
      else:
        logDebug("CFG", fmt"skipping setting field: {name}({$mName}) => {oldVal=} -> {val=}")
  
  template implSetObjectField[V](obj: object, field: string, val: V) =
    block fieldFound:
      for objField, objVal in fieldPairs(obj):
        if objField == field:
          when objVal is typeof(val):
            setField(objVal, val)
          # objVal = val
          break fieldFound
      raise newException(ValueError, "unexpected field: " & field)