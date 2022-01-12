import ../wrapper_utils
import ../zdevice
import zgpio

export wrapper_utils, zdevice, zgpio

const hdr = "<drivers/spi.h>"

##
##  Copyright (c) 2015 Intel Corporation
##
##  SPDX-License-Identifier: Apache-2.0
##
## *
##  @file
##  @brief Public API for SPI drivers and applications
##

## *
##  @brief SPI Interface
##  @defgroup spi_interface SPI Interface
##  @ingroup io_interfaces
##  @{
##

## *
##  @brief SPI operational mode
##

const
  SPI_OP_MODE_MASTER* = 0x0
  SPI_OP_MODE_SLAVE* = BIT(0)
  SPI_OP_MODE_MASK* = 0x1


#define SPI_OP_MODE_GET(_operation_) ((_operation_) & SPI_OP_MODE_MASK)
template SPI_OP_MODE_GET*(operation: untyped): untyped =
  operation and SPI_OP_MODE_MASK

## *
##  @brief SPI Polarity & Phase Modes
##
## *
##  Clock Polarity: if set, clock idle state will be 1
##  and active state will be 0. If untouched, the inverse will be true
##  which is the default.
##
const
  SPI_MODE_CPOL* = BIT(1)



## *
##  Clock Phase: this dictates when is the data captured, and depends
##  clock's polarity. When SPI_MODE_CPOL is set and this bit as well,
##  capture will occur on low to high transition and high to low if
##  this bit is not set (default). This is fully reversed if CPOL is
##  not set.
##
const
  SPI_MODE_CPHA* = BIT(2)



## *
##  Whatever data is transmitted is looped-back to the receiving buffer of
##  the controller. This is fully controller dependent as some may not
##  support this, and can be used for testing purposes only.
##
const
  SPI_MODE_LOOP* = BIT(3)
  SPI_MODE_MASK* = 0xE

template SPI_MODE_GET*(mode: untyped): untyped =
  mode and SPI_MODE_MASK


## *
##  @brief SPI Transfer modes (host controller dependent)
##
const
  SPI_TRANSFER_MSB* = 0x0
  SPI_TRANSFER_LSB* = BIT(4)




## *
##  @brief SPI word size
##
const
  SPI_WORD_SIZE_SHIFT* = 0x5
  SPI_WORD_SIZE_MASK* = 0x3F shl SPI_WORD_SIZE_SHIFT


template SPI_WORD_SIZE_GET*(operation: untyped): untyped =
  (((operation) and SPI_WORD_SIZE_MASK) shr SPI_WORD_SIZE_SHIFT)

template SPI_WORD_SET*(word_size: untyped): untyped =
  ((word_size) shl SPI_WORD_SIZE_SHIFT)



## *
##  @brief SPI MISO lines
##
##  Some controllers support dual, quad or octal MISO lines connected to slaves.
##  Default is single, which is the case most of the time.
##
const
  SPI_LINES_SINGLE* = (0x0 shl 11)
  SPI_LINES_DUAL*   = (0x1 shl 11)
  SPI_LINES_QUAD*   = (0x2 shl 11)
  SPI_LINES_OCTAL*  = (0x3 shl 11)
  SPI_LINES_MASK*   = (0x3 shl 11)



## *
##  @brief Specific SPI devices control bits
##
##  Requests - if possible - to keep CS asserted after the transaction
const
  SPI_HOLD_ON_CS* = BIT(13)

##  Keep the device locked after the transaction for the current config.
##  Use this with extreme caution (see spi_release() below) as it will
##  prevent other callers to access the SPI device until spi_release() is
##  properly called.
##
const
  SPI_LOCK_ON* = BIT(14)



##  Active high logic on CS - Usually, and by default, CS logic is active
##  low. However, some devices may require the reverse logic: active high.
##  This bit will request the controller to use that logic. Note that not
##  all controllers are able to handle that natively. In this case deferring
##  the CS control to a gpio line through struct spi_cs_control would be
##  the solution.
##
const
  SPI_CS_ACTIVE_HIGH* = BIT(15)



