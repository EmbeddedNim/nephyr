import std/options

import nephyr
import nephyr/general
import nephyr/zephyr/[zdevice, zdevicetree]
import nephyr/zephyr/drivers/[zflash, znvs]

import mcu_utils/[logging, timeutils, allocstats]

type
  NvsConfig* = ref object
    fs*: nvs_fs
    flash*: ptr device

static:
  assert CONFIG_NVS == true, "must config nvs in project config to use this module"

proc initNvs*(
    flash: string,
    sectorCount: int,
    partitionOffset: ByteSz
): NvsConfig =
  ## create and initialize an nvs partiton
  result = NvsConfig()
  result.flash = device_get_binding(flashDevice)

  if not device_is_ready(result.flash):
    raiseZephyrError("Flash device is not ready", 0)

  var info: flash_pages_info
  check: flash_get_page_info_by_offs(result.flash, result.fs.offset, addr info)

  result.fs.flash_device = flash_dev
  result.fs.sector_size = Qspiflash_config.sectorSize.uint16
  result.fs.sector_count = sectorCount

  check: nvs_init(result.fs.addr, result.flash.name)

template initNvs*(
    flash: string,
    sectorCount: int,
    partitionName: static[string],
    isBits = static[bool] = false,
): NvsConfig =
  ## helper template that finds the flash partition offset
  let offsetRaw = FLASH_AREA_OFFSET(partitionName)
  let offset: ByteSz = 
    when isBits:
      ByteSz(offsetRaw div 8)
    else:
      ByteSz(offsetRaw)
  result = initNvs(flash, sectorCount, offset)
