import ../zkernel_fixes
import ../zconfs
import ../zdevice
import ../zkernel
import ../kernel/zk_locks

const hdr = "<drivers/flash.h>"
const hdr_flash_map = "<storage/flash_map.h>"

proc FLASH_AREA_OFFSET*(node: cminvtoken): cint {.importc: "$1", header: hdr_flash_map.} ##\
  ## Zephyr macro to get the flash offset for a partition from the DTS. 
  ## This will return the offset address as listed in the DTS partition, e.g.
  ##  `slot1_partition: partition@1800000 { ... } ` => 1800000 
  ## 
  ## Note: Be careful to note whether the flash driver expects bits or bytes.

type
  flash_pages_layout* {.importc: "struct flash_pages_layout", header: hdr,
      bycopy.} = object
    pages_count* {.importc: "pages_count".}: csize ##  count of pages sequence of the same size
    pages_size* {.importc: "pages_size".}: csize

type
  flash_parameters* {.importc: "struct flash_parameters", header: hdr, bycopy.} = object ##\
    ##  Flash memory parameters. Contents of this structure suppose to be
    ##  filled in during flash device initialization and stay constant
    ##  through a runtime.
    ##
    write_block_size* {.importc: "write_block_size".}: csize_t
    erase_value* {.importc: "erase_value".}: uint8 ##  Byte value of erased flash


type
  flash_api_read* = proc (dev: ptr device; offset: off_t; data: pointer;
      len: csize_t): cint {.cdecl.}


type
  flash_api_write* = proc (dev: ptr device; offset: off_t; data: pointer;
      len: csize_t): cint {.cdecl.} ##\
    ##  @note Any necessary write protection management must be performed by
    ##  the driver, with the driver responsible for ensuring the "write-protect"
    ##  after the operation completes (successfully or not) matches the write-protect
    ##  state when the operation was started.
    ##

type
  flash_api_erase* = proc (dev: ptr device; offset: off_t; size: csize_t): cint {.cdecl.} ##\
    ## *
    ##  @brief Flash erase implementation handler type
    ##
    ##  @note Any necessary erase protection management must be performed by
    ##  the driver, with the driver responsible for ensuring the "erase-protect"
    ##  after the operation completes (successfully or not) matches the erase-protect
    ##  state when the operation was started.
    ##


when defined(CONFIG_FLASH_PAGE_LAYOUT):
  type
    flash_api_pages_layout* = proc (dev: ptr device;
                                 layout: ptr ptr flash_pages_layout;
                                 layout_size: ptr csize_t) {.cdecl.} ##\
      ##  A flash device layout is a run-length encoded description of the
      ##  pages on the device. (Here, "page" means the smallest erasable
      ##  area on the flash device.)
      ##
      ##  For flash memories which have uniform page sizes, this routine
      ##  returns an array of length 1, which specifies the page size and
      ##  number of pages in the memory.
      ##
      ##  Layouts for flash memories with nonuniform page sizes will be
      ##  returned as an array with multiple elements, each of which
      ##  describes a group of pages that all have the same size. In this
      ##  case, the sequence of array elements specifies the order in which
      ##  these groups occur on the device.
      ##
      ##  @param dev         Flash device whose layout to retrieve.
      ##  @param layout      The flash layout will be returned in this argument.
      ##  @param layout_size The number of elements in the returned layout.
      ##


type
  flash_api_sfdp_read* = proc (dev: ptr device; offset: off_t; data: pointer;
      len: csize_t): cint

  flash_api_read_jedec_id* = proc (dev: ptr device; id: ptr uint8): cint

  flash_driver_api* {.importc: "struct flash_driver_api", header: hdr,
      bycopy.} = object
    read* {.importc: "read".}: flash_api_read
    write* {.importc: "write".}: flash_api_write
    erase* {.importc: "erase".}: flash_api_erase
    when defined(CONFIG_FLASH_PAGE_LAYOUT):
      page_layout* {.header: hdr.}: flash_api_pages_layout
    when defined(CONFIG_FLASH_JESD216_API):
      sfdp_read* {.header: hdr.}: flash_api_sfdp_read
      read_jedec_id* {.header: hdr.}: flash_api_read_jedec_id


proc flash_read*(dev: ptr device; offset: off_t; data: pointer;
    len: csize_t): cint {.
    syscall, importc: "flash_read", header: hdr.} ##\
      ##   All flash drivers support reads without alignment restrictions on
      ##   the read offset, the read size, or the destination address.
      ##
      ##   @param  dev             : flash dev
      ##   @param  offset          : Offset (byte aligned) to read
      ##   @param  data            : Buffer to store read data
      ##   @param  len             : Number of bytes to read.
      ##
      ##   @return  0 on success, negative errno code on fail.
      ##





