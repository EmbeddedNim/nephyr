##
##  Copyright (c) 2019-2020 Nordic Semiconductor ASA
##  Copyright (c) 2019 Piotr Mienkowski
##  Copyright (c) 2017 ARM Ltd
##  Copyright (c) 2015-2016 Intel Corporation.
##
##  SPDX-License-Identifier: Apache-2.0
##
## *
##  @file
##  @brief Public APIs for GPIO drivers
##

## *
##  @brief GPIO Driver APIs
##  @defgroup gpio_interface GPIO Driver APIs
##  @ingroup io_interfaces
##  @{
##
## *
##  @name GPIO input/output configuration flags
##  @{
##

import ../wrapper_utils
import ../zdevice

const hdr = "<drivers/gpio.h>"

const

  GPIO_INPUT* = (1'u shl 8) ## * Enables pin as input.

  GPIO_OUTPUT* = (1'u shl 9) ## * Enables pin as output, no change to the output state.

  GPIO_DISCONNECTED* = 0 ## * Disables pin for both input and output.

  GPIO_OUTPUT_INIT_LOW* = (1'u shl 10) ##  Initializes output to a low state.

  GPIO_OUTPUT_INIT_HIGH* = (1'u shl 11) ##  Initializes output to a high state.

  GPIO_OUTPUT_INIT_LOGICAL* = (1'u shl 12) ##  Initializes output based on logic level

  GPIO_OUTPUT_LOW* = (GPIO_OUTPUT or GPIO_OUTPUT_INIT_LOW) ## * Configures GPIO pin as output and initializes it to a low state.

  GPIO_OUTPUT_HIGH* = (GPIO_OUTPUT or GPIO_OUTPUT_INIT_HIGH) ## * Configures GPIO pin as output and initializes it to a high state.

  GPIO_OUTPUT_INACTIVE* = ( GPIO_OUTPUT or
        GPIO_OUTPUT_INIT_LOW or GPIO_OUTPUT_INIT_LOGICAL) ## \
    ## * Configures GPIO pin as output and initializes it to a logic 0.

  GPIO_OUTPUT_ACTIVE* = (GPIO_OUTPUT or
    GPIO_OUTPUT_INIT_HIGH or GPIO_OUTPUT_INIT_LOGICAL) ## \
      ## * Configures GPIO pin as output and initializes it to a logic 1.




## * @}
## *
##  @name GPIO interrupt configuration flags
##  The `GPIO_INT_*` flags are used to specify how input GPIO pins will trigger
##  interrupts. The interrupts can be sensitive to pin physical or logical level.
##  Interrupts sensitive to pin logical level take into account GPIO_ACTIVE_LOW
##  flag. If a pin was configured as Active Low, physical level low will be
##  considered as logical level 1 (an active state), physical level high will
##  be considered as logical level 0 (an inactive state).
##  @{
##

const
  GPIO_INT_DISABLE* = (1'u shl 13) ## * Disables GPIO pin interrupt.

  GPIO_INT_ENABLE* = (1'u shl 14) ##  Enables GPIO pin interrupt.

  GPIO_INT_LEVELS_LOGICAL* = (1'u shl 15) ## \
    ##  GPIO interrupt is sensitive to logical levels.
    ##
    ##  This is a component flag that should be combined with other
    ##  `GPIO_INT_*` flags to produce a meaningful configuration.
    ##

  GPIO_INT_EDGE* = (1'u shl 16) ## \
    ##  GPIO interrupt is edge sensitive.
    ##
    ##  Note: by default interrupts are level sensitive.
    ##
    ##  This is a component flag that should be combined with other
    ##  `GPIO_INT_*` flags to produce a meaningful configuration.
    ##

  GPIO_INT_LOW_0* = (1'u shl 17) ## \
    ##  Trigger detection when input state is (or transitions to) physical low or
    ##  logical 0 level.
    ##
    ##  This is a component flag that should be combined with other
    ##  `GPIO_INT_*` flags to produce a meaningful configuration.
    ##

  GPIO_INT_HIGH_1* = (1'u shl 18)

  GPIO_INT_MASK* = (GPIO_INT_DISABLE or GPIO_INT_ENABLE or GPIO_INT_LEVELS_LOGICAL or
      GPIO_INT_EDGE or GPIO_INT_LOW_0 or GPIO_INT_HIGH_1) ## \
    ##  Trigger detection on input state is (or transitions to) physical high or
    ##  logical 1 level.
    ##
    ##  This is a component flag that should be combined with other
    ##  `GPIO_INT_*` flags to produce a meaningful configuration.
    ##

  GPIO_INT_EDGE_RISING* = (GPIO_INT_ENABLE or GPIO_INT_EDGE or GPIO_INT_HIGH_1) ##\
    ## * Configures GPIO interrupt to be triggered on pin rising edge and enables it.

  GPIO_INT_EDGE_FALLING* = (GPIO_INT_ENABLE or GPIO_INT_EDGE or GPIO_INT_LOW_0) ##\
    ## * Configures GPIO interrupt to be triggered on pin falling edge and enables
    ##  it.
    ##

  GPIO_INT_EDGE_BOTH* = (
    GPIO_INT_ENABLE or GPIO_INT_EDGE or GPIO_INT_LOW_0 or GPIO_INT_HIGH_1) ##\
    ## * Configures GPIO interrupt to be triggered on pin rising or falling edge and
    ##  enables it.
    ##

  GPIO_INT_LEVEL_LOW* = (GPIO_INT_ENABLE or GPIO_INT_LOW_0) ##\
    ## * Configures GPIO interrupt to be triggered on pin physical level low and
    ##  enables it.
    ##

  GPIO_INT_LEVEL_HIGH* = (GPIO_INT_ENABLE or GPIO_INT_HIGH_1) ##\
    ## * Configures GPIO interrupt to be triggered on pin physical level high and
    ##  enables it.
    ##


  GPIO_INT_EDGE_TO_INACTIVE* = (GPIO_INT_ENABLE or GPIO_INT_LEVELS_LOGICAL or ##\
      GPIO_INT_EDGE or GPIO_INT_LOW_0)
    ## * Configures GPIO interrupt to be triggered on pin state change to logical
    ##  level 0 and enables it.
    ##


  GPIO_INT_EDGE_TO_ACTIVE* = (GPIO_INT_ENABLE or GPIO_INT_LEVELS_LOGICAL or
      GPIO_INT_EDGE or GPIO_INT_HIGH_1)
    ## * Configures GPIO interrupt to be triggered on pin state change to logical
    ##  level 1 and enables it.
    ##

  GPIO_INT_LEVEL_INACTIVE* = (
    GPIO_INT_ENABLE or GPIO_INT_LEVELS_LOGICAL or GPIO_INT_LOW_0) ##\
      ## * Configures GPIO interrupt to be triggered on pin logical level 0 and enables
      ##  it.
      ##

  GPIO_INT_LEVEL_ACTIVE* = (
    GPIO_INT_ENABLE or GPIO_INT_LEVELS_LOGICAL or GPIO_INT_HIGH_1) ##\
      ## * Configures GPIO interrupt to be triggered on pin logical level 1 and enables
      ##  it.
      ##

  GPIO_INT_DEBOUNCE* = (1'u shl 19)
    ## * Enable GPIO pin debounce.
    ##
    ##  @note Drivers that do not support a debounce feature should ignore
    ##  this flag rather than rejecting the configuration with -ENOTSUP.
    ##


const
  ## *
  ##  @name GPIO drive strength flags
  ##  The `GPIO_DS_*` flags are used with `gpio_pin_configure` to specify the drive
  ##  strength configuration of a GPIO pin.
  ##
  ##  The drive strength of individual pins can be configured
  ##  independently for when the pin output is low and high.
  ##
  ##  The `GPIO_DS_*_LOW` enumerations define the drive strength of a pin
  ##  when output is low.
  ##
  ##  The `GPIO_DS_*_HIGH` enumerations define the drive strength of a pin
  ##  when output is high.
  ##
  ##  The interface supports two different drive strengths:
  ##  `DFLT` - The lowest drive strength supported by the HW
  ##  `ALT` - The highest drive strength supported by the HW
  ##
  ##  On hardware that supports only one standard drive strength, both
  ##  `DFLT` and `ALT` have the same behavior.
  
  GPIO_DS_LOW_POS* = 20
  GPIO_DS_LOW_MASK* = (0x3 shl GPIO_DS_LOW_POS)


  GPIO_DS_DFLT_LOW* = (0x0 shl GPIO_DS_LOW_POS) ##\
    ## * Default drive strength standard when GPIO pin output is low.
    ##

  GPIO_DS_ALT_LOW* = (0x1 shl GPIO_DS_LOW_POS) ##\
    ## * Alternative drive strength when GPIO pin output is low.
    ##  For hardware that does not support configurable drive strength
    ##  use the default drive strength.
    ##

  GPIO_DS_HIGH_POS* = 22
  GPIO_DS_HIGH_MASK* = (0x3 shl GPIO_DS_HIGH_POS)

  GPIO_DS_DFLT_HIGH* = (0x0 shl GPIO_DS_HIGH_POS) ##\
    ## * Default drive strength when GPIO pin output is high.
    ##


  GPIO_DS_ALT_HIGH* = (0x1 shl GPIO_DS_HIGH_POS) ##\
    ## * Alternative drive strength when GPIO pin output is high.
    ##  For hardware that does not support configurable drive strengths
    ##  use the default drive strength.
    ##

  GPIO_DIR_MASK* = (GPIO_INPUT or GPIO_OUTPUT)


## *
##  @brief Identifies a set of pins associated with a port.
##
##  The pin with index n is present in the set if and only if the bit
##  identified by (1U << n) is set.
##

type
  gpio_port_pins_t* = distinct uint32




## *
##  @brief Provides values for a set of pins associated with a port.
##
##  The value for a pin with index n is high (physical mode) or active
##  (logical mode) if and only if the bit identified by (1U << n) is set.
##  Otherwise the value for the pin is low (physical mode) or inactive
##  (logical mode).
##
##  Values of this type are often paired with a `gpio_port_pins_t` value
##  that specifies which encoded pin values are valid for the operation.
##

type
  gpio_port_value_t* = distinct uint32




## *
##  @brief Provides a type to hold a GPIO pin index.
##
##  This reduced-size type is sufficient to record a pin number,
##  e.g. from a devicetree GPIOS property.
##

type
  gpio_pin_t* = distinct uint8




## *
##  @brief Provides a type to hold GPIO devicetree flags.
##
##  All GPIO flags that can be expressed in devicetree fit in the low 8
##  bits of the full flags field, so use a reduced-size type to record
##  that part of a GPIOS property.
##

type
  gpio_dt_flags_t* = distinct uint8




## *
##  @brief Provides a type to hold GPIO configuration flags.
##
##  This type is sufficient to hold all flags used to control GPIO
##  configuration, whether pin or interrupt.
##

type
  gpio_flags_t* = distinct uint32



## *
##  @brief Provides a type to hold GPIO information specified in devicetree
##
##  This type is sufficient to hold a GPIO device pointer, pin number,
##  and the subset of the flags used to control GPIO configuration
##  which may be given in devicetree.
##

type
  gpio_dt_spec* {.importc: "gpio_dt_spec", header: hdr, bycopy.} = object
    port* {.importc: "port".}: ptr device
    pin* {.importc: "pin".}: gpio_pin_t
    dt_flags* {.importc: "dt_flags".}: gpio_dt_flags_t



## *
##  @brief Static initializer for a @p gpio_dt_spec
##
##  This returns a static initializer for a @p gpio_dt_spec structure given a
##  devicetree node identifier, a property specifying a GPIO and an index.
##
##  Example devicetree fragment:
##
## 	n: node {
## 		foo-gpios = <&gpio0 1 GPIO_ACTIVE_LOW>,
## 			    <&gpio1 2 GPIO_ACTIVE_LOW>;
## 	}
##
##  Example usage:
##
## 	const struct gpio_dt_spec spec = GPIO_DT_SPEC_GET_BY_IDX(DT_NODELABEL(n),
## 								 foo_gpios, 1);
## 	// Initializes 'spec' to:
## 	// {
## 	//         .port = DEVICE_DT_GET(DT_NODELABEL(gpio1)),
## 	//         .pin = 2,
## 	//         .dt_flags = GPIO_ACTIVE_LOW
## 	// }
##
##  The 'gpio' field must still be checked for readiness, e.g. using
##  device_is_ready(). It is an error to use this macro unless the node
##  exists, has the given property, and that property specifies a GPIO
##  controller, pin number, and flags as shown above.
##
##  @param node_id devicetree node identifier
##  @param prop lowercase-and-underscores property name
##  @param idx logical index into "prop"
##  @return static initializer for a struct gpio_dt_spec for the property
##

proc GPIO_DT_SPEC_GET_BY_IDX*(node_id: cminvtoken; prop: cminvtoken; idx: cminvtoken) {.
    importc: "GPIO_DT_SPEC_GET_BY_IDX", header: hdr.}



## *
##  @brief Like GPIO_DT_SPEC_GET_BY_IDX(), with a fallback to a default value
##
##  If the devicetree node identifier 'node_id' refers to a node with a
##  property 'prop', this expands to
##  <tt>GPIO_DT_SPEC_GET_BY_IDX(node_id, prop, idx)</tt>. The @p
##  default_value parameter is not expanded in this case.
##
##  Otherwise, this expands to @p default_value.
##
##  @param node_id devicetree node identifier
##  @param prop lowercase-and-underscores property name
##  @param idx logical index into "prop"
##  @param default_value fallback value to expand to
##  @return static initializer for a struct gpio_dt_spec for the property,
##          or default_value if the node or property do not exist
##

proc GPIO_DT_SPEC_GET_BY_IDX_OR*(node_id: cminvtoken; prop: cminvtoken; idx: cminvtoken;
                                default_value: cminvtoken) {.
    importc: "GPIO_DT_SPEC_GET_BY_IDX_OR", header: hdr.}



## *
##  @brief Equivalent to GPIO_DT_SPEC_GET_BY_IDX(node_id, prop, 0).
##
##  @param node_id devicetree node identifier
##  @param prop lowercase-and-underscores property name
##  @return static initializer for a struct gpio_dt_spec for the property
##  @see GPIO_DT_SPEC_GET_BY_IDX()
##

proc GPIO_DT_SPEC_GET*(node_id: cminvtoken; prop: cminvtoken) {.
    importc: "GPIO_DT_SPEC_GET", header: hdr.}



## *
##  @brief Equivalent to
##         GPIO_DT_SPEC_GET_BY_IDX_OR(node_id, prop, 0, default_value).
##
##  @param node_id devicetree node identifier
##  @param prop lowercase-and-underscores property name
##  @param default_value fallback value to expand to
##  @return static initializer for a struct gpio_dt_spec for the property
##  @see GPIO_DT_SPEC_GET_BY_IDX_OR()
##

proc GPIO_DT_SPEC_GET_OR*(node_id: cminvtoken; prop: cminvtoken; default_value: cminvtoken) {.
    importc: "GPIO_DT_SPEC_GET_OR", header: hdr.}



## *
##  @brief Static initializer for a @p gpio_dt_spec from a DT_DRV_COMPAT
##  instance's GPIO property at an index.
##
##  @param inst DT_DRV_COMPAT instance number
##  @param prop lowercase-and-underscores property name
##  @param idx logical index into "prop"
##  @return static initializer for a struct gpio_dt_spec for the property
##  @see GPIO_DT_SPEC_GET_BY_IDX()
##

proc GPIO_DT_SPEC_INST_GET_BY_IDX*(inst: cminvtoken; prop: cminvtoken; idx: cminvtoken) {.
    importc: "GPIO_DT_SPEC_INST_GET_BY_IDX", header: hdr.}



## *
##  @brief Static initializer for a @p gpio_dt_spec from a DT_DRV_COMPAT
##         instance's GPIO property at an index, with fallback
##
##  @param inst DT_DRV_COMPAT instance number
##  @param prop lowercase-and-underscores property name
##  @param idx logical index into "prop"
##  @param default_value fallback value to expand to
##  @return static initializer for a struct gpio_dt_spec for the property
##  @see GPIO_DT_SPEC_GET_BY_IDX()
##

proc GPIO_DT_SPEC_INST_GET_BY_IDX_OR*(inst: cminvtoken; prop: cminvtoken; idx: cminvtoken;
                                     default_value: cminvtoken) {.
    importc: "GPIO_DT_SPEC_INST_GET_BY_IDX_OR", header: hdr.}



## *
##  @brief Equivalent to GPIO_DT_SPEC_INST_GET_BY_IDX(inst, prop, 0).
##
##  @param inst DT_DRV_COMPAT instance number
##  @param prop lowercase-and-underscores property name
##  @return static initializer for a struct gpio_dt_spec for the property
##  @see GPIO_DT_SPEC_INST_GET_BY_IDX()
##

proc GPIO_DT_SPEC_INST_GET*(inst: cminvtoken; prop: cminvtoken) {.
    importc: "GPIO_DT_SPEC_INST_GET", header: hdr.}



## *
##  @brief Equivalent to
##         GPIO_DT_SPEC_INST_GET_BY_IDX_OR(inst, prop, 0, default_value).
##
##  @param inst DT_DRV_COMPAT instance number
##  @param prop lowercase-and-underscores property name
##  @param default_value fallback value to expand to
##  @return static initializer for a struct gpio_dt_spec for the property
##  @see GPIO_DT_SPEC_INST_GET_BY_IDX()
##

proc GPIO_DT_SPEC_INST_GET_OR*(inst: cminvtoken; prop: cminvtoken; default_value: cminvtoken) {.
    importc: "GPIO_DT_SPEC_INST_GET_OR", header: hdr.}



## *
##  @brief Maximum number of pins that are supported by `gpio_port_pins_t`.
##

var GPIO_MAX_PINS_PER_PORT* {.importc: "GPIO_MAX_PINS_PER_PORT", header: hdr.}: int



## *
##  This structure is common to all GPIO drivers and is expected to be
##  the first element in the object pointed to by the config field
##  in the device structure.
##



type
  gpio_driver_config* {.importc: "gpio_driver_config", header: hdr, bycopy.} = object ##\
      ## *
      ##  This structure is common to all GPIO drivers and is expected to be
      ##  the first element in the object pointed to by the config field
      ##  in the device structure.
      ##
    port_pin_mask* {.importc: "port_pin_mask".}: gpio_port_pins_t ##  Mask identifying pins supported by the controller.
                                                              ##
                                                              ##  Initialization of this mask is the responsibility of device
                                                              ##  instance generation in the driver.
                                                              ##



type
  gpio_driver_data* {.importc: "gpio_driver_data", header: hdr, bycopy.} = object ##\
      ## *
      ##  This structure is common to all GPIO drivers and is expected to be the first
      ##  element in the driver's struct driver_data declaration.
      ##
    invert* {.importc: "invert".}: gpio_port_pins_t ##  Mask identifying pins that are configured as active low.
                                                ##
                                                ##  Management of this mask is the responsibility of the
                                                ##  wrapper functions in this header.
                                                ##


type
  gpio_callback_handler_t* = proc (port: ptr device; cb: ptr gpio_callback;
                                pins: gpio_port_pins_t)

  gpio_callback* {.importc: "gpio_callback", header: hdr, bycopy.} = object ##\
      ## *
      ##  @brief GPIO callback structure
      ##
      ##  Used to register a callback in the driver instance callback list.
      ##  As many callbacks as needed can be added as long as each of them
      ##  are unique pointers of struct gpio_callback.
      ##  Beware such structure should not be allocated on stack.
      ##
      ##  Note: To help setting it, see gpio_init_callback() below
      ##
    node* {.importc: "node".}: sys_snode_t ## * This is meant to be used in the driver and the user should not
                                       ##  mess with it (see drivers/gpio/gpio_utils.h)
                                       ##
    ## * Actual callback function being called when relevant.
    handler* {.importc: "handler".}: gpio_callback_handler_t ## * A mask of pins the callback is interested in, if 0 the callback
                                                         ##  will never be called. Such pin_mask can be modified whenever
                                                         ##  necessary by the owner, and thus will affect the handler being
                                                         ##  called or not. The selected pins must be configured to trigger
                                                         ##  an interrupt.
                                                         ##
    pin_mask* {.importc: "pin_mask".}: gpio_port_pins_t


##
## *
##  @brief Configure pin interrupt.
##
##  @note This function can also be used to configure interrupts on pins
##        not controlled directly by the GPIO module. That is, pins which are
##        routed to other modules such as I2C, SPI, UART.
##
##  @param port Pointer to device structure for the driver instance.
##  @param pin Pin number.
##  @param flags Interrupt configuration flags as defined by GPIO_INT_*.
##
##  @retval 0 If successful.
##  @retval -ENOTSUP If any of the configuration options is not supported
##                   (unless otherwise directed by flag documentation).
##  @retval -EINVAL  Invalid argument.
##  @retval -EBUSY   Interrupt line required to configure pin interrupt is
##                   already in use.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_pin_interrupt_configure*(port: ptr device; pin: gpio_pin_t;
                                  flags: gpio_flags_t): cint {.syscall,
    importc: "gpio_pin_interrupt_configure", header: hdr.}

proc z_impl_gpio_pin_interrupt_configure*(port: ptr device; pin: gpio_pin_t;
    flags: gpio_flags_t): cint {.importc: "z_impl_gpio_pin_interrupt_configure", header: hdr.}




## *
##  @brief Configure pin interrupts from a @p gpio_dt_spec.
##
##  This is equivalent to:
##
##      gpio_pin_interrupt_configure(spec->port, spec->pin, flags);
##
##  The <tt>spec->dt_flags</tt> value is not used.
##
##  @param spec GPIO specification from devicetree
##  @param flags interrupt configuration flags
##  @retval a value from gpio_pin_interrupt_configure()
##

proc gpio_pin_interrupt_configure_dt*(spec: ptr gpio_dt_spec; flags: gpio_flags_t): cint {.
    importc: "gpio_pin_interrupt_configure_dt", header: hdr.} =
  return gpio_pin_interrupt_configure(spec.port, spec.pin, flags)




## *
##  @brief Configure a single pin.
##
##  @param port Pointer to device structure for the driver instance.
##  @param pin Pin number to configure.
##  @param flags Flags for pin configuration: 'GPIO input/output configuration
##         flags', 'GPIO drive strength flags', 'GPIO pin drive flags', 'GPIO pin
##         bias flags', GPIO_INT_DEBOUNCE.
##
##  @retval 0 If successful.
##  @retval -ENOTSUP if any of the configuration options is not supported
##                   (unless otherwise directed by flag documentation).
##  @retval -EINVAL Invalid argument.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_pin_configure*(port: ptr device; pin: gpio_pin_t; flags: gpio_flags_t): cint {.
    importc: "gpio_pin_configure", header: hdr.}

proc z_impl_gpio_pin_configure*(port: ptr device; pin: gpio_pin_t; flags: gpio_flags_t): cint {.
    importc: "z_impl_gpio_pin_configure", header: hdr.} 




## *
##  @brief Configure a single pin from a @p gpio_dt_spec and some extra flags.
##
##  This is equivalent to:
##
##      gpio_pin_configure(spec->port, spec->pin, spec->dt_flags | extra_flags);
##
##  @param spec GPIO specification from devicetree
##  @param extra_flags additional flags
##  @retval a value from gpio_pin_configure()
##

proc gpio_pin_configure_dt*(spec: ptr gpio_dt_spec; extra_flags: gpio_flags_t): cint {.
    importc: "gpio_pin_configure_dt".} 

## *
##  @brief Get physical level of all input pins in a port.
##
##  A low physical level on the pin will be interpreted as value 0. A high
##  physical level will be interpreted as value 1. This function ignores
##  GPIO_ACTIVE_LOW flag.
##
##  Value of a pin with index n will be represented by bit n in the returned
##  port value.
##
##  @param port Pointer to the device structure for the driver instance.
##  @param value Pointer to a variable where pin values will be stored.
##
##  @retval 0 If successful.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_port_get_raw*(port: ptr device; value: ptr gpio_port_value_t): cint {.syscall,
    importc: "gpio_port_get_raw", header: hdr.}
proc z_impl_gpio_port_get_raw*(port: ptr device; value: ptr gpio_port_value_t): cint {.
    importc: "z_impl_gpio_port_get_raw", header: hdr.}




## *
##  @brief Get logical level of all input pins in a port.
##
##  Get logical level of an input pin taking into account GPIO_ACTIVE_LOW flag.
##  If pin is configured as Active High, a low physical level will be interpreted
##  as logical value 0. If pin is configured as Active Low, a low physical level
##  will be interpreted as logical value 1.
##
##  Value of a pin with index n will be represented by bit n in the returned
##  port value.
##
##  @param port Pointer to the device structure for the driver instance.
##  @param value Pointer to a variable where pin values will be stored.
##
##  @retval 0 If successful.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_port_get*(port: ptr device; value: ptr gpio_port_value_t): cint {.
    importc: "gpio_port_get", header: hdr.}




## *
##  @brief Set physical level of output pins in a port.
##
##  Writing value 0 to the pin will set it to a low physical level. Writing
##  value 1 will set it to a high physical level. This function ignores
##  GPIO_ACTIVE_LOW flag.
##
##  Pin with index n is represented by bit n in mask and value parameter.
##
##  @param port Pointer to the device structure for the driver instance.
##  @param mask Mask indicating which pins will be modified.
##  @param value Value assigned to the output pins.
##
##  @retval 0 If successful.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_port_set_masked_raw*(port: ptr device; mask: gpio_port_pins_t;
                              value: gpio_port_value_t): cint {.syscall,
    importc: "gpio_port_set_masked_raw", header: hdr.}
proc z_impl_gpio_port_set_masked_raw*(port: ptr device; mask: gpio_port_pins_t;
                                     value: gpio_port_value_t): cint {.
    importc: "z_impl_gpio_port_set_masked_raw", header: hdr.}




## *
##  @brief Set logical level of output pins in a port.
##
##  Set logical level of an output pin taking into account GPIO_ACTIVE_LOW flag.
##  Value 0 sets the pin in logical 0 / inactive state. Value 1 sets the pin in
##  logical 1 / active state. If pin is configured as Active High, the default,
##  setting it in inactive state will force the pin to a low physical level. If
##  pin is configured as Active Low, setting it in inactive state will force the
##  pin to a high physical level.
##
##  Pin with index n is represented by bit n in mask and value parameter.
##
##  @param port Pointer to the device structure for the driver instance.
##  @param mask Mask indicating which pins will be modified.
##  @param value Value assigned to the output pins.
##
##  @retval 0 If successful.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_port_set_masked*(port: ptr device; mask: gpio_port_pins_t;
                          value: gpio_port_value_t): cint {.
    importc: "gpio_port_set_masked", header: hdr.}




## *
##  @brief Set physical level of selected output pins to high.
##
##  @param port Pointer to the device structure for the driver instance.
##  @param pins Value indicating which pins will be modified.
##
##  @retval 0 If successful.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_port_set_bits_raw*(port: ptr device; pins: gpio_port_pins_t): cint {.syscall,
    importc: "gpio_port_set_bits_raw", header: hdr.}
proc z_impl_gpio_port_set_bits_raw*(port: ptr device; pins: gpio_port_pins_t): cint {.
    importc: "z_impl_gpio_port_set_bits_raw", header: hdr.}




## *
##  @brief Set logical level of selected output pins to active.
##
##  @param port Pointer to the device structure for the driver instance.
##  @param pins Value indicating which pins will be modified.
##
##  @retval 0 If successful.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_port_set_bits*(port: ptr device; pins: gpio_port_pins_t): cint {.
    importc: "gpio_port_set_bits", header: hdr.}




## *
##  @brief Set physical level of selected output pins to low.
##
##  @param port Pointer to the device structure for the driver instance.
##  @param pins Value indicating which pins will be modified.
##
##  @retval 0 If successful.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_port_clear_bits_raw*(port: ptr device; pins: gpio_port_pins_t): cint {.
    syscall, importc: "gpio_port_clear_bits_raw", header: hdr.}
proc z_impl_gpio_port_clear_bits_raw*(port: ptr device; pins: gpio_port_pins_t): cint {.
    importc: "z_impl_gpio_port_clear_bits_raw", header: hdr.}




## *
##  @brief Set logical level of selected output pins to inactive.
##
##  @param port Pointer to the device structure for the driver instance.
##  @param pins Value indicating which pins will be modified.
##
##  @retval 0 If successful.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_port_clear_bits*(port: ptr device; pins: gpio_port_pins_t): cint {.
    importc: "gpio_port_clear_bits", header: hdr.}




## *
##  @brief Toggle level of selected output pins.
##
##  @param port Pointer to the device structure for the driver instance.
##  @param pins Value indicating which pins will be modified.
##
##  @retval 0 If successful.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_port_toggle_bits*(port: ptr device; pins: gpio_port_pins_t): cint {.
    importc: "gpio_port_toggle_bits", header: hdr.}
proc z_impl_gpio_port_toggle_bits*(port: ptr device; pins: gpio_port_pins_t): cint {.
    importc: "z_impl_gpio_port_toggle_bits", header: hdr.}




## *
##  @brief Set physical level of selected output pins.
##
##  @param port Pointer to the device structure for the driver instance.
##  @param set_pins Value indicating which pins will be set to high.
##  @param clear_pins Value indicating which pins will be set to low.
##
##  @retval 0 If successful.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_port_set_clr_bits_raw*(port: ptr device; set_pins: gpio_port_pins_t;
                                clear_pins: gpio_port_pins_t): cint {.
    importc: "gpio_port_set_clr_bits_raw", header: hdr.}




