##
##  Copyright (c) 2019 Intel Corporation
##
##  SPDX-License-Identifier: Apache-2.0
##

## * @brief System-wide macro to denote "forever" in milliseconds
##
##   Usage of this macro is limited to APIs that want to expose a timeout value
##   that can optionally be unlimited, or "forever".
##   This macro can not be fed into kernel functions or macros directly. Use
##   @ref SYS_TIMEOUT_MS instead.
##

var SYS_FOREVER_MS* {.importc: "SYS_FOREVER_MS", header: "time_units.h".}: int

## * @brief System-wide macro to convert milliseconds to kernel timeouts
##
proc SYS_TIMEOUT_MS*(ms: int64) {.importc: "SYS_TIMEOUT_MS", header: "time_units.h".}

##  Exhaustively enumerated, highly optimized time unit conversion API
when defined(CONFIG_TIMER_READS_ITS_FREQUENCY_AT_RUNTIME):
  proc sys_clock_hw_cycles_per_sec_runtime_get*(): cint {.syscall,
      importc: "sys_clock_hw_cycles_per_sec_runtime_get", header: "time_units.h".}
  proc z_impl_sys_clock_hw_cycles_per_sec_runtime_get*(): cint {.inline.} =
    var z_clock_hw_cycles_per_sec: cint
    return z_clock_hw_cycles_per_sec

proc sys_clock_hw_cycles_per_sec*(): cint =
  when defined(CONFIG_TIMER_READS_ITS_FREQUENCY_AT_RUNTIME):
    return sys_clock_hw_cycles_per_sec_runtime_get()
  else:
    return CONFIG_SYS_CLOCK_HW_CYCLES_PER_SEC

##  Time converter generator gadget.  Selects from one of three
##  conversion algorithms: ones that take advantage when the
##  frequencies are an integer ratio (in either direction), or a full
##  precision conversion.  Clever use of extra arguments causes all the
##  selection logic to be optimized out, and the generated code even
##  reduces to 32 bit only if a ratio conversion is available and the
##  result is 32 bits.
##
##  This isn't intended to be used directly, instead being wrapped
##  appropriately in a user-facing API.  The boolean arguments are:
##
##     const_hz  - The hz arguments are known to be compile-time
##                 constants (because otherwise the modulus test would
##                 have to be done at runtime)
##     result32  - The result will be truncated to 32 bits on use
##     round_up  - Return the ceiling of the resulting fraction
##     round_off - Return the nearest value to the resulting fraction
##                 (pass both round_up/off as false to get "round_down")
##

proc z_tmcvt*(t: uint64; from_hz: uint32; to_hz: uint32; const_hz: bool; result32: bool;
             round_up: bool; round_off: bool): uint64 =
  var mul_ratio: bool
  var div_ratio: bool
  if from_hz == to_hz:
    return if result32: (cast[uint32](t)) else: t
  var off: uint64
  if not mul_ratio:
    var rdivisor: uint32
    if round_up:
      off = rdivisor - 1'u
    if round_off:
      off = rdivisor div 2'u
  if div_ratio:
    inc(t, off)
    if result32 and (t < BIT64(32)):
      return (cast[uint32](t)) div (from_hz div to_hz)
    else:
      return t div (cast[uint64](from_hz div to_hz))
  elif mul_ratio:
    if result32:
      return (cast[uint32](t)) * (to_hz div from_hz)
    else:
      return t * (cast[uint64](to_hz div from_hz))
  else:
    if result32:
      return (uint32)((t * to_hz + off) div from_hz)
    else:
      return (t * to_hz + off) div from_hz

