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


## *
##  @defgroup devicetree-gpio Devicetree GPIO API
##  @ingroup devicetree
##  @{
##
## *
##  @brief Get the node identifier for the controller phandle from a
##         gpio phandle-array property at an index
##
##  Example devicetree fragment:
##
##      gpio1: gpio@... { };
##
##      gpio2: gpio@... { };
##
##      n: node {
##              gpios = <&gpio1 10 GPIO_ACTIVE_LOW>,
##                      <&gpio2 30 GPIO_ACTIVE_HIGH>;
##      };
##
##  Example usage:
##
##      DT_GPIO_CTLR_BY_IDX(DT_NODELABEL(n), gpios, 1) // DT_NODELABEL(gpio2)
##
##  @param node_id node identifier
##  @param gpio_pha lowercase-and-underscores GPIO property with
##         type "phandle-array"
##  @param idx logical index into "gpio_pha"
##  @return the node identifier for the gpio controller referenced at
##          index "idx"
##  @see DT_PHANDLE_BY_IDX()
##
proc DT_GPIO_CTLR_BY_IDX*(node_id: cminvtoken; gpio_pha: cminvtoken; idx: int): cminvtoken {.
    importc: "DT_GPIO_CTLR_BY_IDX", header: hdr.}


## *
##  @brief Equivalent to DT_GPIO_CTLR_BY_IDX(node_id, gpio_pha, 0)
##  @param node_id node identifier
##  @param gpio_pha lowercase-and-underscores GPIO property with
##         type "phandle-array"
##  @return a node identifier for the gpio controller at index 0
##          in "gpio_pha"
##  @see DT_GPIO_CTLR_BY_IDX()
##
proc DT_GPIO_CTLR*(node_id: cminvtoken; gpio_pha: cminvtoken): cminvtoken {.importc: "DT_GPIO_CTLR",
    header: hdr.}


## *
##  @brief Get a label property from a gpio phandle-array property
##         at an index
##
##  It's an error if the GPIO controller node referenced by the phandle
##  in node_id's "gpio_pha" property at index "idx" has no label
##  property.
##
##  Example devicetree fragment:
##
##      gpio1: gpio@... {
##              label = "GPIO_1";
##      };
##
##      gpio2: gpio@... {
##              label = "GPIO_2";
##      };
##
##      n: node {
##              gpios = <&gpio1 10 GPIO_ACTIVE_LOW>,
##                      <&gpio2 30 GPIO_ACTIVE_HIGH>;
##      };
##
##  Example usage:
##
##      DT_GPIO_LABEL_BY_IDX(DT_NODELABEL(n), gpios, 1) // "GPIO_2"
##
##  @param node_id node identifier
##  @param gpio_pha lowercase-and-underscores GPIO property with
##         type "phandle-array"
##  @param idx logical index into "gpio_pha"
##  @return the label property of the node referenced at index "idx"
##  @see DT_PHANDLE_BY_IDX()
##
proc DT_GPIO_LABEL_BY_IDX*(node_id: cminvtoken; gpio_pha: cminvtoken; idx: int): cstring {.
    importc: "DT_GPIO_LABEL_BY_IDX", header: hdr.}


## *
##  @brief Equivalent to DT_GPIO_LABEL_BY_IDX(node_id, gpio_pha, 0)
##  @param node_id node identifier
##  @param gpio_pha lowercase-and-underscores GPIO property with
##         type "phandle-array"
##  @return the label property of the node referenced at index 0
##  @see DT_GPIO_LABEL_BY_IDX()
##
proc DT_GPIO_LABEL*(node_id: cminvtoken; gpio_pha: cminvtoken): cstring {.importc: "DT_GPIO_LABEL",
    header: hdr.}


