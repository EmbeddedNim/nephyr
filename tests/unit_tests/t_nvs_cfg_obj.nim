import std/[tables, strformat]
import unittest

import mcu_utils/[logging, timeutils, allocstats]

import nephyr/zephyr/drivers/[zflash, znvs]
include nephyr/extras/nvs_config_obj

type 
  CalibConsts* = object
    a*: int32
    b*: int32
    c*: float32

  ExampleConfigs* = object
    dac_calib_gain*: int32 
    dac_calib_offset*: int32 

    adc_calib_gain*: float32
    adc_calib_offset*: int32

  ExampleComplexConfigs* = object
    dac_calib_gain*: int32 
    dac_calib_offset*: int32 

    adc_calib_gain*: float32
    adc_calib_offset*: int32
    some_tuple*: (int32, float32)
    adc_calibs*: CalibConsts


suite "nvs basic config object":

  setup:
    var nvs = initNvsMock[NvsConfig]()
    # pre-make fields to simulate flash values
    let fld1 = mangleFieldName("/ExampleConfigs/dac_calib_gain").toNvsId(0)
    let fld2 = mangleFieldName("/ExampleConfigs/dac_calib_offset").toNvsId(0)
    nvs.write(fld1, 31415'i32)
    nvs.write(fld2, 2718'i32)
    let fld3 = mangleFieldName("/ExampleConfigs/adc_calib_gain").toNvsId(0)
    let fld4 = mangleFieldName("/ExampleConfigs/adc_calib_offset").toNvsId(0)
    nvs.write(fld3, 3.1415'f32)
    nvs.write(fld4, 2718'i32)
    echo fmt"{fld1.repr=}"
    echo fmt"{fld2.repr=}"
    echo fmt"{fld3.repr=}"
    echo fmt"{fld4.repr=}"

  test "ensure stable hash":
    check mangleFieldName("abracadabra") == -5600162842546114722.Hash
    check mangleFieldName("hello world") == -3218706494461838991.Hash

  test "essential truths":
    # give up and stop if this fails

    let id1 = 1234'i32
    nvs.write(1.NvsId, id1)
    let id1res = nvs.read(1.NvsId, int32)
    check id1 == id1res

  test "basic load":
    var settings = newConfigSettings(nvs, ExampleConfigs())

    # check default 0
    check settings.values.dac_calib_gain == 0
    check settings.values.dac_calib_offset == 0

    # check loaded
    settings.loadAll()
    check settings.values.dac_calib_gain == 31415
    check settings.values.dac_calib_offset == 2718
    check settings.values.adc_calib_gain == 3.1415'f32
    check settings.values.adc_calib_offset == 2718

  test "basic store":
    var settings = newConfigSettings(nvs, ExampleConfigs())

    settings.values.dac_calib_gain = 1111
    settings.values.dac_calib_offset = 2222
    settings.values.adc_calib_gain = 3.34e-1
    settings.values.adc_calib_offset = 89032

    # check loaded
    settings.saveAll()

    var fld1Val = nvs.read(fld1, int32)
    var fld2Val = nvs.read(fld2, int32)
    check fld1Val == 1111
    check fld2Val == 2222
  
    var fld3Val = nvs.read(fld3, float32)
    var fld4Val = nvs.read(fld4, int32)
    check fld3Val - 3.34e-1 < 1.0e-6
    check fld4Val == 89032

  test "key collision":
    # checkAllFields(ExampleConfigs, 0, prefix = "", overrideTest = true)
    let doesCompile = compiles(checkAllFields(ExampleConfigs, 0, prefix = "", overrideTest = true))
    check not doesCompile

  
suite "nvs complex config object":

  setup:
    var nvs = initNvsMock[NvsConfig]()

    # pre-make fields to simulate flash values
    let fld1 = mangleFieldName("/ExampleComplexConfigs/dac_calib_gain").toNvsId(0)
    let fld2 = mangleFieldName("/ExampleComplexConfigs/dac_calib_offset").toNvsId(0)
    let fld3 = mangleFieldName("/ExampleComplexConfigs/some_tuple").toNvsId(0)
    nvs.write(fld1, 31415'i32)
    nvs.write(fld2, 2718'i32)
    nvs.write(fld3, (42'i32, 3.1415'f32)) 
    let fldA1 = mangleFieldName("/ExampleComplexConfigs/adc_calibs/a").toNvsId(0)
    let fldA2 = mangleFieldName("/ExampleComplexConfigs/adc_calibs/b").toNvsId(0)
    let fldA3 = mangleFieldName("/ExampleComplexConfigs/adc_calibs/c").toNvsId(0)
    nvs.write(fldA1, 1137'i32) # fine structure constant
    nvs.write(fldA2, 136'i32) # hydrogen eV
    nvs.write(fldA3, 6.62607015e-34'f32) # planck 

    let fldI11 = mangleFieldName("/ExampleComplexConfigs/dac_calib_gain").toNvsId(1)
    let fldI12 = mangleFieldName("/ExampleComplexConfigs/dac_calib_offset").toNvsId(1)
    let fldI13 = mangleFieldName("/ExampleComplexConfigs/some_tuple").toNvsId(1)
    let fldI1A1 = mangleFieldName("/ExampleComplexConfigs/adc_calibs/a").toNvsId(1)
    let fldI1A2 = mangleFieldName("/ExampleComplexConfigs/adc_calibs/b").toNvsId(1)
    let fldI1A3 = mangleFieldName("/ExampleComplexConfigs/adc_calibs/c").toNvsId(1)

  test "load values":
    var settings = newConfigSettings(nvs, ExampleComplexConfigs())

    # check default 0
    check settings.values.dac_calib_gain == 0
    check settings.values.dac_calib_offset == 0
    check settings.values.some_tuple == (0'i32, 0.0'f32)
    check settings.values.adc_calibs.a == 0
    check settings.values.adc_calibs.b == 0
    check settings.values.adc_calibs.c == 0

    # check loaded
    settings.loadAll()
    check settings.values.dac_calib_gain == 31415
    check settings.values.dac_calib_offset == 2718
    check settings.values.some_tuple == (42'i32, 3.1415'f32)
    check settings.values.adc_calibs.a == 1137
    check settings.values.adc_calibs.b == 136
    check settings.values.adc_calibs.c - 6.62607015e-34'f32 < 1.0e-6

  test "save values":
    var settings = newConfigSettings(nvs, ExampleComplexConfigs(), 1)

    settings.values.dac_calib_gain = 1111
    settings.values.dac_calib_offset = 2222
    settings.values.some_tuple = (33'i32, 0.31415'f32)

    settings.values.adc_calibs.a = 2137
    settings.values.adc_calibs.b = -2121
    settings.values.adc_calibs.c = 89.4324

    # check loaded
    settings.saveAll()

    var fld1Val = nvs.read(fldI11, int32)
    var fld2Val = nvs.read(fldI12, int32)
    var fld3Val = nvs.read(fldI13, (int32, float32))
    check fld1Val == 1111
    check fld2Val == 2222
    check fld3Val == (33'i32, 0.31415'f32)
  
    var fldA1Val = nvs.read(fldI1A1, int32)
    var fldA2Val = nvs.read(fldI1A2, int32)
    var fldA3Val = nvs.read(fldI1A3, float32)
    check fldA1Val == 2137
    check fldA2Val == -2121
    check fldA3Val - 89.4324 < 1.0e-5
  
  test "save values":
    var settings = newConfigSettings(nvs, ExampleComplexConfigs(), 1)
    

    settings.values.dac_calib_gain = 1111
    settings.values.dac_calib_offset = 2222

    settings.values.adc_calibs.a = 2137
    settings.values.adc_calibs.b = -2121
    settings.values.adc_calibs.c = 89.4324

    # check loaded
    settings.saveAll()

    var fld1Val = nvs.read(fldI11, int32)
    var fld2Val = nvs.read(fldI12, int32)
    check fld1Val == 1111
    check fld2Val == 2222
  
    var fldA1Val = nvs.read(fldI1A1, int32)
    var fldA2Val = nvs.read(fldI1A2, int32)
    var fldA3Val = nvs.read(fldI1A3, float32)
    check fldA1Val == 2137
    check fldA2Val == -2121
    check fldA3Val - 89.4324 < 1.0e-5
  