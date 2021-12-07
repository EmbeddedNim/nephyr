##
##  Copyright (c) 2019 Piotr Mienkowski
##  Copyright (c) 2018 Linaro Limited
##
##  SPDX-License-Identifier: Apache-2.0
##

## *
##  @brief GPIO Driver APIs
##  @defgroup gpio_interface GPIO Driver APIs
##  @ingroup io_interfaces
##  @{
##
## *
##  @name GPIO pin active level flags
##  @{
##

import ../wrapper_utils
import ../cmtoken
import ../drivers/zgpio

const hdr = "<devicetree/gpio.h>"

const
  GPIO_ACTIVE_LOW* = (1 shl 0) ## * GPIO pin is active (has logical value '1') in low state.

  GPIO_ACTIVE_HIGH* = (0 shl 0) ## * GPIO pin is active (has logical value '1') in high state.

const
  ##  @name GPIO pin drive flags
  ## 


  GPIO_SINGLE_ENDED* = (1 shl 1) ##  Configures GPIO output in single-ended mode (open drain or open source).

  GPIO_PUSH_PULL* = (0 shl 1) ##  Configures GPIO output in push-pull mode

  GPIO_LINE_OPEN_DRAIN* = (1 shl 2) ##  Indicates single ended open drain mode (wired AND).

  GPIO_LINE_OPEN_SOURCE* = (0 shl 2) ##  Indicates single ended open source mode (wired OR).


  GPIO_OPEN_DRAIN* = (GPIO_SINGLE_ENDED or GPIO_LINE_OPEN_DRAIN) ##\
  ## * Configures GPIO output in open drain mode (wired AND).
  ##
  ##  @note 'Open Drain' mode also known as 'Open Collector' is an output
  ##  configuration which behaves like a switch that is either connected to ground
  ##  or disconnected.
  ##

  GPIO_OPEN_SOURCE* = (GPIO_SINGLE_ENDED or GPIO_LINE_OPEN_SOURCE) ##\
    ## * Configures GPIO output in open source mode (wired OR).
    ##
    ##  @note 'Open Source' is a term used by software engineers to describe output
    ##  mode opposite to 'Open Drain'. It behaves like a switch that is either
    ##  connected to power supply or disconnected. There exist no corresponding
    ##  hardware schematic and the term is generally unknown to hardware engineers.
    ##


const
  ##  @name GPIO pin bias flags

  GPIO_PULL_UP* = (1 shl 4) ## * Enables GPIO pin pull-up.

  GPIO_PULL_DOWN* = (1 shl 5) ## * Enable GPIO pin pull-down.


proc DT_GPIO_LABEL*(name: cminvtoken, group: cminvtoken): cstring {.importc: "DT_GPIO_LABEL",
                                       header: hdr.}
proc DT_GPIO_PIN*(name: cminvtoken, group: cminvtoken): gpio_pin_t {.importc: "DT_GPIO_PIN",
                                       header: hdr.}
proc DT_GPIO_FLAGS*(name: cminvtoken, group: cminvtoken): uint {.importc: "DT_GPIO_FLAGS",
                                       header: hdr.}