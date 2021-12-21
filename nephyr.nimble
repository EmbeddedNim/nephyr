# Package

version       = "0.2.0"
author        = "Jaremy J. Creechley"
description   = "Nim wrapper for Zephyr RTOS"
license       = "Apache-2.0"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["nephyr"]


# Dependencies

requires "nim >= 1.4.8"
requires "msgpack4nim >= 0.3.1"
requires "stew >= 0.1.0"
requires "https://github.com/EmbeddedNim/mcu_utils"
requires "https://github.com/EmbeddedNim/fast_rpc"

task test_nim_api_compilation, "compile Nim wrapper apis":
  exec "nim c --compileonly:on tests/api_compilations/tgpio.nim"
  exec "nim c --compileonly:on tests/api_compilations/ti2c.nim"
