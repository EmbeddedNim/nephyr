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
  
proc test_i2c_txn_form1() =
  var dev = i2c_devptr()

  dev.transfer: 
    register: CMD_WRITE
    read or stop: [0x8, 0x7]
    read: CMD_A CMD_B

when defined(TodoI2cForm2Macro):
  ## keeping this here for now, this might be the "better" format
  proc test_i2c_txn_form2() =
    var dev = i2c_devptr()

    dev.transfer( 
      register = CMD_WRITE,
      write = @[0x8, 0x7],
      read = CMD_A CMD_B,
    )

test_i2c_devptr()
test_i2c_dev_cstring()
test_i2c_txn_form1()
