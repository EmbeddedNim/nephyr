
import macros

import nephyr/general
import nephyr/drivers/i2c
import zephyr_c/drivers/zi2c

macro transfer*(i2cDev: I2cDevice; args: varargs[untyped]): untyped =

  echo "args: ", treeRepr args
  let cnt = newIntLitNode(4)

  result = 
    quote do:
      var msgs: array[`cnt`, i2c_msg]
      check: i2c_transfer(`i2cDev`.bus, addr(msgs[0]), msgs.len().uint8, `i2cDev`.address.uint16)

proc msg*(data: var openArray[uint8]): i2cMsg =
  result = i2cMsg()
  result.buf = addr data[0]

proc testExample*() =
  var m1 = @[0x01'u8]
  var trns = [
    msg(m1)
  ]

let devptr: cstring = "i2c0"
var dev = initI2cDevice(devptr, 0x06.I2cAddr)

dev.transfer: 
  register: CMD_WRITE
  read: [0x8, 0x7]
  read: CMD_A CMD_B

dev.transfer( 
  register = CMD_WRITE,
  write = @[0x8, 0x7],
  read = CMD_A CMD_B,
)
