##
##  Copyright (c) 2015 Intel Corporation.
##
##  SPDX-License-Identifier: Apache-2.0
##

## *
##  @brief Device Driver APIs
##  @defgroup io_interfaces Device Driver APIs
##  @{
##  @}
##
## *
##  @brief Miscellaneous Drivers APIs
##  @defgroup misc_interfaces Miscellaneous Drivers APIs
##  @ingroup io_interfaces
##  @{
##  @}
##
## *
##  @brief Device Model APIs
##  @defgroup device_model Device Model APIs
##  @{
##

## * @brief Type used to represent devices and functions.
##
##  The extreme values and zero have special significance.  Negative
##  values identify functionality that does not correspond to a Zephyr
##  device, such as the system clock or a SYS_INIT() function.
##

import wrapper_utils

type
  device_handle_t* = int16

## * @brief Flag value used in lists of device handles to separate
##  distinct groups.
##
##  This is the minimum value for the device_handle_t type.
##

const
  DEVICE_HANDLE_SEP* = low(device_handle_t)

## * @brief Flag value used in lists of device handles to indicate the
##  end of the list.
##
##  This is the maximum value for the device_handle_t type.
##

const
  DEVICE_HANDLE_ENDS* = high(device_handle_t)

const
  DEVICE_HANDLE_NULL* = 0
  Z_DEVICE_MAX_NAME_LEN* = 48

type
  zp_data_ptr* = distinct pointer
  zp_config_ptr* = distinct pointer
  zp_api_ptr* = distinct pointer

  init_func_cb* = proc (dev: ptr device): cint {.cdecl.}

  pm_device_cb* = proc (dev: ptr device, status: int, state: uint32, arg: pointer): void {.cdecl.}

  pm_control_cb* = proc (port: ptr device; ctrl_command: uint32; context: ptr uint32;
                        cb: pm_device_cb; arg: pointer): cint  {.cdecl.}

  device_state* {.importc: "struct device_state", header: "device.h", bycopy.} = object ## *
      ##  @brief Runtime device dynamic structure (in RAM) per driver instance
      ##
      ##  Fields in this are expected to be default-initialized to zero.  The
      ##  kernel driver infrastructure and driver access functions are
      ##  responsible for ensuring that any non-zero initialization is done
      ##  before they are accessed.
      ##

    init_res* {.importc: "init_res", bitsize: 8.}: uint8 ##
        ## * Non-negative result of initializing the device.
        ##
        ##  The absolute value returned when the device initialization
        ##  function was invoked, or `UINT8_MAX` if the value exceeds
        ##  an 8-bit integer.  If initialized is also set, a zero value
        ##  indicates initialization succeeded.
        ##
    initialized* {.importc: "initialized", bitsize: 1.}: bool ##
        ## * Indicates the device initialization function has been
        ##  invoked.
        ##
    when defined(CONFIG_PM_DEVICE):
      ##  Power management data
      pm* {.header: "device.h".}: pm_device

  device* {.importc: "struct device", header: "device.h", bycopy.} = object ##
      ## *
      ##  @brief Runtime device structure (in ROM) per driver instance
      ##
    name* {.importc: "name".}: cstring ## * Name of the device instance
    ## * Address of device instance config information
    config* {.importc: "config".}: pointer ## * Address of the API structure exposed by the device instance
    api* {.importc: "api".}: pointer ## * Address of the common device state
    state* {.importc: "state".}: ptr device_state ## * Address of the device instance private data
    data* {.importc: "data".}: pointer ## * optional pointer to handles associated with the device.
                                   ##
                                   ##  This encodes a sequence of sets of device handles that have
                                   ##  some relationship to this node.  The individual sets are
                                   ##  extracted with dedicated API, such as
                                   ##  device_required_handles_get().
                                   ##
    handles* {.importc: "handles".}: ptr device_handle_t
    when defined(CONFIG_PM_DEVICE):
      ## * Power Management function
      pm_control*: proc (dev: ptr device; command: uint32; state: ptr uint32;
                          cb: pm_device_cb; arg: pointer): cint
      ## * Pointer to device instance power management data
      pm* {.header: "device.h".}: ptr pm_device


