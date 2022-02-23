##
##  Copyright (c) 2016 Intel Corporation.
##
##  SPDX-License-Identifier: Apache-2.0
##


## *
##  @file
##  @brief Public API for network interface
##



## *
##  @brief Network Interface abstraction layer
##  @defgroup net_if Network Interface abstraction layer
##  @ingroup networking
##  @{
##

import ../zkernel_fixes
import ../zconfs
import ../zdevice
import ../kernel/zk_fifo
import ../zkernel

import znet_core
import znet_ip
import znet_l2
import znet_linkaddr
import znet_timeout

import posix

const hdr = "<net/net_if.h>"



## *
##  @brief Network Interface unicast IP addresses
##
##  Stores the unicast IP addresses assigned to this network interface.
##

when CONFIG_NET_NATIVE_IPV6:
  const
    NET_IF_MAX_IPV6_ADDR* = CONFIG_NET_IF_UNICAST_IPV6_ADDR_COUNT
    NET_IF_MAX_IPV6_MADDR* = CONFIG_NET_IF_MCAST_IPV6_ADDR_COUNT
    NET_IF_MAX_IPV6_PREFIX* = CONFIG_NET_IF_IPV6_PREFIX_COUNT
else:
  const
    NET_IF_MAX_IPV6_ADDR* = 0
    NET_IF_MAX_IPV6_MADDR* = 0
    NET_IF_MAX_IPV6_PREFIX* = 0

when CONFIG_NET_NATIVE_IPV4:
  const
    NET_IF_MAX_IPV4_ADDR* = CONFIG_NET_IF_UNICAST_IPV4_ADDR_COUNT
    NET_IF_MAX_IPV4_MADDR* = CONFIG_NET_IF_MCAST_IPV4_ADDR_COUNT
else:
  const
    NET_IF_MAX_IPV4_ADDR* = 0
    NET_IF_MAX_IPV4_MADDR* = 0

const
  NET_IF_MAX_CONFIGS* = 1


type
  net_if_flag* {.size: sizeof(cint).} = enum 
    NET_IF_UP,                ## * Interface is up/ready to receive and transmit
    NET_IF_POINTOPOINT,       ## * Interface is pointopoint
    NET_IF_PROMISC, ## * Interface is in promiscuous mode
    NET_IF_NO_AUTO_START, ## *\
                   ## Do not start the interface immediately after initialization.
                   ##  This requires that either the device driver or some other entity
                   ##  will need to manually take the interface up when needed.
                   ##  For example for Ethernet this will happen when the driver calls
                   ##  the net_eth_carrier_on() function.
                   ##
    NET_IF_SUSPENDED, ## * Power management specific: interface is being suspended
    NET_IF_FORWARD_MULTICASTS, ## * Flag defines if received multicasts of other interface are
                     ##  forwarded on this interface. This activates multicast
                     ##  routing / forwarding for this interface.
                     ##
    NET_IF_IPV4,              ## * Interface supports IPv4
    NET_IF_IPV6,              ## * Interface supports IPv6
    NET_IF_NUM_FLAGS          ##  Total number of flags - must be at the end of the enum

## * @endcond


