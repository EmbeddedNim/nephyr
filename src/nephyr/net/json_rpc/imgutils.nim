
import json

import strutils

import nephyr/general

import zephyr_c/drivers/zflash_img
import zephyr_c/zmcuboot

import router

# TODO: FIXME: handle non-secure and/or second core images
{.emit: """
#include <storage/flash_map.h>

#define ImagePrimary FLASH_AREA_ID(image_0)
#define ImageSecondary FLASH_AREA_ID(image_1)
""".}

var ImagePrimary* {.importc: "$1", nodecl.}: uint8
var ImageSecondary* {.importc: "$1", nodecl.}: uint8
# var ImageBPrimary* {.importc: "FLASH_AREA_ID(image_2)", nodecl.}: cint
# var ImageBSecondary* {.importc: "FLASH_AREA_ID(image_3)", nodecl.}: cint


type
  FirmwareImg = ref object
    idx: int
    ctx: flash_img_context

  FirmwareFinish* = object
    permanent: bool

proc initFirmwareImg*(): FirmwareImg =
  result = new(FirmwareImg)
  check: flash_img_init(addr result.ctx)
  result.idx = 0

proc len*(fw: FirmwareImg): int = 
  result = flash_img_bytes_written(addr fw.ctx).int

proc write*(fw: FirmwareImg, data: string, flush = false): int =
  let dataPtr = cast[ptr uint8](data[0].unsafeAddr)
  check:
    flash_img_buffered_write(addr fw.ctx, dataPtr, data.len().csize_t, flush)
  fw.idx.inc()
  return data.len()

proc finish*(fw: FirmwareImg): int =
  var data = [0'u8,0'u8]
  let dataPtr = addr data[0]
  check:
    flash_img_buffered_write(addr fw.ctx, dataPtr, 0.csize_t, true)

proc check*(fw: FirmwareImg, id: uint8): flash_img_check =
  var chk = flash_img_check()
  check: flash_img_checks(addr fw.ctx, addr chk, id.uint8)
  result = chk

var
  fwImage: FirmwareImg

# Setup RPC Server #
proc addImageUtilMethods*(rt: var RpcRouter) =

  rpc(rt, "fw-info") do() -> JsonNode:
    return %* {"block_size": CONFIG_IMG_BLOCK_BUF_SIZE}

  rpc(rt, "fw-init") do() -> bool:
    fwImage = initFirmwareImg()
    logi("fw-init: 0x" & cast[int](addr fwImage.ctx).tohex())
    result = true

  rpc(rt, "fw-write") do(idx: int, img_chunk: string, flush: bool) -> int:
    logd("fw writing: idx: " & $idx & " curr_idx: " $fwImage.idx & " size: " & $img_chunk.len())
    if idx != fwImage.idx:
      raise newException(ValueError, "mismatch indexes!")
    if flush:
      logi("fw writing & flushing ")
    result = fwImage.write(img_chunk, flush)


  rpc(rt, "fw-len") do() -> int:
    result = fwImage.len()

  rpc(rt, "fw-finish") do(arg: FirmwareFinish) -> JsonNode:
    logi("fw finish: arg: " & $arg )
    let bytes = fwImage.finish()
    logi("fw finish: wrote: " & $bytes )
    check: boot_request_upgrade(if arg.permanent: 1 else: 0)
    result = %* {"written": bytes, "permanent": arg.permanent}

  rpc(rt, "fw-upgrade") do(arg: FirmwareFinish) -> JsonNode:
    check: boot_request_upgrade(if arg.permanent: 1 else: 0)
    result = %* {"permanent": arg.permanent}

  rpc(rt, "fw-imgcheck") do(id: int) -> JsonNode:
    let res = fwImage.check(id.uint8)
    result = %* res

  rpc(rt, "fw-verify") do() -> bool:
    check: boot_write_img_confirmed()
    result = true

  rpc(rt, "fw-status") do() -> JsonNode:
    let
      img_status = boot_write_img_confirmed() != 0
      swap_type_id = mcuboot_swap_type()
    
    if swap_type_id <= 0:
      raise newException(OSError, "swap type id: " & $(swap_type_id))
    let
      swapType = BtSwapType(swap_type_id)

    result = %* {"confirmed": img_status, "swap_type": $swapType}

  rpc(rt, "fw-header") do(id: int) -> JsonNode:
    var hdr = mcuboot_img_header()
    let area_id: uint8 = 
      if id == -1:
        ImagePrimary
      else:
        id.uint8

    check: boot_read_bank_header(area_id, addr hdr, sizeof(hdr).csize_t)
    result = %* hdr

  rpc(rt, "sys-reboot") do():
    sysReboot(false)

  rpc(rt, "sys-reboot-cold") do():
    sysReboot(coldReboot=true)