## *
##  @def DEVICE_NAME_GET
##
##  @brief Expands to the full name of a global device object
##
##  @details Return the full name of a device object symbol created by
##  DEVICE_DEFINE(), using the dev_name provided to DEVICE_DEFINE().
##
##  It is meant to be used for declaring extern symbols pointing on device
##  objects before using the DEVICE_GET macro to get the device object.
##
##  @param name The same as dev_name provided to DEVICE_DEFINE()
##
##  @return The expanded name of the device object created by DEVICE_DEFINE()
##

proc DEVICE_NAME_GET*(name: string): ptr device {.importc: "DEVICE_NAME_GET", header: "device.h".}




## *
##  @def SYS_DEVICE_DEFINE
##
##  @brief Run an initialization function at boot at specified priority,
##  and define device PM control function.
##
##  @details Invokes DEVICE_DEFINE() with no power management support
##  (@p pm_control_fn), no API (@p api_ptr), and a device name derived from
##  the @p init_fn name (@p dev_name).
##

proc SYS_DEVICE_DEFINE*(drv_name: cstring;
                        init_fn: init_func_cb;
                        pm_control_fn: pm_control_cb;
                        level: cmtoken;
                        prio: cmtoken) {.
    importc: "SYS_DEVICE_DEFINE", header: "device.h".}



## *
##  @def DEVICE_INIT
##
##  @brief Invoke DEVICE_DEFINE() with no power management support (@p
##  pm_control_fn) and no API (@p api_ptr).
##

## *
##  @def DEVICE_AND_API_INIT
##
##  @brief Invoke DEVICE_DEFINE() with no power management support (@p
##  pm_control_fn).
##

## *
##  @def DEVICE_DEFINE
##
##  @brief Create device object and set it up for boot time initialization,
##  with the option to pm_control. In case of Device Idle Power
##  Management is enabled, make sure the device is in suspended state after
##  initialization.
##
##  @details This macro defines a device object that is automatically
##  configured by the kernel during system initialization. Note that
##  devices set up with this macro will not be accessible from user mode
##  since the API is not specified;
##
##  @param dev_name Device name. This must be less than Z_DEVICE_MAX_NAME_LEN
##  characters (including terminating NUL) in order to be looked up from user
##  mode with device_get_binding().
##
##  @param drv_name The name this instance of the driver exposes to
##  the system.
##
##  @param init_fn Address to the init function of the driver.
##
##  @param pm_control_fn Pointer to pm_control function.
##  Can be NULL if not implemented.
##
##  @param data_ptr Pointer to the device's private data.
##
##  @param cfg_ptr The address to the structure containing the
##  configuration information for this instance of the driver.
##
##  @param level The initialization level.  See SYS_INIT() for
##  details.
##
##  @param prio Priority within the selected initialization level. See
##  SYS_INIT() for details.
##
##  @param api_ptr Provides an initial pointer to the API function struct
##  used by the driver. Can be NULL.
##

proc DEVICE_DEFINE*(dev_name: cminvtoken;
                    drv_name: cstring;
                    init_fn: init_func_cb;
                    pm_control_fn: pm_control_cb;
                    data_ptr: zp_data_ptr;
                    cfg_ptr: zp_config_ptr;
                    level: cminvtoken;
                    prio: cminvtoken;
                    api_ptr: zp_api_ptr) {.
    importc: "DEVICE_DEFINE", header: "device.h".}


  # Z_DEVICE_DEFINE(DT_INVALID_NODE, dev_name, drv_name, init_fn,  \
      # pm_control_fn,          \
      # data_ptr, cfg_ptr, level, prio, api_ptr)


## *
##  @def DEVICE_DT_NAME
##
##  @brief Return a string name for a devicetree node.
##
##  @details This macro returns a string literal usable as a device name
##  from a devicetree node. If the node has a "label" property, its value is
##  returned. Otherwise, the node's full "node-name@@unit-address" name is
##  returned.
##
##  @param node_id The devicetree node identifier.
##