type
  net_if_addr* {.importc: "net_if_addr", header: hdr, bycopy.} = object
    address* {.importc: "address".}: NetAddr ## * IP address
    when CONFIG_NET_NATIVE_IPV6:
      lifetime* {.importc: "lifetime", header: hdr.}: net_timeout
    when CONFIG_NET_IPV6_DAD and CONFIG_NET_NATIVE_IPV6:
      dad_node* {.importc: "dad_node", header: hdr.}: sys_snode_t ## * Duplicate address detection (DAD) timer
      dad_start* {.importc: "dad_start", header: hdr.}: uint32
    addr_type* {.importc: "addr_type".}: net_addr_type ## * How the IP address was set
    addr_state* {.importc: "addr_state".}: net_addr_state ## * What is the current state of the address
    when CONFIG_NET_IPV6_DAD and CONFIG_NET_NATIVE_IPV6:
      dad_count* {.importc: "dad_count", header: hdr.}: uint8 ## * How many times we have done DAD
    is_infinite* {.importc: "is_infinite", bitsize: 1.}: uint8 ## * Is the IP address valid forever
    is_used* {.importc: "is_used", bitsize: 1.}: uint8 ## * Is this IP address used or not
    is_mesh_local* {.importc: "is_mesh_local", bitsize: 1.}: uint8 ## * Is this IP address usage limited to the subnet (mesh) or not
    unused {.importc: "_unused", bitsize: 5.}: uint8


  net_if_mcast_addr* {.importc: "net_if_mcast_addr", header: hdr, bycopy.} = object
    ##  @brief Network Interface multicast IP addresses
    ##
    ##  Stores the multicast IP addresses assigned to this network interface.
    ##
    address* {.importc: "address".}: NetAddr ## * IP address
    is_used* {.importc: "is_used", bitsize: 1.}: uint8 ## * Is this multicast IP address used or not
    is_joined* {.importc: "is_joined", bitsize: 1.}: uint8 ## * Did we join to this group
    unused {.importc: "_unused", bitsize: 6.}: uint8

  net_if_ipv6_prefix* {.importc: "net_if_ipv6_prefix", header: hdr, bycopy.} = object
    ##  @brief Network Interface IPv6 prefixes
    ##
    ##  Stores the multicast IP addresses assigned to this network interface.
    ##
    lifetime* {.importc: "lifetime".}: net_timeout ## * Prefix lifetime
    prefix* {.importc: "prefix".}: In6Addr ## * IPv6 prefix
    iface* {.importc: "iface".}: ptr net_if_alias ## * Backpointer to network interface where this prefix is used
    len* {.importc: "len".}: uint8 ## * Prefix length
    is_infinite* {.importc: "is_infinite", bitsize: 1.}: uint8 ## * Is the IP prefix valid forever
    is_used* {.importc: "is_used", bitsize: 1.}: uint8 ## * Is this prefix used or not
    unused {.importc: "_unused", bitsize: 6.}: uint8


  net_if_router* {.importc: "net_if_router", header: hdr, bycopy.} = object
    ##  @brief Information about routers in the system.
    ##
    ##  Stores the router information.
    ##
    node* {.importc: "node".}: sys_snode_t ## * Slist lifetime timer node
    address* {.importc: "address".}: NetAddr ## * IP address
    iface* {.importc: "iface".}: ptr net_if_alias ## * Network interface the router is connected to
    life_start* {.importc: "life_start".}: uint32 ## * Router life timer start
    lifetime* {.importc: "lifetime".}: uint16 ## * Router lifetime
    is_used* {.importc: "is_used", bitsize: 1.}: uint8 ## * Is this router used or not
    is_default* {.importc: "is_default", bitsize: 1.}: uint8 ## * Is default router
    is_infinite* {.importc: "is_infinite", bitsize: 1.}: uint8 ## * Is the router valid forever
    unused* {.importc: "_unused", bitsize: 5.}: uint8


  net_if_ipv6* {.importc: "net_if_ipv6", header: hdr, bycopy.} = object
    unicast* {.importc: "unicast".}: array[NET_IF_MAX_IPV6_ADDR, net_if_addr] ## * Unicast IP addresses
    mcast* {.importc: "mcast".}: array[NET_IF_MAX_IPV6_MADDR, net_if_mcast_addr] ## * Multicast IP addresses

    prefix* {.importc: "prefix".}: array[NET_IF_MAX_IPV6_PREFIX, net_if_ipv6_prefix] ## Prefixes
    base_reachable_time* {.importc: "base_reachable_time".}: uint32 ## Default reachable time (RFC 4861, page 52)
    reachable_time* {.importc: "reachable_time".}: uint32 ## * Reachable time (RFC 4861, page 20)
    retrans_timer* {.importc: "retrans_timer".}: uint32 ## * Retransmit timer (RFC 4861, page 52)
    when CONFIG_NET_IPV6_ND and CONFIG_NET_NATIVE_IPV6:
      rs_node* {.importc: "rs_node", header: hdr.}: sys_snode_t ## * Router solicitation timer node
      rs_start* {.importc: "rs_start", header: hdr.}: uint32 ##  RS start time
      rs_count* {.importc: "rs_count", header: hdr.}: uint8 ## * RS count
    hop_limit* {.importc: "hop_limit".}: uint8 ## * IPv6 hop limit
  
  net_if_ipv4* {.importc: "net_if_ipv4", header: hdr, bycopy.} = object
    unicast* {.importc: "unicast".}: array[NET_IF_MAX_IPV4_ADDR, net_if_addr] ## * Unicast IP addresses
    mcast* {.importc: "mcast".}: array[NET_IF_MAX_IPV4_MADDR, net_if_mcast_addr] ## * Multicast IP addresses
    gw* {.importc: "gw".}: InAddr ## Gateway
    netmask* {.importc: "netmask".}: InAddr ## * Netmask
    ttl* {.importc: "ttl".}: uint8 ## * IPv4 time-to-live

  net_if_ip* {.importc: "net_if_ip", header: hdr, bycopy.} = object
    ##  @brief Network interface IP address configuration.
    when CONFIG_NET_NATIVE_IPV6:
      ipv6* {.importc: "ipv6", header: hdr.}: ptr net_if_ipv6
    when CONFIG_NET_NATIVE_IPV4:
      ipv4* {.importc: "ipv4", header: hdr.}: ptr net_if_ipv4

  net_if_config* {.importc: "net_if_config", header: hdr, bycopy.} = object
    ##  @brief IP and other configuration related data for network interface.
    ip* {.importc: "ip".}: net_if_ip ## * IP address configuration setting

    when CONFIG_NET_DHCPV4 and CONFIG_NET_NATIVE_IPV4:
      dhcpv4* {.importc: "dhcpv4", header: hdr.}: net_if_dhcpv4
    when CONFIG_NET_IPV4_AUTO and CONFIG_NET_NATIVE_IPV4:
      ipv4auto* {.importc: "ipv4auto", header: hdr.}: net_if_ipv4_autoconf
    when CONFIG_NET_L2_VIRTUAL:
      virtual_interfaces* {.importc: "virtual_interfaces", header: hdr.}: sys_slist_t ##\
        ##  This list keeps track of the virtual network interfaces
        ##  that are attached to this network interface.
        ##

  net_traffic_class* {.importc: "net_traffic_class", header: hdr, bycopy.} = object
    ##  @brief Network traffic class.
    ##
    ##  Traffic classes are used when sending or receiving data that is classified
    ##  with different priorities. So some traffic can be marked as high priority
    ##  and it will be sent or received first. Each network packet that is
    ##  transmitted or received goes through a fifo to a thread that will transmit
    ##  it.
    fifo* {.importc: "fifo".}: k_fifo ## * Fifo for handling this Tx or Rx packet
    

    handler* {.importc: "handler".}: k_thread ## * Traffic class handler thread
    stack* {.importc: "stack".}: ptr k_thread_stack_t ## * Stack for this handler


  net_if_dev* {.importc: "net_if_dev", header: hdr, bycopy.} = object
    ##  @brief Network Interface Device structure
    ##
    ##  Used to handle a network interface on top of a device driver instance.
    ##  There can be many net_if_dev instance against the same device.
    ##
    ##  Such interface is mainly to be used by the link layer, but is also tight
    ##  to a network context: it then makes the relation with a network context
    ##  and the network device.
    ##
    ##  Because of the strong relationship between a device driver and such
    ##  network interface, each net_if_dev should be instantiated by
    ##
    dev* {.importc: "dev".}: ptr device ## * The actually device driver instance the net_if is related to
    

    l2* {.importc: "l2".}: ptr net_l2 ## * Interface's L2 layer

    l2_data* {.importc: "l2_data".}: pointer ## * Interface's private L2 data pointer

    link_addr* {.importc: "link_addr".}: net_linkaddr ## * The hardware link address
    when CONFIG_NET_OFFLOAD:
      ## * TCP/IP Offload functions.
      ##  If non-NULL, then the TCP/IP stack is located
      ##  in the communication chip that is accessed via this
      ##  network interface.
      ##
      offload* {.importc: "offload", header: hdr.}: ptr net_offload
    mtu* {.importc: "mtu".}: uint16 ## * The hardware MTU
    when CONFIG_NET_SOCKETS_OFFLOAD:
      offloaded* {.importc: "offloaded", header: hdr.}: bool ## * Indicate whether interface is offloaded at socket level.


  net_if* {.importc: "net_if", header: hdr, bycopy.} = object
    ##  @brief Network Interface structure
    ##
    ##  Used to handle a network interface on top of a net_if_dev instance.
    ##  There can be many net_if instance against the same net_if_dev instance.
    ##
    ##
    if_dev* {.importc: "if_dev".}: ptr net_if_dev ## * The net_if_dev instance the net_if is related to

    when CONFIG_NET_STATISTICS_PER_INTERFACE:
      stats* {.importc: "stats", header: hdr.}: net_stats ## * Network statistics related to this network interface
    config* {.importc: "config".}: net_if_config ## * Network interface instance configuration
    when CONFIG_NET_POWER_MANAGEMENT:
      tx_pending* {.importc: "tx_pending", header: hdr.}: cint ##\
      ## * Keep track of packets pending in traffic queues. This is
      ##  needed to avoid putting network device driver to sleep if
      ##  there are packets waiting to be sent.
      ##

  net_if_link_callback_t* = proc (iface: ptr net_if; dst: ptr net_linkaddr; status: cint) ##\
    ##  @typedef net_if_link_callback_t
    ##  @brief Define callback that is called after a network packet
    ##         has been sent.
    ##  @param iface A pointer to a struct net_if to which the the net_pkt was sent to.
    ##  @param dst Link layer address of the destination where the network packet was sent.
    ##  @param status Send status, 0 is ok, < 0 error.
    ##

  net_if_link_cb* {.importc: "net_if_link_cb", header: hdr, bycopy.} = object
    ##  @brief Link callback handler struct.
    ##
    ##  Stores the link callback information. Caller must make sure that
    ##  the variable pointed by this is valid during the lifetime of
    ##  registration. Typically this means that the variable cannot be
    ##  allocated from stack.
    ##
    node* {.importc: "node".}: sys_snode_t ## * Node information for the slist.
    cb* {.importc: "cb".}: net_if_link_callback_t ## * Link callback

when CONFIG_NET_DHCPV4 and CONFIG_NET_NATIVE_IPV4:
  type
    net_if_dhcpv4* {.importc: "net_if_dhcpv4", header: hdr, bycopy.} = object
      node* {.importc: "node".}: sys_snode_t ## * Used for timer lists
      timer_start* {.importc: "timer_start".}: int64 ## * Timer start
      request_time* {.importc: "request_time".}: uint32 ## * Time for INIT, DISCOVER, REQUESTING, RENEWAL
      xid* {.importc: "xid".}: uint32 
      lease_time* {.importc: "lease_time".}: uint32 ## * IP address Lease time
      renewal_time* {.importc: "renewal_time".}: uint32 ## * IP address Renewal time
      rebinding_time* {.importc: "rebinding_time".}: uint32 ## * IP address Rebinding time
      server_id* {.importc: "server_id".}: InAddr ## * Server ID
      requested_ip* {.importc: "requested_ip".}: InAddr ## * Requested IP addr
      state* {.importc: "state".}: net_dhcpv4_state ##   DHCPv4 client state in the process of network address allocation.
      attempts* {.importc: "attempts".}: uint8 ## * Number of attempts made for REQUEST and RENEWAL messages

when CONFIG_NET_IPV4_AUTO and CONFIG_NET_NATIVE_IPV4:
  type
    net_if_ipv4_autoconf* {.importc: "net_if_ipv4_autoconf", header: hdr,
                           bycopy.} = object
      node* {.importc: "node".}: sys_snode_t ## * Used for timer lists
      iface* {.importc: "iface".}: ptr net_if_alias ## * Backpointer to correct network interface
      timer_start* {.importc: "timer_start".}: int64 ## * Timer start
      timer_timeout* {.importc: "timer_timeout".}: uint32 ## * Time for INIT, DISCOVER, REQUESTING, RENEWAL
      current_ip* {.importc: "current_ip".}: InAddr ## * Current IP addr
      requested_ip* {.importc: "requested_ip".}: InAddr ## * Requested IP addr
      state* {.importc: "state".}: net_ipv4_autoconf_state ## * IPV4 Autoconf state in the process of network address allocation.
      probe_cnt* {.importc: "probe_cnt".}: uint8 ## * Number of sent probe requests
      announce_cnt* {.importc: "announce_cnt".}: uint8 ## * Number of sent announcements
      conflict_cnt* {.importc: "conflict_cnt".}: uint8 ## * Incoming conflict count




