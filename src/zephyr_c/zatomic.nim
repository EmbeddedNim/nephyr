##
##  Copyright (c) 1997-2015, Wind River Systems, Inc.
##  Copyright (c) 2021 Intel Corporation
##
##  SPDX-License-Identifier: Apache-2.0
##

type
  atomic_t* = cint
  atomic_ptr_t* = distinct pointer
  atomic_ptr_val_t* = atomic_ptr_t

##  Low-level primitives come in several styles:

##  Portable higher-level utilities:
## *
##  @defgroup atomic_apis Atomic Services APIs
##  @ingroup kernel_apis
##  @{
##
## *
##  @brief Initialize an atomic variable.
##
##  This macro can be used to initialize an atomic variable. For example,
##  @code atomic_t my_var = ATOMIC_INIT(75); @endcode
##
##  @param i Value to assign to atomic variable.
##

proc ATOMIC_INIT*(i: cint): atomic_t {.importc: "ATOMIC_INIT", header: "atomic.h".}



## *
##  @brief Initialize an atomic pointer variable.
##
##  This macro can be used to initialize an atomic pointer variable. For
##  example,
##  @code atomic_ptr_t my_ptr = ATOMIC_PTR_INIT(&data); @endcode
##
##  @param p Pointer value to assign to atomic pointer variable.
##
proc ATOMIC_PTR_INIT*(p: pointer): atomic_ptr_t {.importc: "ATOMIC_PTR_INIT", header: "atomic.h".}


# ## *
# ##  @brief Define an array of atomic variables.
# ##
# ##  This macro defines an array of atomic variables containing at least
# ##  @a num_bits bits.
# ##
# ##  @note
# ##  If used from file scope, the bits of the array are initialized to zero;
# ##  if used from within a function, the bits are left uninitialized.
# ##
# ##  @cond INTERNAL_HIDDEN
# ##  @note
# ##  This macro should be replicated in the PREDEFINED field of the documentation
# ##  Doxyfile.
# ##  @endcond
# ##
# ##  @param name Name of array of atomic variables.
# ##  @param num_bits Number of bits needed.
# ##
# proc ATOMIC_BITMAP_SIZE(num_bits: int): atomic_ptr_t {.importc: "ATOMIC_BITMAP_SIZE", header: "atomic.h".}
# template ATOMIC_DEFINE*(name: untyped; num_bits: static[int]) =
#   var `name`: array[ATOMIC_BITMAP_SIZE(num_bits)]


## *
##  @brief Atomically test a bit.
##
##  This routine tests whether bit number @a bit of @a target is set or not.
##  The target may be a single atomic variable or an array of them.
##
##  @param target Address of atomic variable or array.
##  @param bit Bit number (starting from 0).
##
##  @return true if the bit was set, false if it wasn't.
##
proc atomic_test_bit*(target: ptr atomic_t; bit: cint): bool {.
  importc: "$1", header: "atomic.h".}



## *
##  @brief Atomically test and clear a bit.
##
##  Atomically clear bit number @a bit of @a target and return its old value.
##  The target may be a single atomic variable or an array of them.
##
##  @param target Address of atomic variable or array.
##  @param bit Bit number (starting from 0).
##
##  @return true if the bit was set, false if it wasn't.
##
proc atomic_test_and_clear_bit*(target: ptr atomic_t; bit: cint): bool {.
  importc: "$1", header: "atomic.h".}



## *
##  @brief Atomically set a bit.
##
##  Atomically set bit number @a bit of @a target and return its old value.
##  The target may be a single atomic variable or an array of them.
##
##  @param target Address of atomic variable or array.
##  @param bit Bit number (starting from 0).
##
##  @return true if the bit was set, false if it wasn't.
##
proc atomic_test_and_set_bit*(target: ptr atomic_t; bit: cint): bool {.
  importc: "$1", header: "atomic.h".}



## *
##  @brief Atomically clear a bit.
##
##  Atomically clear bit number @a bit of @a target.
##  The target may be a single atomic variable or an array of them.
##
##  @param target Address of atomic variable or array.
##  @param bit Bit number (starting from 0).
##
##  @return N/A
##

proc atomic_clear_bit*(target: ptr atomic_t; bit: cint) {.
  importc: "$1", header: "atomic.h".}



## *
##  @brief Atomically set a bit.
##
##  Atomically set bit number @a bit of @a target.
##  The target may be a single atomic variable or an array of them.
##
##  @param target Address of atomic variable or array.
##  @param bit Bit number (starting from 0).
##
##  @return N/A
##
proc atomic_set_bit*(target: ptr atomic_t; bit: cint) {.
  importc: "$1", header: "atomic.h".}



## *
##  @brief Atomically set a bit to a given value.
##
##  Atomically set bit number @a bit of @a target to value @a val.
##  The target may be a single atomic variable or an array of them.
##
##  @param target Address of atomic variable or array.
##  @param bit Bit number (starting from 0).
##  @param val true for 1, false for 0.
##
##  @return N/A
##
proc atomic_set_bit_to*(target: ptr atomic_t; bit: cint; val: bool) {.
  importc: "$1", header: "atomic.h".}

