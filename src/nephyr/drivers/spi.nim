
import nephyr/general
import zephyr_c/cmtoken
import zephyr_c/wrapper_utils
import zephyr_c/zdevicetree
import zephyr_c/drivers/zspi
import zephyr_c/dt_bindings/dt_gpio
import zephyr_c/dt_bindings/dt_spi

import sequtils

export cmtoken
export general

# var
#   cs_ctrl: spi_cs_control
#   spi_cfg: spi_config
#   spi_dev: ptr device

type

  SpiDevice* = ref object
    cs_ctrl: spi_cs_control
    cfg: spi_config
    spi_ptr: ptr device




template spiDeviceInit*(node_label: untyped, cs_label: untyped; spi_freq: Hertz, cs_delay=2): SpiDevice =
  var dev = SpiDevice()

  dev.spi_ptr = DEVICE_DT_GET(DT_NODELABEL(node_label))
  dev.cs_ctrl =
        spi_cs_control(
                gpio_dev: DEVICE_DT_GET(DT_SPI_DEV_CS_GPIOS_CTLR(cs_label)),
                delay: cs_delay,
                gpio_pin: DT_SPI_DEV_CS_GPIOS_PIN(cs_label),
                gpio_dt_flags: DT_SPI_DEV_CS_GPIOS_FLAGS(cs_label)
        )

  dev.cfg = spi_config(
        frequency: 1_000_000'u32,
        operation: SPI_WORD_SET(8) or SPI_TRANSFER_MSB or SPI_OP_MODE_MASTER,
        cs: addr dev.cs_ctrl)
  
  dev


proc spi_read*(dev: SpiDevice): seq[uint8] =

  var
    rx_buf = @[0x0'u8, 0x0]
    rx_bufs = @[spi_buf(buf: addr rx_buf[0], len: csize_t(sizeof(uint8) * rx_buf.len())) ]
    rx_bset = spi_buf_set(buffers: addr(rx_bufs[0]), count: rx_bufs.len().csize_t)

  var
    tx_buf = [0x0'u8, ]
    tx_bufs = @[spi_buf(buf: addr tx_buf[0], len: csize_t(sizeof(uint8) * tx_buf.len())) ]
    tx_bset = spi_buf_set(buffers: addr(tx_bufs[0]), count: tx_bufs.len().csize_t)

  check: spi_transceive(dev.spi_ptr, addr dev.cfg, addr tx_bset, addr rx_bset)

  result = rx_buf


