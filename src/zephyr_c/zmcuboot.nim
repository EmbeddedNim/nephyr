##
##  Copyright (c) 2017 Nordic Semiconductor ASA
##  Copyright (c) 2016 Linaro Limited
##
##  SPDX-License-Identifier: Apache-2.0
##

const hdrmcu = "<dfu/mcuboot.h>"

var
  BOOT_SWAP_TYPE_NONE* {.importc: "$1", header: hdrmcu, nodecl.}: cint #\
    # * Attempt to boot the contents of slot 0.
  BOOT_SWAP_TYPE_TEST* {.importc: "$1", header: hdrmcu, nodecl.}: cint #\
    # * Swap to slot 1.  Absent a confirm command, revert back on next boot.
  BOOT_SWAP_TYPE_PERM* {.importc: "$1", header: hdrmcu, nodecl.}: cint #\
    # * Swap to slot 1, and permanently switch to booting its contents.
  BOOT_SWAP_TYPE_REVERT* {.importc: "$1", header: hdrmcu, nodecl.}: cint #\
    # * Swap back to alternate slot.  A confirm changes this state to NONE.
  BOOT_SWAP_TYPE_FAIL* {.importc: "$1", header: hdrmcu, nodecl.}: cint #\
    # * Swap failed because image to be run is not valid
  BOOT_IMG_VER_STRLEN_MAX* {.importc: "$1", header: hdrmcu, nodecl.}: cint #\
    # * max strlen 

type
  BtSwapType* {.size: sizeof(cint).} = enum
    swNone = 1,
    swTest = 2,
    swPerm = 3,
    swRevert = 4,
    swFail = 5

##  Trailer:
var
  BOOT_MAX_ALIGN* {.importc: "$1", header: hdrmcu, nodecl.}: cint #\
  BOOT_MAGIC_SZ* {.importc: "$1", header: hdrmcu, nodecl.}: cint #\

proc BOOT_TRAILER_IMG_STATUS_OFFS*(bank_area: csize_t): csize_t {.importc: "$1", header: hdrmcu.}

## *
##  @brief MCUboot image header representation for image version
##
##  The header for an MCUboot firmware image contains an embedded
##  version number, in semantic versioning format. This structure
##  represents the information it contains.
##

type
  mcuboot_img_sem_ver* {.bycopy.} = object
    major*: uint8
    minor*: uint8
    revision*: uint16
    build_num*: uint32


## *
##  @brief Model for the MCUboot image header as of version 1
##
##  This represents the data present in the image header, in version 1
##  of the header format.
##
##  Some information present in the header but not currently relevant
##  to applications is omitted.
##

type
  mcuboot_img_header_v1* {.bycopy.} = object
    image_size*: uint32      ## * The size of the image, in bytes.
    sem_ver*: mcuboot_img_sem_ver ## * The image version.


## *
##  @brief Model for the MCUBoot image header
##
##  This contains the decoded image header, along with the major
##  version of MCUboot that the header was built for.
##
##  (The MCUboot project guarantees that incompatible changes to the
##  image header will result in major version changes to the bootloader
##  itself, and will be detectable in the persistent representation of
##  the header.)
##

type
  mcuboot_version_union* {.bycopy, union.} = object
    v1*: mcuboot_img_header_v1 ## * Header information for MCUboot version 1.

  mcuboot_img_header* {.bycopy.} = object
    mcuboot_version*: uint32 ## *
                             ##  The version of MCUboot the header is built for.
                             ##
                             ##  The value 1 corresponds to MCUboot versions 1.x.y.
                             ##
    ## *
    ##  The header information. It is only valid to access fields
    ##  in the union member corresponding to the mcuboot_version
    ##  field above.
    ##
    h*: mcuboot_version_union


## *
##  @brief Read the MCUboot image header information from an image bank.
##
##  This attempts to parse the image header,
##  From the start of the @a area_id image.
##
##  @param area_id flash_area ID of image bank which stores the image.
##  @param header On success, the returned header information is available
##                in this structure.
##  @param header_size Size of the header structure passed by the caller.
##                     If this is not large enough to contain all of the
##                     necessary information, an error is returned.
##  @return Zero on success, a negative value on error.
##
proc boot_read_bank_header*(area_id: uint8; header: ptr mcuboot_img_header;
                           header_size: csize_t): cint {.
    importc: "boot_read_bank_header", header: hdrmcu.}


## *
##  @brief Check if the currently running image is confirmed as OK.
##
##  MCUboot can perform "test" upgrades. When these occur, a new
##  firmware image is installed and booted, but the old version will be
##  reverted at the next reset unless the new image explicitly marks
##  itself OK.
##
##  This routine can be used to check if the currently running image
##  has been marked as OK.
##
##  @return True if the image is confirmed as OK, false otherwise.
##  @see boot_write_img_confirmed()
##
proc boot_is_img_confirmed*(): bool {.importc: "boot_is_img_confirmed", header: hdrmcu.}


## *
##  @brief Marks the currently running image as confirmed.
##
##  This routine attempts to mark the currently running firmware image
##  as OK, which will install it permanently, preventing MCUboot from
##  reverting it for an older image at the next reset.
##
##  This routine is safe to call if the current image has already been
##  confirmed. It will return a successful result in this case.
##
##  @return 0 on success, negative errno code on fail.
##
proc boot_write_img_confirmed*(): cint {.importc: "boot_write_img_confirmed", header: hdrmcu.}


## *
##  @brief Determines the action, if any, that mcuboot will take on the next
##  reboot.
##  @return a BOOT_SWAP_TYPE_[...] constant on success, negative errno code on
##  fail.
##
proc mcuboot_swap_type*(): cint {.importc: "mcuboot_swap_type", header: hdrmcu.}

## * Boot upgrade request modes
const
  BOOT_UPGRADE_TEST* = 0
  BOOT_UPGRADE_PERMANENT* = 1

## *
##  @brief Marks the image in slot 1 as pending. On the next reboot, the system
##  will perform a boot of the slot 1 image.
##
##  @param permanent Whether the image should be used permanently or
##  only tested once:
##    BOOT_UPGRADE_TEST=run image once, then confirm or revert.
##    BOOT_UPGRADE_PERMANENT=run image forever.
##  @return 0 on success, negative errno code on fail.
##
proc boot_request_upgrade*(permanent: cint): cint {.importc: "boot_request_upgrade", header: hdrmcu.}


## *
##  @brief Erase the image Bank.
##
##  @param area_id flash_area ID of image bank to be erased.
##  @return 0 on success, negative errno code on fail.
##
proc boot_erase_img_bank*(area_id: uint8): cint {.importc: "boot_erase_img_bank", header: hdrmcu.}
