import bitops

import nephyr/general
import zephyr_c/zdevicetree
import zephyr_c/zdevice
import zephyr_c/drivers/zi2c
import zephyr_c/cmtoken

import typetraits
export zi2c
export cmtoken, zdevice, zdevicetree

const
  ##
  ##  I2C_MSG_* are I2C Message flags.
  ##
  i2cWrite* = I2C_MSG_WRITE
  i2cRead* = I2C_MSG_READ
  i2cStop* = I2C_MSG_STOP
  i2cRestart* = I2C_MSG_RESTART
  i2cAddr10Bit* = I2C_MSG_ADDR_10_BITS


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

template unsafeI2cMsg*(args: varargs[uint8], flag: I2cFlag): i2c_msg =
  when not (args.len() < 256):
    {.fatal: "i2c message must be less than 256 bytes".}
  var data: array[args.len(), uint8]
  let dl = uint8(data.len() * sizeof(uint8))
  for idx in 0..<args.len(): data[idx] = args[idx]

  i2c_msg(buf: unsafeAddr data[0], len: dl, flags: flag)
# template unsafeI2cMsg*(data: varargs[uint8], flag: I2cFlag): i2c_msg =
  # var arr: array[data.len(), uint8] = data
  # i2c_msg(buf: addr arr[0], len: uint8(arr.lenBytes()), flags: flag)

template doTransfers*(dev: var I2cDevice, args: varargs[i2c_msg]) =
  var msgs: array[args.len(), i2c_msg]
  for idx in 0..<args.len():
    echo "msg: ", repr(args[idx])
    msgs[idx] = args[idx]
  check: i2c_transfer(dev.bus, addr(msgs[0]), msgs.len().uint8, dev.address.uint16)


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

  var idx = 0
  while idx < args.len():
    if args[idx].kind != nnkIdent:
      break;

    case args[idx].strVal:
    of "or":
      discard "skip"
    of "read":
      txFlag = txFlag or I2C_MSG_READ
    of "write":
      txFlag = txFlag or I2C_MSG_WRITE
    of "register":
      txFlag = txFlag or I2C_MSG_WRITE
      txIsRegister = true
    else:
      error("must be one of I2cFlag type, found: " & repr(args[idx]), args[idx])
    
    inc idx
    
  args = args[idx..^1]

  echo "txFlag: ", repr txFlag
  return (txFlag, txIsRegister)


macro transfer*(i2cDev: I2cDevice; args: varargs[untyped]): untyped =

  echo "<".repeat(20)
  echo "stmt: ", repr args
  echo "args: ", treeRepr args
  let cnt = newIntLitNode(args.len())
  result = newStmtList()

  # args.expectKind(nnkStmtList)
  for arg in args.children:
    echo "arg(repr): ", repr arg
    echo "arg: ", treeRepr arg
    # arg.expectMinLen(2)
    # var txArgs = arg[0..^1]

    # let (txFlag, txIsReg) = txArgs.parseFlags()

    # echo "<<< txflags post: "
    # for txa in txArgs: echo "txarg: ", treeRepr txa
    # echo ">>> txflags post done\n\n\n"

    # case arg[1]
    # arg[1].expectKind(nnkIdent)
  
  # result.add quote do:
      # var msgs: array[`cnt`, i2c_msg]
      # check: i2c_transfer(`i2cDev`.bus, addr(msgs[0]), msgs.len().uint8, `i2cDev`.address.uint16)
  echo ">".repeat(20)
