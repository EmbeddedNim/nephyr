import nephyr/general
import zephyr_c/zdevicetree
import zephyr_c/zdevice
import zephyr_c/drivers/zi2c

import typetraits

## *
##  @file Sample app using the Fujitsu MB85RC256V FRAM through ARC I2C.
##

type

  I2cAddress* = distinct uint8
  I2cRegister* = distinct uint8 | distinct uint16

  I2cDevice* = ref object
    dev: ptr device
    address: I2cAddress

template regAddressToBytes(reg: untyped): untyped =
  ##  register address
  var wr_addr: array[sizeof(reg), uint8]
  when distinctBase(I2cRegister) == uint8:
    assert wr_addr.len() == 1
    wr_addr[0] = uint8(devAddr)
  elif distinctBase(I2cRegister) == uint16:
    assert wr_addr.len() == 2
    wr_addr[0] = uint8(devAddr shr 8)
    wr_addr[1] = uint8(devAddr)

proc writeBytes*(i2cDev: I2cDevice; reg: I2cRegister; data: openArray[uint8]) =

  var msgs: array[2, i2c_msg]

  ##  Setup I2C messages
  var wr_addr = regAddressToBytes(reg)

  ##  Send the address to write to
  msgs[0].buf = addr wr_addr[0]
  msgs[0].len = wr_addr.lenBytes()

  msgs[0].flags = I2C_MSG_WRITE

  ##  Data to be written, and STOP after this.
  msgs[1].buf = data
  msgs[1].len = data.len()
  msgs[1].flags = I2C_MSG_WRITE or I2C_MSG_STOP

  return i2c_transfer(i2c_dev, addr(msgs[0]), 2, i2cDev.address)

proc readBytes*(i2cDev: I2cDevice; reg: I2cRegister; data: openArray[uint8]): seq[uint8] =
  var msgs: array[2, i2c_msg]

  ##  Now try to read back from FRAM
  ##  FRAM address
  var wr_addr = regAddressToBytes(reg)

  ##  Setup I2C messages
  ## 
  ##  Send the address to read from
  msgs[0].buf = wr_addr
  msgs[0].len = 2'u
  msgs[0].flags = I2C_MSG_WRITE

  ##  Read from device. STOP after this.
  msgs[1].buf = data
  msgs[1].len = data.lenBytes()
  msgs[1].flags = I2C_MSG_READ or I2C_MSG_STOP

  return i2c_transfer(i2c_dev, addr(msgs[0]), 2, i2cDev.address)
