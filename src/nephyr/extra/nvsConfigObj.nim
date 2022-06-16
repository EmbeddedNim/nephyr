
## Example usage of NVS
## license: Apache-2.0

import macros, strutils, md5, options
import json

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

proc `$`*(serial: SerialNumber): string =
  let 
    bmajor = serial.board_major.int.intToStr(3)
    bminor = serial.board_minor.int.intToStr(1)
    number = serial.number.int.intToStr(4)
  
  "" & bmajor & bminor & number

proc parseSerialNumber*(raw_serno: string): SerialNumber =
  let serno = raw_serno.replace("0x", "")
  assert serno.len() == 8
  result.board_major = parseInt(serno[0..2])
  result.board_minor = parseInt(serno[3..3])
  result.number = parseInt(serno[4..7])

proc parseSerialNumber*(serno: int): SerialNumber =
  serno.toHex(8).parseSerialNumber()

proc toInt*(serial: SerialNumber): int32 =
  let serstr: string = $serial
  serstr.parseHexInt().int32


type 

  ConfigSettings* = object
    # Object with all possible configuration settings
    # Note only values that are changed from the defaults
    # are written the NVS flash. 
    
    serial_number*: int32
    reading_time*: int32
    
    dac_calib_zero_cha*: int32 
    dac_calib_gain_cha*: int32 

    adc_calib_gain*: float32
    adc_calib_zero*: int32


## The code below is a bit ugly, it's to handle putting in different 
## types like ints, floats, strings, etc
## 
## Don't read too closely, it may produce a headache. Read
## the "public api" after this section ;) 

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

var
  SETTINGS*: ConfigSettings
  store: NvsConfig

proc load_field*(settings: var ConfigSettings, name: string): int32 =
  var mname = mangleFieldName(name)
  try:
    var rval = store.read(mname, int32)
    logi("CFG", "name: %s => %s", name, $rval)
    setObjectField(settings, name, rval)
  except KeyError:
    logi("CFG", "skipping name: %s", $name)

proc save_field*(settings: var ConfigSettings, name: string, val: int32) =
  logi("CFG", "saving settings ")
  var mName = mangleFieldName(name)
  var oldVal = getObjectField(settings, name)
  var currVal = val
  if currVal != oldVal:
    logi("CFG", "save setting field: %s(%s) => %d => %d", name.cstring, mName, oldVal, currVal)
    store.write(mName, val)
  else:
    logi("CFG", "skip setting field: %s(%s) => %d => %d", name.cstring, mName, oldVal, currVal)


proc config_settings_default*(): ConfigSettings =
  # set up the default values for the ConfigSettings type

  result = ConfigSettings(
    dac_calib_zero_cha: -100, 
    dac_calib_gain_cha: 194, 

    adc_calib_gain: 3.452e-3,
    adc_calib_zero: 0,
  )
 
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
