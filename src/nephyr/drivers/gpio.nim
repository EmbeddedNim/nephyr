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
    flags*: gpio_flags_t

template initPin*(name: cminvtoken, flags: GpioFlags, property: cminvtoken): Pin =
  let
    label = DT_GPIO_LABEL(name, property)
    pin = DT_GPIO_PIN(name, property)
    port = device_get_binding(label)
    fl: gpio_flags_t = flags

  var p: Pin = Pin(port: port, pin: pin)

  var res = gpio_pin_configure(p.port, p.pin.gpio_pin_t, fl)
  p


template initPin*(name: cminvtoken, flags: untyped): Pin =
  initPin(name, flags, tok"gpios")