##  The following code is programmatically generated using this perl
##  code, which enumerates all possible combinations of units, rounding
##  modes and precision.  Do not edit directly.
##
##  Note that nano/microsecond conversions are only defined with 64 bit
##  precision.  These units conversions were not available in 32 bit
##  variants historically, and doing 32 bit math with units that small
##  has precision traps that we probably don't want to support in an
##  official API.
##
##  #!/usr/bin/perl -w
##  use strict;
##
##  my %human = ("ms" => "milliseconds",
##               "us" => "microseconds",
##               "ns" => "nanoseconds",
##               "cyc" => "hardware cycles",
##               "ticks" => "ticks");
##
##  sub big { return $_[0] eq "us" || $_[0] eq "ns"; }
##  sub prefix { return $_[0] eq "ms" || $_[0] eq "us" || $_[0] eq "ns"; }
##
##  for my $from_unit ("ms", "us", "ns", "cyc", "ticks") {
##      for my $to_unit ("ms", "us", "ns", "cyc", "ticks") {
##          next if $from_unit eq $to_unit;
##          next if prefix($from_unit) && prefix($to_unit);
##          for my $round ("floor", "near", "ceil") {
##              for(my $big=0; $big <= 1; $big++) {
##                  my $sz = $big ? 64 : 32;
##                  my $sym = "k_${from_unit}_to_${to_unit}_$round$sz";
##                  my $type = "u${sz}_t";
##                  my $const_hz = ($from_unit eq "cyc" || $to_unit eq "cyc")
##                      ? "Z_CCYC" : "true";
##                  my $ret32 = $big ? "false" : "true";
##                  my $rup = $round eq "ceil" ? "true" : "false";
##                  my $roff = $round eq "near" ? "true" : "false";
##
##                  my $hfrom = $human{$from_unit};
##                  my $hto = $human{$to_unit};
##                  print "/", "** \@brief Convert $hfrom to $hto\n";
##                  print " *\n";
##                  print " * Converts time values in $hfrom to $hto.\n";
##                  print " * Computes result in $sz bit precision.\n";
##                  if ($round eq "ceil") {
##                      print " * Rounds up to the next highest output unit.\n";
##                  } elsif ($round eq "near") {
##                      print " * Rounds to the nearest output unit.\n";
##                  } else {
##                      print " * Truncates to the next lowest output unit.\n";
##                  }
##                  print " *\n";
##                  print " * \@return The converted time value\n";
##                  print " *", "/\n";
##
##                  print " $type $sym($type t)\n{\n\t";
##                  print "/", "* Generated.  Do not edit.  See above. *", "/\n\t";
##                  print "return z_tmcvt(t, Z_HZ_$from_unit, Z_HZ_$to_unit,";
##                  print " $const_hz, $ret32, $rup, $roff);\n";
##                  print "}\n\n";
##              }
##          }
##      }
##  }
##
##  Some more concise declarations to simplify the generator script and
##  save bytes below
##

var Z_HZ_ms* {.importc: "Z_HZ_ms", header: "time_units.h".}: int
## * @brief Convert milliseconds to hardware cycles
##
##  Converts time values in milliseconds to hardware cycles.
##  Computes result in 32 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_ms_to_cyc_floor32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ms, Z_HZ_cyc, Z_CCYC, true, false, false)

## * @brief Convert milliseconds to hardware cycles
##
##  Converts time values in milliseconds to hardware cycles.
##  Computes result in 64 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_ms_to_cyc_floor64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ms, Z_HZ_cyc, Z_CCYC, false, false, false)

## * @brief Convert milliseconds to hardware cycles
##
##  Converts time values in milliseconds to hardware cycles.
##  Computes result in 32 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_ms_to_cyc_near32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ms, Z_HZ_cyc, Z_CCYC, true, false, true)

## * @brief Convert milliseconds to hardware cycles
##
##  Converts time values in milliseconds to hardware cycles.
##  Computes result in 64 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_ms_to_cyc_near64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ms, Z_HZ_cyc, Z_CCYC, false, false, true)

## * @brief Convert milliseconds to hardware cycles
##
##  Converts time values in milliseconds to hardware cycles.
##  Computes result in 32 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_ms_to_cyc_ceil32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ms, Z_HZ_cyc, Z_CCYC, true, true, false)

## * @brief Convert milliseconds to hardware cycles
##
##  Converts time values in milliseconds to hardware cycles.
##  Computes result in 64 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_ms_to_cyc_ceil64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ms, Z_HZ_cyc, Z_CCYC, false, true, false)

## * @brief Convert milliseconds to ticks
##
##  Converts time values in milliseconds to ticks.
##  Computes result in 32 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_ms_to_ticks_floor32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ms, Z_HZ_ticks, true, true, false, false)