## *
##  @brief Set a value in network interface flags
##
##  @param iface Pointer to network interface
##  @param value Flag value
##

proc net_if_flag_set*(iface: ptr net_if; value: net_if_flag) {.importc: "$1", header: hdr.}



## *
##  @brief Test and set a value in network interface flags
##
##  @param iface Pointer to network interface
##  @param value Flag value
##
##  @return true if the bit was set, false if it wasn't.
##

proc net_if_flag_test_and_set*(iface: ptr net_if; value: net_if_flag): bool {.importc: "$1", header: hdr.}



## *
##  @brief Clear a value in network interface flags
##
##  @param iface Pointer to network interface
##  @param value Flag value
##

proc net_if_flag_clear*(iface: ptr net_if; value: net_if_flag) {.importc: "$1", header: hdr.}



## *
##  @brief Check if a value in network interface flags is set
##
##  @param iface Pointer to network interface
##  @param value Flag value
##
##  @return True if the value is set, false otherwise
##

proc net_if_flag_is_set*(iface: ptr net_if; value: net_if_flag): bool {.importc: "$1", header: hdr.}



## *
##  @brief Send a packet through a net iface
##
##  @param iface Pointer to a network interface structure
##  @param pkt Pointer to a net packet to send
##
##  return verdict about the packet
##

proc net_if_send_data*(iface: ptr net_if; pkt: ptr net_pkt_alias): net_verdict {.
    importc: "net_if_send_data", header: hdr.}



## *
##  @brief Get a pointer to the interface L2
##
##  @param iface a valid pointer to a network interface structure
##
##  @return a pointer to the iface L2
##

proc net_if_l2*(iface: ptr net_if): ptr net_l2 {.importc: "$1", header: hdr.}



## *
##  @brief Input a packet through a net iface
##
##  @param iface Pointer to a network interface structure
##  @param pkt Pointer to a net packet to input
##
##  @return verdict about the packet
##

proc net_if_recv_data*(iface: ptr net_if; pkt: ptr net_pkt_alias): net_verdict {.
    importc: "net_if_recv_data", header: hdr.}



## *
##  @brief Get a pointer to the interface L2 private data
##
##  @param iface a valid pointer to a network interface structure
##
##  @return a pointer to the iface L2 data
##

proc net_if_l2_data*(iface: ptr net_if): pointer {.importc: "$1", header: hdr.}



## *
##  @brief Get an network interface's device
##
##  @param iface Pointer to a network interface structure
##
##  @return a pointer to the device driver instance
##

proc net_if_get_device*(iface: ptr net_if): ptr device {.importc: "$1", header: hdr.}



## *
##  @brief Queue a packet to the net interface TX queue
##
##  @param iface Pointer to a network interface structure
##  @param pkt Pointer to a net packet to queue
##

proc net_if_queue_tx*(iface: ptr net_if; pkt: ptr net_pkt_alias) {.
    importc: "net_if_queue_tx", header: hdr.}



## *
##  @brief Return the IP offload status
##
##  @param iface Network interface
##
##  @return True if IP offlining is active, false otherwise.
##

proc net_if_is_ip_offloaded*(iface: ptr net_if): bool {.importc: "$1", header: hdr.}



## *
##  @brief Return the IP offload plugin
##
##  @param iface Network interface
##
##  @return NULL if there is no offload plugin defined, valid pointer otherwise
##

proc net_if_offload*(iface: ptr net_if): ptr net_offload_alias {.importc: "$1", header: hdr.}



## *
##  @brief Return the socket offload status
##
##  @param iface Network interface
##
##  @return True if socket offloading is active, false otherwise.
##

proc net_if_is_socket_offloaded*(iface: ptr net_if): bool {.importc: "$1", header: hdr.}



## *
##  @brief Get an network interface's link address
##
##  @param iface Pointer to a network interface structure
##
##  @return a pointer to the network link address
##

proc net_if_get_link_addr*(iface: ptr net_if): ptr net_linkaddr {.importc: "$1", header: hdr.}



## *
##  @brief Return network configuration for this network interface
##
##  @param iface Pointer to a network interface structure
##
##  @return Pointer to configuration
##

proc net_if_get_config*(iface: ptr net_if): ptr net_if_config {.importc: "$1", header: hdr.}



## *
##  @brief Start duplicate address detection procedure.
##
##  @param iface Pointer to a network interface structure
##

proc net_if_start_dad*(iface: ptr net_if) {.importc: "net_if_start_dad", header: hdr.}



## *
##  @brief Start neighbor discovery and send router solicitation message.
##
##  @param iface Pointer to a network interface structure
##

proc net_if_start_rs*(iface: ptr net_if) {.importc: "net_if_start_rs",
                                       header: hdr.}


## *
##  @brief Stop neighbor discovery.
##
##  @param iface Pointer to a network interface structure
##

proc net_if_stop_rs*(iface: ptr net_if) {.importc: "net_if_stop_rs", header: hdr.}



## * @cond INTERNAL_HIDDEN

proc net_if_set_link_addr_unlocked*(iface: ptr net_if; caddr: ptr uint8; len: uint8;
                                   ctype: net_link_type): cint {.importc: "$1", header: hdr.}

proc net_if_set_link_addr_locked*(iface: ptr net_if; caddr: ptr uint8; len: uint8;
                                 ctype: net_link_type): cint {.
    importc: "net_if_set_link_addr_locked", header: hdr.}


## * @endcond


## *
##  @brief Set a network interface's link address
##
##  @param iface Pointer to a network interface structure
##  @param addr A pointer to a uint8_t buffer representing the address.
##              The buffer must remain valid throughout interface lifetime.
##  @param len length of the address buffer
##  @param type network bearer type of this link address
##
##  @return 0 on success
##

proc net_if_set_link_addr*(iface: ptr net_if; caddr: ptr uint8; len: uint8;
                          ctype: net_link_type): cint {.importc: "$1", header: hdr.}



## *
##  @brief Get an network interface's MTU
##
##  @param iface Pointer to a network interface structure
##
##  @return the MTU
##

proc net_if_get_mtu*(iface: ptr net_if): uint16 {.importc: "$1", header: hdr.}



## *
##  @brief Set an network interface's MTU
##
##  @param iface Pointer to a network interface structure
##  @param mtu New MTU, note that we store only 16 bit mtu value.
##

proc net_if_set_mtu*(iface: ptr net_if; mtu: uint16) {.importc: "$1", header: hdr.}



## *
##  @brief Set the infinite status of the network interface address
##
##  @param ifaddr IP address for network interface
##  @param is_infinite Infinite status
##

proc net_if_addr_set_lf*(ifaddr: ptr net_if_addr; is_infinite: bool) {.importc: "$1", header: hdr.}



## *
##  @brief Get an interface according to link layer address.
##
##  @param ll_addr Link layer address.
##
##  @return Network interface or NULL if not found.
##

proc net_if_get_by_link_addr*(ll_addr: ptr net_linkaddr): ptr net_if {.
    importc: "net_if_get_by_link_addr", header: hdr.}



## *
##  @brief Find an interface from it's related device
##
##  @param dev A valid struct device pointer to relate with an interface
##
##  @return a valid struct net_if pointer on success, NULL otherwise
##

proc net_if_lookup_by_dev*(dev: ptr device): ptr net_if {.
    importc: "net_if_lookup_by_dev", header: hdr.}



## *
##  @brief Get network interface IP config
##
##  @param iface Interface to use.
##
##  @return NULL if not found or pointer to correct config settings.
##

proc net_if_config_get*(iface: ptr net_if): ptr net_if_config {.importc: "$1", header: hdr.}



## *
##  @brief Remove a router from the system
##
##  @param router Pointer to existing router
##

proc net_if_router_rm*(router: ptr net_if_router) {.importc: "net_if_router_rm",
    header: hdr.}



## *
##  @brief Get the default network interface.
##
##  @return Default interface or NULL if no interfaces are configured.
##

proc net_if_get_default*(): ptr net_if {.importc: "net_if_get_default",
                                     header: hdr.}



## *
##  @brief Get the first network interface according to its type.
##
##  @param l2 Layer 2 type of the network interface.
##
##  @return First network interface of a given type or NULL if no such
##  interfaces was found.
##

