## *
##  @file
##
##  @brief Public APIs for the DMA drivers.
##
##
##  Copyright (c) 2016 Intel Corporation
##
##  SPDX-License-Identifier: Apache-2.0
##

## *
##  @brief DMA Interface
##  @defgroup dma_interface DMA Interface
##  @ingroup io_interfaces
##  @{
##

import zconfs
import zdevice

const hdr = "<dma.h>"

type
  dma_channel_direction* {.size: sizeof(cint).} = enum
    MEMORY_TO_MEMORY = 0x0,
    MEMORY_TO_PERIPHERAL,
    PERIPHERAL_TO_MEMORY,
    PERIPHERAL_TO_PERIPHERAL ## only supported in NXP EDMA


type
  dma_addr_adj* {.size: sizeof(cint).} = enum
    ## * Valid values for @a source_addr_adj and @a dest_addr_adj
    DMA_ADDR_ADJ_INCREMENT,
    DMA_ADDR_ADJ_DECREMENT,
    DMA_ADDR_ADJ_NO_CHANGE


##  channel attributes

type
  dma_channel_filter* {.size: sizeof(cint).} = enum
    DMA_CHANNEL_NORMAL,       ##  normal DMA channel
    DMA_CHANNEL_PERIODIC      ##  can be triggerred by periodic sources

## *
##  @struct dma_block_config
##  @brief DMA block configuration structure.
##
##  @param source_address is block starting address at source
##  @param source_gather_interval is the address adjustment at gather boundary
##  @param dest_address is block starting address at destination
##  @param dest_scatter_interval is the address adjustment at scatter boundary
##  @param dest_scatter_count is the continuous transfer count between scatter
##                     boundaries
##  @param source_gather_count is the continuous transfer count between gather
##                      boundaries
##
##  @param block_size is the number of bytes to be transferred for this block.
##
##  @param config is a bit field with the following parts:
##
##      source_gather_en   [ 0 ]       - 0-disable, 1-enable.
##      dest_scatter_en    [ 1 ]       - 0-disable, 1-enable.
##      source_addr_adj    [ 2 : 3 ]   - 00-increment, 01-decrement,
##                                       10-no change.
##      dest_addr_adj      [ 4 : 5 ]   - 00-increment, 01-decrement,
##                                       10-no change.
##      source_reload_en   [ 6 ]       - reload source address at the end of
##                                       block transfer
##                                       0-disable, 1-enable.
##      dest_reload_en     [ 7 ]       - reload destination address at the end
##                                       of block transfer
##                                       0-disable, 1-enable.
##      fifo_mode_control  [ 8 : 11 ]  - How full  of the fifo before transfer
##                                       start. HW specific.
##      flow_control_mode  [ 12 ]      - 0-source request served upon data
##                                         availability.
##                                       1-source request postponed until
##                                         destination request happens.
##      reserved           [ 13 : 15 ]
##

type
  dma_block_config* {.importc: "dma_block_config", header: hdr, bycopy.} = object
    when CONFIG_DMA_64BIT:
      source_address* {.importc: "source_address".}: uint64
      dest_address* {.importc: "dest_address".}: uint64
    else:
      source_address* {.importc: "source_address".}: uint32
      dest_address* {.importc: "dest_address".}: uint32
    source_gather_interval* {.importc: "source_gather_interval".}: uint32
    dest_scatter_interval* {.importc: "dest_scatter_interval".}: uint32
    dest_scatter_count* {.importc: "dest_scatter_count".}: uint16
    source_gather_count* {.importc: "source_gather_count".}: uint16
    block_size* {.importc: "block_size".}: uint32
    next_block* {.importc: "next_block".}: ptr dma_block_config
    source_gather_en* {.importc: "source_gather_en", bitsize: 1.}: uint16
    dest_scatter_en* {.importc: "dest_scatter_en", bitsize: 1.}: uint16
    source_addr_adj* {.importc: "source_addr_adj", bitsize: 2.}: uint16
    dest_addr_adj* {.importc: "dest_addr_adj", bitsize: 2.}: uint16
    source_reload_en* {.importc: "source_reload_en", bitsize: 1.}: uint16
    dest_reload_en* {.importc: "dest_reload_en", bitsize: 1.}: uint16
    fifo_mode_control* {.importc: "fifo_mode_control", bitsize: 4.}: uint16
    flow_control_mode* {.importc: "flow_control_mode", bitsize: 1.}: uint16
    reserved* {.importc: "reserved", bitsize: 3.}: uint16


