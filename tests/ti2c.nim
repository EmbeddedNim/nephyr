

type
  I2cFlag* = distinct uint32

  i2c_msg* {.bycopy.} = object
    buf*: ptr uint8             ## * Data buffer in bytes
    ## * Length of buffer in bytes
    len*: uint32               ## * Flags for this message
    flags*: I2cFlag

const
  I2C_MSG_WRITE* = I2cFlag(0 shl 0) ## Write message to I2C
  I2C_MSG_READ* = I2cFlag(1) ## Read message from I2C
  I2C_MSG_STOP* = I2cFlag(1 shl 1) ## Send STOP after this
  I2C_MSG_RESTART* = I2cFlag(1 shl 2) ## RESTART I2C transaction for this
  I2C_MSG_ADDR_10_BITS* = I2cFlag(1 shl 3) ## Use 10-bit addressing for this


proc test() =
  var x = ([1,2], [2,3,4])
  echo "x: tp: ", typeof(x)
  echo "x: ", x
  echo "testArg: "
  devdoTransfers(
    unsafeI2cMsg(0x1, 0x2, I2C_MSG_WRITE),
    unsafeI2cMsg([0x1'u8, 0x2], I2C_MSG_READ)
  )

test()