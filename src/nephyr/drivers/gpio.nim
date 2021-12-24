import bitops
import macros
import sets

import nephyr/general
import nephyr/utils
import zephyr_c/zdevicetree
import zephyr_c/zdevice
import zephyr_c/dt_bindings/dt_gpio
import zephyr_c/drivers/zgpio
import zephyr_c/cmtoken

export zgpio
export dt_gpio
export utils, cmtoken, zdevice, zdevicetree

import Pins
export Pins

type

  Pin* = object
    port*: ptr device
    pin*: gpio_pin_t
    mode*: gpio_flags_t

template initPin*(name: cminvtoken, config: GpioFlags, property: cminvtoken): Pin =
  let
    label = DT_GPIO_LABEL(name, property)
    pin = DT_GPIO_PIN(name, property)
    port = device_get_binding(label)

  var pinobj: Pin = Pin(port: port, pin: pin, mode: config)

  check: gpio_pin_configure(pinobj.port, pinobj.pin, config)
  pinobj


template initPin*(name: cminvtoken, flags: untyped): Pin =
  initPin(name, flags, tok"gpios")