proc net_if_get_first_by_type*(l2: ptr net_l2): ptr net_if {.
    importc: "net_if_get_first_by_type", header: hdr.}

when CONFIG_NET_L2_IEEE802154:
  ##  @brief Get the first IEEE 802.15.4 network interface.
  ##
  ##  @return First IEEE 802.15.4 network interface or NULL if no such
  ##  interfaces was found.
  ##
  proc net_if_get_ieee802154*(): ptr net_if {.importc: "$1", header: hdr.}



## *
##  @brief Allocate network interface IPv6 config.
##
##  @details This function will allocate new IPv6 config.
##
##  @param iface Interface to use.
##  @param ipv6 Pointer to allocated IPv6 struct is returned to caller.
##
##  @return 0 if ok, <0 if error
##

proc net_if_config_ipv6_get*(iface: ptr net_if; ipv6: ptr ptr net_if_ipv6): cint {.
    importc: "net_if_config_ipv6_get", header: hdr.}



## *
##  @brief Release network interface IPv6 config.
##
##  @param iface Interface to use.
##
##  @return 0 if ok, <0 if error
##

proc net_if_config_ipv6_put*(iface: ptr net_if): cint {.
    importc: "net_if_config_ipv6_put", header: hdr.}



## *
##  @brief Check if this IPv6 address belongs to one of the interfaces.
##
##  @param addr IPv6 address
##  @param iface Pointer to interface is returned
##
##  @return Pointer to interface address, NULL if not found.
##

proc net_if_ipv6_addr_lookup*(caddr: ptr In6Addr; iface: ptr ptr net_if): ptr net_if_addr {.
    importc: "net_if_ipv6_addr_lookup", header: hdr.}



## *
##  @brief Check if this IPv6 address belongs to this specific interfaces.
##
##  @param iface Network interface
##  @param addr IPv6 address
##
##  @return Pointer to interface address, NULL if not found.
##

proc net_if_ipv6_addr_lookup_by_iface*(iface: ptr net_if; caddr: ptr In6Addr): ptr net_if_addr {.
    importc: "net_if_ipv6_addr_lookup_by_iface", header: hdr.}



## *
##  @brief Check if this IPv6 address belongs to one of the interface indices.
##
##  @param addr IPv6 address
##
##  @return >0 if address was found in given network interface index,
##  all other values mean address was not found
##

proc net_if_ipv6_addr_lookup_by_index*(caddr: ptr In6Addr): cint {.
    importc: "net_if_ipv6_addr_lookup_by_index", header: hdr.}



## *
##  @brief Add a IPv6 address to an interface
##
##  @param iface Network interface
##  @param addr IPv6 address
##  @param addr_type IPv6 address type
##  @param vlifetime Validity time for this address
##
##  @return Pointer to interface address, NULL if cannot be added
##

proc net_if_ipv6_addr_add*(iface: ptr net_if; caddr: ptr In6Addr;
                          addr_type: net_addr_type; vlifetime: uint32): ptr net_if_addr {.
    importc: "net_if_ipv6_addr_add", header: hdr.}



## *
##  @brief Add a IPv6 address to an interface by index
##
##  @param index Network interface index
##  @param addr IPv6 address
##  @param addr_type IPv6 address type
##  @param vlifetime Validity time for this address
##
##  @return True if ok, false if address could not be added
##

proc net_if_ipv6_addr_add_by_index*(index: cint; caddr: ptr In6Addr;
                                   addr_type: net_addr_type; vlifetime: uint32): bool {.
    syscall, importc: "net_if_ipv6_addr_add_by_index", header: hdr.}


## *
##  @brief Update validity lifetime time of an IPv6 address.
##
##  @param ifaddr Network IPv6 address
##  @param vlifetime Validity time for this address
##

proc net_if_ipv6_addr_update_lifetime*(ifaddr: ptr net_if_addr; vlifetime: uint32) {.
    importc: "net_if_ipv6_addr_update_lifetime", header: hdr.}


## *
##  @brief Remove an IPv6 address from an interface
##
##  @param iface Network interface
##  @param addr IPv6 address
##
##  @return True if successfully removed, false otherwise
##

proc net_if_ipv6_addr_rm*(iface: ptr net_if; caddr: ptr In6Addr): bool {.
    importc: "net_if_ipv6_addr_rm", header: hdr.}


## *
##  @brief Remove an IPv6 address from an interface by index
##
##  @param index Network interface index
##  @param addr IPv6 address
##
##  @return True if successfully removed, false otherwise
##

proc net_if_ipv6_addr_rm_by_index*(index: cint; caddr: ptr In6Addr): bool {.syscall,
    importc: "net_if_ipv6_addr_rm_by_index", header: hdr.}


## *
##  @brief Add a IPv6 multicast address to an interface
##
##  @param iface Network interface
##  @param addr IPv6 multicast address
##
##  @return Pointer to interface multicast address, NULL if cannot be added
##

proc net_if_ipv6_maddr_add*(iface: ptr net_if; caddr: ptr In6Addr): ptr net_if_mcast_addr {.
    importc: "net_if_ipv6_maddr_add", header: hdr.}


## *
##  @brief Remove an IPv6 multicast address from an interface
##
##  @param iface Network interface
##  @param addr IPv6 multicast address
##
##  @return True if successfully removed, false otherwise
##

proc net_if_ipv6_maddr_rm*(iface: ptr net_if; caddr: ptr In6Addr): bool {.
    importc: "net_if_ipv6_maddr_rm", header: hdr.}


## *
##  @brief Check if this IPv6 multicast address belongs to a specific interface
##  or one of the interfaces.
##
##  @param addr IPv6 address
##  @param iface If *iface is null, then pointer to interface is returned,
##  otherwise the *iface value needs to be matched.
##
##  @return Pointer to interface multicast address, NULL if not found.
##

proc net_if_ipv6_maddr_lookup*(caddr: ptr In6Addr; iface: ptr ptr net_if): ptr net_if_mcast_addr {.
    importc: "net_if_ipv6_maddr_lookup", header: hdr.}


## *
##  @typedef net_if_mcast_callback_t
##
##  @brief Define callback that is called whenever IPv6 multicast address group
##  is joined or left.
##
##  @param iface A pointer to a struct net_if to which the multicast address is
##         attached.
##  @param addr IPv6 multicast address.
##  @param is_joined True if the address is joined, false if left.
##

type
  net_if_mcast_callback_t* = proc (iface: ptr net_if; caddr: ptr In6Addr;
                                is_joined: bool)



## *
##  @brief Multicast monitor handler struct.
##
##  Stores the multicast callback information. Caller must make sure that
##  the variable pointed by this is valid during the lifetime of
##  registration. Typically this means that the variable cannot be
##  allocated from stack.
##

type
  net_if_mcast_monitor* {.importc: "net_if_mcast_monitor", header: hdr, bycopy.} = object
    node* {.importc: "node".}: sys_snode_t ## * Node information for the slist.
    iface* {.importc: "iface".}: ptr net_if_alias ## * Network interface
    cb* {.importc: "cb".}: net_if_mcast_callback_t ## * Multicast callback


## *
##  @brief Register a multicast monitor
##
##  @param mon Monitor handle. This is a pointer to a monitor storage structure
##  which should be allocated by caller, but does not need to be initialized.
##  @param iface Network interface
##  @param cb Monitor callback
##

proc net_if_mcast_mon_register*(mon: ptr net_if_mcast_monitor; iface: ptr net_if;
                               cb: net_if_mcast_callback_t) {.
    importc: "net_if_mcast_mon_register", header: hdr.}


## *
##  @brief Unregister a multicast monitor
##
##  @param mon Monitor handle
##

proc net_if_mcast_mon_unregister*(mon: ptr net_if_mcast_monitor) {.
    importc: "net_if_mcast_mon_unregister", header: hdr.}


## *
##  @brief Call registered multicast monitors
##
##  @param iface Network interface
##  @param addr Multicast address
##  @param is_joined Is this multicast address joined (true) or not (false)
##

proc net_if_mcast_monitor_check*(iface: ptr net_if_alias; caddr: ptr In6Addr; is_joined: bool) {.
    importc: "net_if_mcast_monitor", header: hdr.}


## *
##  @brief Mark a given multicast address to be joined.
##
##  @param addr IPv6 multicast address
##

