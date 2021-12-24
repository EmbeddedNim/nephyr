
import nephyr
import nephyr/drivers/spi

var spi_dev: SpiDevice

proc spi_devptr(): SpiDevice =
  var dev0: SpiDevice = initSpiDevice(
    bus = DtSpiDevice(tok"mikrobus_spi"),
    frequency = 1_000_000.Hertz,
    operation = SPI_WORD_SET(8) or SPI_TRANSFER_MSB or SPI_OP_MODE_MASTER,
    cs_ctrl = DtSpiCsDevice(tok"click_spi2", tok"1")
  )

  let cs_ctrl1 = DtSpiCsDevice(tok"click_spi2", tok"1")

proc spi_setup*() =
  var dev0: SpiDevice = initSpiDevice(
    bus = DtSpiDevice(tok"mikrobus_spi"),
    frequency = 1_000_000.Hertz,
    operation = SPI_WORD_SET(8) or SPI_TRANSFER_MSB or SPI_OP_MODE_MASTER,
    cs_ctrl = DtSpiCsDevice(tok"click_spi2", tok"1")
  )

  let cs_ctrl1 = DtSpiCsDevice(tok"click_spi2", tok"1")
  var dev1: SpiDevice = initSpiDevice(
    bus = DEVICE_DT_GET(DT_NODELABEL(tok"mikrobus_spi")),
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
  var someData: Bytes[4]

  # Nim nep1 format
  dev.doTransfers(
    read(data), # spi read into array
    read(data2), # spi read into seq
    write([0x1'u8, 0x2]), # spi write w/ stop
    write(someData),
    readWrite(someData, [0x1'u8, 0x2]), # i2c write w/ stop
    write(bytes(0x1, 0x2)),
  )

  echo "got data: ", repr data
  echo "got data2: ", repr data2

# /* MCP2515 Opcodes */
const
  MCP2515_OPCODE_WRITE          {.used.}  = 0x02'u8
  MCP2515_OPCODE_READ           {.used.}  = 0x03'u8
  MCP2515_OPCODE_BIT_MODIFY     {.used.}  = 0x05'u8
  MCP2515_OPCODE_LOAD_TX_BUFFER {.used.}  = 0x40'u8
  MCP2515_OPCODE_RTS            {.used.}  = 0x80'u8
  MCP2515_OPCODE_READ_RX_BUFFER {.used.}  = 0x90'u8
  MCP2515_OPCODE_READ_STATUS    {.used.}  = 0xA0'u8
  MCP2515_OPCODE_RESET          {.used.}  = 0xC0'u8

proc mcp2515_cmd_read_reg*(reg_addr: SpiReg8, data: var openArray[uint8]) =
  # Examples of generic I2C Api
  var dev = spi_devptr()
  var cmds = [MCP2515_OPCODE_READ, reg_addr]

  # ===== Raw Zephyr API ===== 
  var
    tx_bufs = @[spi_buf(buf: addr cmds[0], len: csize_t(sizeof(uint8) * cmds.len())) ]
    tx_bset = spi_buf_set(buffers: addr(tx_bufs[0]), count: tx_bufs.len().csize_t)

  var
    rx_bufs = @[spi_buf(buf: addr data[0], len: csize_t(sizeof(uint8) * data.len())) ]
    rx_bset = spi_buf_set(buffers: addr(rx_bufs[0]), count: rx_bufs.len().csize_t)

  check: spi_transceive(dev.bus, addr dev.cfg, addr tx_bset, addr rx_bset)

  # ===== Nephyr API ===== 
  dev.doTransfers(
    write(cmds), # spi read into array
    read(data), # spi read into seq
  )

spi_setup()
spi_raw_zephyr_trx()
spi_do_trxn()

var data: Bytes[8]
mcp2515_cmd_read_reg(SpiReg 0x32, data)

