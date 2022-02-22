## * @file
##  @brief Network core definitions
##
##  Definitions for networking support.
##
##
##  Copyright (c) 2015 Intel Corporation
##
##  SPDX-License-Identifier: Apache-2.0
##

## *
##  @brief Networking
##  @defgroup networking Networking
##  @{
##  @}
##
## *
##  @brief Network core library
##  @defgroup net_core Network Core Library
##  @ingroup networking
##  @{
##
## * @cond INTERNAL_HIDDEN
##  Network subsystem logging helpers

when defined(CONFIG_THREAD_NAME):
  proc NET_DBG*(fmt: untyped) {.varargs, importc: "NET_DBG", header: "net_core.h".}
else:
  proc NET_DBG*(fmt: untyped) {.varargs, importc: "NET_DBG", header: "net_core.h".}
proc NET_ERR*(fmt: untyped) {.varargs, importc: "NET_ERR", header: "net_core.h".}
proc NET_WARN*(fmt: untyped) {.varargs, importc: "NET_WARN", header: "net_core.h".}
proc NET_INFO*(fmt: untyped) {.varargs, importc: "NET_INFO", header: "net_core.h".}
proc NET_HEXDUMP_DBG*(_data: untyped; _length: untyped; _str: untyped) {.
    importc: "NET_HEXDUMP_DBG", header: "net_core.h".}
proc NET_HEXDUMP_ERR*(_data: untyped; _length: untyped; _str: untyped) {.
    importc: "NET_HEXDUMP_ERR", header: "net_core.h".}
proc NET_HEXDUMP_WARN*(_data: untyped; _length: untyped; _str: untyped) {.
    importc: "NET_HEXDUMP_WARN", header: "net_core.h".}
proc NET_HEXDUMP_INFO*(_data: untyped; _length: untyped; _str: untyped) {.
    importc: "NET_HEXDUMP_INFO", header: "net_core.h".}
##  This needs to be here in order to avoid circular include dependency between
##  net_pkt.h and net_if.h
##

when defined(CONFIG_NET_PKT_TXTIME_STATS_DETAIL) or
    defined(CONFIG_NET_PKT_RXTIME_STATS_DETAIL):
  when not defined(NET_PKT_DETAIL_STATS_COUNT):
    when defined(CONFIG_NET_PKT_TXTIME_STATS_DETAIL):
      when defined(CONFIG_NET_PKT_RXTIME_STATS_DETAIL):
        var NET_PKT_DETAIL_STATS_COUNT* {.importc: "NET_PKT_DETAIL_STATS_COUNT",
                                        header: "net_core.h".}: int
      else:
        var NET_PKT_DETAIL_STATS_COUNT* {.importc: "NET_PKT_DETAIL_STATS_COUNT",
                                        header: "net_core.h".}: int
    else:
      var NET_PKT_DETAIL_STATS_COUNT* {.importc: "NET_PKT_DETAIL_STATS_COUNT",
                                      header: "net_core.h".}: int
## * @endcond

discard "forward decl of net_buf"
discard "forward decl of net_pkt"
discard "forward decl of net_context"
discard "forward decl of net_if"
type
  net_verdict* {.size: sizeof(cint).} = enum ## * Packet has been taken care of.
    NET_OK, ## * Packet has not been touched, other part should decide about its
           ##  fate.
           ##
    NET_CONTINUE,             ## * Packet must be dropped.
    NET_DROP


## *
##  @brief Called by lower network stack or network device driver when
##  a network packet has been received. The function will push the packet up in
##  the network stack for further processing.
##
##  @param iface Network interface where the packet was received.
##  @param pkt Network packet data.
##
##  @return 0 if ok, <0 if error.
##

proc net_recv_data*(iface: ptr net_if; pkt: ptr net_pkt): cint {.
    importc: "net_recv_data", header: "net_core.h".}
## *
##  @brief Send data to network.
##
##  @details Send data to network. This should not be used normally by
##  applications as it requires that the network packet is properly
##  constructed.
##
##  @param pkt Network packet.
##
##  @return 0 if ok, <0 if error. If <0 is returned, then the caller needs
##  to unref the pkt in order to avoid memory leak.
##

proc net_send_data*(pkt: ptr net_pkt): cint {.importc: "net_send_data",
    header: "net_core.h".}
## * @cond INTERNAL_HIDDEN
##  Some helper defines for traffic class support

when defined(CONFIG_NET_TC_TX_COUNT) and defined(CONFIG_NET_TC_RX_COUNT):
  var NET_TC_TX_COUNT* {.importc: "NET_TC_TX_COUNT", header: "net_core.h".}: int
  when NET_TC_TX_COUNT > NET_TC_RX_COUNT:
    var NET_TC_COUNT* {.importc: "NET_TC_COUNT", header: "net_core.h".}: int
  else:
    var NET_TC_COUNT* {.importc: "NET_TC_COUNT", header: "net_core.h".}: int
else:
  var NET_TC_TX_COUNT* {.importc: "NET_TC_TX_COUNT", header: "net_core.h".}: int
##  @endcond
## *
##  @}
##