proc DEVICE_DT_NAME*(node_id: cminvtoken) {.importc: "DEVICE_DT_NAME",
                                      header: "device.h".}



## *
##  @def DEVICE_DT_DEFINE
##
##  @brief Like DEVICE_DEFINE but taking metadata from a devicetree node.
##
##  @details This macro defines a device object that is automatically
##  configured by the kernel during system initialization.  The device
##  object name is derived from the node identifier (encoding the
##  devicetree path to the node), and the driver name is from the @p
##  label property of the devicetree node.
##
##  The device is declared with extern visibility, so device objects
##  defined through this API can be obtained directly through
##  DEVICE_DT_GET() using @p node_id.  Before using the pointer the
##  referenced object should be checked using device_is_ready().
##
##  @param node_id The devicetree node identifier.
##
##  @param init_fn Address to the init function of the driver.
##
##  @param pm_control_fn Pointer to pm_control function.
##  Can be NULL if not implemented.
##
##  @param data_ptr Pointer to the device's private data.
##
##  @param cfg_ptr The address to the structure containing the
##  configuration information for this instance of the driver.
##
##  @param level The initialization level.  See SYS_INIT() for
##  details.
##
##  @param prio Priority within the selected initialization level. See
##  SYS_INIT() for details.
##
##  @param api_ptr Provides an initial pointer to the API function struct
##  used by the driver. Can be NULL.
##

proc DEVICE_DT_DEFINE*(node_id: cminvtoken;
                       init_fn: init_func_cb;
                       pm_control_fn: pm_control_cb;
                       data_ptr: zp_data_ptr;
                       cfg_ptr: zp_config_ptr;
                       level: cminvtoken;
                       prio: cminvtoken;
                       api_ptr: zp_api_ptr) {.varargs,
    importc: "DEVICE_DT_DEFINE", header: "device.h".}



## *
##  @def DEVICE_DT_INST_DEFINE
##
##  @brief Like DEVICE_DT_DEFINE for an instance of a DT_DRV_COMPAT compatible
##
##  @param inst instance number.  This is replaced by
##  <tt>DT_DRV_COMPAT(inst)</tt> in the call to DEVICE_DT_DEFINE.
##
##  @param ... other parameters as expected by DEVICE_DT_DEFINE.
##

proc DEVICE_DT_INST_DEFINE*(inst: cminvtoken;
                            node_id: cminvtoken;
                            init_fn: init_func_cb;
                            pm_control_fn: pm_control_cb;
                            data_ptr: zp_data_ptr;
                            cfg_ptr: zp_config_ptr;
                            level: cminvtoken;
                            prio: cminvtoken;
                            api_ptr: zp_api_ptr) {.varargs,
    importc: "DEVICE_DT_INST_DEFINE", header: "device.h".}
    # TODO: possibly swap this out with Nim level macros, for now avoids needing
    #   to wrap the devicetree.h header too much
    # DEVICE_DT_DEFINE(DT_DRV_INST(inst), node_id, init_fn, pm_control_fn, data_ptr, cfg_ptr, level, prio, api_prt)


## *
##  @def DEVICE_DT_NAME_GET
##
##  @brief The name of the struct device object for @p node_id
##
##  @details Return the full name of a device object symbol created by
##  DEVICE_DT_DEFINE(), using the dev_name derived from @p node_id
##
##  It is meant to be used for declaring extern symbols pointing on device
##  objects before using the DEVICE_DT_GET macro to get the device object.
##
##  @param node_id The same as node_id provided to DEVICE_DT_DEFINE()
##
##  @return The expanded name of the device object created by
##  DEVICE_DT_DEFINE()
##

proc DEVICE_DT_NAME_GET*(node_id: cminvtoken): cmtoken {.importc: "DEVICE_DT_NAME_GET",
    header: "device.h".}


## *
##  @def DEVICE_DT_GET
##
##  @brief Obtain a pointer to a device object by @p node_id
##
##  @details Return the address of a device object created by
##  DEVICE_DT_INIT(), using the dev_name derived from @p node_id
##
##  @param node_id The same as node_id provided to DEVICE_DT_DEFINE()
##
##  @return A pointer to the device object created by DEVICE_DT_DEFINE()
##