proc net_if_ipv6_maddr_join*(caddr: ptr net_if_mcast_addr) {.
    importc: "net_if_ipv6_maddr_join", header: hdr.}


## *
##  @brief Check if given multicast address is joined or not.
##
##  @param addr IPv6 multicast address
##
##  @return True if address is joined, False otherwise.
##

proc net_if_ipv6_maddr_is_joined*(caddr: ptr net_if_mcast_addr): bool {.importc: "$1", header: hdr.}


## *
##  @brief Mark a given multicast address to be left.
##
##  @param addr IPv6 multicast address
##

proc net_if_ipv6_maddr_leave*(caddr: ptr net_if_mcast_addr) {.
    importc: "net_if_ipv6_maddr_leave", header: hdr.}


## *
##  @brief Return prefix that corresponds to this IPv6 address.
##
##  @param iface Network interface
##  @param addr IPv6 address
##
##  @return Pointer to prefix, NULL if not found.
##

proc net_if_ipv6_prefix_get*(iface: ptr net_if; caddr: ptr In6Addr): ptr net_if_ipv6_prefix {.
    importc: "net_if_ipv6_prefix_get", header: hdr.}


## *
##  @brief Check if this IPv6 prefix belongs to this interface
##
##  @param iface Network interface
##  @param addr IPv6 address
##  @param len Prefix length
##
##  @return Pointer to prefix, NULL if not found.
##

proc net_if_ipv6_prefix_lookup*(iface: ptr net_if; caddr: ptr In6Addr; len: uint8): ptr net_if_ipv6_prefix {.
    importc: "net_if_ipv6_prefix_lookup", header: hdr.}


## *
##  @brief Add a IPv6 prefix to an network interface.
##
##  @param iface Network interface
##  @param prefix IPv6 address
##  @param len Prefix length
##  @param lifetime Prefix lifetime in seconds
##
##  @return Pointer to prefix, NULL if the prefix was not added.
##

proc net_if_ipv6_prefix_add*(iface: ptr net_if; prefix: ptr In6Addr; len: uint8;
                            lifetime: uint32): ptr net_if_ipv6_prefix {.
    importc: "net_if_ipv6_prefix_add", header: hdr.}


## *
##  @brief Remove an IPv6 prefix from an interface
##
##  @param iface Network interface
##  @param addr IPv6 prefix address
##  @param len Prefix length
##
##  @return True if successfully removed, false otherwise
##

proc net_if_ipv6_prefix_rm*(iface: ptr net_if; caddr: ptr In6Addr; len: uint8): bool {.
    importc: "net_if_ipv6_prefix_rm", header: hdr.}


## *
##  @brief Set the infinite status of the prefix
##
##  @param prefix IPv6 address
##  @param is_infinite Infinite status
##

proc net_if_ipv6_prefix_set_lf*(prefix: ptr net_if_ipv6_prefix; is_infinite: bool) {.importc: "$1", header: hdr.}



## *
##  @brief Set the prefix lifetime timer.
##
##  @param prefix IPv6 address
##  @param lifetime Prefix lifetime in seconds
##

proc net_if_ipv6_prefix_set_timer*(prefix: ptr net_if_ipv6_prefix; lifetime: uint32) {.
    importc: "net_if_ipv6_prefix_set_timer", header: hdr.}


## *
##  @brief Unset the prefix lifetime timer.
##
##  @param prefix IPv6 address
##

proc net_if_ipv6_prefix_unset_timer*(prefix: ptr net_if_ipv6_prefix) {.
    importc: "net_if_ipv6_prefix_unset_timer", header: hdr.}


## *
##  @brief Check if this IPv6 address is part of the subnet of our
##  network interface.
##
##  @param iface Network interface. This is returned to the caller.
##  The iface can be NULL in which case we check all the interfaces.
##  @param addr IPv6 address
##
##  @return True if address is part of our subnet, false otherwise
##

proc net_if_ipv6_addr_onlink*(iface: ptr ptr net_if; caddr: ptr In6Addr): bool {.
    importc: "net_if_ipv6_addr_onlink", header: hdr.}


## *
##  @brief Get the IPv6 address of the given router
##  @param router a network router
##
##  @return pointer to the IPv6 address, or NULL if none
##

proc net_if_router_ipv6*(router: ptr net_if_router): ptr In6Addr {.importc: "$1", header: hdr.}



## *
##  @brief Check if IPv6 address is one of the routers configured
##  in the system.
##
##  @param iface Network interface
##  @param addr IPv6 address
##
##  @return Pointer to router information, NULL if cannot be found
##

proc net_if_ipv6_router_lookup*(iface: ptr net_if; caddr: ptr In6Addr): ptr net_if_router {.
    importc: "net_if_ipv6_router_lookup", header: hdr.}


## *
##  @brief Find default router for this IPv6 address.
##
##  @param iface Network interface. This can be NULL in which case we
##  go through all the network interfaces to find a suitable router.
##  @param addr IPv6 address
##
##  @return Pointer to router information, NULL if cannot be found
##

proc net_if_ipv6_router_find_default*(iface: ptr net_if; caddr: ptr In6Addr): ptr net_if_router {.
    importc: "net_if_ipv6_router_find_default", header: hdr.}


## *
##  @brief Update validity lifetime time of a router.
##
##  @param router Network IPv6 address
##  @param lifetime Lifetime of this router.
##

proc net_if_ipv6_router_update_lifetime*(router: ptr net_if_router; lifetime: uint16) {.
    importc: "net_if_ipv6_router_update_lifetime", header: hdr.}


## *
##  @brief Add IPv6 router to the system.
##
##  @param iface Network interface
##  @param addr IPv6 address
##  @param router_lifetime Lifetime of the router
##
##  @return Pointer to router information, NULL if could not be added
##

proc net_if_ipv6_router_add*(iface: ptr net_if; caddr: ptr In6Addr;
                            router_lifetime: uint16): ptr net_if_router {.
    importc: "net_if_ipv6_router_add", header: hdr.}


## *
##  @brief Remove IPv6 router from the system.
##
##  @param router Router information.
##
##  @return True if successfully removed, false otherwise
##

proc net_if_ipv6_router_rm*(router: ptr net_if_router): bool {.
    importc: "net_if_ipv6_router_rm", header: hdr.}


## *
##  @brief Get IPv6 hop limit specified for a given interface. This is the
##  default value but can be overridden by the user.
##
##  @param iface Network interface
##
##  @return Hop limit
##

proc net_if_ipv6_get_hop_limit*(iface: ptr net_if): uint8 {.
    importc: "net_if_ipv6_get_hop_limit", header: hdr.}


## *
##  @brief Set the default IPv6 hop limit of a given interface.
##
##  @param iface Network interface
##  @param hop_limit New hop limit
##

proc net_ipv6_set_hop_limit*(iface: ptr net_if; hop_limit: uint8) {.
    importc: "net_ipv6_set_hop_limit", header: hdr.}


## *
##  @brief Set IPv6 reachable time for a given interface
##
##  @param iface Network interface
##  @param reachable_time New reachable time
##

proc net_if_ipv6_set_base_reachable_time*(iface: ptr net_if; reachable_time: uint32) {.
    inline.} =
  when CONFIG_NET_NATIVE_IPV6:
    if not iface.config.ip.ipv6:
      return
    iface.config.ip.ipv6.base_reachable_time = reachable_time



## *
##  @brief Get IPv6 reachable timeout specified for a given interface
##
##  @param iface Network interface
##
##  @return Reachable timeout
##

proc net_if_ipv6_get_reachable_time*(iface: ptr net_if): uint32 {.importc: "$1", header: hdr.}



## *
##  @brief Calculate next reachable time value for IPv6 reachable time
##
##  @param ipv6 IPv6 address configuration
##
##  @return Reachable time
##

proc net_if_ipv6_calc_reachable_time*(ipv6: ptr net_if_ipv6): uint32 {.
    importc: "net_if_ipv6_calc_reachable_time", header: hdr.}


## *
##  @brief Set IPv6 reachable time for a given interface. This requires
##  that base reachable time is set for the interface.
##
##  @param ipv6 IPv6 address configuration
##

proc net_if_ipv6_set_reachable_time*(ipv6: ptr net_if_ipv6) {.importc: "$1", header: hdr.}



## *
##  @brief Set IPv6 retransmit timer for a given interface
##
##  @param iface Network interface
##  @param retrans_timer New retransmit timer
##

