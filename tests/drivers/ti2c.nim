import nephyr/drivers/i2c
export i2c

proc test_i2c() =
  let devptr = DEVICE_DT_GET(DT_NODELABEL(tok"i2c1"))
  var dev = initI2cDevice(devptr, 0x47.I2cAddr)
  echo "dev: ", repr dev
  
test_i2c()
