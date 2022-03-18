## * @file
##  @brief Routines for network subsystem initialization.
##
##
##  Copyright (c) 2017 Intel Corporation
##
##  SPDX-License-Identifier: Apache-2.0
##

## *
##  @brief Network configuration library
##  @defgroup net_config Network Configuration Library
##  @ingroup networking
##  @{
##
##  Flags that tell what kind of functionality is needed by the client.
## *
##  @brief Application needs routers to be set so that connectivity to remote
##  network is possible. For IPv6 networks, this means that the device should
##  receive IPv6 router advertisement message before continuing.
##

import ../zdevice
import znet_if

const hdr = "<net/net_config.h>"

const
  NET_CONFIG_NEED_ROUTER* = 0x00000001

## *
##  @brief Application needs IPv6 subsystem configured and initialized.
##  Typically this means that the device has IPv6 address set.
##

const
  NET_CONFIG_NEED_IPV6* = 0x00000002

## *
##  @brief Application needs IPv4 subsystem configured and initialized.
##  Typically this means that the device has IPv4 address set.
##

const
  NET_CONFIG_NEED_IPV4* = 0x00000004

## *
##  @brief Initialize this network application.
##
##  @details This will call net_config_init_by_iface() with NULL network
##           interface.
##
##  @param app_info String describing this application.
##  @param flags Flags related to services needed by the client.
##  @param timeout How long to wait the network setup before continuing
##  the startup.
##
##  @return 0 if ok, <0 if error.
##

proc net_config_init*(app_info: cstring; flags: uint32; timeout: int32): cint {.
    importc: "net_config_init", header: hdr.}

## *
##  @brief Initialize this network application using a specific network
##  interface.
##
##  @details If network interface is set to NULL, then the default one
##           is used in the configuration.
##
##  @param iface Initialize networking using this network interface.
##  @param app_info String describing this application.
##  @param flags Flags related to services needed by the client.
##  @param timeout How long to wait the network setup before continuing
##  the startup.
##
##  @return 0 if ok, <0 if error.
##

proc net_config_init_by_iface*(iface: ptr net_if; app_info: cstring; flags: uint32;
                              timeout: int32): cint {.
    importc: "net_config_init_by_iface", header: hdr.}

## *
##  @brief Initialize this network application.
##
##  @details If CONFIG_NET_CONFIG_AUTO_INIT is set, then this function is called
##           automatically when the device boots. If that is not desired, unset
##           the config option and call the function manually when the
##           application starts.
##
##  @param dev Network device to use. The function will figure out what
##         network interface to use based on the device. If the device is NULL,
##         then default network interface is used by the function.
##  @param app_info String describing this application.
##
##  @return 0 if ok, <0 if error.
##

proc net_config_init_app*(dev: ptr device; app_info: cstring): cint {.
    importc: "net_config_init_app", header: hdr.}

## *
##  @}
##