proc net_if_ipv6_set_retrans_timer*(iface: ptr net_if; retrans_timer: uint32) {.importc: "$1", header: hdr.}



## *
##  @brief Get IPv6 retransmit timer specified for a given interface
##
##  @param iface Network interface
##
##  @return Retransmit timer
##

proc net_if_ipv6_get_retrans_timer*(iface: ptr net_if): uint32 {.importc: "$1", header: hdr.}



## *
##  @brief Get a IPv6 source address that should be used when sending
##  network data to destination.
##
##  @param iface Interface that was used when packet was received.
##  If the interface is not known, then NULL can be given.
##  @param dst IPv6 destination address
##
##  @return Pointer to IPv6 address to use, NULL if no IPv6 address
##  could be found.
##

proc net_if_ipv6_select_src_addr*(iface: ptr net_if; dst: ptr In6Addr): ptr In6Addr {.
      importc: "net_if_ipv6_select_src_addr", header: hdr.}



## *
##  @brief Get a network interface that should be used when sending
##  IPv6 network data to destination.
##
##  @param dst IPv6 destination address
##
##  @return Pointer to network interface to use, NULL if no suitable interface
##  could be found.
##

proc net_if_ipv6_select_src_iface*(dst: ptr In6Addr): ptr net_if {.
    importc: "net_if_ipv6_select_src_iface", header: hdr.}



## *
##  @brief Get a IPv6 link local address in a given state.
##
##  @param iface Interface to use. Must be a valid pointer to an interface.
##  @param addr_state IPv6 address state (preferred, tentative, deprecated)
##
##  @return Pointer to link local IPv6 address, NULL if no proper IPv6 address
##  could be found.
##

proc net_if_ipv6_get_ll*(iface: ptr net_if; addr_state: net_addr_state): ptr In6Addr {.
    importc: "net_if_ipv6_get_ll", header: hdr.}


## *
##  @brief Return link local IPv6 address from the first interface that has
##  a link local address matching give state.
##
##  @param state IPv6 address state (ANY, TENTATIVE, PREFERRED, DEPRECATED)
##  @param iface Pointer to interface is returned
##
##  @return Pointer to IPv6 address, NULL if not found.
##

proc net_if_ipv6_get_ll_addr*(state: net_addr_state; iface: ptr ptr net_if): ptr In6Addr {.
    importc: "net_if_ipv6_get_ll_addr", header: hdr.}


## *
##  @brief Stop IPv6 Duplicate Address Detection (DAD) procedure if
##  we find out that our IPv6 address is already in use.
##
##  @param iface Interface where the DAD was running.
##  @param addr IPv6 address that failed DAD
##

proc net_if_ipv6_dad_failed*(iface: ptr net_if; caddr: ptr In6Addr) {.
    importc: "net_if_ipv6_dad_failed", header: hdr.}


## *
##  @brief Return global IPv6 address from the first interface that has
##  a global IPv6 address matching the given state.
##
##  @param state IPv6 address state (ANY, TENTATIVE, PREFERRED, DEPRECATED)
##  @param iface Caller can give an interface to check. If iface is set to NULL,
##  then all the interfaces are checked. Pointer to interface where the IPv6
##  address is defined is returned to the caller.
##
##  @return Pointer to IPv6 address, NULL if not found.
##

proc net_if_ipv6_get_global_addr*(state: net_addr_state; iface: ptr ptr net_if): ptr In6Addr {.
    importc: "net_if_ipv6_get_global_addr", header: hdr.}


## *
##  @brief Allocate network interface IPv4 config.
##
##  @details This function will allocate new IPv4 config.
##
##  @param iface Interface to use.
##  @param ipv4 Pointer to allocated IPv4 struct is returned to caller.
##
##  @return 0 if ok, <0 if error
##

proc net_if_config_ipv4_get*(iface: ptr net_if; ipv4: ptr ptr net_if_ipv4): cint {.
    importc: "net_if_config_ipv4_get", header: hdr.}


## *
##  @brief Release network interface IPv4 config.
##
##  @param iface Interface to use.
##
##  @return 0 if ok, <0 if error
##

proc net_if_config_ipv4_put*(iface: ptr net_if): cint {.
    importc: "net_if_config_ipv4_put", header: hdr.}


## *
##  @brief Get IPv4 time-to-live value specified for a given interface
##
##  @param iface Network interface
##
##  @return Time-to-live
##

proc net_if_ipv4_get_ttl*(iface: ptr net_if): uint8 {.importc: "net_if_ipv4_get_ttl",
    header: hdr.}


## *
##  @brief Set IPv4 time-to-live value specified to a given interface
##
##  @param iface Network interface
##  @param ttl Time-to-live value
##

proc net_if_ipv4_set_ttl*(iface: ptr net_if; ttl: uint8) {.
    importc: "net_if_ipv4_set_ttl", header: hdr.}


## *
##  @brief Check if this IPv4 address belongs to one of the interfaces.
##
##  @param addr IPv4 address
##  @param iface Interface is returned
##
##  @return Pointer to interface address, NULL if not found.
##

proc net_if_ipv4_addr_lookup*(caddr: ptr InAddr; iface: ptr ptr net_if): ptr net_if_addr {.
    importc: "net_if_ipv4_addr_lookup", header: hdr.}



## *
##  @brief Add a IPv4 address to an interface
##
##  @param iface Network interface
##  @param addr IPv4 address
##  @param addr_type IPv4 address type
##  @param vlifetime Validity time for this address
##
##  @return Pointer to interface address, NULL if cannot be added
##

proc net_if_ipv4_addr_add*(iface: ptr net_if; caddr: ptr InAddr;
                          addr_type: net_addr_type; vlifetime: uint32): ptr net_if_addr {.
    importc: "net_if_ipv4_addr_add", header: hdr.}



## *
##  @brief Remove a IPv4 address from an interface
##
##  @param iface Network interface
##  @param addr IPv4 address
##
##  @return True if successfully removed, false otherwise
##

proc net_if_ipv4_addr_rm*(iface: ptr net_if; caddr: ptr InAddr): bool {.
    importc: "net_if_ipv4_addr_rm", header: hdr.}



## *
##  @brief Check if this IPv4 address belongs to one of the interface indices.
##
##  @param addr IPv4 address
##
##  @return >0 if address was found in given network interface index,
##  all other values mean address was not found
##

proc net_if_ipv4_addr_lookup_by_index*(caddr: ptr InAddr): cint {.syscall,
    importc: "net_if_ipv4_addr_lookup_by_index", header: hdr.}



## *
##  @brief Add a IPv4 address to an interface by network interface index
##
##  @param index Network interface index
##  @param addr IPv4 address
##  @param addr_type IPv4 address type
##  @param vlifetime Validity time for this address
##
##  @return True if ok, false if the address could not be added
##

proc net_if_ipv4_addr_add_by_index*(index: cint; caddr: ptr InAddr;
                                   addr_type: net_addr_type; vlifetime: uint32): bool {.
    syscall, importc: "net_if_ipv4_addr_add_by_index", header: hdr.}



## *
##  @brief Remove a IPv4 address from an interface by interface index
##
##  @param index Network interface index
##  @param addr IPv4 address
##
##  @return True if successfully removed, false otherwise
##

proc net_if_ipv4_addr_rm_by_index*(index: cint; caddr: ptr InAddr): bool {.syscall,
    importc: "net_if_ipv4_addr_rm_by_index", header: hdr.}



## *
##  @brief Add a IPv4 multicast address to an interface
##
##  @param iface Network interface
##  @param addr IPv4 multicast address
##
##  @return Pointer to interface multicast address, NULL if cannot be added
##

proc net_if_ipv4_maddr_add*(iface: ptr net_if; caddr: ptr InAddr): ptr net_if_mcast_addr {.
    importc: "net_if_ipv4_maddr_add", header: hdr.}


## *
##  @brief Remove an IPv4 multicast address from an interface
##
##  @param iface Network interface
##  @param addr IPv4 multicast address
##
##  @return True if successfully removed, false otherwise
##

proc net_if_ipv4_maddr_rm*(iface: ptr net_if; caddr: ptr InAddr): bool {.
    importc: "net_if_ipv4_maddr_rm", header: hdr.}


