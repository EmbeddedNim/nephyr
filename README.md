# Nephyr

Nim interface and library for Zephyr RTOS. Run Nim on any microcontroller Zephyr supports! 

WIP! The API and package layout are still prone to large changes. That being said, it's possible to run Nim code on Zephyr and once it compiles it's appears very stable.

## Setup

1. Install Nim (recommend [choosenim](https://github.com/dom96/choosenim) )
  - The Nim `devel` branch is currently required: `choosenim devel --latest`
3. Install Zephyr
  - `pip3 install west` 
  - `west init -m https://github.com/EmbeddedNim/zephyr.git --mr nephyr-v2.7-branch-patched --narrow $HOME/zephyrproject/`
  - note there's work to improve this usine `nephyrcli` but it's not ready for public use yet
5. Recommended to install Nephyr using `nimble develop` as the library will be changing frequently:
  - `git clone https://github.com/EmbeddedNim/nephyr.git`
  - `cd nephyr/`
  - `nimble develop`

## Layout

The library layout is broken into two main portions:
- Nim apis under `src/nephyr/`
- C Wrappers under `src/zephyr_c/`

## Examples

See [Nephyr Examples repo](https://github.com/EmbeddedNim/nephyr_examples) for examples. 

## Why

Zephyr is taking a great approach to modernize RTOS & embedded development. It has support from multiple MCU vendors (NXP, Nordic, TI, etc). In some areas it's still less mature than other RTOS options, however it's rapidly improving and already boasts support for most modern MCU's. It also includes a bootloader, device drivers, and first class CI and testing. The primary downside is the lack of documentation especially when combined with the complicated nature of a very configurable RTOS. 

Nephyr's goal is to provide a stable high-level wrapper around Zephyr. However, the hardware APIs are being designed with being compatible with other RTOS'es. Eventually Nim could replace parts of Zephyr C stack with pure Nim solutions. 


## Status 

### Working

- [x] Zephyr networking via POSIX layer
- [x] Support for using Zephyr sockets & poll
- [x] Nim wrappers for the basics of Zephyr devices and device tree
- [x] Support for Firmware OTA updates using Nim
- [x] I2C works and tested with real devices
- [x] SPI raw api works, Nim SPI api is written but not verified
- [x] Basic set of boards working with Nephyr out-of-the-box
      + nrf52480, STM32-H7 "Disco Boards", Teensy 4 (WIP)

### Ongoing

- [ ] Documentation!
- [ ] Significantly improve the Nim interface to the DTS system in Zephyr
- [ ] Setup auto-installer for Zephyr
- [ ] Setup CI builds with Zephyr
- [ ] Setup CI run tests using QEMU 