## * @brief Convert milliseconds to ticks
##
##  Converts time values in milliseconds to ticks.
##  Computes result in 64 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_ms_to_ticks_floor64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ms, Z_HZ_ticks, true, false, false, false)

## * @brief Convert milliseconds to ticks
##
##  Converts time values in milliseconds to ticks.
##  Computes result in 32 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_ms_to_ticks_near32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ms, Z_HZ_ticks, true, true, false, true)

## * @brief Convert milliseconds to ticks
##
##  Converts time values in milliseconds to ticks.
##  Computes result in 64 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_ms_to_ticks_near64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ms, Z_HZ_ticks, true, false, false, true)

## * @brief Convert milliseconds to ticks
##
##  Converts time values in milliseconds to ticks.
##  Computes result in 32 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_ms_to_ticks_ceil32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ms, Z_HZ_ticks, true, true, true, false)

## * @brief Convert milliseconds to ticks
##
##  Converts time values in milliseconds to ticks.
##  Computes result in 64 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_ms_to_ticks_ceil64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ms, Z_HZ_ticks, true, false, true, false)

## * @brief Convert microseconds to hardware cycles
##
##  Converts time values in microseconds to hardware cycles.
##  Computes result in 32 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_us_to_cyc_floor32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_us, Z_HZ_cyc, Z_CCYC, true, false, false)

## * @brief Convert microseconds to hardware cycles
##
##  Converts time values in microseconds to hardware cycles.
##  Computes result in 64 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_us_to_cyc_floor64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_us, Z_HZ_cyc, Z_CCYC, false, false, false)

## * @brief Convert microseconds to hardware cycles
##
##  Converts time values in microseconds to hardware cycles.
##  Computes result in 32 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_us_to_cyc_near32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_us, Z_HZ_cyc, Z_CCYC, true, false, true)

## * @brief Convert microseconds to hardware cycles
##
##  Converts time values in microseconds to hardware cycles.
##  Computes result in 64 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_us_to_cyc_near64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_us, Z_HZ_cyc, Z_CCYC, false, false, true)

## * @brief Convert microseconds to hardware cycles
##
##  Converts time values in microseconds to hardware cycles.
##  Computes result in 32 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_us_to_cyc_ceil32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_us, Z_HZ_cyc, Z_CCYC, true, true, false)

## * @brief Convert microseconds to hardware cycles
##
##  Converts time values in microseconds to hardware cycles.
##  Computes result in 64 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_us_to_cyc_ceil64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_us, Z_HZ_cyc, Z_CCYC, false, true, false)

## * @brief Convert microseconds to ticks
##
##  Converts time values in microseconds to ticks.
##  Computes result in 32 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_us_to_ticks_floor32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_us, Z_HZ_ticks, true, true, false, false)

## * @brief Convert microseconds to ticks
##
##  Converts time values in microseconds to ticks.
##  Computes result in 64 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_us_to_ticks_floor64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_us, Z_HZ_ticks, true, false, false, false)

## * @brief Convert microseconds to ticks
##
##  Converts time values in microseconds to ticks.
##  Computes result in 32 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_us_to_ticks_near32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_us, Z_HZ_ticks, true, true, false, true)

## * @brief Convert microseconds to ticks
##
##  Converts time values in microseconds to ticks.
##  Computes result in 64 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_us_to_ticks_near64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_us, Z_HZ_ticks, true, false, false, true)

## * @brief Convert microseconds to ticks
##
##  Converts time values in microseconds to ticks.
##  Computes result in 32 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_us_to_ticks_ceil32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_us, Z_HZ_ticks, true, true, true, false)

## * @brief Convert microseconds to ticks
##
##  Converts time values in microseconds to ticks.
##  Computes result in 64 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_us_to_ticks_ceil64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_us, Z_HZ_ticks, true, false, true, false)

## * @brief Convert nanoseconds to hardware cycles
##
##  Converts time values in nanoseconds to hardware cycles.
##  Computes result in 32 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_ns_to_cyc_floor32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ns, Z_HZ_cyc, Z_CCYC, true, false, false)

