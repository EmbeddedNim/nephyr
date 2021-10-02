
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
  read: <0x8 0x7>
  read: CMD_A CMD_B

dev.transfer( 
  register = CMD_WRITE,
  write = @[0x8, 0x7],
  read = CMD_A CMD_B,
)

dev.transfer: 
  register: CMD_WRITE
  register: {1000}
  &mikrobus_i2c {
    status = "okay",
    spi-max-frequency = `<100000>`,
  }
  &mikrobus_spi: 
    status: "okay"

    click_spi2: spi-device@1 {
      compatible = "microchip,mcp3204",
      reg = `<0x1>`,
      spi-max-frequency = `<100000>`,
      label = "MCP3201",
      #io-channel-cells = <1>,
    }


