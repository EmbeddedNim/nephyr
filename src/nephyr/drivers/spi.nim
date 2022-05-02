import macros

import nephyr/general
import ../zephyr/cmtoken
import ../zephyr/zdevicetree
import ../zephyr/drivers/zgpio
import ../zephyr/drivers/zspi
import ../zephyr/dt_bindings/dt_gpio
import ../zephyr/dt_bindings/dt_spi

export zgpio
export zspi
export dt_gpio, dt_spi
export utils, cmtoken, zdevice, zdevicetree

type

  SpiReg8* = uint8
  SpiReg* = SpiReg8
  SpiReg16* = uint16
  SpiRegister* = SpiReg8 | SpiReg16

  SpiDevice* = ref object
    cfg*: spi_config
    bus*: ptr device

proc initSpiDevice*(bus: ptr device,
                    cs_ctrl: ptr spi_cs_control,
                    operation: uint16,
                    frequency: Hertz,
                    slave = 0'u16,
                    ): SpiDevice =
  if result.bus.isNil():
    let emsg = 
      when typeof(bus) is cstring:
        "error finding spi device: " & $dev
      elif typeof(bus) is cminvtoken:
        "error finding spi device: " & dev.toString()
      elif typeof(bus) is ptr device:
        "error finding spi device: 0x" & $(cast[int](bus).toHex())
    raise newException(OSError, emsg)

  result = SpiDevice()
  result.bus = bus
  result.cfg = spi_config(
        frequency: frequency.uint32,
        operation: operation,
        slave: slave, # TODO
        cs: cs_ctrl
    )

template DtSpiDevice*(dev: untyped): untyped =
  var devptr: ptr device
  when typeof(dev) is cstring:
    devptr = device_get_binding(dev)
  when typeof(dev) is cminvtoken:
    devptr = DEVICE_DT_GET(DT_NODELABEL(dev))
  elif typeof(dev) is ptr device:
    devptr = dev
  
  devptr

template DtSpiCsDevice*(cs_name: untyped, cs_idx: untyped): ptr spi_cs_control =
  SPI_CS_CONTROL_PTR_DT(DT_NODELABEL(cs_name), cs_idx)

proc read*(txbuf, rxbuf: var spi_buf; data: var openArray[uint8]) =
  # Create a read-only transaction
  txbuf.buf = nil
  txbuf.len = 0
  rxbuf.buf = unsafeAddr data[0]
  rxbuf.len = data.lenBytes()

proc write*(txbuf, rxbuf: var spi_buf; data: openArray[uint8]) =
  # Create a write-only transaction
  txbuf.buf = unsafeAddr data[0]
  txbuf.len = data.lenBytes()
  rxbuf.buf = nil
  rxbuf.len = 0

proc readWrite*(txbuf, rxbuf: var spi_buf; readData: var openArray[uint8], writeData: openArray[uint8]) =
  # Create a write-read transaction
  txbuf.buf = unsafeAddr writeData[0]
  txbuf.len = writeData.lenBytes()
  rxbuf.buf = unsafeAddr readData[0]
  rxbuf.len = readData.lenBytes()


macro doTransfers*(dev: var SpiDevice, args: varargs[untyped]) =
  ## performs an i2c transfer by iterating through the arguments
  ## which should be proc's that take an i2c_msg var and
  ## sets it up. 
  ## 
  ## Example usage:
  ##   var dev = i2c_devptr()
  ##   var data: array[3, uint8]
  ##   dev.doTransfer(
  ##     reg(I2cReg16(0x4ffd)),
  ##     read(data),
  ##     write([0x1'u8, 0x2], I2C_MSG_STOP))
  ## 
  result = newStmtList()

  if args.len() == 0:
    result.add quote do:
      check: i2c_transfer(`dev`.bus, nil, 0, `dev`.address.uint16)
    return

  # create the new i2cmsg array
  let
    mcnt = newIntLitNode(args.len())
    txvar = genSym(nskVar, "tx_bufs")
    rxvar = genSym(nskVar, "rx_bufs")

  result.add quote do:
    var `txvar`: array[`mcnt`, spi_buf]
    var `rxvar`: array[`mcnt`, spi_buf]
  args.expectKind(nnkArglist)

  # applies array elements to each arg in turn
  for idx in 0..<args.len():
    let i = newIntLitNode(idx)
    var msg = args[idx]
    msg.insert(1, quote do: `txvar`[`i`])
    msg.insert(2, quote do: `rxvar`[`i`])
    result.add msg
  
  # call the i2c_transfer
  result.add quote do:
      var
        tx_bset = spi_buf_set(buffers: addr(`txvar`[0]), count: `txvar`.len().csize_t)
        rx_bset = spi_buf_set(buffers: addr(`rxvar`[0]), count: `rxvar`.len().csize_t)
      # check: spi_transfer(`dev`.bus, addr(`mvar`[0]), `mvar`.len().uint8, `dev`.address.uint16)
      check: spi_transceive(`dev`.bus, addr `dev`.cfg, addr tx_bset, addr rx_bset)