proc DEVICE_DT_GET*(node_id: cminvtoken): ptr device {.importc: "DEVICE_DT_GET", header: "device.h".}



## * @def DEVICE_DT_INST_GET
##
##  @brief Obtain a pointer to a device object for an instance of a
##         DT_DRV_COMPAT compatible
##
##  @param inst instance number
##

proc DEVICE_DT_INST_GET*(inst: cminvtoken) {.importc: "DEVICE_DT_INST_GET",
                                       header: "device.h".}



## *
##  @def DEVICE_DT_GET_ANY
##
##  @brief Obtain a pointer to a device object by devicetree compatible
##
##  If any enabled devicetree node has the given compatible and a
##  device object was created from it, this returns that device.
##
##  If there no such devices, this returns NULL.
##
##  If there are multiple, this returns an arbitrary one.
##
##  If this returns non-NULL, the device must be checked for readiness
##  before use, e.g. with device_is_ready().
##
##  @param compat lowercase-and-underscores devicetree compatible
##  @return a pointer to a device, or NULL
##

proc DEVICE_DT_GET_ANY*(compat: cminvtoken): ptr device {.importc: "DEVICE_DT_GET_ANY",
                                        header: "device.h".}



## *
##  @def DEVICE_GET
##
##  @brief Obtain a pointer to a device object by name
##
##  @details Return the address of a device object created by
##  DEVICE_DEFINE(), using the dev_name provided to DEVICE_DEFINE().
##
##  @param name The same as dev_name provided to DEVICE_DEFINE()
##
##  @return A pointer to the device object created by DEVICE_DEFINE()
##

proc DEVICE_GET*(name: cminvtoken): ptr device {.importc: "DEVICE_GET", header: "device.h".}



## * @def DEVICE_DECLARE
##
##  @brief Declare a static device object
##
##  This macro can be used at the top-level to declare a device, such
##  that DEVICE_GET() may be used before the full declaration in
##  DEVICE_DEFINE().
##
##  This is often useful when configuring interrupts statically in a
##  device's init or per-instance config function, as the init function
##  itself is required by DEVICE_DEFINE() and use of DEVICE_GET()
##  inside it creates a circular dependency.
##
##  @param name Device name
##

proc DEVICE_DECLARE*(name: cminvtoken) {.importc: "DEVICE_DECLARE", header: "device.h".}




## *
##  @brief Get the handle for a given device
##
##  @param dev the device for which a handle is desired.
##
##  @return the handle for the device, or DEVICE_HANDLE_NULL if the
##  device does not have an associated handle.
##

proc device_handle_get*(dev: ptr device): device_handle_t {.inline, importc: "device_handle_get", header: "device".}




## *
##  @brief Get the device corresponding to a handle.
##
##  @param dev_handle the device handle
##
##  @return the device that has that handle, or a null pointer if @p
##  dev_handle does not identify a device.
##

proc device_from_handle*(dev_handle: device_handle_t): ptr device {.inline,
    importc: "device_from_handle", header: "device.h".}




## *
##  @brief Prototype for functions used when iterating over a set of devices.
##
##  Such a function may be used in API that identifies a set of devices and
##  provides a visitor API supporting caller-specific interaction with each
##  device in the set.
##
##  The visit is said to succeed if the visitor returns a non-negative value.
##
##  @param dev a device in the set being iterated
##
##  @param context state used to support the visitor function
##
##  @return A non-negative number to allow walking to continue, and a negative
##  error code to case the iteration to stop.
##

type
  device_visitor_callback_t* = proc (dev: ptr device; context: pointer): cint




## *
##  @brief Get the set of handles for devicetree dependencies of this device.
##
##  These are the device dependencies inferred from devicetree.
##
##  @param dev the device for which dependencies are desired.
##
##  @param count pointer to a place to store the number of devices provided at
##  the returned pointer.  The value is not set if the call returns a null
##  pointer.  The value may be set to zero.
##
##  @return a pointer to a sequence of @p *count device handles, or a null
##  pointer if @p dh does not provide dependency information.
##

