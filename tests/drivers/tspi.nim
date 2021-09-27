import nephyr/drivers/spi
export spi

proc test_spi() =
  var dev = spiDeviceInit(tok"spidev1", tok"gpio0", 1_000_000.Hertz)
  
test_spi()