## * @brief Convert nanoseconds to hardware cycles
##
##  Converts time values in nanoseconds to hardware cycles.
##  Computes result in 64 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_ns_to_cyc_floor64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ns, Z_HZ_cyc, Z_CCYC, false, false, false)

## * @brief Convert nanoseconds to hardware cycles
##
##  Converts time values in nanoseconds to hardware cycles.
##  Computes result in 32 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_ns_to_cyc_near32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ns, Z_HZ_cyc, Z_CCYC, true, false, true)

## * @brief Convert nanoseconds to hardware cycles
##
##  Converts time values in nanoseconds to hardware cycles.
##  Computes result in 64 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_ns_to_cyc_near64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ns, Z_HZ_cyc, Z_CCYC, false, false, true)

## * @brief Convert nanoseconds to hardware cycles
##
##  Converts time values in nanoseconds to hardware cycles.
##  Computes result in 32 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_ns_to_cyc_ceil32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ns, Z_HZ_cyc, Z_CCYC, true, true, false)

## * @brief Convert nanoseconds to hardware cycles
##
##  Converts time values in nanoseconds to hardware cycles.
##  Computes result in 64 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_ns_to_cyc_ceil64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ns, Z_HZ_cyc, Z_CCYC, false, true, false)

## * @brief Convert nanoseconds to ticks
##
##  Converts time values in nanoseconds to ticks.
##  Computes result in 32 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_ns_to_ticks_floor32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ns, Z_HZ_ticks, true, true, false, false)

## * @brief Convert nanoseconds to ticks
##
##  Converts time values in nanoseconds to ticks.
##  Computes result in 64 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_ns_to_ticks_floor64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ns, Z_HZ_ticks, true, false, false, false)

## * @brief Convert nanoseconds to ticks
##
##  Converts time values in nanoseconds to ticks.
##  Computes result in 32 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_ns_to_ticks_near32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ns, Z_HZ_ticks, true, true, false, true)

## * @brief Convert nanoseconds to ticks
##
##  Converts time values in nanoseconds to ticks.
##  Computes result in 64 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_ns_to_ticks_near64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ns, Z_HZ_ticks, true, false, false, true)

## * @brief Convert nanoseconds to ticks
##
##  Converts time values in nanoseconds to ticks.
##  Computes result in 32 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_ns_to_ticks_ceil32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ns, Z_HZ_ticks, true, true, true, false)

## * @brief Convert nanoseconds to ticks
##
##  Converts time values in nanoseconds to ticks.
##  Computes result in 64 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_ns_to_ticks_ceil64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ns, Z_HZ_ticks, true, false, true, false)

## * @brief Convert hardware cycles to milliseconds
##
##  Converts time values in hardware cycles to milliseconds.
##  Computes result in 32 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ms_floor32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ms, Z_CCYC, true, false, false)

## * @brief Convert hardware cycles to milliseconds
##
##  Converts time values in hardware cycles to milliseconds.
##  Computes result in 64 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ms_floor64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ms, Z_CCYC, false, false, false)

## * @brief Convert hardware cycles to milliseconds
##
##  Converts time values in hardware cycles to milliseconds.
##  Computes result in 32 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ms_near32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ms, Z_CCYC, true, false, true)

## * @brief Convert hardware cycles to milliseconds
##
##  Converts time values in hardware cycles to milliseconds.
##  Computes result in 64 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ms_near64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ms, Z_CCYC, false, false, true)

## * @brief Convert hardware cycles to milliseconds
##
##  Converts time values in hardware cycles to milliseconds.
##  Computes result in 32 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ms_ceil32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ms, Z_CCYC, true, true, false)

## * @brief Convert hardware cycles to milliseconds
##
##  Converts time values in hardware cycles to milliseconds.
##  Computes result in 64 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ms_ceil64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ms, Z_CCYC, false, true, false)

## * @brief Convert hardware cycles to microseconds
##
##  Converts time values in hardware cycles to microseconds.
##  Computes result in 32 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_us_floor32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_us, Z_CCYC, true, false, false)

## * @brief Convert hardware cycles to microseconds
##
##  Converts time values in hardware cycles to microseconds.
##  Computes result in 64 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_us_floor64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_us, Z_CCYC, false, false, false)

