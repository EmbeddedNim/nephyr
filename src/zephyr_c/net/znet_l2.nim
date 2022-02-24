##
##  Copyright (c) 2016 Intel Corporation.
##
##  SPDX-License-Identifier: Apache-2.0
##
## *
##  @file
##  @brief Public API for network L2 interface
##

## *
##  @brief Network Layer 2 abstraction layer
##  @defgroup net_l2 Network L2 Abstraction Layer
##  @ingroup networking
##  @{
##

import ../wrapper_utils
import ../zdevice
import znet_core

const hdr = "<net/net_l2.h>"

type
  net_l2_flags* {.size: sizeof(cint).} = enum ## * IP multicast supported
    NET_L2_MULTICAST = BIT(0),  ## * Do not joint solicited node multicast group
    NET_L2_MULTICAST_SKIP_JOIN_SOLICIT_NODE = BIT(1), ## * Is promiscuous mode supported
    NET_L2_PROMISC_MODE = BIT(2), ## * Is this L2 point-to-point with tunneling so no need to have
                               ##  IP address etc to network interface.
                               ##
    NET_L2_POINT_TO_POINT = BIT(3)

## *
##  @brief Network L2 structure
##
##  Used to provide an interface to lower network stack.
##

type
  net_l2* {.importc: "struct net_l2", header: hdr, bycopy.} = object

    recv* {.importc: "recv".}: proc (iface: ptr net_if_alias; pkt: ptr net_pkt_alias): net_verdict ##\
      ##  This function is used by net core to get iface's L2 layer parsing
      ##  what's relevant to itself.
      ##
    send* {.importc: "send".}: proc (iface: ptr net_if_alias; pkt: ptr net_pkt_alias): cint ##\
      ## *
      ##  This function is used by net core to push a packet to lower layer
      ##  (interface's L2), which in turn might work on the packet relevantly.
      ##  (adding proper header etc...)
      ##  Returns a negative error code, or the number of bytes sent otherwise.
      ##
    enable* {.importc: "enable".}: proc (iface: ptr net_if_alias; state: bool): cint ##\
      ##  This function is used to enable/disable traffic over a network
      ##  interface. The function returns <0 if error and >=0 if no error.
      ##
    get_flags* {.importc: "get_flags".}: proc (iface: ptr net_if_alias): net_l2_flags ## *\
      ##  Return L2 flags for the network interface.
      ##

  net_l2_send_t* = proc (dev: ptr device; pkt: ptr net_pkt_alias): cint

##  /** @cond INTERNAL_HIDDEN */
##  #define NET_L2_GET_NAME(_name) _net_l2_##_name
##  #define NET_L2_DECLARE_PUBLIC(_name)					\
##  	extern const struct net_l2 NET_L2_GET_NAME(_name)
##  #define NET_L2_GET_CTX_TYPE(_name) _name##_CTX_TYPE
##  #ifdef CONFIG_NET_L2_VIRTUAL
##  #define VIRTUAL_L2		VIRTUAL
##  NET_L2_DECLARE_PUBLIC(VIRTUAL_L2);
##  #endif /* CONFIG_NET_L2_DUMMY */
##  #ifdef CONFIG_NET_L2_DUMMY
##  #define DUMMY_L2		DUMMY
##  #define DUMMY_L2_CTX_TYPE	void*
##  NET_L2_DECLARE_PUBLIC(DUMMY_L2);
##  #endif /* CONFIG_NET_L2_DUMMY */
##  #ifdef CONFIG_NET_L2_ETHERNET
##  #define ETHERNET_L2		ETHERNET
##  NET_L2_DECLARE_PUBLIC(ETHERNET_L2);
##  #endif /* CONFIG_NET_L2_ETHERNET */
##  #ifdef CONFIG_NET_L2_PPP
##  #define PPP_L2			PPP
##  NET_L2_DECLARE_PUBLIC(PPP_L2);
##  #endif /* CONFIG_NET_L2_PPP */
##  #ifdef CONFIG_NET_L2_IEEE802154
##  #define IEEE802154_L2		IEEE802154
##  NET_L2_DECLARE_PUBLIC(IEEE802154_L2);
##  #endif /* CONFIG_NET_L2_IEEE802154 */
##  #ifdef CONFIG_NET_L2_BT
##  #define BLUETOOTH_L2		BLUETOOTH
##  #define BLUETOOTH_L2_CTX_TYPE	void*
##  NET_L2_DECLARE_PUBLIC(BLUETOOTH_L2);
##  #endif /* CONFIG_NET_L2_BT */
##  #ifdef CONFIG_NET_L2_OPENTHREAD
##  #define OPENTHREAD_L2		OPENTHREAD
##  NET_L2_DECLARE_PUBLIC(OPENTHREAD_L2);
##  #endif /* CONFIG_NET_L2_OPENTHREAD */
##  #ifdef CONFIG_NET_L2_CANBUS_RAW
##  #define CANBUS_RAW_L2		CANBUS_RAW
##  #define CANBUS_RAW_L2_CTX_TYPE	void*
##  NET_L2_DECLARE_PUBLIC(CANBUS_RAW_L2);
##  #endif /* CONFIG_NET_L2_CANBUS_RAW */
##  #ifdef CONFIG_NET_L2_CANBUS
##  #define CANBUS_L2		CANBUS
##  NET_L2_DECLARE_PUBLIC(CANBUS_L2);
##  #endif /* CONFIG_NET_L2_CANBUS */

# proc NET_L2_INIT*(name: untyped; _recv_fn: untyped; _send_fn: untyped;
#                  _enable_fn: untyped; _get_flags_fn: untyped) {.
#     importc: "NET_L2_INIT", header: hdr.}
# proc NET_L2_GET_DATA*(name: untyped; sfx: untyped) {.importc: "NET_L2_GET_DATA",
#     header: hdr.}
# proc NET_L2_DATA_INIT*(name: untyped; sfx: untyped; ctx_type: untyped) {.
#     importc: "NET_L2_DATA_INIT", header: hdr.}

proc net_l2_send*(send_fn: net_l2_send_t,
                  dev: ptr device,
                  iface: ptr net_if_alias,
                  pkt: ptr net_pkt_alias
                  ): cint {.importc: "$1", header: "<net/net_l2.h>".}

## * @endcond
## *
##  @}
##
