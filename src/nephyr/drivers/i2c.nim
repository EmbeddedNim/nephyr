import bitops

import nephyr/general
import zephyr_c/zdevicetree
import zephyr_c/zdevice
import zephyr_c/drivers/zi2c
import zephyr_c/cmtoken

import typetraits
export zi2c
export cmtoken, zdevice, zdevicetree

## *
##  @file Sample app using the Fujitsu MB85RC256V FRAM through ARC I2C.
##

type

  I2cAddr* = distinct uint8
  I2cReg8* = distinct uint8 
  I2cReg16* = distinct uint16
  I2cRegister* = I2cReg8 | I2cReg16

  I2cDevice* = ref object
    bus*: ptr device
    address*: I2cAddr


template regAddressToBytes(reg: untyped): i2cMsg =
  var msg = i2c_msg()
  ##  register address
  var wr_addr: array[sizeof(reg), uint8]
  when distinctBase(typeof(reg), true) is uint8:
    assert wr_addr.len() == 1
    wr_addr[0] = uint8(devAddr)
  elif distinctBase(typeof(reg), true) is uint16:
    assert wr_addr.len() == 2
    wr_addr[0] = uint8(reg.uint16 shr 8)
    wr_addr[1] = uint8(reg)
  
  wr_addr

when defined(ExperimentalI2CApi):
  # This is a holder for breaking out the i2c api a bit more

  func i2cData*(data: var openArray[uint8], flags: set[I2CFlag] = {}): i2cMsg =
    result = i2c_msg()
    result.buf = unsafeAddr data[0]
    result.len = data.lenBytes()
    result.flags = setOr[I2CFlag](flags)

  func i2cData*(data: varargs[uint8], flags: set[I2CFlag] = {}): i2cMsg =
    i2cData(data, flags)

  proc writeRegData*(reg: I2cRegister, data: openArray[uint8], stop = true): openArray[i2cMsg] =
    result = array[2, i2cMsg]
    result[0] = i2cData(data, I2C_MSG_WRITE)
    result[1] = i2cData(data, I2C_MSG_WRITE or I2C_MSG_STOP)

  proc readRegData*(reg: I2cRegister, data: openArray[uint8], stop = true): openArray[i2cMsg] =
    result = array[2, i2cMsg]
    result[0] = i2cData(data, I2C_MSG_READ)
    result[1] = i2cData(data, I2C_MSG_READ or I2C_MSG_STOP)

  proc transfer*(i2cDev: I2cDevice; reg: I2cRegister; data: openArray[i2cMsg]) =
    check: i2c_transfer(i2c_dev, addr(data[0]), data.len(), i2cDev.address)


## ======================================================================================= ##
## Basic I2C api to read/write from a register (or command) then the resulting data 
## ======================================================================================= ##

proc initI2cDevice*(devname: cstring | ptr device, address: I2cAddr): I2cDevice =
  result = I2cDevice()
  when typeof(devname) is cstring:
    result.bus = device_get_binding(devname)
  elif typeof(devname) is ptr device:
    result.bus = devname
  result.address = address

  if result.bus.isNil():
    let emsg = 
      when typeof(devname) is cstring:
        "error finding i2c device: " & $devname
      elif typeof(devname) is ptr device:
        "error finding i2c device: 0x" & $(cast[int](devname).toHex())
    raise newException(OSError, emsg)

proc writeRegister*(i2cDev: I2cDevice; reg: I2cRegister; data: openArray[uint8]) =
  ## Setup I2C messages
  var wr_addr = regAddressToBytes(reg)

  var msgs: array[2, i2c_msg]
  ## reg the address to write to

  msgs[0].buf = addr wr_addr[0]
  msgs[0].len = wr_addr.lenBytes()

  msgs[0].flags = I2C_MSG_WRITE or I2C_MSG_STOP

  ##  Data to be written, and STOP after this.
  msgs[1].buf = addr data[0]
  msgs[1].len = data.lenBytes()
  msgs[1].flags = I2C_MSG_WRITE or I2C_MSG_STOP

  check: i2c_transfer(i2cDev.bus, addr(msgs[0]), msgs.len(), i2cDev.address)

proc readRegister*(i2cDev: I2cDevice; reg: I2cRegister; data: var openArray[uint8]) =

  ## reg address
  var wr_addr = regAddressToBytes(reg)

  var msgs: array[2, i2c_msg]
  ## Setup I2C messages
  ## 
  ## Send the address to read from
  msgs[0].buf = addr wr_addr[0]
  msgs[0].len = wr_addr.lenBytes()
  msgs[0].flags = I2C_MSG_WRITE or I2C_MSG_STOP

  ##  Read from device. STOP after this.
  msgs[1].buf = addr data[0]
  msgs[1].len = data.lenBytes()
  msgs[1].flags = I2C_MSG_READ or I2C_MSG_STOP

  check: i2c_transfer(i2cDev.bus, addr(msgs[0]), msgs.len().uint8, i2cDev.address.uint16)

import macros

proc parseFlags(args: var seq[NimNode]): (I2cFlag, bool) =
  var
    txFlag: I2cFlag 
    txIsRegister: bool 

  case args[0].strVal:
  of "read":
    txFlag = txFlag or I2C_MSG_READ
  of "write":
    txFlag = txFlag or I2C_MSG_WRITE
  of "register":
    txFlag = txFlag or I2C_MSG_WRITE
    txIsRegister = true
  else:
    error("must be one of I2cFlag type", args[0])

  echo "txFlag: ", repr txFlag
  return (txFlag, txIsRegister)


macro transfer*(i2cDev: I2cDevice; args: untyped): untyped =

  echo "args: ", treeRepr args
  let cnt = newIntLitNode(args.len())
  result = newStmtList()

  args.expectKind(nnkStmtList)
  for arg in args.children:
    echo "arg: ", treeRepr arg
    arg.expectMinLen(2)
    var txArgs = args[0..^1]

    var
      txFlag: I2cFlag 
      txIsRegister: bool 

    # case arg[1]
    # arg[1].expectKind(nnkIdent)
  
  result.add quote do:
      var msgs: array[`cnt`, i2c_msg]
      check: i2c_transfer(`i2cDev`.bus, addr(msgs[0]), msgs.len().uint8, `i2cDev`.address.uint16)
