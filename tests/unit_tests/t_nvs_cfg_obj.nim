import std/[tables, strformat]
import unittest

import mcu_utils/[logging, timeutils, allocstats]

import nephyr/zephyr/drivers/[zflash, znvs]
include nephyr/extras/nvsConfigObj

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
    let fld1 = mangleFieldName("/ExampleConfigs/dac_calib_gain").toNvsId()
    let fld2 = mangleFieldName("/ExampleConfigs/dac_calib_offset").toNvsId()
    nvs.write(fld1, 31415'i32)
    nvs.write(fld2, 2718'i32)
    let fld3 = mangleFieldName("/ExampleConfigs/adc_calib_gain").toNvsId()
    let fld4 = mangleFieldName("/ExampleConfigs/adc_calib_offset").toNvsId()
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

    # check loaded
    settings.saveAll()

    var fld1Val: int32
    nvs.read(fld1, fld1Val)

    var fld2Val: int32
    nvs.read(fld2, fld2Val)

    check fld1Val == 1111
    check fld2Val == 2222
  
suite "nvs complex config object":

  setup:
    var nvs = initNvsMock[NvsConfig]()

    # pre-make fields to simulate flash values
    let fld1 = mangleFieldName("/ExampleComplexConfigs/dac_calib_gain").toNvsId
    let fld2 = mangleFieldName("/ExampleComplexConfigs/dac_calib_offset").toNvsId
    nvs.write(fld1, 31415'i32)
    nvs.write(fld2, 2718'i32)
    let fldA1 = mangleFieldName("/ExampleComplexConfigs/adc_calibs/a").toNvsId
    let fldA2 = mangleFieldName("/ExampleComplexConfigs/adc_calibs/b").toNvsId
    let fldA3 = mangleFieldName("/ExampleComplexConfigs/adc_calibs/c").toNvsId
    nvs.write(fldA1, 1137'i32) # fine structure constant
    nvs.write(fldA2, 136'i32) # hydrogen eV
    nvs.write(fldA3, 6.62607015e-34'f32) # planck 

  test "load values":
    var settings = newConfigSettings(nvs, ExampleComplexConfigs())

    # check default 0
    check settings.values.dac_calib_gain == 0
    check settings.values.dac_calib_offset == 0
    check settings.values.adc_calibs.a == 0
    check settings.values.adc_calibs.b == 0
    check settings.values.adc_calibs.c == 0

    # check loaded
    settings.loadAll()
    check settings.values.dac_calib_gain == 31415
    check settings.values.dac_calib_offset == 2718
    check settings.values.adc_calibs.a == 1137
    check settings.values.adc_calibs.b == 136
    check settings.values.adc_calibs.c - 6.62607015e-34'f32 < 1.0e-6

  test "save values":
    var settings = newConfigSettings(nvs, ExampleComplexConfigs())

    settings.values.dac_calib_gain = 1111
    settings.values.dac_calib_offset = 2222

    # check loaded
    settings.saveAll()

    var fld1Val: int32
    nvs.read(fld1, fld1Val)

    var fld2Val: int32
    nvs.read(fld2, fld2Val)

    check fld1Val == 1111
    check fld2Val == 2222

