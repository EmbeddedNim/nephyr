##
##  Copyright (c) 2014-2015 Wind River Systems, Inc.
##
##  SPDX-License-Identifier: Apache-2.0
##
## *
##  @file
##  @brief Variables needed for system clock
##
##
##  Declare variables used by both system timer device driver and kernel
##  components that use timer functionality.
##

## *
##  @addtogroup clock_apis
##  @{
##
## *
##  @brief Tick precision used in timeout APIs
##
##  This type defines the word size of the timeout values used in
##  k_timeout_t objects, and thus defines an upper bound on maximum
##  timeout length (or equivalently minimum tick duration).  Note that
##  this does not affect the size of the system uptime counter, which
##  is always a 64 bit count of ticks.
##

when defined(CONFIG_TIMEOUT_64BIT):
  type
    k_ticks_t* = int64
else:
  type
    k_ticks_t* = uint32

var K_TICKS_FOREVER* {.importc: "K_TICKS_FOREVER", header: "sys_clock.h".}: int


type
  k_timeout_t* {.importc: "k_timeout_t", header: "sys_clock.h", incompleteStruct, bycopy.} = object
    ## *
    ##  @brief Kernel timeout type
    ##
    ##  Timeout arguments presented to kernel APIs are stored in this
    ##  opaque type, which is capable of representing times in various
    ##  formats and units.  It should be constructed from application data
    ##  using one of the macros defined for this purpose (e.g. `K_MSEC()`,
    ##  `K_TIMEOUT_ABS_TICKS()`, etc...), or be one of the two constants
    ##  K_NO_WAIT or K_FOREVER.  Applications should not inspect the
    ##  internal data once constructed.  Timeout values may be compared for
    ##  equality with the `K_TIMEOUT_EQ()` macro.
    ##

    ticks* {.importc: "ticks".}: k_ticks_t


proc K_TIMEOUT_EQ*(a: k_timeout_t; b: k_timeout_t) {.importc: "K_TIMEOUT_EQ",
                                        header: "sys_clock.h".} ## *
##  @brief Compare timeouts for equality
##
##  The k_timeout_t object is an opaque struct that should not be
##  inspected by application code.  This macro exists so that users can
##  test timeout objects for equality with known constants
##  (e.g. K_NO_WAIT and K_FOREVER) when implementing their own APIs in
##  terms of Zephyr timeout constants.
##
##  @return True if the timeout objects are identical
##


var Z_TIMEOUT_NO_WAIT* {.importc: "Z_TIMEOUT_NO_WAIT", header: "sys_clock.h".}: int

var Z_FOREVER* {.importc: "Z_FOREVER", header: "sys_clock.h".}: int

proc Z_TIMEOUT_MS*(t: k_ticks_t): k_timeout_t {.importc: "Z_TIMEOUT_MS", header: "sys_clock.h".}
proc Z_TIMEOUT_US*(t: k_ticks_t): k_timeout_t {.importc: "Z_TIMEOUT_US", header: "sys_clock.h".}
proc Z_TIMEOUT_NS*(t: k_ticks_t): k_timeout_t {.importc: "Z_TIMEOUT_NS", header: "sys_clock.h".}
proc Z_TIMEOUT_CYC*(t: k_ticks_t): k_timeout_t {.importc: "Z_TIMEOUT_CYC", header: "sys_clock.h".}

proc Z_TICK_ABS*(t: k_ticks_t): k_ticks_t {.importc: "Z_TICK_ABS", header: "sys_clock.h".} ##  Converts between absolute timeout expiration values (packed into
##  the negative space below K_TICKS_FOREVER) and (non-negative) delta
##  timeout values.  If the result of Z_TICK_ABS(t) is >= 0, then the
##  value was an absolute timeout with the returend expiration time.
##  Note that this macro is bidirectional: Z_TICK_ABS(Z_TICK_ABS(t)) ==
##  t for all inputs, and that the representation of K_TICKS_FOREVER is
##  the same value in both spaces!  Clever, huh?
##


when defined(CONFIG_TICKLESS_KERNEL):
  proc z_enable_sys_clock*() {.importc: "z_enable_sys_clock", header: "sys_clock.h".}

var NSEC_PER_USEC* {.importc: "NSEC_PER_USEC", header: "sys_clock.h".}: int ##  number of nsec per usec

var USEC_PER_MSEC* {.importc: "USEC_PER_MSEC", header: "sys_clock.h".}: int ##  number of microseconds per millisecond

var MSEC_PER_SEC* {.importc: "MSEC_PER_SEC", header: "sys_clock.h".}: int ##  number of milliseconds per second

var USEC_PER_SEC* {.importc: "USEC_PER_SEC", header: "sys_clock.h".}: int ##  number of microseconds per second

var NSEC_PER_SEC* {.importc: "NSEC_PER_SEC", header: "sys_clock.h".}: int ##  number of nanoseconds per second

##  kernel clocks
##
##  We default to using 64-bit intermediates in timescale conversions,
##  but if the HW timer cycles/sec, ticks/sec and ms/sec are all known
##  to be nicely related, then we can cheat with 32 bits instead.
##

proc SYS_CLOCK_HW_CYCLES_TO_NS_AVG*(X: uint32; NCYCLES: uint32) {.
    importc: "SYS_CLOCK_HW_CYCLES_TO_NS_AVG", header: "sys_clock.h".} ##
##  SYS_CLOCK_HW_CYCLES_TO_NS_AVG converts CPU clock cycles to nanoseconds
##  and calculates the average cycle time
##

proc sys_clock_tick_get_32*(): uint32 {.importc: "sys_clock_tick_get_32",
                                     header: "sys_clock.h".} ## *
##
##  @brief Return the lower part of the current system tick count
##
##  @return the current system tick count
##
##

proc sys_clock_tick_get*(): int64 {.importc: "sys_clock_tick_get",
                                 header: "sys_clock.h".} ## *
##
##  @brief Return the current system tick count
##
##  @return the current system tick count
##
##

proc sys_clock_tick_get*() {.importc: "sys_clock_tick_get", header: "sys_clock.h".}
proc sys_clock_tick_get_32*() {.importc: "sys_clock_tick_get_32",
                                header: "sys_clock.h".}

proc sys_clock_timeout_end_calc*(timeout: k_timeout_t): uint64 {.
    importc: "sys_clock_timeout_end_calc", header: "sys_clock.h".}

