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
  
# proc test_i2c_txn_form2() =
#   var dev = i2c_devptr()
#   dev.transfer( 
#     {write} = CMD_WRITE,
#     {write} = [0x8, 0x7],
#     {read, stop} = @[0x8, 0x7],
#     {read, restart} = @[0x8, 0x7],
#     {read, stop} = [CMD_A, CMD_B],
#   )

proc test_raw_zephyr_api*() =
  ## Setup I2C messages
  var dev = i2c_devptr()
  var wr_addr = regAddressToBytes(I2cReg8 0x44)
  var data = [0x0'u8, 0x0, 0x0]
  var rxdata = [0x0'u8, 0x0, 0x0]

  var msgs: array[3, i2c_msg]
  ## reg the address to write to

  msgs[0].buf = addr wr_addr[0]
  msgs[0].len = wr_addr.lenBytes()

  msgs[0].flags = I2C_MSG_WRITE or I2C_MSG_STOP

  ##  Data to be written, and STOP after this.
  msgs[1].buf = addr data[0]
  msgs[1].len = data.lenBytes()
  msgs[1].flags = I2C_MSG_WRITE or I2C_MSG_STOP

  ##  Data to be read, and STOP after this.
  msgs[2].buf = addr rxdata[0]
  msgs[2].len = rxdata.lenBytes()
  msgs[2].flags = I2C_MSG_READ or I2C_MSG_STOP

  check: i2c_transfer(dev.bus, addr(msgs[0]), msgs.len().uint8, dev.address.uint16)

proc test_i2c_do_txn() =
  # Examples of generic I2C Api
  var dev = i2c_devptr()
  var data: array[3, uint8]
  var data2 = newSeq[uint8](8)
  var someData = [0xE3'u8, 0x01, 0x02]

  # Nim nep1 format
  dev.doTransfer(
    regWrite(I2cReg16(0x4ffd)), # writes i2c register/command
    read(data), # i2c read into array
    read(data2), # i2c read into seq
    write([0x1'u8, 0x2], I2C_MSG_STOP), # i2c write w/ stop
    write(someData, I2C_MSG_STOP),
    write(bytes(0x1'u8, 0x2)),
    write(bytes(0x1, 0x2), {I2C_MSG_WRITE, I2C_MSG_STOP}),
  )

  echo "got data: ", repr data
  echo "got data2: ", repr data2

test_i2c_devptr()
test_i2c_dev_cstring()
# test_i2c_txn_form2()
test_i2c_do_txn()
