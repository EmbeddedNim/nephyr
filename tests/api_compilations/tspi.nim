
import nephyr
import nephyr/drivers/spi

var spi_dev: SpiDevice

proc spi_devptr(): SpiDevice =
  var dev0: SpiDevice = initSpiDevice(
    dev = DtSpiDevice(tok"mikrobus_spi"),
    frequency = 1_000_000.Hertz,
    operation = SPI_WORD_SET(8) or SPI_TRANSFER_MSB or SPI_OP_MODE_MASTER,
    cs_ctrl = DtSpiCsDevice(tok"click_spi2", tok"1")
  )

  let cs_ctrl1 = DtSpiCsDevice(tok"click_spi2", tok"1")

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

proc spi_raw_zephyr_trx*() =
  var
    rx_buf = @[0x0'u8, 0x0]
    rx_bufs = @[spi_buf(buf: addr rx_buf[0], len: csize_t(sizeof(uint8) * rx_buf.len())) ]
    rx_bset = spi_buf_set(buffers: addr(rx_bufs[0]), count: rx_bufs.len().csize_t)

  var
    tx_buf = [0x0'u8, ]
    tx_bufs = @[spi_buf(buf: addr tx_buf[0], len: csize_t(sizeof(uint8) * tx_buf.len())) ]
    tx_bset = spi_buf_set(buffers: addr(tx_bufs[0]), count: tx_bufs.len().csize_t)

proc spi_do_trxn*() =
  # Examples of generic I2C Api
  var dev = spi_devptr()
  var data: array[3, uint8]
  var data2 = newSeq[uint8](8)
  var someData = [0xE3'u8, 0x01, 0x02]

  # Nim nep1 format
  dev.doTransfer(
    regWrite(I2cReg16(0x4ffd)), # writes i2c register/command
    read(data), # i2c read into array
    read(data2), # i2c read into seq
    write([0x1'u8, 0x2], I2C_MSG_STOP), # i2c write w/ stop
    write(someData, I2C_MSG_STOP),
    write(bytes(0x1'u8, 0x2)),
    write(bytes(0x1, 0x2), {I2C_MSG_WRITE, I2C_MSG_STOP}),
  )

  echo "got data: ", repr data
  echo "got data2: ", repr data2

spi_setup()
spi_raw_zephyr_trx()
spi_do_trxn()