proc flash_write*(dev: ptr device; offset: off_t; data: pointer;
    len: csize_t): cint {.
    syscall, importc: "flash_write", header: hdr.} ##\
      ##   All flash drivers support a source buffer located either in RAM or
      ##   SoC flash, without alignment restrictions on the source address.
      ##   Write size and offset must be multiples of the minimum write block size
      ##   supported by the driver.
      ##
      ##   Any necessary write protection management is performed by the driver
      ##   write implementation itself.
      ##
      ##   @param  dev             : flash device
      ##   @param  offset          : starting offset for the write
      ##   @param  data            : data to write
      ##   @param  len             : Number of bytes to write
      ##
      ##   @return  0 on success, negative errno code on fail.
      ##

## *
##   @brief  Erase part or all of a flash memory
##
##   Acceptable values of erase size and offset are subject to
##   hardware-specific multiples of page size and offset. Please check
##   the API implemented by the underlying sub driver, for example by
##   using flash_get_page_info_by_offs() if that is supported by your
##   flash driver.
##
##   Any necessary erase protection management is performed by the driver
##   erase implementation itself.
##
##   @param  dev             : flash device
##   @param  offset          : erase area starting offset
##   @param  size            : size of area to be erased
##
##   @return  0 on success, negative errno code on fail.
##
##   @see flash_get_page_info_by_offs()
##   @see flash_get_page_info_by_idx()
##

proc flash_erase*(dev: ptr device; offset: off_t; size: csize_t): cint {.
    importc: "flash_erase", header: hdr.}


## *
##   @brief  Enable or disable write protection for a flash memory
##
##   This API is deprecated and will be removed in Zephyr 2.8.
##   It will be keep as No-Operation until removal.
##   Flash write/erase protection management has been moved to write and erase
##   operations implementations in flash driver shims. For Out-of-tree drivers
##   which are not updated yet flash write/erase protection management is done
##   in flash_erase() and flash_write() using deprecated <p>write_protection</p>
##   shim handler.
##
##   @param  dev             : flash device
##   @param  enable          : enable or disable flash write protection
##
##   @return  0 on success, negative errno code on fail.
##

proc flash_write_protection_set*(dev: ptr device; enable: bool): cint {.
    importc: "flash_write_protection_set", header: hdr.}

type
  flash_pages_info* {.importc: "struct flash_pages_info", header: hdr,
      bycopy.} = object
    start_offset* {.importc: "start_offset".}: off_t ##  offset from the base of flash address
    size* {.importc: "size".}: csize_t
    index* {.importc: "index".}: uint32

## *
##   @brief  Get the size and start offset of flash page at certain flash offset.
##
##   @param  dev flash device
##   @param  offset Offset within the page
##   @param  info Page Info structure to be filled
##
##   @return  0 on success, -EINVAL if page of the offset doesn't exist.
##
proc flash_get_page_info_by_offs*(dev: ptr device; offset: off_t;
                                  info: ptr flash_pages_info): cint {.zsyscall,
    importc: "flash_get_page_info_by_offs", header: hdr.}
## *
##   @brief  Get the size and start offset of flash page of certain index.
##
##   @param  dev flash device
##   @param  page_index Index of the page. Index are counted from 0.
##   @param  info Page Info structure to be filled
##
##   @return  0 on success, -EINVAL  if page of the index doesn't exist.
##
proc flash_get_page_info_by_idx*(dev: ptr device; page_index: uint32;
                                info: ptr flash_pages_info): cint {.zsyscall,
    importc: "flash_get_page_info_by_idx", header: hdr.}
## *
##   @brief  Get the total number of flash pages.
##
##   @param  dev flash device
##
##   @return  Number of flash pages.
##
proc flash_get_page_count*(dev: ptr device): csize_t {.syscall,
    importc: "flash_get_page_count", header: hdr.}
## *
##  @brief Callback type for iterating over flash pages present on a device.
##
##  The callback should return true to continue iterating, and false to halt.
##
##  @param info Information for current page
##  @param data Private data for callback
##  @return True to continue iteration, false to halt iteration.
##  @see flash_page_foreach()
##
type
  flash_page_cb* = proc (info: ptr flash_pages_info; data: pointer): bool
