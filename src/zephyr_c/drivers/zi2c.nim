


## *
##  @file
##
##  @brief Public APIs for the I2C drivers.
##
##
##  Copyright (c) 2015 Intel Corporation
##
##  SPDX-License-Identifier: Apache-2.0
##




## *
##  @brief I2C Interface
##  @defgroup i2c_interface I2C Interface
##  @ingroup io_interfaces
##  @{
##

import ../wrapper_utils
import ../zdevice

##
##  The following #defines are used to configure the I2C controller.
##
const
  I2C_SPEED_STANDARD* = (0x1) ## I2C Standard Speed: 100

  I2C_SPEED_FAST* = (0x2) ## I2C Fast Speed: 400

  I2C_SPEED_FAST_PLUS* = (0x3) ## I2C Fast Plus Speed: 1

  I2C_SPEED_HIGH* = (0x4) ## I2C High Speed: 3.4

  I2C_SPEED_ULTRA* = (0x5) ## I2C Ultra Fast Speed: 5
  I2C_SPEED_SHIFT* = (1'u)

const
  I2C_SPEED_MASK* = (0x7 shl I2C_SPEED_SHIFT) ##  3 bits

template I2C_SPEED_SET*(speed: untyped): untyped =
  (((speed) shl I2C_SPEED_SHIFT) and I2C_SPEED_MASK)

template I2C_SPEED_GET*(cfg: untyped): untyped =
  (((cfg) and I2C_SPEED_MASK) shr I2C_SPEED_SHIFT)

const
  I2C_ADDR_10_BITS* = BIT(0) ## Use 10-bit addressing. DEPRECATED - Use I2C_MSG_ADDR_10_BITS

  I2C_MODE_MASTER* = BIT(4) ## Controller to act as

  ##
  ##  I2C_MSG_* are I2C Message flags.
  ##
  I2C_MSG_WRITE* = (0 shl 0) ## Write message to I2C

  I2C_MSG_READ* = BIT(0) ## Read message from I2C

  I2C_MSG_RW_MASK* = BIT(0) ## @cond

  I2C_MSG_STOP* = BIT(1) ## Send STOP after this

  I2C_MSG_RESTART* = BIT(2) ## RESTART I2C transaction for this

  I2C_MSG_ADDR_10_BITS* = BIT(3) ## Use 10-bit addressing for this


var I2C_SLAVE_FLAGS_ADDR_10_BITS* {.importc: "I2C_SLAVE_FLAGS_ADDR_10_BITS",
                                  header: "i2c.h".}: int ## * Slave device responds to 10-bit addressing.




## *
##  @brief One I2C Message.
##
##  This defines one I2C message to transact on the I2C bus.
##
##  @note Some of the configurations supported by this API may not be
##  supported by specific SoC I2C hardware implementations, in
##  particular features related to bus transactions intended to read or
##  write data from different buffers within a single transaction.
##  Invocations of i2c_transfer() may not indicate an error when an
##  unsupported configuration is encountered.  In some cases drivers
##  will generate separate transactions for each message fragment, with
##  or without presence of @ref I2C_MSG_RESTART in #flags.
##

type
  i2c_msg* {.bycopy.} = object
    buf*: ptr uint8             ## * Data buffer in bytes
    ## * Length of buffer in bytes
    len*: uint32               ## * Flags for this message
    flags*: uint8


  i2c_api_configure_t* = proc (dev: ptr device; dev_config: uint32): cint
  i2c_api_full_io_t* = proc (dev: ptr device; msgs: ptr i2c_msg; num_msgs: uint8;
                          `addr`: uint16): cint
  i2c_api_slave_register_t* = proc (dev: ptr device; cfg: ptr i2c_slave_config): cint
  i2c_api_slave_unregister_t* = proc (dev: ptr device; cfg: ptr i2c_slave_config): cint
  i2c_api_recover_bus_t* = proc (dev: ptr device): cint
  i2c_driver_api* {.bycopy.} = object
    configure*: i2c_api_configure_t
    transfer*: i2c_api_full_io_t
    slave_register*: i2c_api_slave_register_t
    slave_unregister*: i2c_api_slave_unregister_t
    recover_bus*: i2c_api_recover_bus_t

  i2c_slave_api_register_t* = proc (dev: ptr device): cint
  i2c_slave_api_unregister_t* = proc (dev: ptr device): cint
  i2c_slave_driver_api* {.bycopy.} = object
    driver_register*: i2c_slave_api_register_t
    driver_unregister*: i2c_slave_api_unregister_t



  i2c_slave_write_requested_cb_t* = proc (config: ptr i2c_slave_config): cint ##\
    ## * @brief Function called when a write to the device is initiated.
    ##
    ##  This function is invoked by the controller when the bus completes a
    ##  start condition for a write operation to the address associated
    ##  with a particular device.
    ##
    ##  A success return shall cause the controller to ACK the next byte
    ##  received.  An error return shall cause the controller to NACK the
    ##  next byte received.
    ##
    ##  @param config the configuration structure associated with the
    ##  device to which the operation is addressed.
    ##
    ##  @return 0 if the write is accepted, or a negative error code.
    ##


  i2c_slave_write_received_cb_t* = proc (config: ptr i2c_slave_config; val: uint8): cint ##\
    ## * @brief Function called when a write to the device is continued.
    ##
    ##  This function is invoked by the controller when it completes
    ##  reception of a byte of data in an ongoing write operation to the
    ##  device.
    ##
    ##  A success return shall cause the controller to ACK the next byte
    ##  received.  An error return shall cause the controller to NACK the
    ##  next byte received.
    ##
    ##  @param config the configuration structure associated with the
    ##  device to which the operation is addressed.
    ##
    ##  @param val the byte received by the controller.
    ##
    ##  @return 0 if more data can be accepted, or a negative error
    ##  code.
    ##


  i2c_slave_read_requested_cb_t* = proc (config: ptr i2c_slave_config; val: ptr uint8): cint ##\
    ## * @brief Function called when a read from the device is initiated.
    ##
    ##  This function is invoked by the controller when the bus completes a
    ##  start condition for a read operation from the address associated
    ##  with a particular device.
    ##
    ##  The value returned in @p *val will be transmitted.  A success
    ##  return shall cause the controller to react to additional read
    ##  operations.  An error return shall cause the controller to ignore
    ##  bus operations until a new start condition is received.
    ##
    ##  @param config the configuration structure associated with the
    ##  device to which the operation is addressed.
    ##
    ##  @param val pointer to storage for the first byte of data to return
    ##  for the read request.
    ##
    ##  @return 0 if more data can be requested, or a negative error code.
    ##


  i2c_slave_read_processed_cb_t* = proc (config: ptr i2c_slave_config; val: ptr uint8): cint ##\
    ## * @brief Function called when a read from the device is continued.
    ##
    ##  This function is invoked by the controller when the bus is ready to
    ##  provide additional data for a read operation from the address
    ##  associated with the device device.
    ##
    ##  The value returned in @p *val will be transmitted.  A success
    ##  return shall cause the controller to react to additional read
    ##  operations.  An error return shall cause the controller to ignore
    ##  bus operations until a new start condition is received.
    ##
    ##  @param config the configuration structure associated with the
    ##  device to which the operation is addressed.
    ##
    ##  @param val pointer to storage for the next byte of data to return
    ##  for the read request.
    ##
    ##  @return 0 if data has been provided, or a negative error code.
    ##

  i2c_slave_stop_cb_t* = proc (config: ptr i2c_slave_config): cint ##\
    ## * @brief Function called when a stop condition is observed after a
    ##  start condition addressed to a particular device.
    ##
    ##  This function is invoked by the controller when the bus is ready to
    ##  provide additional data for a read operation from the address
    ##  associated with the device device.  After the function returns the
    ##  controller shall enter a state where it is ready to react to new
    ##  start conditions.
    ##
    ##  @param config the configuration structure associated with the
    ##  device to which the operation is addressed.
    ##
    ##  @return Ignored.
    ##


  i2c_slave_callbacks* {.bycopy.} = object ##\
      ## * @brief Structure providing callbacks to be implemented for devices
      ##  that supports the I2C slave API.
      ##
      ##  This structure may be shared by multiple devices that implement the
      ##  same API at different addresses on the bus.
      ##
    write_requested*: i2c_slave_write_requested_cb_t
    read_requested*: i2c_slave_read_requested_cb_t
    write_received*: i2c_slave_write_received_cb_t
    read_processed*: i2c_slave_read_processed_cb_t
    stop*: i2c_slave_stop_cb_t


  i2c_slave_config* {.bycopy.} = object ##\
      ## * @brief Structure describing a device that supports the I2C
      ##  slave API.
      ##
      ##  Instances of this are passed to the i2c_slave_register() and
      ##  i2c_slave_unregister() functions to indicate addition and removal
      ##  of a slave device, respective.
      ##
      ##  Fields other than @c node must be initialized by the module that
      ##  implements the device behavior prior to passing the object
      ##  reference to i2c_slave_register().
      ##
    node*: sys_snode_t         ## * Private, do not modify
    ## * Flags for the slave device defined by I2C_SLAVE_FLAGS_* constants
    flags*: uint8              ## * Address for this slave device
    address*: uint16           ## * Callback functions
    callbacks*: ptr i2c_slave_callbacks

  i2c_client_config* {.bycopy.} = object
    i2c_master*: cstring
    i2c_addr*: uint16





## *
##  @brief Configure operation of a host controller.
##
##  @param dev Pointer to the device structure for the driver instance.
##  @param dev_config Bit-packed 32-bit value to the device runtime configuration
##  for the I2C controller.
##
##  @retval 0 If successful.
##  @retval -EIO General input / output error, failed to configure device.
##

proc i2c_configure*(dev: ptr device; dev_config: uint32): cint {.syscall,
    importc: "i2c_configure", header: "i2c.h".}



## *
##  @brief Perform data transfer to another I2C device in master mode.
##
##  This routine provides a generic interface to perform data transfer
##  to another I2C device synchronously. Use i2c_read()/i2c_write()
##  for simple read or write.
##
##  The array of message @a msgs must not be NULL.  The number of
##  message @a num_msgs may be zero,in which case no transfer occurs.
##
##  @note Not all scatter/gather transactions can be supported by all
##  drivers.  As an example, a gather write (multiple consecutive
##  `i2c_msg` buffers all configured for `I2C_MSG_WRITE`) may be packed
##  into a single transaction by some drivers, but others may emit each
##  fragment as a distinct write transaction, which will not produce
##  the same behavior.  See the documentation of `struct i2c_msg` for
##  limitations on support for multi-message bus transactions.
##
##  @param dev Pointer to the device structure for an I2C controller
##  driver configured in master mode.
##  @param msgs Array of messages to transfer.
##  @param num_msgs Number of messages to transfer.
##  @param addr Address of the I2C target device.
##
##  @retval 0 If successful.
##  @retval -EIO General input / output error.
##

proc i2c_transfer*(dev: ptr device; msgs: ptr i2c_msg; num_msgs: uint8; `addr`: uint16): cint {.
    syscall, importc: "i2c_transfer", header: "i2c.h".}



## *
##  @brief Recover the I2C bus
##
##  Attempt to recover the I2C bus.
##
##  @param dev Pointer to the device structure for an I2C controller
##  driver configured in master mode.
##  @retval 0 If successful
##  @retval -EBUSY If bus is not clear after recovery attempt.
##  @retval -EIO General input / output error.
##  @retval -ENOSYS If bus recovery is not implemented
##

proc i2c_recover_bus*(dev: ptr device): cint {.syscall, importc: "i2c_recover_bus",
    header: "i2c.h".}



## *
##  @brief Registers the provided config as Slave device of a controller.
##
##  Enable I2C slave mode for the 'dev' I2C bus driver using the provided
##  'config' struct containing the functions and parameters to send bus
##  events. The I2C slave will be registered at the address provided as 'address'
##  struct member. Addressing mode - 7 or 10 bit - depends on the 'flags'
##  struct member. Any I2C bus events related to the slave mode will be passed
##  onto I2C slave device driver via a set of callback functions provided in
##  the 'callbacks' struct member.
##
##  Most of the existing hardware allows simultaneous support for master
##  and slave mode. This is however not guaranteed.
##
##  @param dev Pointer to the device structure for an I2C controller
##  driver configured in slave mode.
##  @param cfg Config struct with functions and parameters used by the I2C driver
##  to send bus events
##
##  @retval 0 Is successful
##  @retval -EINVAL If parameters are invalid
##  @retval -EIO General input / output error.
##  @retval -ENOSYS If slave mode is not implemented
##

proc i2c_slave_register*(dev: ptr device; cfg: ptr i2c_slave_config): cint {.
    importc: "i2c_slave_register", header: "i2c.h".}



## *
##  @brief Unregisters the provided config as Slave device
##
##  This routine disables I2C slave mode for the 'dev' I2C bus driver using
##  the provided 'config' struct containing the functions and parameters
##  to send bus events.
##
##  @param dev Pointer to the device structure for an I2C controller
##  driver configured in slave mode.
##  @param cfg Config struct with functions and parameters used by the I2C driver
##  to send bus events
##
##  @retval 0 Is successful
##  @retval -EINVAL If parameters are invalid
##  @retval -ENOSYS If slave mode is not implemented
##

proc i2c_slave_unregister*(dev: ptr device; cfg: ptr i2c_slave_config): cint {.
    importc: "i2c_slave_unregister", header: "i2c.h".}



## *
##  @brief Instructs the I2C Slave device to register itself to the I2C Controller
##
##  This routine instructs the I2C Slave device to register itself to the I2C
##  Controller via its parent controller's i2c_slave_register() API.
##
##  @param dev Pointer to the device structure for the I2C slave
##  device (not itself an I2C controller).
##
##  @retval 0 Is successful
##  @retval -EINVAL If parameters are invalid
##  @retval -EIO General input / output error.
##

proc i2c_slave_driver_register*(dev: ptr device): cint {.syscall,
    importc: "i2c_slave_driver_register", header: "i2c.h".}


## *
##  @brief Instructs the I2C Slave device to unregister itself from the I2C
##  Controller
##
##  This routine instructs the I2C Slave device to unregister itself from the I2C
##  Controller via its parent controller's i2c_slave_register() API.
##
##  @param dev Pointer to the device structure for the I2C slave
##  device (not itself an I2C controller).
##
##  @retval 0 Is successful
##  @retval -EINVAL If parameters are invalid
##

proc i2c_slave_driver_unregister*(dev: ptr device): cint {.syscall,
    importc: "i2c_slave_driver_unregister", header: "i2c.h".}


##
##  Derived i2c APIs -- all implemented in terms of i2c_transfer()
##



## *
##  @brief Write a set amount of data to an I2C device.
##
##  This routine writes a set amount of data synchronously.
##
##  @param dev Pointer to the device structure for an I2C controller
##  driver configured in master mode.
##  @param buf Memory pool from which the data is transferred.
##  @param num_bytes Number of bytes to write.
##  @param addr Address to the target I2C device for writing.
##
##  @retval 0 If successful.
##  @retval -EIO General input / output error.
##

proc i2c_write*(dev: ptr device; buf: ptr uint8; num_bytes: uint32; `addr`: uint16): cint {.
    importc: "i2c_write", header: "i2c.h".}



## *
##  @brief Read a set amount of data from an I2C device.
##
##  This routine reads a set amount of data synchronously.
##
##  @param dev Pointer to the device structure for an I2C controller
##  driver configured in master mode.
##  @param buf Memory pool that stores the retrieved data.
##  @param num_bytes Number of bytes to read.
##  @param addr Address of the I2C device being read.
##
##  @retval 0 If successful.
##  @retval -EIO General input / output error.
##

proc i2c_read*(dev: ptr device; buf: ptr uint8; num_bytes: uint32; `addr`: uint16): cint {.
    importc: "i2c_read", header: "i2c.h".}



## *
##  @brief Write then read data from an I2C device.
##
##  This supports the common operation "this is what I want", "now give
##  it to me" transaction pair through a combined write-then-read bus
##  transaction.
##
##  @param dev Pointer to the device structure for an I2C controller
##  driver configured in master mode.
##  @param addr Address of the I2C device
##  @param write_buf Pointer to the data to be written
##  @param num_write Number of bytes to write
##  @param read_buf Pointer to storage for read data
##  @param num_read Number of bytes to read
##
##  @retval 0 if successful
##  @retval negative on error.
##

proc i2c_write_read*(dev: ptr device; `addr`: uint16; write_buf: pointer;
                    num_write: csize_t; read_buf: pointer; num_read: csize_t): cint {.
    importc: "i2c_write_read", header: "i2c.h".}



## *
##  @brief Read multiple bytes from an internal address of an I2C device.
##
##  This routine reads multiple bytes from an internal address of an
##  I2C device synchronously.
##
##  Instances of this may be replaced by i2c_write_read().
##
##  @param dev Pointer to the device structure for an I2C controller
##  driver configured in master mode.
##  @param dev_addr Address of the I2C device for reading.
##  @param start_addr Internal address from which the data is being read.
##  @param buf Memory pool that stores the retrieved data.
##  @param num_bytes Number of bytes being read.
##
##  @retval 0 If successful.
##  @retval -EIO General input / output error.
##

proc i2c_burst_read*(dev: ptr device; dev_addr: uint16; start_addr: uint8;
                    buf: ptr uint8; num_bytes: uint32): cint {.
    importc: "i2c_burst_read", header: "i2c.h".}



## *
##  @brief Write multiple bytes to an internal address of an I2C device.
##
##  This routine writes multiple bytes to an internal address of an
##  I2C device synchronously.
##
##  @warning The combined write synthesized by this API may not be
##  supported on all I2C devices.  Uses of this API may be made more
##  portable by replacing them with calls to i2c_write() passing a
##  buffer containing the combined address and data.
##
##  @param dev Pointer to the device structure for an I2C controller
##  driver configured in master mode.
##  @param dev_addr Address of the I2C device for writing.
##  @param start_addr Internal address to which the data is being written.
##  @param buf Memory pool from which the data is transferred.
##  @param num_bytes Number of bytes being written.
##
##  @retval 0 If successful.
##  @retval -EIO General input / output error.
##

proc i2c_burst_write*(dev: ptr device; dev_addr: uint16; start_addr: uint8;
                     buf: ptr uint8; num_bytes: uint32): cint {.
    importc: "i2c_burst_write", header: "i2c.h".}



## *
##  @brief Read internal register of an I2C device.
##
##  This routine reads the value of an 8-bit internal register of an I2C
##  device synchronously.
##
##  @param dev Pointer to the device structure for an I2C controller
##  driver configured in master mode.
##  @param dev_addr Address of the I2C device for reading.
##  @param reg_addr Address of the internal register being read.
##  @param value Memory pool that stores the retrieved register value.
##
##  @retval 0 If successful.
##  @retval -EIO General input / output error.
##

proc i2c_reg_read_byte*(dev: ptr device; dev_addr: uint16; reg_addr: uint8;
                       value: ptr uint8): cint {.importc: "i2c_reg_read_byte",
    header: "i2c.h".}



## *
##  @brief Write internal register of an I2C device.
##
##  This routine writes a value to an 8-bit internal register of an I2C
##  device synchronously.
##
##  @note This function internally combines the register and value into
##  a single bus transaction.
##
##  @param dev Pointer to the device structure for an I2C controller
##  driver configured in master mode.
##  @param dev_addr Address of the I2C device for writing.
##  @param reg_addr Address of the internal register being written.
##  @param value Value to be written to internal register.
##
##  @retval 0 If successful.
##  @retval -EIO General input / output error.
##

proc i2c_reg_write_byte*(dev: ptr device; dev_addr: uint16; reg_addr: uint8;
                        value: uint8): cint {.importc: "i2c_reg_write_byte",
    header: "i2c.h".}



## *
##  @brief Update internal register of an I2C device.
##
##  This routine updates the value of a set of bits from an 8-bit internal
##  register of an I2C device synchronously.
##
##  @note If the calculated new register value matches the value that
##  was read this function will not generate a write operation.
##
##  @param dev Pointer to the device structure for an I2C controller
##  driver configured in master mode.
##  @param dev_addr Address of the I2C device for updating.
##  @param reg_addr Address of the internal register being updated.
##  @param mask Bitmask for updating internal register.
##  @param value Value for updating internal register.
##
##  @retval 0 If successful.
##  @retval -EIO General input / output error.
##

proc i2c_reg_update_byte*(dev: ptr device; dev_addr: uint8; reg_addr: uint8;
                         mask: uint8; value: uint8): cint {.
    importc: "i2c_reg_update_byte", header: "i2c.h".}



## *
##  @brief Dump out an I2C message
##
##  Dumps out a list of I2C messages. For any that are writes (W), the data is
##  displayed in hex.
##
##  It looks something like this (with name "testing"):
##
##  D: I2C msg: testing, addr=56
##  D:    W len=01:
##  D: contents:
##  D: 06                      |.
##  D:    W len=0e:
##  D: contents:
##  D: 00 01 02 03 04 05 06 07 |........
##  D: 08 09 0a 0b 0c 0d       |......
##
##  @param name Name of this dump, displayed at the top.
##  @param msgs Array of messages to dump.
##  @param num_msgs Number of messages to dump.
##  @param addr Address of the I2C target device.
##

proc i2c_dump_msgs*(name: cstring; msgs: ptr i2c_msg; num_msgs: uint8; `addr`: uint16) {.
    importc: "i2c_dump_msgs", header: "i2c.h".}





## *
##  @}
##
