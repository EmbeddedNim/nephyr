import std/options

import nephyr
import nephyr/general
import nephyr/zephyr/[zdevice, zdevicetree]
import nephyr/zephyr/drivers/[zflash, znvs]

import mcu_utils/[logging, timeutils, allocstats]

import strformat

type
  NvsConfig* = ref object
    fs*: nvs_fs

static:
  assert CONFIG_NVS == true, "must config nvs in project config to use this module"

import os

proc initNvs*(
    flash: string,
    sectorCount: uint16,
    partitionOffset: BytesSz,
    sectorSize = -1.BytesSz,
): NvsConfig =
  ## create and initialize an nvs partiton
  result = NvsConfig()
  let flash_dev = device_get_binding(flash)

  if not device_is_ready(flash_dev):
    raise newException(OSError, "Flash device is not ready")

  echo fmt"fs_dev: {flash_dev.name=}"

  result.fs.flash_device = flash_dev
  result.fs.offset = partitionOffset.cint
  result.fs.sector_count = sectorCount
  echo fmt"fs info: {result.fs.offset=}"
  echo fmt"fs info: {result.fs.sector_count=}"

  os.sleep(200)
  if sectorSize.int > 0:
    result.fs.sector_size = sectorSize.uint16
    echo fmt"calling flash info: {result.fs.sector_size=}"
  else:
    echo fmt"calling flash info: "
    ## unless overrided, lookup sectorSize
    var info: flash_pages_info
    check: flash_get_page_info_by_offs(
                flash_dev,
                partitionOffset.cint,
                addr info)
    result.fs.sector_size = info.size.uint16
    echo fmt"calling flash info: {result.fs.sector_size=}"

  echo fmt"calling nvs_init "
  check: nvs_init(result.fs.addr, flash_dev.name)

template initNvs*(
    flash: string,
    sectorCount: uint16,
    partitionName: static[string],
    isBits: static[bool] = false,
): NvsConfig =
  ## helper template that finds the flash partition offset
  let offsetRaw = FLASH_AREA_OFFSET(tok(partitionName))
  let offset: BytesSz = when isBits: BytesSz(offsetRaw div 8)
                        else: BytesSz(offsetRaw)
  initNvs(flash, sectorCount, offset)
