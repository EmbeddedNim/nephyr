import std/sha1, strutils, json, strformat

import router

const TAG = "otaupdate"

var ota: OtaUpdateHandle = nil
var otaId: int = 0
var otaBuff: string

proc checkSha1Hash*(val: string, hash: string) =
    let sh = $secureHash(val)
    if sh != hash:
      raise newException(ValueError, "incorrect hash")

proc addOTAMethods*(rt: RpcRouter, ota_validation_cb = proc(): bool = true) =

  ##[
  See [upload proc in rpc_cli.nim](https://github.com/elcritch/zephyr_example-dumb_http_server_/blob/main/utils/rpc_cli.nim) for reference client usage. 
  
  Note this requires a properly signed image signed by MCUBoot's imgtooly.py program. Directions [west sign](https://docs.zephyrproject.org/latest/guides/west/sign.html).
  
  This api is largely a one-to-one wrapper around the Zephyr api's:
  - [dfu/flash_img.h](https://github.com/zephyrproject-rtos/zephyr/blob/main/include/dfu/flash_img.h)
  - [dfu/mcuboot.h](https://github.com/zephyrproject-rtos/zephyr/blob/main/include/dfu/mcuboot.h)
  
  Detailed docs for using Zephyr with MCUBoot can be found at [readme-zephyr](https://www.mcuboot.com/documentation/readme-zephyr/). 
  
  An overview blog post summarizing MCUBoot can be found [memfault.com mcuboot-overview page](https://interrupt.memfault.com/blog/mcuboot-overview).
  
  ]##
  rpc(rt, "firmware-begin") do(img_head: string, sha1_hash: string) -> JsonNode:
    # Call to begin writing a firmware update to the OTA

    # TODO: add way to reset OTA after it's started? Not sure how...
    if ota != nil:
      raise newException(ValueError, "OTA update already started! Reboot or reset. ")

    # Check the FW Hash
    img_head.checkSha1Hash(sha1_hash)

    # Create new FW Hash
    ota = newOtaUpdateHandle(nil)
    let desc = ota.checkImageHeader(img_head, version_check = true)

    case desc.status:
    of VersionUnchecked, VersionMatchesPreviousInvalid, VersionSameAsCurrent:
      result = % ["incorrect", $desc.status]
    of VersionNewer:
      result = % ["ok", $desc.status]

    ota_id = 1
    ota.begin()

    ota.write(img_head)
    ota_buff = ""

  rpc(rt, "firmware-chunk") do(img_chunk: string, sha1_hash: string, id: int) -> int:
    # Call to write each chunk, the id is just for a double check
    if id != ota_id:
      raise newException(ValueError, "firmware chunk id incorrect!")

    img_chunk.checkSha1Hash(sha1_hash)
    ota_buff.add(img_chunk)

    if ota_buff.len() >= 4096:
      logd(fmt"writing firmware chunk: idx: {id} of size: {ota_buff.len()}")
      ota.write(ota_buff)
      ota_buff = ""
    else:
      logd(fmt"appending firmware chunk: idx: {id} of size: {ota_buff.len()}")

    ota_id.inc()
    result = ota.total_written

  rpc(rt, "firmware-finish") do(sha1_hash: string) -> string:
    # Call to finalize firmware after writing all the chunks
    logd("Writing final block of {ota_buff.len()}")
    ota.write(ota_buff)
    ota_buff = "" # reset buffer string

    logd("Finalizing: firmware finish fw upload for {sha1_hash}")
    ota.finish()
    delayMillis(12)

    logd("Done and setting as boot partion")
    ota.set_as_boot_partition()

    logd("Finalized FW OTA update")
    result = ota.total_written
    ota = nil
    ota_id = 0

    return "ok"

  rpc(rt, "firmware-verify") do() -> string:
    logd("Remotely Verified FW update")
    firmware_verify(ota_validation_cb)

    return "ok"
