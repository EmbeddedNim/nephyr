# ==================== Here for reference, unusef ===============================

{.error: "not supported ".}

##  #if CONFIG_NET_DHCPV4) && defined(CONFIG_NET_NATIVE_IPV4
##  #define NET_IF_DHCPV4_INIT .dhcpv4.state = NET_DHCPV4_DISABLED,
##  #else
##  #define NET_IF_DHCPV4_INIT
##  #endif

proc NET_IF_GET*(dev_name: untyped; sfx: untyped) {.importc: "NET_IF_GET",
    header: "net_if.h".}

proc NET_IF_INIT*(dev_name: untyped; sfx: untyped; _l2: untyped; _mtu: untyped;
                 _num_configs: untyped) {.importc: "NET_IF_INIT", header: "net_if.h".}
proc NET_IF_OFFLOAD_INIT*(dev_name: untyped; sfx: untyped; _mtu: untyped) {.
    importc: "NET_IF_OFFLOAD_INIT", header: "net_if.h".}


## * @endcond
##  Network device initialization macros

proc Z_NET_DEVICE_INIT*(node_id: untyped; dev_name: untyped; drv_name: untyped;
                       init_fn: untyped; pm_control_fn: untyped; data: untyped;
                       cfg: untyped; prio: untyped; api: untyped; l2: untyped;
                       l2_ctx_type: untyped; mtu: untyped) {.
    importc: "Z_NET_DEVICE_INIT", header: "net_if.h".}


## *
##  @def NET_DEVICE_INIT
##
##  @brief Create a network interface and bind it to network device.
##
##  @param dev_name Network device name.
##  @param drv_name The name this instance of the driver exposes to
##  the system.
##  @param init_fn Address to the init function of the driver.
##  @param pm_control_fn Pointer to pm_control function.
##  Can be NULL if not implemented.
##  @param data Pointer to the device's private data.
##  @param cfg The address to the structure containing the
##  configuration information for this instance of the driver.
##  @param prio The initialization level at which configuration occurs.
##  @param api Provides an initial pointer to the API function struct
##  used by the driver. Can be NULL.
##  @param l2 Network L2 layer for this network interface.
##  @param l2_ctx_type Type of L2 context data.
##  @param mtu Maximum transfer unit in bytes for this network interface.
##

proc NET_DEVICE_INIT*(dev_name: untyped; drv_name: untyped; init_fn: untyped;
                     pm_control_fn: untyped; data: untyped; cfg: untyped;
                     prio: untyped; api: untyped; l2: untyped; l2_ctx_type: untyped;
                     mtu: untyped) {.importc: "NET_DEVICE_INIT", header: "net_if.h".}


## *
##  @def NET_DEVICE_DT_DEFINE
##
##  @brief Like NET_DEVICE_INIT but taking metadata from a devicetree node.
##  Create a network interface and bind it to network device.
##
##  @param node_id The devicetree node identifier.
##  @param init_fn Address to the init function of the driver.
##  @param pm_control_fn Pointer to pm_control function.
##  Can be NULL if not implemented.
##  @param data Pointer to the device's private data.
##  @param cfg The address to the structure containing the
##  configuration information for this instance of the driver.
##  @param prio The initialization level at which configuration occurs.
##  @param api Provides an initial pointer to the API function struct
##  used by the driver. Can be NULL.
##  @param l2 Network L2 layer for this network interface.
##  @param l2_ctx_type Type of L2 context data.
##  @param mtu Maximum transfer unit in bytes for this network interface.
##

proc NET_DEVICE_DT_DEFINE*(node_id: untyped; init_fn: untyped;
                          pm_control_fn: untyped; data: untyped; cfg: untyped;
                          prio: untyped; api: untyped; l2: untyped;
                          l2_ctx_type: untyped; mtu: untyped) {.
    importc: "NET_DEVICE_DT_DEFINE", header: "net_if.h".}


## *
##  @def NET_DEVICE_DT_INST_DEFINE
##
##  @brief Like NET_DEVICE_DT_DEFINE for an instance of a DT_DRV_COMPAT compatible
##
##  @param inst instance number.  This is replaced by
##  <tt>DT_DRV_COMPAT(inst)</tt> in the call to NET_DEVICE_DT_DEFINE.
##
##  @param ... other parameters as expected by NET_DEVICE_DT_DEFINE.
##

