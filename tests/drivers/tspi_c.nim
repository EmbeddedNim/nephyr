import nephyr
import nephyr/drivers/spi

var
  cs_ctrl: spi_cs_control
  spi_cfg: spi_config
  spi_dev: ptr device

proc spi_setup*() =

  spi_dev = DEVICE_DT_GET(DT_NODELABEL(tok"mikrobus_spi"))
  cs_ctrl =
    SPI_CS_CONTROL_PTR_DT(DT_NODELABEL(tok"click_spi2"), tok`2`)[]

  spi_cfg = spi_config(
        frequency: 1_000_000'u32,
        operation: SPI_WORD_SET(8) or SPI_TRANSFER_MSB or SPI_OP_MODE_MASTER,
        cs: addr cs_ctrl)


proc spi_read*(): int =

  var
    rx_buf = @[0x0'u8, 0x0]
    rx_bufs = @[spi_buf(buf: addr rx_buf[0], len: csize_t(sizeof(uint8) * rx_buf.len())) ]
    rx_bset = spi_buf_set(buffers: addr(rx_bufs[0]), count: rx_bufs.len().csize_t)

  var
    tx_buf = [0x0'u8, ]
    tx_bufs = @[spi_buf(buf: addr tx_buf[0], len: csize_t(sizeof(uint8) * tx_buf.len())) ]
    tx_bset = spi_buf_set(buffers: addr(tx_bufs[0]), count: tx_bufs.len().csize_t)

  check: spi_transceive(spi_dev, addr spi_cfg, addr tx_bset, addr rx_bset)

  result = joinBytes32[int](rx_buf, 2)
  result = 0b0011_1111_1111_1111 and result

