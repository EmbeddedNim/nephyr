
import nephyr/general
import zephyr_c/cmtoken
import zephyr_c/zdevicetree
import zephyr_c/drivers/zgpio
import zephyr_c/drivers/zspi
import zephyr_c/dt_bindings/dt_gpio
import zephyr_c/dt_bindings/dt_spi

export zgpio
export zspi
export dt_gpio, dt_spi
export utils, cmtoken, zdevice, zdevicetree

type

  SpiDevice* = ref object
    cfg: spi_config
    bus: ptr device

proc initSpiDevice*(dev: ptr device,
                    cs_ctrl: ptr spi_cs_control,
                    operation: uint16,
                    frequency: Hertz,
                    slave = 0'u16,
                    ): SpiDevice =
  if result.bus.isNil():
    let emsg = 
      when typeof(dev) is cstring:
        "error finding spi device: " & $dev
      elif typeof(dev) is cminvtoken:
        "error finding spi device: " & dev.toString()
      elif typeof(dev) is ptr device:
        "error finding spi device: 0x" & $(cast[int](dev).toHex())
    raise newException(OSError, emsg)

  result = SpiDevice()
  result.bus = dev
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


proc readBytes*(dev: SpiDevice): seq[uint8] =

  var
    rx_buf = @[0x0'u8, 0x0]
    rx_bufs = @[spi_buf(buf: addr rx_buf[0], len: rx_buf.lenBytes())]
    rx_bset = spi_buf_set(buffers: addr(rx_bufs[0]), count: rx_bufs.len().csize_t)

  var
    tx_buf = [0x0'u8, ]
    tx_bufs = @[spi_buf(buf: addr tx_buf[0], len: csize_t(sizeof(uint8) *
        tx_buf.len()))]
    tx_bset = spi_buf_set(buffers: addr(tx_bufs[0]), count: tx_bufs.lenBytes())

  check: spi_transceive(dev.bus, addr dev.cfg, addr tx_bset, addr rx_bset)

  result = rx_buf


