
## Example usage of NVS
## license: Apache-2.0

import std/[strutils, hashes, options, strformat, tables]
import std/[macros, macrocache, typetraits]

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
proc mangleFieldName*(base, name: string): Hash {.compileTime.} =
  mangleFieldName(base & "/" & name)
proc toNvsId*(hs: Hash, index: int = 0): NvsId =
  let hn = int(hs !& index)
  result = NvsId(cast[uint16](hn mod high(int16)))


## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
## Public API
## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
## 
## `loadAll` essnetially just unrolls the loop at compile time. 
## For each field the loop produces code somewhat the below example. 
## It's not too different from making a large function doing this
## for each field. 
## 
##   const
##     baseName = "ExampleConfigs"
##   ...
##   const
##     baseHash`gensym51: Hash = 5931869128195016125
##   let keyId`gensym51 = toNvsId(5931869128195016125, 0)
##   let res`gensym51 = loadFieldName(settings.store, keyId`gensym51,
##                                    settings.values.dac_calib_gain)
##   if res`gensym51:
##     echo(["CFG name:", " ", "dac_calib_gain", " ", keyId`gensym51, " ", " => ",
##           " ", settings.values.dac_calib_gain, " "])
##   else:
##     echo(["CFG", " ", "skipping name: ", " ", keyId`gensym51, " ",
##           "dac_calib_gain", " "])
##   ...

proc loadField*[V](store: NvsConfig, keyId: NvsId, value: var V): bool =
  try:
    let rval = store.read(keyId, typeof(value))
    value = rval
    result = true
  except KeyError:
    result = false

proc saveField*[V](store: NvsConfig, keyId: NvsId, value: var V): bool =
  try:
    store.write(keyId, value)
    result = true
  except KeyError:
    result = false

template loadField*[T, V](
    settings: var ConfigSettings[T], 
    base: string,
    index: int,
    name: string,
    value: V,
) =
  const baseHash: Hash = mangleFieldName(base, name)
  let keyId = baseHash.toNvsId()
  let res = loadField(settings.store, keyid, value)
  if res:
    logDebug("CFG name:", name, keyId, " => ", value)
  else:
    logDebug("CFG", "skipping name: ", keyId, name)

template saveField*[T, V](
    settings: var ConfigSettings[T], 
    base: string,
    index: int,
    name: string,
    value: V,
) =
  const baseHash: Hash = mangleFieldName(base, name)
  let keyId = baseHash.toNvsId()
  let res = saveField(settings.store, keyid, value)
  if res:
    logDebug("CFG name:", name, keyId, " => ", value)
  else:
    logDebug("CFG", "skipping name: ", keyId, name)


proc loadAll*[T](settings: var ConfigSettings[T], index: int = 0) =
  expandMacros:
    const baseName = $(distinctBase(T))
    for field, value in settings.values.fieldPairs():
      loadField(settings, baseName, index, field, value)

proc saveAll*[T](settings: var ConfigSettings[T], index: int = 9) =
  expandMacros:
    const baseName = $(distinctBase(T))
    for field, value in settings.values.fieldPairs():
      saveField(settings, baseName, index, field, value)


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