## *
##  @brief SPI Chip Select control structure
##
##  This can be used to control a CS line via a GPIO line, instead of
##  using the controller inner CS logic.
##
##  @param gpio_dev is a valid pointer to an actual GPIO device. A NULL pointer
##         can be provided to full inhibit CS control if necessary.
##  @param gpio_pin is a number representing the gpio PIN that will be used
##     to act as a CS line
##  @param delay is a delay in microseconds to wait before starting the
##     transmission and before releasing the CS line
##  @param gpio_dt_flags is the devicetree flags corresponding to how the CS
##     line should be driven. GPIO_ACTIVE_LOW/GPIO_ACTIVE_HIGH should be
##     equivalent to SPI_CS_ACTIVE_HIGH/SPI_CS_ACTIVE_LOW options in struct
##     spi_config.
##
type
  spi_cs_control* {.importc: "struct spi_cs_control", header: hdr, bycopy.} = object
    gpio_dev* {.importc: "gpio_dev".}: ptr device
    delay* {.importc: "delay".}: uint32
    gpio_pin* {.importc: "gpio_pin".}: gpio_pin_t
    gpio_dt_flags* {.importc: "gpio_dt_flags".}: gpio_dt_flags_t


## *
##  @brief Initialize and get a pointer to a @p spi_cs_control from a
##         devicetree node identifier
##
##  This helper is useful for initializing a device on a SPI bus. It
##  initializes a struct spi_cs_control and returns a pointer to it.
##  Here, @p node_id is a node identifier for a SPI device, not a SPI
##  controller.
##
##  Example devicetree fragment:
##
##      spi@... {
##              cs-gpios = <&gpio0 1 GPIO_ACTIVE_LOW>;
##              spidev: spi-device@0 { ... };
##      };
##
##  Assume that @p gpio0 follows the standard convention for specifying
##  GPIOs, i.e. it has the following in its binding:
##
##      gpio-cells:
##      - pin
##      - flags
##
##  Example usage:
##
##      struct spi_cs_control *ctrl =
##              SPI_CS_CONTROL_PTR_DT(DT_NODELABEL(spidev), 2);
##
##  This example is equivalent to:
##
##      struct spi_cs_control *ctrl =
##              &(struct spi_cs_control) {
##                      .gpio_dev = DEVICE_DT_GET(DT_NODELABEL(gpio0)),
##                      .delay = 2,
##                      .gpio_pin = 1,
##                      .gpio_dt_flags = GPIO_ACTIVE_LOW
##              };
##
##  This macro is not available in C++.
##
##  @param node_id Devicetree node identifier for a device on a SPI bus
##  @param delay_ The @p delay field to set in the @p spi_cs_control
##  @return a pointer to the @p spi_cs_control structure
##
proc SPI_CS_CONTROL_PTR_DT*(node_id: cminvtoken; delay: cminvtoken): ptr spi_cs_control {.
    importc: "SPI_CS_CONTROL_PTR_DT", header: hdr.}



## *
##  @brief Get a pointer to a @p spi_cs_control from a devicetree node
##
##  This is equivalent to
##  <tt>SPI_CS_CONTROL_PTR_DT(DT_DRV_INST(inst), delay)</tt>.
##
##  Therefore, @p DT_DRV_COMPAT must already be defined before using
##  this macro.
##
##  This macro is not available in C++.
##
##  @param inst Devicetree node instance number
##  @param delay_ The @p delay field to set in the @p spi_cs_control
##  @return a pointer to the @p spi_cs_control structure
##
proc SPI_CS_CONTROL_PTR_DT_INST*(inst: cminvtoken; delay: cminvtoken) {.
    importc: "SPI_CS_CONTROL_PTR_DT_INST", header: hdr.}