## *
##  @typedef dma_callback_t
##  @brief Callback function for DMA transfer completion
##
##   If enabled, callback function will be invoked at transfer completion
##   or when error happens.
##
##  @param dev Pointer to the DMA device calling the callback.
##  @param user_data A pointer to some user data or NULL
##  @param channel The channel number
##  @param status 0 on success, a negative errno otherwise
##

type
  dma_callback_t* = proc (dev: ptr device; user_data: pointer; channel: uint32;
                       status: cint)

## *
##  @struct dma_config
##  @brief DMA configuration structure.
##
##  @param dma_slot             [ 0 : 6 ]   - which peripheral and direction
##                                         (HW specific)
##  @param channel_direction    [ 7 : 9 ]   - 000-memory to memory,
##                                         001-memory to peripheral,
##                                         010-peripheral to memory,
##                                         011-peripheral to peripheral,
##                                         ...
##  @param complete_callback_en [ 10 ]       - 0-callback invoked at completion only
##                                         1-callback invoked at completion of
##                                           each block
##  @param error_callback_en    [ 11 ]      - 0-error callback enabled
##                                         1-error callback disabled
##  @param source_handshake     [ 12 ]      - 0-HW, 1-SW
##  @param dest_handshake       [ 13 ]      - 0-HW, 1-SW
##  @param channel_priority     [ 14 : 17 ] - DMA channel priority
##  @param source_chaining_en   [ 18 ]      - enable/disable source block chaining
##                                         0-disable, 1-enable
##  @param dest_chaining_en     [ 19 ]      - enable/disable destination block
##                                         chaining.
##                                         0-disable, 1-enable
##  @param linked_channel       [ 20 : 26 ] - after channel count exhaust will
##                                         initiate a channel service request
##                                         at this channel
##  @param reserved             [ 27 : 31 ]
##  @param source_data_size    [ 0 : 15 ]   - width of source data (in bytes)
##  @param dest_data_size      [ 16 : 31 ]  - width of dest data (in bytes)
##  @param source_burst_length [ 0 : 15 ]   - number of source data units
##  @param dest_burst_length   [ 16 : 31 ]  - number of destination data units
##  @param block_count  is the number of blocks used for block chaining, this
##      depends on availability of the DMA controller.
##  @param user_data  private data from DMA client.
##  @param dma_callback see dma_callback_t for details
##

type
  dma_config* {.importc: "dma_config", header: hdr, bycopy.} = object
    dma_slot* {.importc: "dma_slot", bitsize: 7.}: uint32
    channel_direction* {.importc: "channel_direction", bitsize: 3.}: uint32
    complete_callback_en* {.importc: "complete_callback_en", bitsize: 1.}: uint32
    error_callback_en* {.importc: "error_callback_en", bitsize: 1.}: uint32
    source_handshake* {.importc: "source_handshake", bitsize: 1.}: uint32
    dest_handshake* {.importc: "dest_handshake", bitsize: 1.}: uint32
    channel_priority* {.importc: "channel_priority", bitsize: 4.}: uint32
    source_chaining_en* {.importc: "source_chaining_en", bitsize: 1.}: uint32
    dest_chaining_en* {.importc: "dest_chaining_en", bitsize: 1.}: uint32
    linked_channel* {.importc: "linked_channel", bitsize: 7.}: uint32
    reserved* {.importc: "reserved", bitsize: 5.}: uint32
    source_data_size* {.importc: "source_data_size", bitsize: 16.}: uint32
    dest_data_size* {.importc: "dest_data_size", bitsize: 16.}: uint32
    source_burst_length* {.importc: "source_burst_length", bitsize: 16.}: uint32
    dest_burst_length* {.importc: "dest_burst_length", bitsize: 16.}: uint32
    block_count* {.importc: "block_count".}: uint32
    head_block* {.importc: "head_block".}: ptr dma_block_config
    user_data* {.importc: "user_data".}: pointer
    dma_callback* {.importc: "dma_callback".}: dma_callback_t


## *
##  DMA runtime status structure
##
##  busy 			- is current DMA transfer busy or idle
##  dir				- DMA transfer direction
##  pending_length 		- data length pending to be transferred in bytes
##  					or platform dependent.
##
##

