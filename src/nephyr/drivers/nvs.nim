## NVS: non volatile storage in flash
##

const hdr = "<fs/nvs.h>"

type
  nvs_fs* {.importc: "nvs_fs", header: hdr, bycopy.} = object ##\
    ## *
    ##  @brief Non-volatile Storage File system structure
    ##
    ##  @param offset File system offset in flash
    ##  @param ate_wra Allocation table entry write address. Addresses are stored as uint32:
    ##  high 2 bytes correspond to the sector, low 2 bytes are the offset in the sector
    ##  @param data_wra Data write address
    ##  @param sector_size File system is split into sectors, each sector must be multiple of pagesize
    ##  @param sector_count Number of sectors in the file systems
    ##  @param ready Flag indicating if the filesystem is initialized
    ##  @param nvs_lock Mutex
    ##  @param flash_device Flash Device runtime structure
    ##  @param flash_parameters Flash memory parameters structure
    offset* {.importc: "offset".}: cint ## 
    ate_wra* {.importc: "ate_wra".}: uint32
    data_wra* {.importc: "data_wra".}: uint32
    sector_size* {.importc: "sector_size".}: uint16
    sector_count* {.importc: "sector_count".}: uint16
    ready* {.importc: "ready".}: bool
    nvs_lock* {.importc: "nvs_lock".}: k_mutex
    flash_device* {.importc: "flash_device".}: ptr device
    flash_parameters* {.importc: "flash_parameters".}: ptr flash_parameters



proc nvs_init*(fs: ptr nvs_fs; dev_name: cstring): cint {.importc: "nvs_init",
    header: hdr.} ##\
  ##  Initializes a NVS file system in flash.
  ##
  ##  @param fs Pointer to file system
  ##  @param dev_name Pointer to flash device name
  ##  @retval 0 Success
  ##  @retval -ERRNO errno code if error
  ##




proc nvs_clear*(fs: ptr nvs_fs): cint {.importc: "nvs_clear", header: hdr.} ##\
  ##  Clears the NVS file system from flash.
  ##  @param fs Pointer to file system
  ##  @retval 0 Success
  ##  @retval -ERRNO errno code if error
  ##



proc nvs_write*(fs: ptr nvs_fs; id: uint16; data: pointer; len: csize): csize {.
    importc: "nvs_write", header: hdr.} ##\
  ##  Write an entry to the file system.
  ##
  ##  @param fs Pointer to file system
  ##  @param id Id of the entry to be written
  ##  @param data Pointer to the data to be written
  ##  @param len Number of bytes to be written
  ##
  ##  @return Number of bytes written. On success, it will be equal to the number of bytes requested
  ##  to be written. When a rewrite of the same data already stored is attempted, nothing is written
  ##  to flash, thus 0 is returned. On error, returns negative value of errno.h defined error codes.
  ##




proc nvs_delete*(fs: ptr nvs_fs; id: uint16): cint {.importc: "nvs_delete",
    header: hdr.} ##\
  ##  Delete an entry from the file system
  ##
  ##  @param fs Pointer to file system
  ##  @param id Id of the entry to be deleted
  ##  @retval 0 Success
  ##  @retval -ERRNO errno code if error
  ##




proc nvs_read*(fs: ptr nvs_fs; id: uint16; data: pointer; len: csize): csize {.
    importc: "nvs_read", header: hdr.} ##\
  ##  Read an entry from the file system.
  ##
  ##  @param fs Pointer to file system
  ##  @param id Id of the entry to be read
  ##  @param data Pointer to data buffer
  ##  @param len Number of bytes to be read
  ##
  ##  @return Number of bytes read. On success, it will be equal to the number of bytes requested
  ##  to be read. When the return value is larger than the number of bytes requested to read this
  ##  indicates not all bytes were read, and more data is available. On error, returns negative
  ##  value of errno.h defined error codes.
  ##




proc nvs_read_hist*(fs: ptr nvs_fs; id: uint16; data: pointer; len: csize;
                   cnt: uint16): csize {.importc: "nvs_read_hist",
    header: hdr.} ##\
  ##  Read a history entry from the file system.
  ##
  ##  @param fs Pointer to file system
  ##  @param id Id of the entry to be read
  ##  @param data Pointer to data buffer
  ##  @param len Number of bytes to be read
  ##  @param cnt History counter: 0: latest entry, 1: one before latest ...
  ##
  ##  @return Number of bytes read. On success, it will be equal to the number of bytes requested
  ##  to be read. When the return value is larger than the number of bytes requested to read this
  ##  indicates not all bytes were read, and more data is available. On error, returns negative
  ##  value of errno.h defined error codes.
  ##



proc nvs_calc_free_space*(fs: ptr nvs_fs): csize {.importc: "nvs_calc_free_space",
    header: hdr.} ##\
  ##  Calculate the available free space in the file system.
  ##
  ##  @param fs Pointer to file system
  ##
  ##  @return Number of bytes free. On success, it will be equal to the number of bytes that can
  ##  still be written to the file system. Calculating the free space is a time consuming operation,
  ##  especially on spi flash. On error, returns negative value of errno.h defined error codes.
  ##