## *
##  @brief Check if this IPv4 multicast address belongs to a specific interface
##  or one of the interfaces.
##
##  @param addr IPv4 address
##  @param iface If *iface is null, then pointer to interface is returned,
##  otherwise the *iface value needs to be matched.
##
##  @return Pointer to interface multicast address, NULL if not found.
##

proc net_if_ipv4_maddr_lookup*(caddr: ptr InAddr; iface: ptr ptr net_if): ptr net_if_mcast_addr {.
    importc: "net_if_ipv4_maddr_lookup", header: hdr.}


## *
##  @brief Mark a given multicast address to be joined.
##
##  @param addr IPv4 multicast address
##

proc net_if_ipv4_maddr_join*(caddr: ptr net_if_mcast_addr) {.
    importc: "net_if_ipv4_maddr_join", header: hdr.}


## *
##  @brief Check if given multicast address is joined or not.
##
##  @param addr IPv4 multicast address
##
##  @return True if address is joined, False otherwise.
##

proc net_if_ipv4_maddr_is_joined*(caddr: ptr net_if_mcast_addr): bool {.importc: "$1", header: hdr.}


## *
##  @brief Mark a given multicast address to be left.
##
##  @param addr IPv4 multicast address
##

proc net_if_ipv4_maddr_leave*(caddr: ptr net_if_mcast_addr) {.
    importc: "net_if_ipv4_maddr_leave", header: hdr.}


## *
##  @brief Get the IPv4 address of the given router
##  @param router a network router
##
##  @return pointer to the IPv4 address, or NULL if none
##

proc net_if_router_ipv4*(router: ptr net_if_router): ptr InAddr {.importc: "$1", header: hdr.}



## *
##  @brief Check if IPv4 address is one of the routers configured
##  in the system.
##
##  @param iface Network interface
##  @param addr IPv4 address
##
##  @return Pointer to router information, NULL if cannot be found
##

proc net_if_ipv4_router_lookup*(iface: ptr net_if; caddr: ptr InAddr): ptr net_if_router {.
    importc: "net_if_ipv4_router_lookup", header: hdr.}


## *
##  @brief Find default router for this IPv4 address.
##
##  @param iface Network interface. This can be NULL in which case we
##  go through all the network interfaces to find a suitable router.
##  @param addr IPv4 address
##
##  @return Pointer to router information, NULL if cannot be found
##

proc net_if_ipv4_router_find_default*(iface: ptr net_if; caddr: ptr InAddr): ptr net_if_router {.
    importc: "net_if_ipv4_router_find_default", header: hdr.}


## *
##  @brief Add IPv4 router to the system.
##
##  @param iface Network interface
##  @param addr IPv4 address
##  @param is_default Is this router the default one
##  @param router_lifetime Lifetime of the router
##
##  @return Pointer to router information, NULL if could not be added
##

proc net_if_ipv4_router_add*(iface: ptr net_if; caddr: ptr InAddr; is_default: bool;
                            router_lifetime: uint16): ptr net_if_router {.
    importc: "net_if_ipv4_router_add", header: hdr.}


## *
##  @brief Remove IPv4 router from the system.
##
##  @param router Router information.
##
##  @return True if successfully removed, false otherwise
##

proc net_if_ipv4_router_rm*(router: ptr net_if_router): bool {.
    importc: "net_if_ipv4_router_rm", header: hdr.}


## *
##  @brief Check if the given IPv4 address belongs to local subnet.
##
##  @param iface Interface to use. Must be a valid pointer to an interface.
##  @param addr IPv4 address
##
##  @return True if address is part of local subnet, false otherwise.
##

proc net_if_ipv4_addr_mask_cmp*(iface: ptr net_if; caddr: ptr InAddr): bool {.
    importc: "net_if_ipv4_addr_mask_cmp", header: hdr.}


## *
##  @brief Check if the given IPv4 address is a broadcast address.
##
##  @param iface Interface to use. Must be a valid pointer to an interface.
##  @param addr IPv4 address, this should be in network byte order
##
##  @return True if address is a broadcast address, false otherwise.
##

proc net_if_ipv4_is_addr_bcast*(iface: ptr net_if; caddr: ptr InAddr): bool {.
    importc: "net_if_ipv4_is_addr_bcast", header: hdr.}


## *
##  @brief Get a network interface that should be used when sending
##  IPv4 network data to destination.
##
##  @param dst IPv4 destination address
##
##  @return Pointer to network interface to use, NULL if no suitable interface
##  could be found.
##

proc net_if_ipv4_select_src_iface*(dst: ptr InAddr): ptr net_if {.
      importc: "net_if_ipv4_select_src_iface", header: hdr.}



## *
##  @brief Get a IPv4 source address that should be used when sending
##  network data to destination.
##
##  @param iface Interface to use when sending the packet.
##  If the interface is not known, then NULL can be given.
##  @param dst IPv4 destination address
##
##  @return Pointer to IPv4 address to use, NULL if no IPv4 address
##  could be found.
##

proc net_if_ipv4_select_src_addr*(iface: ptr net_if; dst: ptr InAddr): ptr InAddr {.
      importc: "net_if_ipv4_select_src_addr", header: hdr.}



## *
##  @brief Get a IPv4 link local address in a given state.
##
##  @param iface Interface to use. Must be a valid pointer to an interface.
##  @param addr_state IPv4 address state (preferred, tentative, deprecated)
##
##  @return Pointer to link local IPv4 address, NULL if no proper IPv4 address
##  could be found.
##

proc net_if_ipv4_get_ll*(iface: ptr net_if; addr_state: net_addr_state): ptr InAddr {.
    importc: "net_if_ipv4_get_ll", header: hdr.}


## *
##  @brief Get a IPv4 global address in a given state.
##
##  @param iface Interface to use. Must be a valid pointer to an interface.
##  @param addr_state IPv4 address state (preferred, tentative, deprecated)
##
##  @return Pointer to link local IPv4 address, NULL if no proper IPv4 address
##  could be found.
##

proc net_if_ipv4_get_global_addr*(iface: ptr net_if; addr_state: net_addr_state): ptr InAddr {.
    importc: "net_if_ipv4_get_global_addr", header: hdr.}


## *
##  @brief Set IPv4 netmask for an interface.
##
##  @param iface Interface to use.
##  @param netmask IPv4 netmask
##

proc net_if_ipv4_set_netmask*(iface: ptr net_if; netmask: ptr InAddr) {.
    importc: "net_if_ipv4_set_netmask", header: hdr.}


## *
##  @brief Set IPv4 netmask for an interface index.
##
##  @param index Network interface index
##  @param netmask IPv4 netmask
##
##  @return True if netmask was added, false otherwise.
##

proc net_if_ipv4_set_netmask_by_index*(index: cint; netmask: ptr InAddr): bool {.
    syscall, importc: "net_if_ipv4_set_netmask_by_index", header: hdr.}


## *
##  @brief Set IPv4 gateway for an interface.
##
##  @param iface Interface to use.
##  @param gw IPv4 address of an gateway
##

proc net_if_ipv4_set_gw*(iface: ptr net_if; gw: ptr InAddr) {.
    importc: "net_if_ipv4_set_gw", header: hdr.}


## *
##  @brief Set IPv4 gateway for an interface index.
##
##  @param index Network interface index
##  @param gw IPv4 address of an gateway
##
##  @return True if gateway was added, false otherwise.
##

proc net_if_ipv4_set_gw_by_index*(index: cint; gw: ptr InAddr): bool {.syscall,
    importc: "net_if_ipv4_set_gw_by_index", header: hdr.}


## *
##  @brief Get a network interface that should be used when sending
##  IPv6 or IPv4 network data to destination.
##
##  @param dst IPv6 or IPv4 destination address
##
##  @return Pointer to network interface to use. Note that the function
##  will return the default network interface if the best network interface
##  is not found.
##

proc net_if_select_src_iface*(dst: ptr SockAddr): ptr net_if {.
    importc: "net_if_select_src_iface", header: hdr.}




## *
##  @brief Register a link callback.
##
##  @param link Caller specified handler for the callback.
##  @param cb Callback to register.
##

proc net_if_register_link_cb*(link: ptr net_if_link_cb; cb: net_if_link_callback_t) {.
    importc: "net_if_register_link_cb", header: hdr.}


## *
##  @brief Unregister a link callback.
##
##  @param link Caller specified handler for the callback.
##

