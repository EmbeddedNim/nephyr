
import nephyr
import nephyr/drivers/spi

var spi_dev: SpiDevice

proc spi_setup*() =
  var dev0: SpiDevice = initSpiDevice(
    dev = DtSpiDevice(tok"mikrobus_spi"),
    frequency = 1_000_000.Hertz,
    operation = SPI_WORD_SET(8) or SPI_TRANSFER_MSB or SPI_OP_MODE_MASTER,
    cs_ctrl = DtSpiCsDevice(tok"click_spi2", tok"1")
  )

  let cs_ctrl1 = DtSpiCsDevice(tok"click_spi2", tok"1")
  var dev1: SpiDevice = initSpiDevice(
    dev = DEVICE_DT_GET(DT_NODELABEL(tok"mikrobus_spi")),
    frequency = 1_000_000.Hertz,
    operation = SPI_WORD_SET(8) or SPI_TRANSFER_MSB or SPI_OP_MODE_MASTER,
    cs_ctrl = cs_ctrl1
  )

  echo "dev0: ", repr dev0
  spi_dev = dev1

proc spi_read*() =

  var
    rx_buf = @[0x0'u8, 0x0]
    rx_bufs = @[spi_buf(buf: addr rx_buf[0], len: csize_t(sizeof(uint8) * rx_buf.len())) ]
    rx_bset = spi_buf_set(buffers: addr(rx_bufs[0]), count: rx_bufs.len().csize_t)

  var
    tx_buf = [0x0'u8, ]
    tx_bufs = @[spi_buf(buf: addr tx_buf[0], len: csize_t(sizeof(uint8) * tx_buf.len())) ]
    tx_bset = spi_buf_set(buffers: addr(tx_bufs[0]), count: tx_bufs.len().csize_t)


spi_setup()
spi_read()