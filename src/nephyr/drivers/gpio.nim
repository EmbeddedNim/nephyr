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

template initPinLbl*(label: static[string], config: GpioFlags): Pin =
  let
    pin = 0.gpio_pin_t # DT_N_S_gpio_keys_S_button_0_P_gpios_IDX_0_VAL_pin
    # port = 0 # DT_N_S_soc_S_pin_controller_58020000_S_gpio_58020800
    port = device_get_binding(label)

  echo "initPin: label: ", label
  echo "initPin: port: ", repr(port)
  if port.isNil:
    raise newException(OSError, "gpio port nil label: " & $label)

  var pinobj: Pin = Pin(port: port, pin: pin, mode: config)
  check: gpio_pin_configure(pinobj.port, pinobj.pin, config)
  pinobj

template initPin*(name: cminvtoken, config: GpioFlags, property: cminvtoken): Pin =
  let
    label = DT_GPIO_LABEL(name, property)
    pin = DT_GPIO_PIN(name, property)
    port = device_get_binding(label)

  echo "initPin: label: ", label
  if port.isNil:
    raise newException(OSError, "gpio port nil label: " & $label)

  var pinobj: Pin = Pin(port: port, pin: pin, mode: config)
  check: gpio_pin_configure(pinobj.port, pinobj.pin, config)
  pinobj

template initPin*(name: cminvtoken, flags: untyped): Pin =
  initPin(name, flags, tok"gpios")

proc level*(gpio: Pin): int =
  result = gpio_pin_get(gpio.port, gpio.pin).int

proc level*(gpio: Pin, value: int) =
  check: gpio_pin_set(gpio.port, gpio.pin, value.cint)

proc toggle*(gpio: Pin) =
  check: gpio_pin_toggle(gpio.port, gpio.pin)
