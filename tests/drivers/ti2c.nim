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
    {write} = CMD_WRITE,
    {write} = [0x8, 0x7],
    {read, stop} = @[0x8, 0x7],
    {read, restart} = @[0x8, 0x7],
    {read, stop} = [CMD_A, CMD_B],
  )

proc test_i2c_do_txn() =
  var dev = i2c_devptr()
  var data: array[3, uint8]
  var data2: array[1, uint8]

  dev.doTransfers(
    i2cRead(data),
    i2cWrite([uint8 0x1, 0x2], I2C_MSG_STOP),
    i2cWrite([0x1'u8, 0x2]),
    i2cWrite(0x1, 0x2),
    i2cRead(data),
    i2cRead(data2)
  )

test_i2c_devptr()
test_i2c_dev_cstring()
test_i2c_txn_form2()
test_i2c_do_txn()
