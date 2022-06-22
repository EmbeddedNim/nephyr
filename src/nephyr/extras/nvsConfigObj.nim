
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
  echo "MANGLEFIELDNAME: ", name
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

proc loadFieldValue*[V](store: NvsConfig, keyId: NvsId, value: var V): bool =
  try:
    let rval = store.read(keyId, typeof(value))
    value = rval
    result = true
  except KeyError:
    result = false

proc saveFieldValue*[V](store: NvsConfig, keyId: NvsId, value: V): bool =
  try:
    store.write(keyId, value)
    result = true
  except KeyError:
    result = false

template loadField*[V](
    store: NvsConfig,
    base: string,
    index: int,
    name: string,
    value: V,
) =
  const baseHash: Hash = mangleFieldName(base, name)
  let keyId = baseHash.toNvsId()
  let res = loadFieldValue(store, keyid, value)
  if res:
    logDebug("CFG name:", name, keyId, " => ", value)
  else:
    logDebug("CFG", "skipping name: ", keyId, name)

template saveField*[V](
    store: NvsConfig,
    base: string,
    index: int,
    name: string,
    value: V,
) =
  const baseHash: Hash = mangleFieldName(base, name)
  let keyId = baseHash.toNvsId()
  let res = saveFieldValue(store, keyid, value)
  if res:
    logDebug("CFG name:", name, keyId, " => ", value)
  else:
    logDebug("CFG", "skipping name: ", keyId, name)

proc loadAllImpl[T](store: NvsConfig, values: var T, index: int, prefix: static[string]) =
  expandMacros:
    const baseName = prefix & "/" & $(distinctBase(T))
    for field, value in values.fieldPairs():
      when typeof(value) is object:
        loadAllImpl(store, value, index, prefix = baseName)
      else:
        loadField(store, baseName, index, field, value)

proc loadAll*[T](settings: var ConfigSettings[T], index: int = 0) =
  loadAllImpl(settings.store, settings.values, index, prefix = "")

proc saveAllImpl[T](store: NvsConfig, values: T, index: int, prefix: static[string]) =
  expandMacros:
    const baseName = prefix & "/" & $(distinctBase(T))
    for field, value in values.fieldPairs():
      when typeof(value) is object:
        saveAllImpl(store, value, index, prefix = baseName)
      else:
        saveField(store, baseName, index, field, value)

proc saveAll*[T](settings: ConfigSettings[T], index: int = 9) =
  saveAllImpl(settings.store, settings.values, index, prefix = "")


proc newConfigSettings*[T](nvs: NvsConfig, config: T): ConfigSettings[T] =
  new(result)
  result.store = nvs
  result.values = config
