import nephyr/drivers/i2c
export i2c

proc i2c_devptr(): I2cDevice =
  let devptr = DEVICE_DT_GET(DT_NODELABEL(tok"i2c1"))
  var dev = initI2cDevice(devptr, 0x47.I2cAddr)
  result = dev


proc test_i2c_devptr() =
  var dev = i2c_devptr()
  echo "dev: ", repr dev
  
proc test_i2c_dev_cstring() =
  let devname: cstring = DT_LABEL(DT_ALIAS(tok"i2c0"))
  var dev = initI2cDevice(devname, 0x47.I2cAddr)
  echo "dev: ", repr dev
  
proc test_i2c_txn_form2() =
  var dev = i2c_devptr()
  dev.transfer( 
    register = CMD_WRITE,
    write = @[0x8, 0x7],
    write or stop = @[0x8, 0x7],
    read = CMD_A CMD_B,
  )

proc test_i2c_do_txn() =
  var dev = i2c_devptr()
  dev.doTransfers(
    unsafeI2cMsg(0x1, 0x2, I2C_MSG_WRITE),
    unsafeI2cMsg([0x1'u8, 0x2], I2C_MSG_READ)
  )

test_i2c_devptr()
test_i2c_dev_cstring()
test_i2c_txn_form2()
test_i2c_do_txn()