proc device_required_handles_get*(dev: ptr device; count: ptr csize_t): ptr device_handle_t {.
    inline, importc: "device_required_handles_get", header: "device.h".}




## *
##  @brief Visit every device that @p dev directly requires.
##
##  Zephyr maintains information about which devices are directly required by
##  another device; for example an I2C-based sensor driver will require an I2C
##  controller for communication.  Required devices can derive from
##  statically-defined devicetree relationships or dependencies registered
##  at runtime.
##
##  This API supports operating on the set of required devices.  Example uses
##  include making sure required devices are ready before the requiring device
##  is used, and releasing them when the requiring device is no longer needed.
##
##  There is no guarantee on the order in which required devices are visited.
##
##  If the @p visitor function returns a negative value iteration is halted,
##  and the returned value from the visitor is returned from this function.
##
##  @note This API is not available to unprivileged threads.
##
##  @param dev a device of interest.  The devices that this device depends on
##  will be used as the set of devices to visit.  This parameter must not be
##  null.
##
##  @param visitor_cb the function that should be invoked on each device in the
##  dependency set.  This parameter must not be null.
##
##  @param context state that is passed through to the visitor function.  This
##  parameter may be null if @p visitor tolerates a null @p context.
##
##  @return The number of devices that were visited if all visits succeed, or
##  the negative value returned from the first visit that did not succeed.
##

proc device_required_foreach*(dev: ptr device;
                             visitor_cb: device_visitor_callback_t;
                             context: pointer): cint {.
    importc: "device_required_foreach", header: "device.h".}



## *
##  @brief Retrieve the device structure for a driver by name
##
##  @details Device objects are created via the DEVICE_DEFINE() macro and
##  placed in memory by the linker. If a driver needs to bind to another driver
##  it can use this function to retrieve the device structure of the lower level
##  driver by the name the driver exposes to the system.
##
##  @param name device name to search for.  A null pointer, or a pointer to an
##  empty string, will cause NULL to be returned.
##
##  @return pointer to device structure; NULL if not found or cannot be used.
##

proc device_get_binding*(name: cstring): ptr device {.syscall,
    importc: "device_get_binding", header: "device.h".}



## * @brief Get access to the static array of static devices.
##
##  @param devices where to store the pointer to the array of
##  statically allocated devices.  The array must not be mutated
##  through this pointer.
##
##  @return the number of statically allocated devices.
##

proc z_device_get_all_static*(devices: ptr ptr device): csize_t {.
    importc: "z_device_get_all_static", header: "device.h".}



## * @brief Determine whether a device has been successfully initialized.
##
##  @param dev pointer to the device in question.
##
##  @return true if and only if the device is available for use.
##

proc z_device_ready*(dev: ptr device): bool {.importc: "z_device_ready",
    header: "device.h".}



## * @brief Determine whether a device is ready for use
##
##  This is the implementation underlying `device_usable_check()`, without the
##  overhead of a syscall wrapper.
##
##  @param dev pointer to the device in question.
##
##  @return a non-positive integer as documented in device_usable_check().
##

proc z_device_usable_check*(dev: ptr device): cint {.inline,
    importc: "z_device_usable_check", header: "device.h".}



## * @brief Determine whether a device is ready for use.
##
##  This checks whether a device can be used, returning 0 if it can, and
##  distinct error values that identify the reason if it cannot.
##
##  @retval 0 if the device is usable.
##  @retval -ENODEV if the device has not been initialized, the device pointer
##  is NULL or the initialization failed.
##  @retval other negative error codes to indicate additional conditions that
##  make the device unusable.
##

proc device_usable_check*(dev: ptr device): cint {.syscall,
    importc: "device_usable_check", header: "device.h".}

proc z_impl_device_usable_check*(dev: ptr device): cint {.inline,
    importc: "z_impl_device_usable_check", header: "device.h".}




