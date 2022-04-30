# Package

version       = "0.2.1"
author        = "Jaremy J. Creechley"
description   = "Nim wrapper for Zephyr RTOS"
license       = "Apache-2.0"
srcDir        = "src"

# Dependencies

requires "nim >= 1.6.5"
requires "msgpack4nim >= 0.3.1"
requires "stew >= 0.1.0"
requires "https://github.com/EmbeddedNim/mcu_utils#head"
requires "https://github.com/EmbeddedNim/fastrpc#head"


import os, sequtils, sugar

task test_nim_api_compilation, "compile Nim wrapper apis":
  let api_test_files = "tests/drivers/".listFiles()
  for test in api_test_files:  
    if test.startsWith("t") and test.endswith(".nim") == false: continue
    exec "nim c --compileonly:on " & test

task test_zephyr_c_api, "compile Zephyr wrapper apis":
  let main_files = "src/zephyr_c/".listFiles()
  let kernel_files = "src/zephyr_c/kernel/".listFiles()
  let dt_files = "src/zephyr_c/dt_bindings/".listFiles()
  let driver_files = "src/zephyr_c/drivers/".listFiles()

  let all_tests = concat(main_files, kernel_files, dt_files, driver_files)
  dump all_tests
  for test in all_tests:
    if not test.endswith(".nim"): continue
    let cmd = "nim c --compileonly:on " & test
    exec(cmd)

before test:
  test_zephyr_c_apiTask()
  test_nim_api_compilationTask()