
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

proc initSpiDevice*(dev: cstring | ptr device | cminvtoken,
                    cs_label: (cminvtoken, cminvtoken) | ptr spi_cs_control,
                    operation: uint16,
                    frequency: Hertz,
                    cs_delay = 2,
                    ): SpiDevice =
  result = SpiDevice()
  when typeof(dev) is cstring:
    result.bus = device_get_binding(dev)
  when typeof(dev) is cminvtoken:
    result.bus = DEVICE_DT_GET(DT_NODELABEL(dev))
  elif typeof(dev) is ptr device:
    result.bus = dev

  var cs_ctrl: ptr spi_cs_control
  when typeof(cs_label) is (cminvtoken, cminvtoken):
    let cs_name: cminvtoken = cs_label[0]
    let cs_idx: cminvtoken = cs_label[1]
    discard DT_NODELABEL(tok"cs_name")
    cs_ctrl = SPI_CS_CONTROL_PTR_DT(DT_NODELABEL(cs_name), cs_idx)
  elif typeof(cs_label) is ptr device:
    cs_ctrl  = cs_label

  if result.bus.isNil():
    let emsg = 
      when typeof(dev) is cstring:
        "error finding spi device: " & $dev
      elif typeof(dev) is ptr device:
        "error finding spi device: 0x" & $(cast[int](dev).toHex())
    raise newException(OSError, emsg)

  result.cfg = spi_config(
        frequency: frequency.uint32,
        operation: operation,
        cs: cs_ctrl
    )

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