## * @brief Verify that a device is ready for use.
##
##  Indicates whether the provided device pointer is for a device known to be
##  in a state where it can be used with its standard API.
##
##  This can be used with device pointers captured from DEVICE_DT_GET(), which
##  does not include the readiness checks of device_get_binding().  At minimum
##  this means that the device has been successfully initialized, but it may
##  take on further conditions (e.g. is not powered down).
##
##  @param dev pointer to the device in question.
##
##  @retval true if the device is ready for use.
##  @retval false if the device is not ready for use or if a NULL device pointer
##  is passed as argument.
##

proc device_is_ready*(dev: ptr device): bool {.inline, importc: "device_is_ready", header: "device.h".}




## *
##  @brief Indicate that the device is in the middle of a transaction
##
##  Called by a device driver to indicate that it is in the middle of a
##  transaction.
##
##  @param dev Pointer to device structure of the driver instance.
##

proc device_busy_set*(dev: ptr device) {.importc: "device_busy_set",
                                     header: "device.h".}



## *
##  @brief Indicate that the device has completed its transaction
##
##  Called by a device driver to indicate the end of a transaction.
##
##  @param dev Pointer to device structure of the driver instance.
##

proc device_busy_clear*(dev: ptr device) {.importc: "device_busy_clear",
                                       header: "device.h".}



## *
##  @}
##
##  Node paths can exceed the maximum size supported by device_get_binding() in user mode,
##  so synthesize a unique dev_name from the devicetree node.
##
##  The ordinal used in this name can be mapped to the path by
##  examining zephyr/include/generated/device_extern.h header.  If the
##  format of this conversion changes, gen_defines should be updated to
##  match it.
##

proc Z_DEVICE_DT_DEV_NAME*(node_id: cminvtoken) {.importc: "Z_DEVICE_DT_DEV_NAME",
    header: "device.h".}



##  Synthesize a unique name for the device state associated with
##  dev_name.
##

proc Z_DEVICE_STATE_NAME*(dev_name: cminvtoken) {.importc: "Z_DEVICE_STATE_NAME",
    header: "device.h".}



## * Synthesize the name of the object that holds device ordinal and
##  dependency data.  If the object doesn't come from a devicetree
##  node, use dev_name.
##

proc Z_DEVICE_HANDLE_NAME*(node_id: cminvtoken; dev_name: cminvtoken) {.
    importc: "Z_DEVICE_HANDLE_NAME", header: "device.h".}

proc Z_DEVICE_EXTRA_HANDLES*() {.varargs, importc: "Z_DEVICE_EXTRA_HANDLES",
                               header: "device.h".}



##  If device power management is enabled, this macro defines a pointer to a
##  device in the z_pm_device_slots region. When invoked for each device, this
##  will effectively result in a device pointer array with the same size of the
##  actual devices list. This is used internally by the device PM subsystem to
##  keep track of suspended devices during system power transitions.
##

when defined(CONFIG_PM_DEVICE):
  proc Z_DEVICE_DEFINE_PM_SLOT*(dev_name: untyped) {.
      importc: "Z_DEVICE_DEFINE_PM_SLOT", header: "device.h".}



##  Construct objects that are referenced from struct device.  These
##  include power management and dependency handles.
##

proc Z_DEVICE_DEFINE_PRE*(node_id: cminvtoken; dev_name: cminvtoken) {.varargs,
    importc: "Z_DEVICE_DEFINE_PRE", header: "device.h".}



##  Like DEVICE_DEFINE but takes a node_id AND a dev_name, and trailing
##  dependency handles that come from outside devicetree.
##

proc Z_DEVICE_DEFINE*(node_id: cminvtoken;
                      dev_name: cminvtoken;
                      drv_name: cstring;
                      init_fn: init_func_cb;
                      pm_control_fn: pm_control_cb;
                      data_ptr: zp_data_ptr;
                      cfg_ptr: zp_config_ptr;
                      level: cminvtoken;
                      prio: cminvtoken;
                      api_ptr: zp_api_ptr) {.
    varargs, importc: "Z_DEVICE_DEFINE", header: "device.h".}
##  device_extern is generated based on devicetree nodes