## *
##  @brief Set logical level of selected output pins.
##
##  @param port Pointer to the device structure for the driver instance.
##  @param set_pins Value indicating which pins will be set to active.
##  @param clear_pins Value indicating which pins will be set to inactive.
##
##  @retval 0 If successful.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_port_set_clr_bits*(port: ptr device; set_pins: gpio_port_pins_t;
                            clear_pins: gpio_port_pins_t): cint {.
    importc: "gpio_port_set_clr_bits", header: hdr.}




## *
##  @brief Get physical level of an input pin.
##
##  A low physical level on the pin will be interpreted as value 0. A high
##  physical level will be interpreted as value 1. This function ignores
##  GPIO_ACTIVE_LOW flag.
##
##  @param port Pointer to the device structure for the driver instance.
##  @param pin Pin number.
##
##  @retval 1 If pin physical level is high.
##  @retval 0 If pin physical level is low.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_pin_get_raw*(port: ptr device; pin: gpio_pin_t): cint {.
    importc: "gpio_pin_get_raw", header: hdr.}




## *
##  @brief Get logical level of an input pin.
##
##  Get logical level of an input pin taking into account GPIO_ACTIVE_LOW flag.
##  If pin is configured as Active High, a low physical level will be interpreted
##  as logical value 0. If pin is configured as Active Low, a low physical level
##  will be interpreted as logical value 1.
##
##  Note: If pin is configured as Active High, the default, gpio_pin_get()
##        function is equivalent to gpio_pin_get_raw().
##
##  @param port Pointer to the device structure for the driver instance.
##  @param pin Pin number.
##
##  @retval 1 If pin logical value is 1 / active.
##  @retval 0 If pin logical value is 0 / inactive.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_pin_get*(port: ptr device; pin: gpio_pin_t): cint {.
    importc: "gpio_pin_get", header: hdr.}



