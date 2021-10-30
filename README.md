# Nephyr

Nim interface and library for Zephyr RTOS. Run Nim on any microcontroller Zephyr supports! 

WIP! The API and package layout are still prone to large changes. That being said, it's possible to run Nim code on Zephyr and once it compiles it's stable.

## Setup

1. Install Nim (recommend [choosenim](https://github.com/dom96/choosenim) )
1. Install Zephyr
2. Recommended to install Nephyr using `nimble develop` as the library will be changing frequently:
  - `git clone https://github.com/EmbeddedNim/nephyr.git`
  - `cd nephyr/`
  - `nimble develop`

## Layout

The library layout is broken into two main portions:
- Nim apis under `src/nephyr/`
- C Wrappers under `src/zephyr_c/`

## About

Working: 
- [x] Zephyr networking via POSIX layer (w/ Nim fork)
- [x] Support for using Zephyr sockets & poll (w/ Nim fork)
- [x] Nim wrappers for the basics of Zephyr devices and device tree
- [x] Support for Firmware OTA updates using Nim
- [x] JSON-RPC using JSON/MsgPack with default RPC methods for OTA updates
- [x] In progress work to wrap GPIO, SPI, & I2C
  - I2c exits, but needs testing
  - copy i2c to spi/gpio

However, this currently requires a fork of Nim at `elcritch/Nim`. There is work to upstream the changes. 

Future work will involve a pure Nim implementation of CoaP and CBOR intended for low latency machine-to-machine (M2M) communications. The goal being to make it trivial to write fast, concise, and safe low level machine M2M interactions. 

Another important goal will be to make Zephyr easy to use for developers new to embedded RTOS'es. Zephyr is fantastic but is not currently very friendly for those new to the field. This project will provide helpers to make it as simple to write as Arduino while being built on a solid well engineered RTOS ready for production deployments. 