type
  dma_status* {.importc: "dma_status", header: hdr, bycopy.} = object
    busy* {.importc: "busy".}: bool
    dir* {.importc: "dir".}: dma_channel_direction
    pending_length* {.importc: "pending_length".}: uint32


## *
##  DMA context structure
##  Note: the dma_context shall be the first member
##        of DMA client driver Data, got by dev->data
##
##  magic			- magic code to identify the context
##  dma_channels		- dma channels
##  atomic			- driver atomic_t pointer
##
##

type
  dma_context* {.importc: "dma_context", header: hdr, bycopy, incompleteStruct.} = object
    magic* {.importc: "magic".}: int32
    dma_channels* {.importc: "dma_channels".}: cint
    # atomic* {.importc: "atomic".}: ptr atomic_t


##  magic code to identify context content

const
  DMA_MAGIC* = 0x47494749

## *
##  @cond INTERNAL_HIDDEN
##
##  These are for internal use only, so skip these in
##  public documentation.
##

type
  dma_api_config* = proc (dev: ptr device; channel: uint32; config: ptr dma_config): cint

when defined(CONFIG_DMA_64BIT):
  type
    dma_api_reload* = proc (dev: ptr device; channel: uint32; src: uint64; dst: uint64;
                         size: csize_t): cint
else:
  type
    dma_api_reload* = proc (dev: ptr device; channel: uint32; src: uint32; dst: uint32;
                         size: csize_t): cint
type
  dma_api_start* = proc (dev: ptr device; channel: uint32): cint
  dma_api_stop* = proc (dev: ptr device; channel: uint32): cint
  dma_api_get_status* = proc (dev: ptr device; channel: uint32; status: ptr dma_status): cint

## *
##  @typedef dma_chan_filter
##  @brief channel filter function call
##
##  filter function that is used to find the matched internal dma channel
##  provide by caller
##
##  @param dev Pointer to the DMA device instance
##  @param channel the channel id to use
##  @param filter_param filter function parameter, can be NULL
##
##  @retval True on filter matched otherwise return False.
##

type
  dma_api_chan_filter* = proc (dev: ptr device; channel: cint; filter_param: pointer): bool
  dma_driver_api* {.importc: "dma_driver_api", header: hdr, bycopy.} = object
    config* {.importc: "config".}: dma_api_config
    reload* {.importc: "reload".}: dma_api_reload
    start* {.importc: "start".}: dma_api_start
    stop* {.importc: "stop".}: dma_api_stop
    get_status* {.importc: "get_status".}: dma_api_get_status
    chan_filter* {.importc: "chan_filter".}: dma_api_chan_filter


## *
##  @endcond
##
## *
##  @brief Configure individual channel for DMA transfer.
##
##  @param dev     Pointer to the device structure for the driver instance.
##  @param channel Numeric identification of the channel to configure
##  @param config  Data structure containing the intended configuration for the
##                 selected channel
##
##  @retval 0 if successful.
##  @retval Negative errno code if failure.
##

proc dma_configure*(dev: ptr device; channel: uint32; config: ptr dma_config): cint {.importc: "dma_config", header: hdr.}

## *
##  @brief Reload buffer(s) for a DMA channel
##
##  @param dev     Pointer to the device structure for the driver instance.
##  @param channel Numeric identification of the channel to configure
##                 selected channel
##  @param src     source address for the DMA transfer
##  @param dst     destination address for the DMA transfer
##  @param size    size of DMA transfer
##
##  @retval 0 if successful.
##  @retval Negative errno code if failure.
##

when defined(CONFIG_DMA_64BIT):
  proc dma_reload*(dev: ptr device; channel: uint32; src: uint64; dst: uint64;
                  size: csize_t): cint {.inline, importc: "dma_reload",
                                      header: hdr.}
else:
  proc dma_reload*(dev: ptr device; channel: uint32; src: uint32; dst: uint32;
                  size: csize_t): cint {.inline, importc: "dma_reload",
                                      header: hdr.}

## *
##  @brief Enables DMA channel and starts the transfer, the channel must be
##         configured beforehand.
##
##  Implementations must check the validity of the channel ID passed in and
##  return -EINVAL if it is invalid.
##
##  @param dev     Pointer to the device structure for the driver instance.
##  @param channel Numeric identification of the channel where the transfer will
##                 be processed
##
##  @retval 0 if successful.
##  @retval Negative errno code if failure.
##

