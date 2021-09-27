##
##  Copyright (c) 2015 Intel Corporation
##
##  SPDX-License-Identifier: Apache-2.0
##

const
  I2C_DEV* = DT_LABEL(DT_ALIAS(i2c_0))

## *
##  @file Sample app using the Fujitsu MB85RC256V FRAM through ARC I2C.
##

const
  FRAM_I2C_ADDR* = 0x50

proc write_bytes*(i2c_dev: ptr device; `addr`: uint16; data: ptr uint8; num_bytes: uint32): cint =
  var wr_addr: array[2, uint8]
  var msgs: array[2, i2c_msg]
  ##  FRAM address
  wr_addr[0] = (`addr` shr 8) and 0xFF
  wr_addr[1] = `addr` and 0xFF
  ##  Setup I2C messages
  ##  Send the address to write to
  msgs[0].buf = wr_addr
  msgs[0].len = 2'u
  msgs[0].flags = I2C_MSG_WRITE
  ##  Data to be written, and STOP after this.
  msgs[1].buf = data
  msgs[1].len = num_bytes
  msgs[1].flags = I2C_MSG_WRITE or I2C_MSG_STOP
  return i2c_transfer(i2c_dev, addr(msgs[0]), 2, FRAM_I2C_ADDR)

proc read_bytes*(i2c_dev: ptr device; `addr`: uint16; data: ptr uint8; num_bytes: uint32): cint =
  var wr_addr: array[2, uint8]
  var msgs: array[2, i2c_msg]
  ##  Now try to read back from FRAM
  ##  FRAM address
  wr_addr[0] = (`addr` shr 8) and 0xFF
  wr_addr[1] = `addr` and 0xFF
  ##  Setup I2C messages
  ##  Send the address to read from
  msgs[0].buf = wr_addr
  msgs[0].len = 2'u
  msgs[0].flags = I2C_MSG_WRITE
  ##  Read from device. STOP after this.
  msgs[1].buf = data
  msgs[1].len = num_bytes
  msgs[1].flags = I2C_MSG_READ or I2C_MSG_STOP
  return i2c_transfer(i2c_dev, addr(msgs[0]), 2, FRAM_I2C_ADDR)

proc main*() =
  let i2c_dev: ptr device
  var cmp_data: array[16, uint8]
  var data: array[16, uint8]
  var
    i: cint
    ret: cint
  i2c_dev = device_get_binding(I2C_DEV)
  if not i2c_dev:
    printk("I2C: Device driver not found.\n")
    return
  data[0] = 0xAE
  ret = write_bytes(i2c_dev, 0x00, addr(data[0]), 1)
  if ret:
    printk("Error writing to FRAM! error code (%d)\n", ret)
    return
  else:
    printk("Wrote 0xAE to address 0x00.\n")
  data[0] = 0x86
  ret = write_bytes(i2c_dev, 0x01, addr(data[0]), 1)
  if ret:
    printk("Error writing to FRAM! error code (%d)\n", ret)
    return
  else:
    printk("Wrote 0x86 to address 0x01.\n")
  data[0] = 0x00
  ret = read_bytes(i2c_dev, 0x00, addr(data[0]), 1)
  if ret:
    printk("Error reading from FRAM! error code (%d)\n", ret)
    return
  else:
    printk("Read 0x%X from address 0x00.\n", data[0])
  data[1] = 0x00
  ret = read_bytes(i2c_dev, 0x01, addr(data[0]), 1)
  if ret:
    printk("Error reading from FRAM! error code (%d)\n", ret)
    return
  else:
    printk("Read 0x%X from address 0x01.\n", data[0])
  ##  Do multi-byte read/write
  ##  get some random data, and clear out data[]
  i = 0
  while i < sizeof((cmp_data)):
    cmp_data[i] = k_cycle_get_32() and 0xFF
    data[i] = 0x00
    inc(i)
  ##  write them to the FRAM
  ret = write_bytes(i2c_dev, 0x00, cmp_data, sizeof((cmp_data)))
  if ret:
    printk("Error writing to FRAM! error code (%d)\n", ret)
    return
  else:
    printk("Wrote %zu bytes to address 0x00.\n", sizeof((cmp_data)))
  ret = read_bytes(i2c_dev, 0x00, data, sizeof((data)))
  if ret:
    printk("Error reading from FRAM! error code (%d)\n", ret)
    return
  else:
    printk("Read %zu bytes from address 0x00.\n", sizeof((data)))
  ret = 0
  i = 0
  while i < sizeof((cmp_data)):
    ##  uncomment below if you want to see all the bytes
    ##  printk("0x%X ?= 0x%X\n", cmp_data[i], data[i]);
    if cmp_data[i] != data[i]:
      printk("Data comparison failed @ %d.\n", i)
      ret = -EIO
    inc(i)
  if ret == 0:
    printk("Data comparison successful.\n")