proc net_if_unregister_link_cb*(link: ptr net_if_link_cb) {.
    importc: "net_if_unregister_link_cb", header: hdr.}


## *
##  @brief Call a link callback function.
##
##  @param iface Network interface.
##  @param lladdr Destination link layer address
##  @param status 0 is ok, < 0 error
##

proc net_if_call_link_cb*(iface: ptr net_if; lladdr: ptr net_linkaddr; status: cint) {.
    importc: "net_if_call_link_cb", header: hdr.}


## *
##  @brief Check if received network packet checksum calculation can be avoided
##  or not. For example many ethernet devices support network packet offloading
##  in which case the IP stack does not need to calculate the checksum.
##
##  @param iface Network interface
##
##  @return True if checksum needs to be calculated, false otherwise.
##

proc net_if_need_calc_rx_checksum*(iface: ptr net_if): bool {.
    importc: "net_if_need_calc_rx_checksum", header: hdr.}


## *
##  @brief Check if network packet checksum calculation can be avoided or not
##  when sending the packet. For example many ethernet devices support network
##  packet offloading in which case the IP stack does not need to calculate the
##  checksum.
##
##  @param iface Network interface
##
##  @return True if checksum needs to be calculated, false otherwise.
##

proc net_if_need_calc_tx_checksum*(iface: ptr net_if): bool {.
    importc: "net_if_need_calc_tx_checksum", header: hdr.}


## *
##  @brief Get interface according to index
##
##  @details This is a syscall only to provide access to the object for purposes
##           of assigning permissions.
##
##  @param index Interface index
##
##  @return Pointer to interface or NULL if not found.
##

proc net_if_get_by_index*(index: cint): ptr net_if {.syscall,
    importc: "net_if_get_by_index", header: hdr.}


## *
##  @brief Get interface index according to pointer
##
##  @param iface Pointer to network interface
##
##  @return Interface index
##

proc net_if_get_by_iface*(iface: ptr net_if): cint {.importc: "net_if_get_by_iface",
    header: hdr.}


## *
##  @typedef net_if_cb_t
##  @brief Callback used while iterating over network interfaces
##
##  @param iface Pointer to current network interface
##  @param user_data A valid pointer to user data or NULL
##

type
  net_if_cb_t* = proc (iface: ptr net_if; user_data: pointer)



## *
##  @brief Go through all the network interfaces and call callback
##  for each interface.
##
##  @param cb User-supplied callback function to call
##  @param user_data User specified data
##

proc net_if_foreach*(cb: net_if_cb_t; user_data: pointer) {.
    importc: "net_if_foreach", header: hdr.}


## *
##  @brief Bring interface up
##
##  @param iface Pointer to network interface
##
##  @return 0 on success
##

proc net_if_up*(iface: ptr net_if): cint {.importc: "net_if_up", header: hdr.}


## *
##  @brief Check if interface is up.
##
##  @param iface Pointer to network interface
##
##  @return True if interface is up, False if it is down.
##

proc net_if_is_up*(iface: ptr net_if): bool {.importc: "$1", header: hdr.}



## *
##  @brief Bring interface down
##
##  @param iface Pointer to network interface
##
##  @return 0 on success
##

proc net_if_down*(iface: ptr net_if): cint {.importc: "net_if_down", header: hdr.}

when CONFIG_NET_PKT_TIMESTAMP and CONFIG_NET_NATIVE:
  ## *
  ##  @typedef net_if_timestamp_callback_t
  ##  @brief Define callback that is called after a network packet
  ##         has been timestamped.
  ##  @param "struct net_pkt *pkt" A pointer on a struct net_pkt which has
  ##         been timestamped after being sent.
  ##
  type
    net_if_timestamp_callback_t* = proc (pkt: ptr net_pkt)
  
  ##  @brief Timestamp callback handler struct.
  ##
  ##  Stores the timestamp callback information. Caller must make sure that
  ##  the variable pointed by this is valid during the lifetime of
  ##  registration. Typically this means that the variable cannot be
  ##  allocated from stack.
  ##
  type
    net_if_timestamp_cb* {.importc: "net_if_timestamp_cb", header: hdr, bycopy.} = object
      node* {.importc: "node".}: sys_snode_t ## * Node information for the slist.
      pkt* {.importc: "pkt".}: ptr net_pkt ## * Packet for which the callback is needed. A NULL value means all packets.
      iface* {.importc: "iface".}: ptr net_if ## * Net interface for which the callback is needed.  A NULL value means all interfaces.
      cb* {.importc: "cb".}: net_if_timestamp_callback_t ## * Timestamp callback

  

  ##  @brief Register a timestamp callback.
  ##
  ##  @param handle Caller specified handler for the callback.
  ##  @param pkt Net packet for which the callback is registered. NULL for all
  ##  	      packets.
  ##  @param iface Net interface for which the callback is. NULL for all
  ## 		interfaces.
  ##  @param cb Callback to register.
  ##
  proc net_if_register_timestamp_cb*(handle: ptr net_if_timestamp_cb;
                                    pkt: ptr net_pkt; iface: ptr net_if;
                                    cb: net_if_timestamp_callback_t) {.
      importc: "net_if_register_timestamp_cb", header: hdr.}
  

  ##  @brief Unregister a timestamp callback.
  ##
  ##  @param handle Caller specified handler for the callback.
  ##
  proc net_if_unregister_timestamp_cb*(handle: ptr net_if_timestamp_cb) {.
      importc: "net_if_unregister_timestamp_cb", header: hdr.}
  

  ##  @brief Call a timestamp callback function.
  ##
  ##  @param pkt Network buffer.
  ##
  proc net_if_call_timestamp_cb*(pkt: ptr net_pkt) {.
      importc: "net_if_call_timestamp_cb", header: hdr.}
  ##
  ##  @brief Add timestamped TX buffer to be handled
  ##
  ##  @param pkt Timestamped buffer
  ##
  proc net_if_add_tx_timestamp*(pkt: ptr net_pkt) {.
      importc: "net_if_add_tx_timestamp", header: hdr.}


## *
##  @brief Set network interface into promiscuous mode
##
##  @details Note that not all network technologies will support this.
##
##  @param iface Pointer to network interface
##
##  @return 0 on success, <0 if error
##

proc net_if_set_promisc*(iface: ptr net_if): cint {.importc: "net_if_set_promisc",
    header: hdr.}


## *
##  @brief Set network interface into normal mode
##
##  @param iface Pointer to network interface
##

proc net_if_unset_promisc*(iface: ptr net_if) {.importc: "net_if_unset_promisc",
    header: hdr.}


## *
##  @brief Check if promiscuous mode is set or not.
##
##  @param iface Pointer to network interface
##
##  @return True if interface is in promisc mode,
##          False if interface is not in in promiscuous mode.
##

proc net_if_is_promisc*(iface: ptr net_if): bool {.importc: "net_if_is_promisc",
    header: hdr.}


## *
##  @brief Check if there are any pending TX network data for a given network
##         interface.
##
##  @param iface Pointer to network interface
##
##  @return True if there are pending TX network packets for this network
##          interface, False otherwise.
##

proc net_if_are_pending_tx_packets*(iface: ptr net_if): bool {.importc: "$1", header: hdr.}

when CONFIG_NET_POWER_MANAGEMENT:
  ##  @brief Suspend a network interface from a power management perspective
  ##
  ##  @param iface Pointer to network interface
  ##
  ##  @return 0 on success, or -EALREADY/-EBUSY as possible errors.
  ##
  proc net_if_suspend*(iface: ptr net_if): cint {.importc: "net_if_suspend",
      header: hdr.}
  

  ##  @brief Resume a network interface from a power management perspective
  ##
  ##  @param iface Pointer to network interface
  ##
  ##  @return 0 on success, or -EALREADY as a possible error.
  ##
  proc net_if_resume*(iface: ptr net_if): cint {.importc: "net_if_resume",
      header: hdr.}
  
  ##  @brief Check if the network interface is suspended or not.
  ##
  ##  @param iface Pointer to network interface
  ##
  ##  @return True if interface is suspended, False otherwise.
  ##
  proc net_if_is_suspended*(iface: ptr net_if): bool {.
      importc: "net_if_is_suspended", header: hdr.}


type
  net_if_api* {.importc: "net_if_api", header: hdr, bycopy.} = object
    init* {.importc: "init".}: proc (iface: ptr net_if)