proc NET_DEVICE_DT_INST_DEFINE*(inst: untyped) {.varargs,
    importc: "NET_DEVICE_DT_INST_DEFINE", header: "net_if.h".}
proc Z_NET_DEVICE_INIT_INSTANCE*(node_id: untyped; dev_name: untyped;
                                drv_name: untyped; instance: untyped;
                                init_fn: untyped; pm_control_fn: untyped;
                                data: untyped; cfg: untyped; prio: untyped;
                                api: untyped; l2: untyped; l2_ctx_type: untyped;
                                mtu: untyped) {.
    importc: "Z_NET_DEVICE_INIT_INSTANCE", header: "net_if.h".}


## *
##  @def NET_DEVICE_INIT_INSTANCE
##
##  @brief Create multiple network interfaces and bind them to network device.
##  If your network device needs more than one instance of a network interface,
##  use this macro below and provide a different instance suffix each time
##  (0, 1, 2, ... or a, b, c ... whatever works for you)
##
##  @param dev_name Network device name.
##  @param drv_name The name this instance of the driver exposes to
##  the system.
##  @param instance Instance identifier.
##  @param init_fn Address to the init function of the driver.
##  @param pm_control_fn Pointer to pm_control function.
##  Can be NULL if not implemented.
##  @param data Pointer to the device's private data.
##  @param cfg The address to the structure containing the
##  configuration information for this instance of the driver.
##  @param prio The initialization level at which configuration occurs.
##  @param api Provides an initial pointer to the API function struct
##  used by the driver. Can be NULL.
##  @param l2 Network L2 layer for this network interface.
##  @param l2_ctx_type Type of L2 context data.
##  @param mtu Maximum transfer unit in bytes for this network interface.
##

proc NET_DEVICE_INIT_INSTANCE*(dev_name: untyped; drv_name: untyped;
                              instance: untyped; init_fn: untyped;
                              pm_control_fn: untyped; data: untyped; cfg: untyped;
                              prio: untyped; api: untyped; l2: untyped;
                              l2_ctx_type: untyped; mtu: untyped) {.
    importc: "NET_DEVICE_INIT_INSTANCE", header: "net_if.h".}


## *
##  @def NET_DEVICE_DT_DEFINE_INSTANCE
##
##  @brief Like NET_DEVICE_OFFLOAD_INIT but taking metadata from a devicetree.
##  Create multiple network interfaces and bind them to network device.
##  If your network device needs more than one instance of a network interface,
##  use this macro below and provide a different instance suffix each time
##  (0, 1, 2, ... or a, b, c ... whatever works for you)
##
##  @param node_id The devicetree node identifier.
##  @param instance Instance identifier.
##  @param init_fn Address to the init function of the driver.
##  @param pm_control_fn Pointer to pm_control function.
##  Can be NULL if not implemented.
##  @param data Pointer to the device's private data.
##  @param cfg The address to the structure containing the
##  configuration information for this instance of the driver.
##  @param prio The initialization level at which configuration occurs.
##  @param api Provides an initial pointer to the API function struct
##  used by the driver. Can be NULL.
##  @param l2 Network L2 layer for this network interface.
##  @param l2_ctx_type Type of L2 context data.
##  @param mtu Maximum transfer unit in bytes for this network interface.
##

proc NET_DEVICE_DT_DEFINE_INSTANCE*(node_id: untyped; instance: untyped;
                                   init_fn: untyped; pm_control_fn: untyped;
                                   data: untyped; cfg: untyped; prio: untyped;
                                   api: untyped; l2: untyped; l2_ctx_type: untyped;
                                   mtu: untyped) {.
    importc: "NET_DEVICE_DT_DEFINE_INSTANCE", header: "net_if.h".}


