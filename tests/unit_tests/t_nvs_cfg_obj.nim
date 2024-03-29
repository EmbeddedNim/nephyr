import std/[tables, strformat]
import unittest

include nephyr/extras/nvsConfigObj

type 
  ExampleConfigs* = object
    dac_calib_gain*: int32 
    dac_calib_offset*: int32 

    adc_calib_gain*: float32
    adc_calib_offset*: int32

suite "nvs config object":

  setup:
    var nvs = NvsConfig()

    # pre-make fields to simulate flash values
    let fld1 = mangleFieldName("dac_calib_gain")
    let fld2 = mangleFieldName("dac_calib_offset")
    nvs.write(fld1, 31415)
    nvs.write(fld2, 2718)


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

  test "basic store":
    var settings = newConfigSettings(nvs, ExampleConfigs())

    # check default 0
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