## *
##  @brief Set physical level of an output pin.
##
##  Writing value 0 to the pin will set it to a low physical level. Writing any
##  value other than 0 will set it to a high physical level. This function
##  ignores GPIO_ACTIVE_LOW flag.
##
##  @param port Pointer to the device structure for the driver instance.
##  @param pin Pin number.
##  @param value Value assigned to the pin.
##
##  @retval 0 If successful.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_pin_set_raw*(port: ptr device; pin: gpio_pin_t; value: cint): cint {.
    importc: "gpio_pin_set_raw", header: hdr.}




## *
##  @brief Set logical level of an output pin.
##
##  Set logical level of an output pin taking into account GPIO_ACTIVE_LOW flag.
##  Value 0 sets the pin in logical 0 / inactive state. Any value other than 0
##  sets the pin in logical 1 / active state. If pin is configured as Active
##  High, the default, setting it in inactive state will force the pin to a low
##  physical level. If pin is configured as Active Low, setting it in inactive
##  state will force the pin to a high physical level.
##
##  Note: If pin is configured as Active High, gpio_pin_set() function is
##        equivalent to gpio_pin_set_raw().
##
##  @param port Pointer to the device structure for the driver instance.
##  @param pin Pin number.
##  @param value Value assigned to the pin.
##
##  @retval 0 If successful.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_pin_set*(port: ptr device; pin: gpio_pin_t; value: cint): cint {.
    importc: "gpio_pin_set", header: hdr.}




