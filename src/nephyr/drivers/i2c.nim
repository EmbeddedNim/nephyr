import bitops
import macros

import nephyr/general
import nephyr/utils
import zephyr_c/zdevicetree
import zephyr_c/zdevice
import zephyr_c/drivers/zi2c
import zephyr_c/cmtoken

import typetraits
export zi2c
export utils, cmtoken, zdevice, zdevicetree

type
  # I2cMsg * {.size: sizeof(uint8).} = enum
  #   write = I2C_MSG_WRITE,
  #   read = I2C_MSG_READ,
  #   stop = I2C_MSG_STOP,
  #   restart = I2C_MSG_RESTART,
  #   addr10 = I2C_MSG_ADDR_10_BITS

  I2cAddr* = distinct uint8
  I2cReg8* = distinct uint8 
  I2cReg16* = distinct uint16
  I2cRegister* = I2cReg8 | I2cReg16

  I2cDevice* = ref object
    bus*: ptr device
    address*: I2cAddr


template regAddressToBytes(reg: untyped): untyped =
  ##  register address
  var wr_addr: array[sizeof(reg), uint8]
  when reg is I2cReg8:
    assert wr_addr.len() == 1
    wr_addr[0] = uint8(reg)
  elif reg is I2cReg16:
    assert wr_addr.len() == 2
    wr_addr[0] = uint8(reg.uint16 shr 8)
    wr_addr[1] = uint8(reg.uint16 and 0xFF'u8)
  
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


proc read*(msg: var i2c_msg; data: var openArray[uint8], flag = I2cFlag(0)) =
  msg.buf = unsafeAddr data[0]
  msg.len = data.lenBytes()
  msg.flags = flag or I2C_MSG_READ

proc write*(msg: var i2c_msg; args: openArray[uint8], flag: I2cFlag) =
  msg.buf = unsafeAddr args[0]
  msg.len = args.lenBytes()
  msg.flags = flag or I2C_MSG_WRITE


proc write*(msg: var i2c_msg; args: openArray[uint8]; flags: set[I2cFlag] = {}) =
  write(msg, args, cast[I2cFlag](flags))

template reg*(msg: var i2c_msg; register: I2cRegister, flag: I2cFlag = I2C_MSG_WRITE) =
  let data = regAddressToBytes(register)
  write(msg, data, flag)


macro doTransfers*(dev: var I2cDevice, args: varargs[untyped]) =
  let mvar = genSym(nskVar, "i2cMsgArr")
  let mcnt = newIntLitNode(args.len())
  result = newStmtList()
  result.add quote do:
    var `mvar`: array[`mcnt`, i2c_msg]

  args.expectKind(nnkArglist)
  for idx in 0..<args.len():
    # echo "\n"
    # echo "arg(repr): ", repr args[idx]
    # echo "arg: ", treeRepr args[idx]
    let i = newIntLitNode(idx)
    var msg = args[idx]
    msg.insert(1, quote do: `mvar`[`i`])
    result.add msg
    # result.add quote do:
      # `mvar`[`i`].`args[idx]`
  
  result.add quote do:
      check: i2c_transfer(`dev`.bus, addr(`mvar`[0]), `mvar`.len().uint8, `dev`.address.uint16)
  echo "doTransfers: "
  echo result.repr


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

  args.expectKind(nnkArglist)
  for arg in args.children:
    echo "\n"
    echo "arg(repr): ", repr arg
    echo "arg: ", treeRepr arg
    arg.expectLen(2)
    arg.expectKind(nnkExprEqExpr)
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
