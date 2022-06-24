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
    diffed: bool

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

proc getObj[T: ref](v: typedesc[T]): T = result = T()
proc getObj[T](v: typedesc[T]): T = discard

proc loadFieldValue*[T, V](cfg: ConfigSettings[T], keyId: NvsId, value: var V): bool =
  try:
    let rval = cfg.store.read(keyId, typeof(value))
    value = rval
    result = true
  except KeyError:
    result = false

proc saveFieldValue*[T, V](cfg: ConfigSettings[T], keyId: NvsId, value: V): bool =
  try:
    cfg.store.write(keyId, value)
    result = true
  except KeyError:
    result = false

template loadField*[T, V](
    cfg: ConfigSettings[T],
    base: string,
    index: int,
    name: string,
    value: var V,
) =
  const baseHash: Hash = mangleFieldName(base & "/" & name)
  let keyId = baseHash.toNvsId(index)
  let res = loadFieldValue(cfg, keyid, value)
  if res:
    logDebug("CFG name:", name, keyId, " => ", value)
  else:
    logDebug("CFG", "skipping name: ", keyId, name)

template saveField*[T, V](
    cfg: ConfigSettings[T],
    base: string,
    index: int,
    name: string,
    value: V,
) =
  const baseHash: Hash = mangleFieldName(base & "/" & name)
  let keyId = baseHash.toNvsId(index)
  let res = saveFieldValue(cfg, keyid, value)
  if res:
    logDebug("CFG name:", name, keyId, " => ", value)
  else:
    logDebug("CFG", "skipping name: ", keyId, name)

template diffField*[T, V](
    cfg: ConfigSettings[T],
    base: string,
    index: int,
    name: string,
    value: V,
) =
  const baseHash: Hash = mangleFieldName(base & "/" & name)
  let keyId = baseHash.toNvsId(index)
  var previous: T
  let res = loadFieldValue(cfg, keyid, previous)
  if res:
    logDebug("CFG diff name:", name, keyId, " => ", value)
  else:
    logDebug("CFG", "diff skipping name: ", keyId, name)

proc checkField*(
    overrideTest: static[bool],
    base: static[string],
    index: static[int],
    name: static[string],
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

template doForAllFields(cfg, values, doAllImpl, doField, baseName: untyped) =
  ## template to handle recursively apply `doAllImpl` and `doField` for 
  ## all fields in `values` object 
  for field, value in values.fieldPairs():
    when typeof(value) is object:
      doAllImpl(cfg, value, index, prefix = baseName & "/" & field)
    elif typeof(value) is tuple:
      doField(cfg, baseName, index, field, value)
    elif typeof(value) is ref:
      static: error("not implemented yet")
    elif typeof(value) is array:
      static: error("not implemented yet")
    else:
      doField(cfg, baseName, index, field, value)

template checkFieldTmpl( overrideTest, base, index, name, value: untyped) =
  static:
    checkField(overrideTest, base, index, name)

proc diffAllImpl[T, V](cfg: ConfigSettings[T], values: V, index: int, prefix: static[string]) =
  const baseName = makeBaseName(prefix, V)
  echo "DIFFALLIMPL: ", $typeof(values), " basename: ", baseName
  doForAllFields(cfg, values, diffAllImpl, diffField, baseName)
  
proc loadAllImpl[T, V](cfg: ConfigSettings[T], values: var V, index: int, prefix: static[string]) =
  const baseName = makeBaseName(prefix, V)
  # echo "LOADALLIMPL: ", $typeof(values), " basename: ", baseName
  doForAllFields(cfg, values, loadAllImpl, loadField, baseName)

proc saveAllImpl[T, V](cfg: ConfigSettings[T], values: V, index: int, prefix: static[string]) =
  const baseName = makeBaseName(prefix, V)
  # echo "SAVEALLIMPL: ", $typeof(values), " basename: ", baseName
  doForAllFields(cfg, values, saveAllImpl, saveField, baseName)

template checkAllFields*[V](overrideTest: static[bool], values: typedesc[V], index: static[int], prefix: static[string]) =
  const baseName = makeBaseName(prefix, V)
  const store = false
  var vals = getObj(values)
  doForAllFields(store, vals, checkAllFields, checkFieldTmpl, baseName)

## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
## Public API
## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
## Implements a wrapper on top of NVS. 
## 
## 

template checkAllFields*[T](overrideTest: static[bool], value: T, index: static[int], prefix: static[string]) =
  const store = false
  checkAllFields(store, typeof value, index, prefix)

proc loadAll*[T](settings: var ConfigSettings[T], index: static[int] = 0) =
  ## loads all fields for an object from an nvs store
  ## 
  let idx = if index != 0: index else: settings.index
  checkAllFields(false, T, index, prefix = "")
  loadAllImpl(settings, settings.values, idx, prefix = "")

proc saveAll*[T](settings: ConfigSettings[T], index: static[int] = 0) =
  ## saves all fields for an object into an nvs store
  ## 
  let idx = if index != 0: index else: settings.index
  checkAllFields(false, T, index, prefix = "")
  saveAllImpl(settings, settings.values, idx, prefix = "")

proc isDiff*[T](settings: ConfigSettings[T], index: static[int] = 0): bool =
  ## checks if diff
  ## 
  let idx = if index != 0: index else: settings.index
  var previous: T = getObj(T)
  diffAllImpl(settings, previous, idx, prefix = "")

proc newConfigSettings*[T](nvs: NvsConfig, config: T, index: static[int] = 0): ConfigSettings[T] =
  new(result)
  result.store = nvs
  result.values = config
  result.index = index

  checkAllFields(false, T, index, prefix = "")