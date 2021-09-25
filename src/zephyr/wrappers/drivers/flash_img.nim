##
##  Copyright (c) 2017 Nordic Semiconductor ASA
##  Copyright (c) 2017 Linaro Limited
##
##  SPDX-License-Identifier: Apache-2.0
##

const flshdr = "<dfu/flash_img.h>"

var CONFIG_IMG_BLOCK_BUF_SIZE* {.importc: "CONFIG_IMG_BLOCK_BUF_SIZE", header: flshdr, nodecl.}: cint

type
  flash_img_context* {.importc: "struct $1", header: flshdr,
                        bycopy, incompleteStruct.} = object


## *
##  @brief Structure for verify flash region integrity
##
##  Match vector length is fixed and depends on size from hash algorithm used
##  to verify flash integrity.  The current available algorithm is SHA-256.
##
type
  flash_img_check* {.importc: "struct flash_img_check", header: flshdr,
                        bycopy, incompleteStruct.} = object

## *
##  @brief Initialize context needed for writing the image to the flash.
##
##  @param ctx     context to be initialized
##  @param area_id flash area id of partition where the image should be written
##
##  @return  0 on success, negative errno code on fail
##
proc flash_img_init_id*(ctx: ptr flash_img_context; area_id: uint8): cint {.
    importc: "flash_img_init_id", header: flshdr.}


## *
##  @brief Initialize context needed for writing the image to the flash.
##
##  @param ctx context to be initialized
##
##  @return  0 on success, negative errno code on fail
##
proc flash_img_init*(ctx: ptr flash_img_context): cint {.importc: "flash_img_init", header: flshdr.}


## *
##  @brief Read number of bytes of the image written to the flash.
##
##  @param ctx context
##
##  @return Number of bytes written to the image flash.
##
proc flash_img_bytes_written*(ctx: ptr flash_img_context): csize_t {.
    importc: "flash_img_bytes_written", header: flshdr.}


## *
##  @brief  Process input buffers to be written to the image slot 1. flash
##  memory in single blocks. Will store remainder between calls.
##
##  A final call to this function with flush set to true
##  will write out the remaining block buffer to flash. Since flash is written to
##  in blocks, the contents of flash from the last byte written up to the next
##  multiple of CONFIG_IMG_BLOCK_BUF_SIZE is padded with 0xff.
##
##  @param ctx context
##  @param data data to write
##  @param len Number of bytes to write
##  @param flush when true this forces any buffered
##  data to be written to flash
##
##  @return  0 on success, negative errno code on fail
##
proc flash_img_buffered_write*(ctx: ptr flash_img_context; data: ptr uint8;
                              len: csize_t; flush: bool): cint {.
    importc: "flash_img_buffered_write", header: flshdr.}


## *
##  @brief  Verify flash memory length bytes integrity from a flash area. The
##  start point is indicated by an offset value.
##
##  @param[in] ctx context.
##  @param[in] fic flash img check data.
##  @param[in] area_id flash area id of partition where the image should be
##  verified.
##
##  @return  0 on success, negative errno code on fail
##
proc flash_img_checks*(ctx: ptr flash_img_context; fic: ptr flash_img_check;
                      area_id: uint8): cint {.importc: "flash_img_check", header: flshdr.}