## *
##  @brief Get a GPIO specifier's pin cell at an index
##
##  This macro only works for GPIO specifiers with cells named "pin".
##  Refer to the node's binding to check if necessary.
##
##  Example devicetree fragment:
##
##      gpio1: gpio@... {
##              compatible = "vnd,gpio";
##              #gpio-cells = <2>;
##      };
##
##      gpio2: gpio@... {
##              compatible = "vnd,gpio";
##              #gpio-cells = <2>;
##      };
##
##      n: node {
##              gpios = <&gpio1 10 GPIO_ACTIVE_LOW>,
##                      <&gpio2 30 GPIO_ACTIVE_HIGH>;
##      };
##
##  Bindings fragment for the vnd,gpio compatible:
##
##      gpio-cells:
##        - pin
##        - flags
##
##  Example usage:
##
##      DT_GPIO_PIN_BY_IDX(DT_NODELABEL(n), gpios, 0) // 10
##      DT_GPIO_PIN_BY_IDX(DT_NODELABEL(n), gpios, 1) // 30
##
##  @param node_id node identifier
##  @param gpio_pha lowercase-and-underscores GPIO property with
##         type "phandle-array"
##  @param idx logical index into "gpio_pha"
##  @return the pin cell value at index "idx"
##  @see DT_PHA_BY_IDX()
##
proc DT_GPIO_PIN_BY_IDX*(node_id: cminvtoken; gpio_pha: cminvtoken; idx: int): gpio_pin_t {.
    importc: "DT_GPIO_PIN_BY_IDX", header: hdr.}


## *
##  @brief Equivalent to DT_GPIO_PIN_BY_IDX(node_id, gpio_pha, 0)
##  @param node_id node identifier
##  @param gpio_pha lowercase-and-underscores GPIO property with
##         type "phandle-array"
##  @return the pin cell value at index 0
##  @see DT_GPIO_PIN_BY_IDX()
##
proc DT_GPIO_PIN*(node_id: cminvtoken; gpio_pha: cminvtoken): gpio_pin_t {.importc: "DT_GPIO_PIN",
    header: hdr.}


## *
##  @brief Get a GPIO specifier's flags cell at an index
##
##  This macro expects GPIO specifiers with cells named "flags".
##  If there is no "flags" cell in the GPIO specifier, zero is returned.
##  Refer to the node's binding to check specifier cell names if necessary.
##
##  Example devicetree fragment:
##
##      gpio1: gpio@... {
##              compatible = "vnd,gpio";
##              #gpio-cells = <2>;
##      };
##
##      gpio2: gpio@... {
##              compatible = "vnd,gpio";
##              #gpio-cells = <2>;
##      };
##
##      n: node {
##              gpios = <&gpio1 10 GPIO_ACTIVE_LOW>,
##                      <&gpio2 30 GPIO_ACTIVE_HIGH>;
##      };
##
##  Bindings fragment for the vnd,gpio compatible:
##
##      gpio-cells:
##        - pin
##        - flags
##
##  Example usage:
##
##      DT_GPIO_FLAGS_BY_IDX(DT_NODELABEL(n), gpios, 0) // GPIO_ACTIVE_LOW
##      DT_GPIO_FLAGS_BY_IDX(DT_NODELABEL(n), gpios, 1) // GPIO_ACTIVE_HIGH
##
##  @param node_id node identifier
##  @param gpio_pha lowercase-and-underscores GPIO property with
##         type "phandle-array"
##  @param idx logical index into "gpio_pha"
##  @return the flags cell value at index "idx", or zero if there is none
##  @see DT_PHA_BY_IDX()
##
proc DT_GPIO_FLAGS_BY_IDX*(node_id: cminvtoken; gpio_pha: cminvtoken; idx: int): gpio_flags_t {.
    importc: "DT_GPIO_FLAGS_BY_IDX", header: hdr.}


## *
##  @brief Equivalent to DT_GPIO_FLAGS_BY_IDX(node_id, gpio_pha, 0)
##  @param node_id node identifier
##  @param gpio_pha lowercase-and-underscores GPIO property with
##         type "phandle-array"
##  @return the flags cell value at index 0, or zero if there is none
##  @see DT_GPIO_FLAGS_BY_IDX()
##
proc DT_GPIO_FLAGS*(node_id: cminvtoken; gpio_pha: cminvtoken): gpio_flags_t {.importc: "DT_GPIO_FLAGS",
    header: hdr.}