## *
##  @brief SPI controller configuration structure
##
##  @param frequency is the bus frequency in Hertz
##  @param operation is a bit field with the following parts:
##
##      operational mode    [ 0 ]       - master or slave.
##      mode                [ 1 : 3 ]   - Polarity, phase and loop mode.
##      transfer            [ 4 ]       - LSB or MSB first.
##      word_size           [ 5 : 10 ]  - Size of a data frame in bits.
##      lines               [ 11 : 12 ] - MISO lines: Single/Dual/Quad/Octal.
##      cs_hold             [ 13 ]      - Hold on the CS line if possible.
##      lock_on             [ 14 ]      - Keep resource locked for the caller.
##      cs_active_high      [ 15 ]      - Active high CS logic.
##  @param slave is the slave number from 0 to host controller slave limit.
##  @param cs is a valid pointer on a struct spi_cs_control is CS line is
##     emulated through a gpio line, or NULL otherwise.
##
##  @note Only cs_hold and lock_on can be changed between consecutive
##  transceive call. Rest of the attributes are not meant to be tweaked.
##
##  @warning Most drivers use pointer comparison to determine whether a
##  passed configuration is different from one used in a previous
##  transaction.  Changes to fields in the structure may not be
##  detected.
##
type
  spi_config* {.importc: "struct spi_config", header: hdr, bycopy.} = object
    frequency* {.importc: "frequency".}: uint32
    operation* {.importc: "operation".}: uint16
    slave* {.importc: "slave".}: uint16
    cs* {.importc: "cs".}: ptr spi_cs_control





## *
##  @brief Structure initializer for spi_config from devicetree
##
##  This helper macro expands to a static initializer for a <tt>struct
##  spi_config</tt> by reading the relevant @p frequency, @p slave, and
##  @p cs data from the devicetree.
##
##  Important: the @p cs field is initialized using
##  SPI_CS_CONTROL_PTR_DT(). The @p gpio_dev value pointed to by this
##  structure must be checked using device_is_ready() before use.
##
##  This macro is not available in C++.
##
##  @param node_id Devicetree node identifier for the SPI device whose
##                 struct spi_config to create an initializer for
##  @param operation_ the desired @p operation field in the struct spi_config
##  @param delay_ the desired @p delay field in the struct spi_config's
##                spi_cs_control, if there is one
##
proc SPI_CONFIG_DT*(node_id: cminvtoken; operation: cminvtoken; delay: cminvtoken) {.
    importc: "SPI_CONFIG_DT", header: hdr.}



## *
##  @brief Structure initializer for spi_config from devicetree instance
##
##  This is equivalent to
##  <tt>SPI_CONFIG_DT(DT_DRV_INST(inst), operation_, delay_)</tt>.
##
##  This macro is not available in C++.
##
##  @param inst Devicetree instance number
##  @param operation_ the desired @p operation field in the struct spi_config
##  @param delay_ the desired @p delay field in the struct spi_config's
##                spi_cs_control, if there is one
##

proc SPI_CONFIG_DT_INST*(inst: cminvtoken; operation: cminvtoken; delay: cminvtoken) {.
    importc: "SPI_CONFIG_DT_INST", header: hdr.}



## *
##  @brief SPI buffer structure
##
##  @param buf is a valid pointer on a data buffer, or NULL otherwise.
##  @param len is the length of the buffer or, if buf is NULL, will be the
##     length which as to be sent as dummy bytes (as TX buffer) or
##     the length of bytes that should be skipped (as RX buffer).
##
type
  spi_buf* {.importc: "struct spi_buf", header: hdr, bycopy.} = object
    buf* {.importc: "buf".}: pointer
    len* {.importc: "len".}: csize_t


## *
##  @brief SPI buffer array structure
##
##  @param buffers is a valid pointer on an array of spi_buf, or NULL.
##  @param count is the length of the array pointed by buffers.
##

type
  spi_buf_set* {.importc: "struct spi_buf_set", header: hdr, bycopy.} = object
    buffers* {.importc: "buffers".}: ptr spi_buf
    count* {.importc: "count".}: csize_t


## *
##  @typedef spi_api_io
##  @brief Callback API for I/O
##  See spi_transceive() for argument descriptions
##
type
  spi_api_io* = proc (dev: ptr device; config: ptr spi_config; tx_bufs: ptr spi_buf_set;
                   rx_bufs: ptr spi_buf_set): cint

