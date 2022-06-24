## Example usage of NVS
## license: Apache-2.0

## Module for getting and setting global constants that need to be 
## written or read from flash memory. This uses the "NVS" flash library 
## from Zephyr. 

import std/[strutils, hashes, options, strformat, tables]
import std/[macros, macrocache, typetraits]

import mcu_utils/logging

import ../drivers/nvs

const keyTableCheck = CacheTable"keyTableCheck"

type
  ConfigSettings*[T] = ref object
    store*: NvsConfig
    values*: T
    index*: int

## The code below handles mangling field names to unique id's
## for types like ints, floats, strings, etc
## 

proc mangleFieldName*(name: string): Hash {.compileTime.} =
  result = hashIgnoreStyle(name)
proc toNvsId*(hs: Hash, index: int): NvsId =
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

template makeBaseName(prefix: string, typ: untyped): string =
  if prefix == "": prefix & "/" & $(distinctBase(typ))
  else: prefix

proc getObj[T: ref](v: typedesc[T]): T =
  result = T()
proc getObj[T](v: typedesc[T]): T =
  discard

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
    value: var V,
) =
  const baseHash: Hash = mangleFieldName(base & "/" & name)
  let keyId = baseHash.toNvsId(index)
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
  const baseHash: Hash = mangleFieldName(base & "/" & name)
  let keyId = baseHash.toNvsId(index)
  let res = saveFieldValue(store, keyid, value)
  if res:
    logDebug("CFG name:", name, keyId, " => ", value)
  else:
    logDebug("CFG", "skipping name: ", keyId, name)

proc checkField*(
    base: static[string],
    index: static[int],
    name: static[string],
    overrideTest: static[bool]
) {.compileTime.} =
  let baseName = base & "/" & name
  let baseHash: Hash = mangleFieldName(baseName)
  let keyId = baseHash.toNvsId(index)
  # echo "CFG check:name:", name, " keyId: ", keyId
  var found = false
  for key, val in keyTableCheck:
    if key == $keyId:
      found = true
      if val.strVal != name or overrideTest:
        echo("KeyId's present: ")
        for k, v in keyTableCheck:
          echo("KeyId's: " & $k & " val: " & $v)
        error("keyId hash collision: " & $keyId & " name: " & $name)

  if not found:
    keyTableCheck[$keyId] = newLit(name)

template forAllFields(store, values, doAllImpl, doField, baseName: untyped) =
  for field, value in values.fieldPairs():
    when typeof(value) is object:
      doAllImpl(store, value, index, prefix = baseName & "/" & field)
    elif typeof(value) is tuple:
      doField(store, baseName, index, field, value)
    elif typeof(value) is ref:
      static: error("not implemented yet")
    elif typeof(value) is array:
      static: error("not implemented yet")
    else:
      doField(store, baseName, index, field, value)

template checkAllFields*[T](values: typedesc[T], index: static[int], prefix: static[string], overrideTest = false) =
  const baseName = makeBaseName(prefix, T)
  # echo "CHECKFIELDSIMPL: ", $typeof(values), " basename: ", baseName
  for field, value in getObj(values).fieldPairs():
    when typeof(value) is object or typeof(value) is tuple:
      checkAllFields(typeof(value), index, baseName & "/" & field, overrideTest)
    elif typeof(value) is ref:
      static: warning("not implemented yet")
    elif typeof(value) is array:
      static: warning("not implemented yet")
    else:
      static:
        checkField(baseName, index, field, overrideTest)

proc diffAllImpl[T](store: NvsConfig, values: T, index: int, prefix: static[string]) =
  const baseName = makeBaseName(prefix, T)
  echo "DIFFALLIMPL: ", $typeof(values), " basename: ", baseName
  for field, value in values.fieldPairs():
    when typeof(value) is object:
      saveAllImpl(store, value, index, prefix = baseName & "/" & field)
    elif typeof(value) is tuple:
      saveField(store, baseName, index, field, value)
    elif typeof(value) is ref:
      static: error("not implemented yet")
    elif typeof(value) is array:
      static: error("not implemented yet")
    else:
      saveField(store, baseName, index, field, value)

proc loadAllImpl[T](store: NvsConfig, values: var T, index: int, prefix: static[string]) =
  const baseName = makeBaseName(prefix, T)
  # echo "LOADALLIMPL: ", $typeof(values), " basename: ", baseName
  forAllFields(store, values, loadAllImpl, loadField, baseName)

proc loadAll*[T](settings: var ConfigSettings[T], index: static[int] = 0) =
  ## loads all fields for an object from an nvs store
  ## 
  let idx = if index != 0: index else: settings.index
  checkAllFields(T, index, prefix = "")
  loadAllImpl(settings.store, settings.values, idx, prefix = "")

proc saveAllImpl[T](store: NvsConfig, values: T, index: int, prefix: static[string]) =
  const baseName = makeBaseName(prefix, T)
  # echo "SAVEALLIMPL: ", $typeof(values), " basename: ", baseName
  forAllFields(store, values, saveAllImpl, saveField, baseName)

proc saveAll*[T](settings: ConfigSettings[T], index: static[int] = 0) =
  ## saves all fields for an object into an nvs store
  ## 
  let idx = if index != 0: index else: settings.index
  checkAllFields(T, index, prefix = "")
  saveAllImpl(settings.store, settings.values, idx, prefix = "")

proc mdiffs*[T](settings: ConfigSettings[T], values: T, index: static[int] = 0) =
  discard

proc isDiff*[T](settings: ConfigSettings[T], index: static[int] = 0) =
  ## checks if diff
  ## 
  var previous = getObj[T]()
  diffAllImpl(settings.store, previous, index, prefix = "")

proc newConfigSettings*[T](nvs: NvsConfig, config: T, index: static[int] = 0): ConfigSettings[T] =
  new(result)
  result.store = nvs
  result.values = config
  result.index = index

  checkAllFields(T, index, prefix = "")