## *
##  @brief Toggle pin level.
##
##  @param port Pointer to the device structure for the driver instance.
##  @param pin Pin number.
##
##  @retval 0 If successful.
##  @retval -EIO I/O error when accessing an external GPIO chip.
##  @retval -EWOULDBLOCK if operation would block.
##

proc gpio_pin_toggle*(port: ptr device; pin: gpio_pin_t): cint {.
    importc: "gpio_pin_toggle", header: hdr.}




## *
##  @brief Helper to initialize a struct gpio_callback properly
##  @param callback A valid Application's callback structure pointer.
##  @param handler A valid handler function pointer.
##  @param pin_mask A bit mask of relevant pins for the handler
##

proc gpio_init_callback*(callback: ptr gpio_callback;
                        handler: gpio_callback_handler_t;
                        pin_mask: gpio_port_pins_t) {.
    importc: "gpio_init_callback", header: hdr.}




## *
##  @brief Add an application callback.
##  @param port Pointer to the device structure for the driver instance.
##  @param callback A valid Application's callback structure pointer.
##  @return 0 if successful, negative errno code on failure.
##
##  @note Callbacks may be added to the device from within a callback
##  handler invocation, but whether they are invoked for the current
##  GPIO event is not specified.
##
##  Note: enables to add as many callback as needed on the same port.
##