## *
##  @typedef spi_api_io
##  @brief Callback API for asynchronous I/O
##  See spi_transceive_async() for argument descriptions
##
type
  spi_api_io_async* = proc (dev: ptr device; config: ptr spi_config;
                         tx_bufs: ptr spi_buf_set; rx_bufs: ptr spi_buf_set;
                         async: ptr k_poll_signal): cint

## *
##  @typedef spi_api_release
##  @brief Callback API for unlocking SPI device.
##  See spi_release() for argument descriptions
##
type
  spi_api_release* = proc (dev: ptr device; config: ptr spi_config): cint




## *
##  @brief SPI driver API
##  This is the mandatory API any SPI driver needs to expose.
##
type
  spi_driver_api* {.importc: "spi_driver_api", header: hdr, bycopy.} = object
    transceive* {.importc: "transceive".}: spi_api_io
    when CONFIG_SPI_ASYNC:
      transceive_async* {.header: hdr.}: spi_api_io_async
    release* {.importc: "release".}: spi_api_release





## *
##  @brief Read/write the specified amount of data from the SPI driver.
##
##  Note: This function is synchronous.
##
##  @param dev Pointer to the device structure for the driver instance
##  @param config Pointer to a valid spi_config structure instance.
##         Pointer-comparison may be used to detect changes from
##         previous operations.
##  @param tx_bufs Buffer array where data to be sent originates from,
##         or NULL if none.
##  @param rx_bufs Buffer array where data to be read will be written to,
##         or NULL if none.
##
##  @retval 0 If successful, negative errno code otherwise. In case of slave
##          transaction: if successful it will return the amount of frames
##          received, negative errno code otherwise.
##
proc spi_transceive*(dev: ptr device; config: ptr spi_config; tx_bufs: ptr spi_buf_set;
                    rx_bufs: ptr spi_buf_set): cint {.syscall,
    importc: "spi_transceive", header: hdr.}



## *
##  @brief Read the specified amount of data from the SPI driver.
##
##  Note: This function is synchronous.
##
##  @param dev Pointer to the device structure for the driver instance
##  @param config Pointer to a valid spi_config structure instance.
##         Pointer-comparison may be used to detect changes from
##         previous operations.
##  @param rx_bufs Buffer array where data to be read will be written to.
##
##  @retval 0 If successful, negative errno code otherwise.
##
##  @note This function is an helper function calling spi_transceive.
##
proc spi_read*(dev: ptr device; config: ptr spi_config; rx_bufs: ptr spi_buf_set): cint {.
    inline, importc: "spi_read".} =
  return spi_transceive(dev, config, nil, rx_bufs)

## *
##  @brief Write the specified amount of data from the SPI driver.
##
##  Note: This function is synchronous.
##
##  @param dev Pointer to the device structure for the driver instance
##  @param config Pointer to a valid spi_config structure instance.
##         Pointer-comparison may be used to detect changes from
##         previous operations.
##  @param tx_bufs Buffer array where data to be sent originates from.
##
##  @retval 0 If successful, negative errno code otherwise.
##
##  @note This function is an helper function calling spi_transceive.
##
proc spi_write*(dev: ptr device; config: ptr spi_config; tx_bufs: ptr spi_buf_set): cint {.
    inline, importc: "spi_write".} =
  return spi_transceive(dev, config, tx_bufs, nil)

##  Doxygen defines this so documentation is generated.

