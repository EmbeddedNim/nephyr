import std/options

import nephyr
import nephyr/general
import nephyr/zephyr/[zdevice, zdevicetree]
import nephyr/zephyr/drivers/[zflash, znvs]

import mcu_utils/[logging, timeutils, allocstats]

type
  NvsConfig* = ref object
    fs*: nvs_fs

static:
  assert CONFIG_NVS == true, "must config nvs in project config to use this module"

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

  result.fs.flash_device = flash_dev
  result.fs.offset = partitionOffset.cint
  result.fs.sector_count = sectorCount

  if sectorSize.int > 0:
    result.fs.sector_size = sectorSize.uint16
  else:
    ## unless overrided, lookup sectorSize
    var info: flash_pages_info
    check: flash_get_page_info_by_offs(
                flash_dev,
                partitionOffset.cint,
                addr info)
    result.fs.sector_size = info.size.uint16

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
