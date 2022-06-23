
## Mock for NVS using just a table 

import std/[tables, strformat]

import nephyr/zephyr/zkernel_fixes
import nephyr/zephyr/zdevice
# import nephyr/zephyr/drivers/zflash

type
  flash_pages_info* = object
    start_offset* {.importc: "start_offset".}: off_t ##  offset from the base of flash address
    size* {.importc: "size".}: csize_t
    index* {.importc: "index".}: uint32

proc flash_get_page_info_by_offs*(dev: ptr device; offset: off_t;
                                  info: ptr flash_pages_info): cint = 0