## * @brief Convert hardware cycles to microseconds
##
##  Converts time values in hardware cycles to microseconds.
##  Computes result in 32 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_us_near32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_us, Z_CCYC, true, false, true)

## * @brief Convert hardware cycles to microseconds
##
##  Converts time values in hardware cycles to microseconds.
##  Computes result in 64 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_us_near64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_us, Z_CCYC, false, false, true)

## * @brief Convert hardware cycles to microseconds
##
##  Converts time values in hardware cycles to microseconds.
##  Computes result in 32 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_us_ceil32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_us, Z_CCYC, true, true, false)

## * @brief Convert hardware cycles to microseconds
##
##  Converts time values in hardware cycles to microseconds.
##  Computes result in 64 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_us_ceil64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_us, Z_CCYC, false, true, false)

## * @brief Convert hardware cycles to nanoseconds
##
##  Converts time values in hardware cycles to nanoseconds.
##  Computes result in 32 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ns_floor32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ns, Z_CCYC, true, false, false)

## * @brief Convert hardware cycles to nanoseconds
##
##  Converts time values in hardware cycles to nanoseconds.
##  Computes result in 64 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ns_floor64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ns, Z_CCYC, false, false, false)

## * @brief Convert hardware cycles to nanoseconds
##
##  Converts time values in hardware cycles to nanoseconds.
##  Computes result in 32 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ns_near32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ns, Z_CCYC, true, false, true)

## * @brief Convert hardware cycles to nanoseconds
##
##  Converts time values in hardware cycles to nanoseconds.
##  Computes result in 64 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ns_near64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ns, Z_CCYC, false, false, true)

## * @brief Convert hardware cycles to nanoseconds
##
##  Converts time values in hardware cycles to nanoseconds.
##  Computes result in 32 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ns_ceil32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ns, Z_CCYC, true, true, false)

## * @brief Convert hardware cycles to nanoseconds
##
##  Converts time values in hardware cycles to nanoseconds.
##  Computes result in 64 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ns_ceil64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ns, Z_CCYC, false, true, false)

## * @brief Convert hardware cycles to ticks
##
##  Converts time values in hardware cycles to ticks.
##  Computes result in 32 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ticks_floor32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ticks, Z_CCYC, true, false, false)

## * @brief Convert hardware cycles to ticks
##
##  Converts time values in hardware cycles to ticks.
##  Computes result in 64 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ticks_floor64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ticks, Z_CCYC, false, false, false)

## * @brief Convert hardware cycles to ticks
##
##  Converts time values in hardware cycles to ticks.
##  Computes result in 32 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ticks_near32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ticks, Z_CCYC, true, false, true)

## * @brief Convert hardware cycles to ticks
##
##  Converts time values in hardware cycles to ticks.
##  Computes result in 64 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ticks_near64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ticks, Z_CCYC, false, false, true)

## * @brief Convert hardware cycles to ticks
##
##  Converts time values in hardware cycles to ticks.
##  Computes result in 32 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ticks_ceil32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ticks, Z_CCYC, true, true, false)

## * @brief Convert hardware cycles to ticks
##
##  Converts time values in hardware cycles to ticks.
##  Computes result in 64 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_cyc_to_ticks_ceil64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_cyc, Z_HZ_ticks, Z_CCYC, false, true, false)

## * @brief Convert ticks to milliseconds
##
##  Converts time values in ticks to milliseconds.
##  Computes result in 32 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_ms_floor32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_ms, true, true, false, false)

## * @brief Convert ticks to milliseconds
##
##  Converts time values in ticks to milliseconds.
##  Computes result in 64 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_ms_floor64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_ms, true, false, false, false)

## * @brief Convert ticks to milliseconds
##
##  Converts time values in ticks to milliseconds.
##  Computes result in 32 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_ms_near32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_ms, true, true, false, true)

## * @brief Convert ticks to milliseconds
##
##  Converts time values in ticks to milliseconds.
##  Computes result in 64 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_ms_near64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_ms, true, false, false, true)