when CONFIG_SPI_ASYNC:
  ## *
  ##  @brief Read/write the specified amount of data from the SPI driver.
  ##
  ##  @note This function is asynchronous.
  ##
  ##  @note This function is available only if @option{CONFIG_SPI_ASYNC}
  ##  is selected.
  ##
  ##  @param dev Pointer to the device structure for the driver instance
  ##  @param config Pointer to a valid spi_config structure instance.
  ##         Pointer-comparison may be used to detect changes from
  ##         previous operations.
  ##  @param tx_bufs Buffer array where data to be sent originates from,
  ##         or NULL if none.
  ##  @param rx_bufs Buffer array where data to be read will be written to,
  ##         or NULL if none.
  ##  @param async A pointer to a valid and ready to be signaled
  ##         struct k_poll_signal. (Note: if NULL this function will not
  ##         notify the end of the transaction, and whether it went
  ##         successfully or not).
  ##
  ##  @retval 0 If successful, negative errno code otherwise. In case of slave
  ##          transaction: if successful it will return the amount of frames
  ##          received, negative errno code otherwise.
  ##
  proc spi_transceive_async*(dev: ptr device; config: ptr spi_config;
                            tx_bufs: ptr spi_buf_set; rx_bufs: ptr spi_buf_set;
                            async: ptr k_poll_signal): cint {.inline,
      importc: "spi_transceive_async".} =
    let api: ptr spi_driver_api
    return api.transceive_async(dev, config, tx_bufs, rx_bufs, async)

  ## *
  ##  @brief Read the specified amount of data from the SPI driver.
  ##
  ##  @note This function is asynchronous.
  ##
  ##  @note This function is available only if @option{CONFIG_SPI_ASYNC}
  ##  is selected.
  ##
  ##  @param dev Pointer to the device structure for the driver instance
  ##  @param config Pointer to a valid spi_config structure instance.
  ##         Pointer-comparison may be used to detect changes from
  ##         previous operations.
  ##  @param rx_bufs Buffer array where data to be read will be written to.
  ##  @param async A pointer to a valid and ready to be signaled
  ##         struct k_poll_signal. (Note: if NULL this function will not
  ##         notify the end of the transaction, and whether it went
  ##         successfully or not).
  ##
  ##  @retval 0 If successful, negative errno code otherwise.
  ##
  ##  @note This function is an helper function calling spi_transceive_async.
  ##
  proc spi_read_async*(dev: ptr device; config: ptr spi_config;
                      rx_bufs: ptr spi_buf_set; async: ptr k_poll_signal): cint {.
      inline, importc: "spi_read_async".} =
    return spi_transceive_async(dev, config, nil, rx_bufs, async)

  ## *
  ##  @brief Write the specified amount of data from the SPI driver.
  ##
  ##  @note This function is asynchronous.
  ##
  ##  @note This function is available only if @option{CONFIG_SPI_ASYNC}
  ##  is selected.
  ##
  ##  @param dev Pointer to the device structure for the driver instance
  ##  @param config Pointer to a valid spi_config structure instance.
  ##         Pointer-comparison may be used to detect changes from
  ##         previous operations.
  ##  @param tx_bufs Buffer array where data to be sent originates from.
  ##  @param async A pointer to a valid and ready to be signaled
  ##         struct k_poll_signal. (Note: if NULL this function will not
  ##         notify the end of the transaction, and whether it went
  ##         successfully or not).
  ##
  ##  @retval 0 If successful, negative errno code otherwise.
  ##
  ##  @note This function is an helper function calling spi_transceive_async.
  ##
  proc spi_write_async*(dev: ptr device; config: ptr spi_config;
                       tx_bufs: ptr spi_buf_set; async: ptr k_poll_signal): cint {.
      inline, importc: "spi_write_async".} =
    return spi_transceive_async(dev, config, tx_bufs, nil, async)




## *
##  @brief Release the SPI device locked on by the current config
##
##  Note: This synchronous function is used to release the lock on the SPI
##        device that was kept if, and if only, given config parameter was
##        the last one to be used (in any of the above functions) and if
##        it has the SPI_LOCK_ON bit set into its operation bits field.
##        This can be used if the caller needs to keep its hand on the SPI
##        device for consecutive transactions.
##
##  @param dev Pointer to the device structure for the driver instance
##  @param config Pointer to a valid spi_config structure instance.
##         Pointer-comparison may be used to detect changes from
##         previous operations.
##
proc spi_release*(dev: ptr device; config: ptr spi_config): cint {.syscall,
    importc: "spi_release", header: hdr.}


## *
##  @}
##