proc dma_start*(dev: ptr device; channel: uint32): cint {.syscall, importc: "dma_start",
    header: hdr.}
proc z_impl_dma_start*(dev: ptr device; channel: uint32): cint {.importc: "$1", header: hdr.}

## *
##  @brief Stops the DMA transfer and disables the channel.
##
##  Implementations must check the validity of the channel ID passed in and
##  return -EINVAL if it is invalid.
##
##  @param dev     Pointer to the device structure for the driver instance.
##  @param channel Numeric identification of the channel where the transfer was
##                 being processed
##
##  @retval 0 if successful.
##  @retval Negative errno code if failure.
##

proc dma_stop*(dev: ptr device; channel: uint32): cint {.syscall, importc: "dma_stop",
    header: hdr.}
proc z_impl_dma_stop*(dev: ptr device; channel: uint32): cint {.importc: "$1", header: hdr.}

## *
##  @brief request DMA channel.
##
##  request DMA channel resources
##  return -EINVAL if there is no valid channel available.
##
##  @param dev Pointer to the device structure for the driver instance.
##  @param filter_param filter function parameter
##
##  @retval dma channel if successful.
##  @retval Negative errno code if failure.
##

proc dma_request_channel*(dev: ptr device; filter_param: pointer): cint {.syscall,
    importc: "dma_request_channel", header: hdr.}
proc z_impl_dma_request_channel*(dev: ptr device; filter_param: pointer): cint {.importc: "$1", header: hdr.}

## *
##  @brief release DMA channel.
##
##  release DMA channel resources
##
##  @param dev  Pointer to the device structure for the driver instance.
##  @param channel  channel number
##
##

proc dma_release_channel*(dev: ptr device; channel: uint32) {.syscall,
    importc: "dma_release_channel", header: hdr.}
proc z_impl_dma_release_channel*(dev: ptr device; channel: uint32) {.importc: "$1", header: hdr.}

## *
##  @brief DMA channel filter.
##
##  filter channel by attribute
##
##  @param dev  Pointer to the device structure for the driver instance.
##  @param channel  channel number
##  @param filter_param filter attribute
##
##  @retval Negative errno code if not support
##
##

proc dma_chan_filter*(dev: ptr device; channel: cint; filter_param: pointer): cint {.
    syscall, importc: "dma_chan_filter", header: hdr.}
proc z_impl_dma_chan_filter*(dev: ptr device; channel: cint; filter_param: pointer): cint {.importc: "$1", header: hdr.}

## *
##  @brief get current runtime status of DMA transfer
##
##  Implementations must check the validity of the channel ID passed in and
##  return -EINVAL if it is invalid or -ENOSYS if not supported.
##
##  @param dev     Pointer to the device structure for the driver instance.
##  @param channel Numeric identification of the channel where the transfer was
##                 being processed
##  @param stat   a non-NULL dma_status object for storing DMA status
##
##  @retval non-negative if successful.
##  @retval Negative errno code if failure.
##

proc dma_get_status*(dev: ptr device; channel: uint32; stat: ptr dma_status): cint {.importc: "$1", header: hdr.}

## *
##  @brief Look-up generic width index to be used in registers
##
##  WARNING: This look-up works for most controllers, but *may* not work for
##           yours.  Ensure your controller expects the most common register
##           bit values before using this convenience function.  If your
##           controller does not support these values, you will have to write
##           your own look-up inside the controller driver.
##
##  @param size: width of bus (in bytes)
##
##  @retval common DMA index to be placed into registers.
##

proc dma_width_index*(size: uint32): uint32 {.importc: "$1", header: hdr.}

## *
##  @brief Look-up generic burst index to be used in registers
##
##  WARNING: This look-up works for most controllers, but *may* not work for
##           yours.  Ensure your controller expects the most common register
##           bit values before using this convenience function.  If your
##           controller does not support these values, you will have to write
##           your own look-up inside the controller driver.
##
##  @param burst: number of bytes to be sent in a single burst
##
##  @retval common DMA index to be placed into registers.
##

proc dma_burst_index*(burst: uint32): uint32 {.importc: "$1", header: hdr.}

## *
##  @}
##
