
import nephyr/utils
import nephyr/drivers/i2c

const
  SF05_ADDR*: I2cAddr = I2cAddr(0x40)
  CMD_READ_CONTINUOUS*: I2cRegister = I2cReg16(0x1000)
  CMD_READ_SERIAL_HIGH*: I2cRegister = I2cReg16(0x31AE)
  CMD_READ_SERIAL_LOW*: I2cRegister = I2cReg16(0x31AF)
  CMD_SOFT_RESET*: I2cRegister = I2cReg16(0x2000)

  SCALE_FLOW* = 140'f32   #// scale factor flow
  OFFSET_FLOW* = 32_000'f32   #// offset flow

  POLYNOMIAL* = 0x131'u16    #// P(x) = x^8 + x^5 + x^4 + 1 = 100110001


var dev: I2cDevice

proc test() =
  var data: Bytes[4]
  dev.doTransfer(
      regWrite(CMD_READ_SERIAL_LOW, STOP),
      read(data, STOP)
  )

test()