## *
##  @brief Get a label property from a DT_DRV_COMPAT instance's GPIO
##         property at an index
##  @param inst DT_DRV_COMPAT instance number
##  @param gpio_pha lowercase-and-underscores GPIO property with
##         type "phandle-array"
##  @param idx logical index into "gpio_pha"
##  @return the label property of the node referenced at index "idx"
##
proc DT_INST_GPIO_LABEL_BY_IDX*(inst: cminvtoken; gpio_pha: cminvtoken; idx: int): gpio_flags_t {.
    importc: "DT_INST_GPIO_LABEL_BY_IDX", header: hdr.}


## *
##  @brief Equivalent to DT_INST_GPIO_LABEL_BY_IDX(inst, gpio_pha, 0)
##  @param inst DT_DRV_COMPAT instance number
##  @param gpio_pha lowercase-and-underscores GPIO property with
##         type "phandle-array"
##  @return the label property of the node referenced at index 0
##
proc DT_INST_GPIO_LABEL*(inst: cminvtoken; gpio_pha: cminvtoken): cstring {.
    importc: "DT_INST_GPIO_LABEL", header: hdr.}

## *
##  @brief Get a DT_DRV_COMPAT instance's GPIO specifier's pin cell value
##         at an index
##  @param inst DT_DRV_COMPAT instance number
##  @param gpio_pha lowercase-and-underscores GPIO property with
##         type "phandle-array"
##  @param idx logical index into "gpio_pha"
##  @return the pin cell value at index "idx"
##  @see DT_GPIO_PIN_BY_IDX()
##
proc DT_INST_GPIO_PIN_BY_IDX*(inst: cminvtoken; gpio_pha: cminvtoken; idx: int): gpio_flags_t {.
    importc: "DT_INST_GPIO_PIN_BY_IDX", header: hdr.}

## *
##  @brief Equivalent to DT_INST_GPIO_PIN_BY_IDX(inst, gpio_pha, 0)
##  @param inst DT_DRV_COMPAT instance number
##  @param gpio_pha lowercase-and-underscores GPIO property with
##         type "phandle-array"
##  @return the pin cell value at index 0
##  @see DT_INST_GPIO_PIN_BY_IDX()
##
proc DT_INST_GPIO_PIN*(inst: cminvtoken; gpio_pha: cminvtoken): int {.
    importc: "DT_INST_GPIO_PIN", header: hdr.}

## *
##  @brief Get a DT_DRV_COMPAT instance's GPIO specifier's flags cell
##         at an index
##  @param inst DT_DRV_COMPAT instance number
##  @param gpio_pha lowercase-and-underscores GPIO property with
##         type "phandle-array"
##  @param idx logical index into "gpio_pha"
##  @return the flags cell value at index "idx", or zero if there is none
##  @see DT_GPIO_FLAGS_BY_IDX()
##
proc DT_INST_GPIO_FLAGS_BY_IDX*(inst: cminvtoken; gpio_pha: cminvtoken; idx: int): gpio_flags_t {.
    importc: "DT_INST_GPIO_FLAGS_BY_IDX", header: hdr.}

## *
##  @brief Equivalent to DT_INST_GPIO_FLAGS_BY_IDX(inst, gpio_pha, 0)
##  @param inst DT_DRV_COMPAT instance number
##  @param gpio_pha lowercase-and-underscores GPIO property with
##         type "phandle-array"
##  @return the flags cell value at index 0, or zero if there is none
##  @see DT_INST_GPIO_FLAGS_BY_IDX()
##
proc DT_INST_GPIO_FLAGS*(inst: cminvtoken; gpio_pha: cminvtoken): gpio_flags_t {.
    importc: "DT_INST_GPIO_FLAGS", header: hdr.}


## *
##  @}
##