## * @brief Convert ticks to milliseconds
##
##  Converts time values in ticks to milliseconds.
##  Computes result in 32 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_ms_ceil32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_ms, true, true, true, false)

## * @brief Convert ticks to milliseconds
##
##  Converts time values in ticks to milliseconds.
##  Computes result in 64 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_ms_ceil64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_ms, true, false, true, false)

## * @brief Convert ticks to microseconds
##
##  Converts time values in ticks to microseconds.
##  Computes result in 32 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_us_floor32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_us, true, true, false, false)

## * @brief Convert ticks to microseconds
##
##  Converts time values in ticks to microseconds.
##  Computes result in 64 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_us_floor64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_us, true, false, false, false)

## * @brief Convert ticks to microseconds
##
##  Converts time values in ticks to microseconds.
##  Computes result in 32 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_us_near32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_us, true, true, false, true)

## * @brief Convert ticks to microseconds
##
##  Converts time values in ticks to microseconds.
##  Computes result in 64 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_us_near64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_us, true, false, false, true)

## * @brief Convert ticks to microseconds
##
##  Converts time values in ticks to microseconds.
##  Computes result in 32 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_us_ceil32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_us, true, true, true, false)

## * @brief Convert ticks to microseconds
##
##  Converts time values in ticks to microseconds.
##  Computes result in 64 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_us_ceil64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_us, true, false, true, false)

## * @brief Convert ticks to nanoseconds
##
##  Converts time values in ticks to nanoseconds.
##  Computes result in 32 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_ns_floor32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_ns, true, true, false, false)

## * @brief Convert ticks to nanoseconds
##
##  Converts time values in ticks to nanoseconds.
##  Computes result in 64 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_ns_floor64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_ns, true, false, false, false)

## * @brief Convert ticks to nanoseconds
##
##  Converts time values in ticks to nanoseconds.
##  Computes result in 32 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_ns_near32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_ns, true, true, false, true)

## * @brief Convert ticks to nanoseconds
##
##  Converts time values in ticks to nanoseconds.
##  Computes result in 64 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_ns_near64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_ns, true, false, false, true)

## * @brief Convert ticks to nanoseconds
##
##  Converts time values in ticks to nanoseconds.
##  Computes result in 32 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_ns_ceil32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_ns, true, true, true, false)

## * @brief Convert ticks to nanoseconds
##
##  Converts time values in ticks to nanoseconds.
##  Computes result in 64 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_ns_ceil64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_ns, true, false, true, false)

## * @brief Convert ticks to hardware cycles
##
##  Converts time values in ticks to hardware cycles.
##  Computes result in 32 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_cyc_floor32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_cyc, Z_CCYC, true, false, false)

## * @brief Convert ticks to hardware cycles
##
##  Converts time values in ticks to hardware cycles.
##  Computes result in 64 bit precision.
##  Truncates to the next lowest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_cyc_floor64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_cyc, Z_CCYC, false, false, false)

## * @brief Convert ticks to hardware cycles
##
##  Converts time values in ticks to hardware cycles.
##  Computes result in 32 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_cyc_near32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_cyc, Z_CCYC, true, false, true)

## * @brief Convert ticks to hardware cycles
##
##  Converts time values in ticks to hardware cycles.
##  Computes result in 64 bit precision.
##  Rounds to the nearest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_cyc_near64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_cyc, Z_CCYC, false, false, true)

## * @brief Convert ticks to hardware cycles
##
##  Converts time values in ticks to hardware cycles.
##  Computes result in 32 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_cyc_ceil32*(t: uint32): uint32 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_cyc, Z_CCYC, true, true, false)

## * @brief Convert ticks to hardware cycles
##
##  Converts time values in ticks to hardware cycles.
##  Computes result in 64 bit precision.
##  Rounds up to the next highest output unit.
##
##  @return The converted time value
##

proc k_ticks_to_cyc_ceil64*(t: uint64): uint64 =
  ##  Generated.  Do not edit.  See above.
  return z_tmcvt(t, Z_HZ_ticks, Z_HZ_cyc, Z_CCYC, false, true, false)

when defined(CONFIG_TIMER_READS_ITS_FREQUENCY_AT_RUNTIME):
  discard