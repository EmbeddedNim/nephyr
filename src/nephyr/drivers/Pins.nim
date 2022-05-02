
import zephyr/drivers/zgpio

type
  GpioPin* = gpio_pin_t
  GpioFlags* = gpio_flags_t

const

  IN* = GpioFlags GPIO_INPUT ## Configure pin in input mode
  OUT* = GpioFlags GPIO_OUTPUT ## Configure pin in output mode
  OFF* = GpioFlags 0 ## Disables pin for both input and output

  OUT_LOW* = GpioFlags GPIO_OUTPUT_LOW ## * Configures pin as output and initializes it to a low state
  OUT_HIGH* = GpioFlags GPIO_OUTPUT_HIGH ## * Configures pin as output and initializes it to a high state

  OUT_INACTIVE* = GpioFlags GPIO_OUTPUT_INACTIVE ## Configures pin as output and initializes it to a logic 0
  OUT_ACTIVE* = GpioFlags GPIO_OUTPUT_ACTIVE ## Configures pin as output and initializes it to a logic 1.