## *
##  @brief Iterate over all flash pages on a device
##
##  This routine iterates over all flash pages on the given device,
##  ordered by increasing start offset. For each page, it invokes the
##  given callback, passing it the page's information and a private
##  data object.
##
##  @param dev Device whose pages to iterate over
##  @param cb Callback to invoke for each flash page
##  @param data Private data for callback function
##
proc flash_page_foreach*(dev: ptr device; cb: flash_page_cb; data: pointer) {.
    importc: "flash_page_foreach", header: hdr.}

when defined(CONFIG_FLASH_JESD216_API):
  ## *
  ##  @brief Read data from Serial Flash Discoverable Parameters
  ##
  ##  This routine reads data from a serial flash device compatible with
  ##  the JEDEC JESD216 standard for encoding flash memory
  ##  characteristics.
  ##
  ##  Availability of this API is conditional on selecting
  ##  @c CONFIG_FLASH_JESD216_API and support of that functionality in
  ##  the driver underlying @p dev.
  ##
  ##  @param dev device from which parameters will be read
  ##  @param offset address within the SFDP region containing data of interest
  ##  @param data where the data to be read will be placed
  ##  @param len the number of bytes of data to be read
  ##
  ##  @retval 0 on success
  ##  @retval -ENOTSUP if the flash driver does not support SFDP access
  ##  @retval negative values for other errors.
  ##
  proc flash_sfdp_read*(dev: ptr device; offset: off_t; data: pointer;
      len: csize_t): cint {.
      syscall, importc: "flash_sfdp_read", header: hdr.}

  ## *
  ##  @brief Read the JEDEC ID from a compatible flash device.
  ##
  ##  @param dev device from which id will be read
  ##  @param id pointer to a buffer of at least 3 bytes into which id
  ##  will be stored
  ##
  ##  @retval 0 on successful store of 3-byte JEDEC id
  ##  @retval -ENOTSUP if flash driver doesn't support this function
  ##  @retval negative values for other errors
  ##
  proc flash_read_jedec_id*(dev: ptr device; id: ptr uint8): cint {.syscall,
      importc: "flash_read_jedec_id", header: hdr.}

## *
##   @brief  Get the minimum write block size supported by the driver
##
##   The write block size supported by the driver might differ from the write
##   block size of memory used because the driver might implements write-modify
##   algorithm.
##
##   @param  dev flash device
##
##   @return  write block size in bytes.
##

proc flash_get_write_block_size*(dev: ptr device): csize_t {.syscall,
    importc: "flash_get_write_block_size", header: hdr.}

## *
##   @brief  Get pointer to flash_parameters structure
##
##   Returned pointer points to a structure that should be considered
##   constant through a runtime, regardless if it is defined in RAM or
##   Flash.
##   Developer is free to cache the structure pointer or copy its contents.
##
##   @return pointer to flash_parameters structure characteristic for
##           the device.
##

proc flash_get_parameters*(dev: ptr device): ptr flash_parameters {.syscall,
    importc: "flash_get_parameters", header: hdr.}


