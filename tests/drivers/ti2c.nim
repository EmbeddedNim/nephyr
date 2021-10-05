import nephyr/drivers/i2c
export i2c

proc test_i2c_devptr() =
  let devptr = DEVICE_DT_GET(DT_NODELABEL(tok"i2c1"))
  var dev = initI2cDevice(devptr, 0x47.I2cAddr)
  echo "dev: ", repr dev
  
proc test_i2c_dev_cstring() =
  let devname: cstring = DT_LABEL(DT_ALIAS(tok"i2c0"))
  var dev = initI2cDevice(devname, 0x47.I2cAddr)
  echo "dev: ", repr dev
  
test_i2c_devptr()
test_i2c_dev_cstring()
