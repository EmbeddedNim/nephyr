import os

import nephyr
import nephyr/drivers/gpio

const
  SLEEP_TIME_MS* = 100

##  The devicetree node identifier for the "led0" alias.

var
  LED0* = DT_GPIO_LABEL(tok"DT_ALIAS(led0)", tok"gpios")
  LED1* = DT_GPIO_LABEL(DT_ALIAS(tok"led1"), tok"gpios")
  PIN0* = DT_GPIO_PIN(tok"DT_ALIAS(led0)", tok"gpios")
  PIN1* = DT_GPIO_PIN(DT_ALIAS(tok"led0"), tok"gpios")
  FLAGS* = DT_GPIO_FLAGS(tok"DT_ALIAS(led0)", tok"gpios")

proc test_gpio*() =
  var pin2 = DT_GPIO_PIN(DT_ALIAS(tok"led0"), tok"gpios")
  var dev: ptr device
  var led_is_on: bool = true
  var ret: cint
  dev = device_get_binding(LED0)
  if dev == nil:
    return
  ret = gpio_pin_configure(dev, PIN0, GPIO_OUTPUT_ACTIVE or FLAGS)
  ret = gpio_pin_configure(dev, PIN1, GPIO_OUTPUT_ACTIVE or FLAGS)
  if ret < 0:
    return
  while true:
    discard gpio_pin_set(dev, PIN1, led_is_on.cint)
    discard gpio_pin_set(dev, pin2, led_is_on.cint)
    led_is_on = not led_is_on
    os.sleep(SLEEP_TIME_MS)
    printk("test!\n")

test_gpio()