## *
##  @def NET_DEVICE_DT_INST_DEFINE_INSTANCE
##
##  @brief Like NET_DEVICE_DT_DEFINE_INSTANCE for an instance of a DT_DRV_COMPAT
##  compatible
##
##  @param inst instance number.  This is replaced by
##  <tt>DT_DRV_COMPAT(inst)</tt> in the call to NET_DEVICE_DT_DEFINE_INSTANCE.
##
##  @param ... other parameters as expected by NET_DEVICE_DT_DEFINE_INSTANCE.
##

proc NET_DEVICE_DT_INST_DEFINE_INSTANCE*(inst: untyped) {.varargs,
    importc: "NET_DEVICE_DT_INST_DEFINE_INSTANCE", header: "net_if.h".}
proc Z_NET_DEVICE_OFFLOAD_INIT*(node_id: untyped; dev_name: untyped;
                               drv_name: untyped; init_fn: untyped;
                               pm_control_fn: untyped; data: untyped; cfg: untyped;
                               prio: untyped; api: untyped; mtu: untyped) {.
    importc: "Z_NET_DEVICE_OFFLOAD_INIT", header: "net_if.h".}


## *
##  @def NET_DEVICE_OFFLOAD_INIT
##
##  @brief Create a offloaded network interface and bind it to network device.
##  The offloaded network interface is implemented by a device vendor HAL or
##  similar.
##
##  @param dev_name Network device name.
##  @param drv_name The name this instance of the driver exposes to
##  the system.
##  @param init_fn Address to the init function of the driver.
##  @param pm_control_fn Pointer to pm_control function.
##  Can be NULL if not implemented.
##  @param data Pointer to the device's private data.
##  @param cfg The address to the structure containing the
##  configuration information for this instance of the driver.
##  @param prio The initialization level at which configuration occurs.
##  @param api Provides an initial pointer to the API function struct
##  used by the driver. Can be NULL.
##  @param mtu Maximum transfer unit in bytes for this network interface.
##

proc NET_DEVICE_OFFLOAD_INIT*(dev_name: untyped; drv_name: untyped; init_fn: untyped;
                             pm_control_fn: untyped; data: untyped; cfg: untyped;
                             prio: untyped; api: untyped; mtu: untyped) {.
    importc: "NET_DEVICE_OFFLOAD_INIT", header: "net_if.h".}


## *
##  @def NET_DEVICE_DT_OFFLOAD_DEFINE
##
##  @brief Like NET_DEVICE_OFFLOAD_INIT but taking metadata from a devicetree
##  node. Create a offloaded network interface and bind it to network device.
##  The offloaded network interface is implemented by a device vendor HAL or
##  similar.
##
##  @param node_id The devicetree node identifier.
##  @param init_fn Address to the init function of the driver.
##  @param pm_control_fn Pointer to pm_control function.
##  Can be NULL if not implemented.
##  @param data Pointer to the device's private data.
##  @param cfg The address to the structure containing the
##  configuration information for this instance of the driver.
##  @param prio The initialization level at which configuration occurs.
##  @param api Provides an initial pointer to the API function struct
##  used by the driver. Can be NULL.
##  @param mtu Maximum transfer unit in bytes for this network interface.
##

proc NET_DEVICE_DT_OFFLOAD_DEFINE*(node_id: untyped; init_fn: untyped;
                                  pm_control_fn: untyped; data: untyped;
                                  cfg: untyped; prio: untyped; api: untyped;
                                  mtu: untyped) {.
    importc: "NET_DEVICE_DT_OFFLOAD_DEFINE", header: "net_if.h".}


## *
##  @def NET_DEVICE_DT_INST_OFFLOAD_DEFINE
##
##  @brief Like NET_DEVICE_DT_OFFLOAD_DEFINE for an instance of a DT_DRV_COMPAT
##  compatible
##
##  @param inst instance number.  This is replaced by
##  <tt>DT_DRV_COMPAT(inst)</tt> in the call to NET_DEVICE_DT_OFFLOAD_DEFINE.
##
##  @param ... other parameters as expected by NET_DEVICE_DT_OFFLOAD_DEFINE.
##

proc NET_DEVICE_DT_INST_OFFLOAD_DEFINE*(inst: untyped) {.varargs,
    importc: "NET_DEVICE_DT_INST_OFFLOAD_DEFINE", header: "net_if.h".}


## *
##  @}
##