when true: # CONFIG_BOOT_FLEXSPI_NOR or defined(zephyr):
  type
    flexspi_mem_config_t* {.importc: "struct flexspi_mem_config_t",
        header: "<flexspi_nor_config.h>", bycopy.} = object
      # tag* {.importc: "tag".}: uint32
      # version* {.importc: "version".}: uint32_t
      # reserved0* {.importc: "reserved0".}: uint32_t
      # readSampleClkSrc* {.importc: "readSampleClkSrc".}: uint8_t
      # csHoldTime* {.importc: "csHoldTime".}: uint8_t
      # csSetupTime* {.importc: "csSetupTime".}: uint8_t
      # columnAddressWidth* {.importc: "columnAddressWidth".}: uint8_t
      # deviceModeCfgEnable* {.importc: "deviceModeCfgEnable".}: uint8_t
      # deviceModeType* {.importc: "deviceModeType".}: uint8_t
      # waitTimeCfgCommands* {.importc: "waitTimeCfgCommands".}: uint16_t
      # deviceModeSeq* {.importc: "deviceModeSeq".}: flexspi_lut_seq_t
      # deviceModeArg* {.importc: "deviceModeArg".}: uint32_t
      # configCmdEnable* {.importc: "configCmdEnable".}: uint8_t
      # configModeType* {.importc: "configModeType".}: array[3, uint8_t]
      # configCmdSeqs* {.importc: "configCmdSeqs".}: array[3, flexspi_lut_seq_t]
      # reserved1* {.importc: "reserved1".}: uint32_t
      # configCmdArgs* {.importc: "configCmdArgs".}: array[3, uint32_t]
      # reserved2* {.importc: "reserved2".}: uint32_t
      # controllerMiscOption* {.importc: "controllerMiscOption".}: uint32_t
      # deviceType* {.importc: "deviceType".}: uint8_t
      # sflashPadType* {.importc: "sflashPadType".}: uint8_t
      # serialClkFreq* {.importc: "serialClkFreq".}: uint8_t
      # lutCustomSeqEnable* {.importc: "lutCustomSeqEnable".}: uint8_t
      # reserved3* {.importc: "reserved3".}: array[2, uint32_t]
      sflashA1Size* {.importc: "sflashA1Size".}: uint32
      # sflashA2Size* {.importc: "sflashA2Size".}: uint32_t
      # sflashB1Size* {.importc: "sflashB1Size".}: uint32_t
      # sflashB2Size* {.importc: "sflashB2Size".}: uint32_t
      # csPadSettingOverride* {.importc: "csPadSettingOverride".}: uint32_t
      # sclkPadSettingOverride* {.importc: "sclkPadSettingOverride".}: uint32_t
      # dataPadSettingOverride* {.importc: "dataPadSettingOverride".}: uint32_t
      # dqsPadSettingOverride* {.importc: "dqsPadSettingOverride".}: uint32_t
      # timeoutInMs* {.importc: "timeoutInMs".}: uint32_t
      # commandInterval* {.importc: "commandInterval".}: uint32_t
      # dataValidTime* {.importc: "dataValidTime".}: array[2, uint16_t]
      # busyOffset* {.importc: "busyOffset".}: uint16_t
      # busyBitPolarity* {.importc: "busyBitPolarity".}: uint16_t
      # lookupTable* {.importc: "lookupTable".}: array[64, uint32_t]
      # lutCustomSeq* {.importc: "lutCustomSeq".}: array[12, flexspi_lut_seq_t]
      # reserved4* {.importc: "reserved4".}: array[4, uint32_t]

    flexspi_nor_config_t* {.importc: "struct flexspi_nor_config_t",
        header: "<flexspi_nor_config.h>", bycopy.} = object  ##\
        ## flash config for nxp chip families like i.mx
      memConfig* {.importc: "memConfig".}: flexspi_mem_config_t
      pageSize* {.importc: "pageSize".}: uint32
      sectorSize* {.importc: "sectorSize".}: uint32
      ipcmdSerialClkFreq* {.importc: "ipcmdSerialClkFreq".}: uint8
      isUniformBlockSize* {.importc: "isUniformBlockSize".}: uint8
      # reserved0* {.importc: "reserved0".}: array[2, uint8_t]
      serialNorType* {.importc: "serialNorType".}: uint8
      needExitNoCmdMode* {.importc: "needExitNoCmdMode".}: uint8
      halfClkForNonReadCmd* {.importc: "halfClkForNonReadCmd".}: uint8
      needRestoreNoCmdMode* {.importc: "needRestoreNoCmdMode".}: uint8
      blockSize* {.importc: "blockSize".}: uint32
      # reserve2* {.importc: "reserve2".}: array[11, uint32_t]

    flexspi_device_config_t* {.importc: "struct flexspi_device_config_t",
                              bycopy, incompleteStruct.} = object
      # flexspiRootClk* {.importc: "flexspiRootClk".}: uint32 ## !< FLEXSPI serial root clock.
      # isSck2Enabled* {.importc: "isSck2Enabled".}: bool ## !< FLEXSPI use SCK2.
      flashSize* {.importc: "flashSize".}: uint32 ## !< Flash size in KByte.
      # dataValidTime* {.importc: "dataValidTime".}: uint8 ## !< Data valid time for external device.
      # columnspace* {.importc: "columnspace".}: uint8 ## !< Column space size.
      # enableWordAddress* {.importc: "enableWordAddress".}: bool ## !< If enable word address.
      # enableWriteMask* {.importc: "enableWriteMask".}: bool ## !< Enable/Disable FLEXSPI drive DQS pin as write mask

    flash_flexspi_nor_config* {.importc: "struct flash_flexspi_nor_config",
                              bycopy, incompleteStruct.} = object
      controller_label* {.importc: "controller_label".}: cstring
      # port* {.importc: "port".}: flexspi_port_t
      config* {.importc: "config".}: flexspi_device_config_t
      layout* {.importc: "layout".}: flash_pages_layout
      flash_parameters* {.importc: "flash_parameters".}: flash_parameters

  var Qspiflash_config* {.importc: "Qspiflash_config".}: flexspi_nor_config_t


else:
  static:
    raise newException(Exception, "flexspi")