proc gpio_add_callback*(port: ptr device; callback: ptr gpio_callback): cint {.
    importc: "gpio_add_callback", header: hdr.}




## *
##  @brief Remove an application callback.
##  @param port Pointer to the device structure for the driver instance.
##  @param callback A valid application's callback structure pointer.
##  @return 0 if successful, negative errno code on failure.
##
##  @warning It is explicitly permitted, within a callback handler, to
##  remove the registration for the callback that is running, i.e. @p
##  callback.  Attempts to remove other registrations on the same
##  device may result in undefined behavior, including failure to
##  invoke callbacks that remain registered and unintended invocation
##  of removed callbacks.
##
##  Note: enables to remove as many callbacks as added through
##        gpio_add_callback().
##

proc gpio_remove_callback*(port: ptr device; callback: ptr gpio_callback): cint {.
    importc: "gpio_remove_callback", header: hdr.}




## *
##  @brief Function to get pending interrupts
##
##  The purpose of this function is to return the interrupt
##  status register for the device.
##  This is especially useful when waking up from
##  low power states to check the wake up source.
##
##  @param dev Pointer to the device structure for the driver instance.
##
##  @retval status != 0 if at least one gpio interrupt is pending.
##  @retval 0 if no gpio interrupt is pending.
##

proc gpio_get_pending_int*(dev: ptr device): cint {.syscall,
    importc: "gpio_get_pending_int", header: hdr.}
proc z_impl_gpio_get_pending_int*(dev: ptr device): cint {.
    importc: "z_impl_gpio_get_pending_int", header: hdr.}

