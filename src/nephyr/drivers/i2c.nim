import nephyr/utils
import zephyr_c/zdevicetree
import zephyr_c/drivers/zspi
import zephyr_c/dt_bindings/dt_gpio

import sequtils

## *
##  @file Sample app using the Fujitsu MB85RC256V FRAM through ARC I2C.
##

proc write_bytes*(i2c_dev: ptr device; `addr`: uint16; data: ptr uint8; num_bytes: uint32): cint =
  var wr_addr: array[2, uint8]
  var msgs: array[2, i2c_msg]
  ##  FRAM address
  wr_addr[0] = (`addr` shr 8) and 0xFF
  wr_addr[1] = `addr` and 0xFF
  ##  Setup I2C messages
  ##  Send the address to write to
  msgs[0].buf = wr_addr
  msgs[0].len = 2'u
  msgs[0].flags = I2C_MSG_WRITE
  ##  Data to be written, and STOP after this.
  msgs[1].buf = data
  msgs[1].len = num_bytes
  msgs[1].flags = I2C_MSG_WRITE or I2C_MSG_STOP
  return i2c_transfer(i2c_dev, addr(msgs[0]), 2, FRAM_I2C_ADDR)

proc read_bytes*(i2c_dev: ptr device; `addr`: uint16; data: ptr uint8; num_bytes: uint32): cint =
  var wr_addr: array[2, uint8]
  var msgs: array[2, i2c_msg]
  ##  Now try to read back from FRAM
  ##  FRAM address
  wr_addr[0] = (`addr` shr 8) and 0xFF
  wr_addr[1] = `addr` and 0xFF
  ##  Setup I2C messages
  ##  Send the address to read from
  msgs[0].buf = wr_addr
  msgs[0].len = 2'u
  msgs[0].flags = I2C_MSG_WRITE
  ##  Read from device. STOP after this.
  msgs[1].buf = data
  msgs[1].len = num_bytes
  msgs[1].flags = I2C_MSG_READ or I2C_MSG_STOP
  return i2c_transfer(i2c_dev, addr(msgs[0]), 2, FRAM_I2C_ADDR)
