## * @file
##  @brief IPv6 and IPv4 definitions
##
##  Generic IPv6 and IPv4 address definitions.
##
##
##  Copyright (c) 2016 Intel Corporation
##
##  SPDX-License-Identifier: Apache-2.0
##

## *
##  @brief IPv4/IPv6 primitives and helpers
##  @defgroup ip_4_6 IPv4/IPv6 primitives and helpers
##  @ingroup networking
##  @{
##

const hdr = "<net/net_ip.h>"

var PF_UNSPEC* {.importc: "PF_UNSPEC", header: hdr.}: int
##  Address families.

var AF_UNSPEC* {.importc: "AF_UNSPEC", header: hdr.}: int
## * Protocol numbers from IANA/BSD

type
  net_ip_protocol* {.size: sizeof(uint16).} = enum
    IPPROTO_IP = 0,             ## *< IP protocol (pseudo-val for setsockopt()
    IPPROTO_ICMP = 1,           ## *< ICMP protocol
    IPPROTO_IGMP = 2,           ## *< IGMP protocol
    IPPROTO_IPIP = 4,           ## *< IPIP tunnels
    IPPROTO_TCP = 6,            ## *< TCP protocol
    IPPROTO_UDP = 17,           ## *< UDP protocol
    IPPROTO_IPV6 = 41,          ## *< IPv6 protocol
    IPPROTO_ICMPV6 = 58,        ## *< ICMPv6 protocol
    IPPROTO_RAW = 255           ## *< RAW IP packets


## * Protocol numbers for TLS protocols

type
  net_ip_protocol_secure* {.size: sizeof(uint16).} = enum
    IPPROTO_TLS_1_0 = 256,      ## *< TLS 1.0 protocol
    IPPROTO_TLS_1_1 = 257,      ## *< TLS 1.1 protocol
    IPPROTO_TLS_1_2 = 258,      ## *< TLS 1.2 protocol
    IPPROTO_DTLS_1_0 = 272,     ## *< DTLS 1.0 protocol
    IPPROTO_DTLS_1_2 = 273      ## *< DTLS 1.2 protocol


## * Socket type

type
  net_sock_type* {.size: sizeof(uint16).} = enum
    SOCK_STREAM = 1,            ## *< Stream socket type
    SOCK_DGRAM,               ## *< Datagram socket type
    SOCK_RAW                  ## *< RAW socket type

#[

  ======================== ========================= ====================== 
  ======================= Use Nim std/posix instead  ====================== 
  ======================== ========================= ====================== 


## * @brief Convert 16-bit value from network to host byte order.
##
##  @param x The network byte order value to convert.
##
##  @return Host byte order value.
##
proc ntohs*(x: untyped) {.importc: "ntohs", header: hdr.}

## * @brief Convert 32-bit value from network to host byte order.
##
##  @param x The network byte order value to convert.
##
##  @return Host byte order value.
##
proc ntohl*(x: untyped) {.importc: "ntohl", header: hdr.}

## * @brief Convert 64-bit value from network to host byte order.
##
##  @param x The network byte order value to convert.
##
##  @return Host byte order value.
##
proc ntohll*(x: untyped) {.importc: "ntohll", header: hdr.}

## * @brief Convert 16-bit value from host to network byte order.
##
##  @param x The host byte order value to convert.
##
##  @return Network byte order value.
##
proc htons*(x: untyped) {.importc: "htons", header: hdr.}

## * @brief Convert 32-bit value from host to network byte order.
##
##  @param x The host byte order value to convert.
##
##  @return Network byte order value.
##
proc htonl*(x: untyped) {.importc: "htonl", header: hdr.}

## * @brief Convert 64-bit value from host to network byte order.
##
##  @param x The host byte order value to convert.
##
##  @return Network byte order value.
##
proc htonll*(x: untyped) {.importc: "htonll", header: hdr.}


type
  INNER_C_UNION_net_ip_0* {.importc: "no_name", header: hdr, bycopy, union.} = object
    s6_addr* {.importc: "s6_addr".}: array[16, uint8]
    s6_addr16* {.importc: "s6_addr16".}: array[8, uint16] ##  In big endian
    s6_addr32* {.importc: "s6_addr32".}: array[4, uint32] ##  In big endian

  ## * IPv6 address struct
  In6Addr* {.importc: "In6Addr", header: hdr, bycopy.} = object
    ano_net_ip_1* {.importc: "ano_net_ip_1".}: INNER_C_UNION_net_ip_0


## * IPv4 address struct

type
  INNER_C_UNION_net_ip_2* {.importc: "no_name", header: hdr, bycopy, union.} = object
    s4_addr* {.importc: "s4_addr".}: array[4, uint8]
    s4_addr16* {.importc: "s4_addr16".}: array[2, uint16] ##  In big endian
    s4_addr32* {.importc: "s4_addr32".}: array[1, uint32] ##  In big endian
    s_addr* {.importc: "s_addr".}: uint32 ##  In big endian, for POSIX compatibility.

  InAddr* {.importc: "InAddr", header: hdr, bycopy.} = object
    ano_net_ip_3* {.importc: "ano_net_ip_3".}: INNER_C_UNION_net_ip_2


## * Socket address family type

type
  sa_family_t* = uint16

## * Length of a socket address

type
  socklen_t* = csize_t

##
##  Note that the sin_port and sin6_port are in network byte order
##  in various sockaddr* structs.
##
## * Socket address struct for IPv6.

type
  sockaddr_in6* {.importc: "sockaddr_in6", header: hdr, bycopy.} = object
    sin6_family* {.importc: "sin6_family".}: sa_family_t ##  AF_INET6
    sin6_port* {.importc: "sin6_port".}: uint16 ##  Port number
    sin6_addr* {.importc: "sin6_addr".}: In6Addr ##  IPv6 address
    sin6_scope_id* {.importc: "sin6_scope_id".}: uint8 ##  interfaces for a scope

  sockaddr_in6_ptr* {.importc: "sockaddr_in6_ptr", header: hdr, bycopy.} = object
    sin6_family* {.importc: "sin6_family".}: sa_family_t ##  AF_INET6
    sin6_port* {.importc: "sin6_port".}: uint16 ##  Port number
    sin6_addr* {.importc: "sin6_addr".}: ptr In6Addr ##  IPv6 address
    sin6_scope_id* {.importc: "sin6_scope_id".}: uint8 ##  interfaces for a scope


## * Socket address struct for IPv4.

type
  sockaddr_in* {.importc: "sockaddr_in", header: hdr, bycopy.} = object
    sin_family* {.importc: "sin_family".}: sa_family_t ##  AF_INET
    sin_port* {.importc: "sin_port".}: uint16 ##  Port number
    sin_addr* {.importc: "sin_addr".}: InAddr ##  IPv4 address

  sockaddr_in_ptr* {.importc: "sockaddr_in_ptr", header: hdr, bycopy.} = object
    sin_family* {.importc: "sin_family".}: sa_family_t ##  AF_INET
    sin_port* {.importc: "sin_port".}: uint16 ##  Port number
    sin_addr* {.importc: "sin_addr".}: ptr InAddr ##  IPv4 address


## * Socket address struct for packet socket.

type
  sockaddr_ll* {.importc: "sockaddr_ll", header: hdr, bycopy.} = object
    sll_family* {.importc: "sll_family".}: sa_family_t ##  Always AF_PACKET
    sll_protocol* {.importc: "sll_protocol".}: uint16 ##  Physical-layer protocol
    sll_ifindex* {.importc: "sll_ifindex".}: cint ##  Interface number
    sll_hatype* {.importc: "sll_hatype".}: uint16 ##  ARP hardware type
    sll_pkttype* {.importc: "sll_pkttype".}: uint8 ##  Packet type
    sll_halen* {.importc: "sll_halen".}: uint8 ##  Length of address
    sll_addr* {.importc: "sll_addr".}: array[8, uint8] ##  Physical-layer address

  sockaddr_ll_ptr* {.importc: "sockaddr_ll_ptr", header: hdr, bycopy.} = object
    sll_family* {.importc: "sll_family".}: sa_family_t ##  Always AF_PACKET
    sll_protocol* {.importc: "sll_protocol".}: uint16 ##  Physical-layer protocol
    sll_ifindex* {.importc: "sll_ifindex".}: cint ##  Interface number
    sll_hatype* {.importc: "sll_hatype".}: uint16 ##  ARP hardware type
    sll_pkttype* {.importc: "sll_pkttype".}: uint8 ##  Packet type
    sll_halen* {.importc: "sll_halen".}: uint8 ##  Length of address
    sll_addr* {.importc: "sll_addr".}: ptr uint8 ##  Physical-layer address

  sockaddr_can_ptr* {.importc: "sockaddr_can_ptr", header: hdr, bycopy.} = object
    can_family* {.importc: "can_family".}: sa_family_t
    can_ifindex* {.importc: "can_ifindex".}: cint


when not defined(HAVE_IOVEC):
  type
    iovec* {.importc: "iovec", header: hdr, bycopy.} = object
      iov_base* {.importc: "iov_base".}: pointer
      iov_len* {.importc: "iov_len".}: csize_t

type
  msghdr* {.importc: "msghdr", header: hdr, bycopy.} = object
    msg_name* {.importc: "msg_name".}: pointer ##  optional socket address
    msg_namelen* {.importc: "msg_namelen".}: socklen_t ##  size of socket address
    msg_iov* {.importc: "msg_iov".}: ptr iovec ##  scatter/gather array
    msg_iovlen* {.importc: "msg_iovlen".}: csize_t ##  number of elements in msg_iov
    msg_control* {.importc: "msg_control".}: pointer ##  ancillary data
    msg_controllen* {.importc: "msg_controllen".}: csize_t ##  ancillary data buffer len
    msg_flags* {.importc: "msg_flags".}: cint ##  flags on received message

  cmsghdr* {.importc: "cmsghdr", header: hdr, bycopy.} = object
    cmsg_len* {.importc: "cmsg_len".}: socklen_t ##  Number of bytes, including header
    cmsg_level* {.importc: "cmsg_level".}: cint ##  Originating protocol
    cmsg_type* {.importc: "cmsg_type".}: cint ##  Protocol-specific type
                                          ##  Flexible array member to force alignment of cmsghdr
    cmsg_data* {.importc: "cmsg_data".}: UncheckedArray[z_max_align_t]


##  Alignment for headers and data. These are arch specific but define
##  them here atm if not found alredy.
##

when not defined(ALIGN_H):
  proc ALIGN_H*(x: untyped) {.importc: "ALIGN_H", header: hdr.}
when not defined(ALIGN_D):
  proc ALIGN_D*(x: untyped) {.importc: "ALIGN_D", header: hdr.}
when not defined(CMSG_FIRSTHDR):
  proc CMSG_FIRSTHDR*(msghdr: untyped) {.importc: "CMSG_FIRSTHDR", header: hdr.}
when not defined(CMSG_NXTHDR):
  proc CMSG_NXTHDR*(msghdr: untyped; cmsg: untyped) {.importc: "CMSG_NXTHDR",
      header: hdr.}
when not defined(CMSG_DATA):
  proc CMSG_DATA*(cmsg: untyped) {.importc: "CMSG_DATA", header: hdr.}
when not defined(CMSG_SPACE):
  proc CMSG_SPACE*(length: untyped) {.importc: "CMSG_SPACE", header: hdr.}
when not defined(CMSG_LEN):
  proc CMSG_LEN*(length: untyped) {.importc: "CMSG_LEN", header: hdr.}
## * @cond INTERNAL_HIDDEN
##  Packet types.

var PACKET_HOST* {.importc: "PACKET_HOST", header: hdr.}: int
##  Note: These macros are defined in a specific order.
##  The largest sockaddr size is the last one.
##

when defined(CONFIG_NET_IPV4):
  var NET_SOCKADDR_MAX_SIZE* {.importc: "NET_SOCKADDR_MAX_SIZE", header: hdr.}: int
when defined(CONFIG_NET_SOCKETS_PACKET):
  var NET_SOCKADDR_MAX_SIZE* {.importc: "NET_SOCKADDR_MAX_SIZE", header: hdr.}: int
when defined(CONFIG_NET_IPV6):
  var NET_SOCKADDR_MAX_SIZE* {.importc: "NET_SOCKADDR_MAX_SIZE", header: hdr.}: int
  when not defined(CONFIG_NET_SOCKETS_PACKET):
    var NET_SOCKADDR_PTR_MAX_SIZE* {.importc: "NET_SOCKADDR_PTR_MAX_SIZE",
                                   header: hdr.}: int
when not defined(CONFIG_NET_IPV4):
  when not defined(CONFIG_NET_IPV6):
    when not defined(CONFIG_NET_SOCKETS_PACKET):
      var NET_SOCKADDR_MAX_SIZE* {.importc: "NET_SOCKADDR_MAX_SIZE",
                                 header: hdr.}: int
## * @endcond
## * Generic sockaddr struct. Must be cast to proper type.

type
  sockaddr* {.importc: "sockaddr", header: hdr, bycopy.} = object
    sa_family* {.importc: "sa_family".}: sa_family_t
    data* {.importc: "data".}: array[NET_SOCKADDR_MAX_SIZE - sizeof((sa_family_t)),
                                  char]


## * @cond INTERNAL_HIDDEN

type
  sockaddr_ptr* {.importc: "sockaddr_ptr", header: hdr, bycopy.} = object
    family* {.importc: "family".}: sa_family_t
    data* {.importc: "data".}: array[NET_SOCKADDR_PTR_MAX_SIZE -
        sizeof((sa_family_t)), char]


##  Same as sockaddr in our case

type
  sockaddr_storage* {.importc: "sockaddr_storage", header: hdr, bycopy.} = object
    ss_family* {.importc: "ss_family".}: sa_family_t
    data* {.importc: "data".}: array[NET_SOCKADDR_MAX_SIZE - sizeof((sa_family_t)),
                                  char]


##  Socket address struct for UNIX domain sockets

type
  sockaddr_un* {.importc: "sockaddr_un", header: hdr, bycopy.} = object
    sun_family* {.importc: "sun_family".}: sa_family_t ##  AF_UNIX
    sun_path* {.importc: "sun_path".}: array[
        NET_SOCKADDR_MAX_SIZE - sizeof((sa_family_t)), char]

  INNER_C_UNION_net_ip_4* {.importc: "no_name", header: hdr, bycopy, union.} = object
    In6Addr* {.importc: "In6Addr".}: In6Addr
    InAddr* {.importc: "InAddr".}: InAddr

  NetAddr* {.importc: "NetAddr", header: hdr, bycopy.} = object
    family* {.importc: "family".}: sa_family_t
    ano_net_ip_5* {.importc: "ano_net_ip_5".}: INNER_C_UNION_net_ip_4


var IN6ADDR_ANY_INIT* {.importc: "IN6ADDR_ANY_INIT", header: hdr.}: int
let in6addr_any* {.importc: "in6addr_any", header: hdr.}: In6Addr

let in6addr_loopback* {.importc: "in6addr_loopback", header: hdr.}: In6Addr

## * @endcond
## * Max length of the IPv4 address as a string. Defined by POSIX.

var INET_ADDRSTRLEN* {.importc: "INET_ADDRSTRLEN", header: hdr.}: int
## * Max length of the IPv6 address as a string. Takes into account possible
##  mapped IPv4 addresses.
##

var INET6_ADDRSTRLEN* {.importc: "INET6_ADDRSTRLEN", header: hdr.}: int
## * @cond INTERNAL_HIDDEN
##  These are for internal usage of the stack

var NET_IPV6_ADDR_LEN* {.importc: "NET_IPV6_ADDR_LEN", header: hdr.}: int
## * @endcond

]#

import posix

type

  NetAddr* {.importc: "NetAddr", header: hdr, bycopy, incompleteStruct.} = object
    family* {.importc: "family".}: TSa_Family
    ## the C code uses an anonymous union 
    In6Addr* {.importc: "In6Addr".}: In6Addr
    InAddr* {.importc: "InAddr".}: InAddr


type
  net_ip_mtu* {.size: sizeof(cint).} = enum
    NET_IPV4_MTU = 576, ## *\
      ## IPv6 MTU length. We must be able to receive this size IPv6 packet
      ##  without fragmentation.
      ##
    NET_IPV6_MTU = 1280 ## *\
      ## IPv4 MTU length. We must be able to receive this size IPv4 packet
      ##  without fragmentation.
      ##


type
  net_priority* {.size: sizeof(uint8).} = enum
    ## * Network packet priority settings described in IEEE 802.1Q Annex I.1
    NET_PRIORITY_BE = 0,        ## *< Best effort (default)
    NET_PRIORITY_BK = 1,        ## *< Background (lowest)
    NET_PRIORITY_EE = 2,        ## *< Excellent effort
    NET_PRIORITY_CA = 3,        ## *< Critical applications (highest)
    NET_PRIORITY_VI = 4,        ## *< Video, < 100 ms latency and jitter
    NET_PRIORITY_VO = 5,        ## *< Voice, < 10 ms latency and jitter
    NET_PRIORITY_IC = 6,        ## *< Internetwork control
    NET_PRIORITY_NC = 7         ## *< Network control


var NET_MAX_PRIORITIES* {.importc: "NET_MAX_PRIORITIES", header: hdr.}: int
## * IPv6/IPv4 network connection tuple

type
  net_tuple* {.importc: "net_tuple", header: hdr, bycopy.} = object
    remote_addr* {.importc: "remote_addr".}: ptr NetAddr ## *< IPv6/IPv4 remote address
    local_addr* {.importc: "local_addr".}: ptr NetAddr ## *< IPv6/IPv4 local address
    remote_port* {.importc: "remote_port".}: uint16 ## *< UDP/TCP remote port
    local_port* {.importc: "local_port".}: uint16 ## *< UDP/TCP local port
    ip_proto* {.importc: "ip_proto".}: net_ip_protocol ## *< IP protocol



type
  net_addr_state* {.size: sizeof(uint8).} = enum
    ## * What is the current state of the network address
    NET_ADDR_ANY_STATE = -1,    ## *< Default (invalid) address type
    NET_ADDR_TENTATIVE = 0,     ## *< Tentative address
    NET_ADDR_PREFERRED,       ## *< Preferred address
    NET_ADDR_DEPRECATED       ## *< Deprecated address

  net_addr_type* {.size: sizeof(uint8).} = enum ## * Default value. This is not a valid value.
  ## * How the network address is assigned to network interface
    NET_ADDR_ANY = 0,           ## * Auto configured address
    NET_ADDR_AUTOCONF,        ## * Address is from DHCP
    NET_ADDR_DHCP,            ## * Manually set address
    NET_ADDR_MANUAL,          ## * Manually set address which is overridable by DHCP
    NET_ADDR_OVERRIDABLE


## * @cond INTERNAL_HIDDEN

type
  net_ipv6_hdr* {.importc: "net_ipv6_hdr", header: hdr, bycopy, packed.} = object
    vtc* {.importc: "vtc".}: uint8
    tcflow* {.importc: "tcflow".}: uint8
    flow* {.importc: "flow".}: uint16
    len* {.importc: "len".}: uint16
    nexthdr* {.importc: "nexthdr".}: uint8
    hop_limit* {.importc: "hop_limit".}: uint8
    src* {.importc: "src".}: In6Addr
    dst* {.importc: "dst".}: In6Addr

  net_ipv6_frag_hdr* {.importc: "net_ipv6_frag_hdr", header: hdr, bycopy, packed.} = object
    nexthdr* {.importc: "nexthdr".}: uint8
    reserved* {.importc: "reserved".}: uint8
    offset* {.importc: "offset".}: uint16
    id* {.importc: "id".}: uint32

  net_ipv4_hdr* {.importc: "net_ipv4_hdr", header: hdr, bycopy, packed.} = object
    vhl* {.importc: "vhl".}: uint8
    tos* {.importc: "tos".}: uint8
    len* {.importc: "len".}: uint16
    id* {.importc: "id".}: array[2, uint8]
    offset* {.importc: "offset".}: array[2, uint8]
    ttl* {.importc: "ttl".}: uint8
    proto* {.importc: "proto".}: uint8
    chksum* {.importc: "chksum".}: uint16
    src* {.importc: "src".}: InAddr
    dst* {.importc: "dst".}: InAddr

  net_icmp_hdr* {.importc: "net_icmp_hdr", header: hdr, bycopy, packed.} = object
    typ* {.importc: "type".}: uint8
    code* {.importc: "code".}: uint8
    chksum* {.importc: "chksum".}: uint16

  net_udp_hdr* {.importc: "net_udp_hdr", header: hdr, bycopy, packed.} = object
    src_port* {.importc: "src_port".}: uint16
    dst_port* {.importc: "dst_port".}: uint16
    len* {.importc: "len".}: uint16
    chksum* {.importc: "chksum".}: uint16

  net_tcp_hdr* {.importc: "net_tcp_hdr", header: hdr, bycopy, packed.} = object
    src_port* {.importc: "src_port".}: uint16
    dst_port* {.importc: "dst_port".}: uint16
    seq* {.importc: "seq".}: array[4, uint8]
    ack* {.importc: "ack".}: array[4, uint8]
    offset* {.importc: "offset".}: uint8
    flags* {.importc: "flags".}: uint8
    wnd* {.importc: "wnd".}: array[2, uint8]
    chksum* {.importc: "chksum".}: uint16
    urg* {.importc: "urg".}: array[2, uint8]
    optdata* {.importc: "optdata".}: UncheckedArray[uint8]


proc net_addr_type2str*(addrType: net_addr_type): cstring {.importc: "$1", header: hdr.}


##  IPv6 extension headers types

var NET_IPV6_NEXTHDR_HBHO* {.importc: "NET_IPV6_NEXTHDR_HBHO", header: hdr.}: cint
## *
##  This 2 unions are here temporarily, as long as net_context.h will
##  be still public and not part of the core only.
##

type
  net_ip_header* {.importc: "net_ip_header", header: hdr, bycopy, union.} = object
    ipv4* {.importc: "ipv4".}: ptr net_ipv4_hdr
    ipv6* {.importc: "ipv6".}: ptr net_ipv6_hdr

  net_proto_header* {.importc: "net_proto_header", header: hdr, bycopy, union.} = object
    udp* {.importc: "udp".}: ptr net_udp_hdr
    tcp* {.importc: "tcp".}: ptr net_tcp_hdr

var NET_UDPH_LEN* {.importc: "NET_UDPH_LEN", header: hdr.}: cint


## *
##  @brief Check if the IPv6 address is a loopback address (::1).
##
##  @param addr IPv6 address
##
##  @return True if address is a loopback address, False otherwise.
##
proc net_ipv6_is_addr_loopback*(inaddr: ptr In6Addr): bool {.importc: "$1", header: hdr.}


## *
##  @brief Check if the IPv6 address is a multicast address.
##
##  @param addr IPv6 address
##
##  @return True if address is multicast address, False otherwise.
##
proc net_ipv6_is_addr_mcast*(inaddr: ptr In6Addr): bool {.importc: "$1", header: hdr.}

# TODO: FIXME
# proc net_if_ipv6_addr_lookup*(inaddr: ptr In6Addr; iface: ptr ptr net_if): ptr net_if_addr {.
    # importc: "net_if_ipv6_addr_lookup", header: hdr.}


## *
##  @brief Check if IPv6 address is found in one of the network interfaces.
##
##  @param addr IPv6 address
##
##  @return True if address was found, False otherwise.
##
proc net_ipv6_is_my_addr*(inaddr: ptr In6Addr): bool {.importc: "$1", header: hdr.}

# TODO: FIXME
# proc net_if_ipv6_maddr_lookup*(inaddr: ptr In6Addr; iface: ptr ptr net_if): ptr net_if_mcast_addr {.
    # importc: "net_if_ipv6_maddr_lookup", header: hdr.}


## *
##  @brief Check if IPv6 multicast address is found in one of the
##  network interfaces.
##
##  @param maddr Multicast IPv6 address
##
##  @return True if address was found, False otherwise.
##

proc net_ipv6_is_my_maddr*(maddr: ptr In6Addr): bool {.importc: "$1", header: hdr.}

## *
##  @brief Check if two IPv6 addresses are same when compared after prefix mask.
##
##  @param addr1 First IPv6 address.
##  @param addr2 Second IPv6 address.
##  @param length Prefix length (max length is 128).
##
##  @return True if IPv6 prefixes are the same, False otherwise.
##

proc net_ipv6_is_prefix*(addr1: ptr uint8; addr2: ptr uint8; length: uint8): bool {.
    importc: "$1", header: hdr.}

## *
##  @brief Check if the IPv4 address is a loopback address (127.0.0.0/8).
##
##  @param addr IPv4 address
##
##  @return True if address is a loopback address, False otherwise.
##

proc net_ipv4_is_addr_loopback*(inaddr: ptr InAddr): bool {.importc: "$1", header: hdr.}

## *
##   @brief Check if the IPv4 address is unspecified (all bits zero)
##
##   @param addr IPv4 address.
##
##   @return True if the address is unspecified, false otherwise.
##

proc net_ipv4_is_addr_unspecified*(inaddr: ptr InAddr): bool {.importc: "$1", header: hdr.}

## *
##  @brief Check if the IPv4 address is a multicast address.
##
##  @param addr IPv4 address
##
##  @return True if address is multicast address, False otherwise.
##

proc net_ipv4_is_addr_mcast*(inaddr: ptr InAddr): bool {.importc: "$1", header: hdr.}

## *
##  @brief Check if the given IPv4 address is a link local address.
##
##  @param addr A valid pointer on an IPv4 address
##
##  @return True if it is, false otherwise.
##

proc net_ipv4_is_ll_addr*(inaddr: ptr InAddr): bool {.importc: "$1", header: hdr.}

## *
##   @def net_ipaddr_copy
##   @brief Copy an IPv4 or IPv6 address
##
##   @param dest Destination IP address.
##   @param src Source IP address.
##
##   @return Destination address.
##

proc net_ipaddr_copy*(dest: ptr InAddr; src: ptr InAddr) {.importc: "net_ipaddr_copy", header: hdr.}
proc net_ipaddr_copy*(dest: ptr In6Addr; src: ptr In6Addr) {.importc: "net_ipaddr_copy", header: hdr.}

## *
##   @brief Compare two IPv4 addresses
##
##   @param addr1 Pointer to IPv4 address.
##   @param addr2 Pointer to IPv4 address.
##
##   @return True if the addresses are the same, false otherwise.
##

proc net_ipv4_addr_cmp*(addr1: ptr InAddr; addr2: ptr InAddr): bool {.importc: "$1", header: hdr.}


## *
##   @brief Compare two IPv6 addresses
##
##   @param addr1 Pointer to IPv6 address.
##   @param addr2 Pointer to IPv6 address.
##
##   @return True if the addresses are the same, false otherwise.
##

proc net_ipv6_addr_cmp*(addr1: ptr In6Addr; addr2: ptr In6Addr): bool {.importc: "$1", header: hdr.}

## *
##  @brief Check if the given IPv6 address is a link local address.
##
##  @param addr A valid pointer on an IPv6 address
##
##  @return True if it is, false otherwise.
##

proc net_ipv6_is_ll_addr*(inaddr: ptr In6Addr): bool {.importc: "$1", header: hdr.}

## *
##  @brief Check if the given IPv6 address is a unique local address.
##
##  @param addr A valid pointer on an IPv6 address
##
##  @return True if it is, false otherwise.
##

proc net_ipv6_is_ula_addr*(inaddr: ptr In6Addr): bool {.importc: "$1", header: hdr.}

## *
##  @brief Return pointer to any (all bits zeros) IPv6 address.
##
##  @return Any IPv6 address.
##

proc net_ipv6_unspecified_address*(): ptr In6Addr {.
    importc: "net_ipv6_unspecified_address", header: hdr.}

## *
##  @brief Return pointer to any (all bits zeros) IPv4 address.
##
##  @return Any IPv4 address.
##

proc net_ipv4_unspecified_address*(): ptr InAddr {.
    importc: "net_ipv4_unspecified_address", header: hdr.}

## *
##  @brief Return pointer to broadcast (all bits ones) IPv4 address.
##
##  @return Broadcast IPv4 address.
##

proc net_ipv4_broadcast_address*(): ptr InAddr {.
    importc: "net_ipv4_broadcast_address", header: hdr.}

# TODO: FIXME
# proc net_if_ipv4_addr_mask_cmp*(iface: ptr net_if; inaddr: ptr InAddr): bool {.
    # importc: "net_if_ipv4_addr_mask_cmp", header: hdr.}

## *
##  @brief Check if the given address belongs to same subnet that
##  has been configured for the interface.
##
##  @param iface A valid pointer on an interface
##  @param addr IPv4 address
##
##  @return True if address is in same subnet, false otherwise.
##

# TODO: FIXME
# proc net_ipv4_addr_mask_cmp*(iface: ptr net_if; inaddr: ptr InAddr): bool =
  # return net_if_ipv4_addr_mask_cmp(iface, `addr`)

# proc net_if_ipv4_is_addr_bcast*(iface: ptr net_if; inaddr: ptr InAddr): bool {.
    # importc: "net_if_ipv4_is_addr_bcast", header: hdr.}


## *
##  @brief Check if the given IPv4 address is a broadcast address.
##
##  @param iface Interface to use. Must be a valid pointer to an interface.
##  @param addr IPv4 address
##
##  @return True if address is a broadcast address, false otherwise.
##

# TODO: FIXME
# proc net_ipv4_is_addr_bcast*(iface: ptr net_if; inaddr: ptr InAddr): bool {.importc: "$1", header: hdr.}

# proc net_if_ipv4_addr_lookup*(inaddr: ptr InAddr; iface: ptr ptr net_if): ptr net_if_addr {.  importc: "net_if_ipv4_addr_lookup", header: hdr.}

## *
##  @brief Check if the IPv4 address is assigned to any network interface
##  in the system.
##
##  @param addr A valid pointer on an IPv4 address
##
##  @return True if IPv4 address is found in one of the network interfaces,
##  False otherwise.
##

proc net_ipv4_is_my_addr*(inaddr: ptr InAddr): bool {.importc: "$1", header: hdr.}


## *
##   @brief Check if the IPv6 address is unspecified (all bits zero)
##
##   @param addr IPv6 address.
##
##   @return True if the address is unspecified, false otherwise.
##

proc net_ipv6_is_addr_unspecified*(inaddr: ptr In6Addr): bool {.importc: "$1", header: hdr.}


## *
##   @brief Check if the IPv6 address is solicited node multicast address
##   FF02:0:0:0:0:1:FFXX:XXXX defined in RFC 3513
##
##   @param addr IPv6 address.
##
##   @return True if the address is solicited node address, false otherwise.
##

proc net_ipv6_is_addr_solicited_node*(inaddr: ptr In6Addr): bool {.importc: "$1", header: hdr.}


## *
##  @brief Check if the IPv6 address is a given scope multicast
##  address (FFyx::).
##
##  @param addr IPv6 address
##  @param scope Scope to check
##
##  @return True if the address is in given scope multicast address,
##  false otherwise.
##

proc net_ipv6_is_addr_mcast_scope*(inaddr: ptr In6Addr; scope: cint): bool {.importc: "$1", header: hdr.}


## *
##  @brief Check if the IPv6 addresses have the same multicast scope (FFyx::).
##
##  @param addr_1 IPv6 address 1
##  @param addr_2 IPv6 address 2
##
##  @return True if both addresses have same multicast scope,
##  false otherwise.
##

proc net_ipv6_is_same_mcast_scope*(addr_1: ptr In6Addr; addr_2: ptr In6Addr): bool {.importc: "$1", header: hdr.}


## *
##  @brief Check if the IPv6 address is a global multicast address (FFxE::/16).
##
##  @param addr IPv6 address.
##
##  @return True if the address is global multicast address, false otherwise.
##

proc net_ipv6_is_addr_mcast_global*(inaddr: ptr In6Addr): bool {.importc: "$1", header: hdr.}


## *
##  @brief Check if the IPv6 address is a interface scope multicast
##  address (FFx1::).
##
##  @param addr IPv6 address.
##
##  @return True if the address is a interface scope multicast address,
##  false otherwise.
##

proc net_ipv6_is_addr_mcast_iface*(inaddr: ptr In6Addr): bool {.importc: "$1", header: hdr.}

## *
##  @brief Check if the IPv6 address is a link local scope multicast
##  address (FFx2::).
##
##  @param addr IPv6 address.
##
##  @return True if the address is a link local scope multicast address,
##  false otherwise.
##

proc net_ipv6_is_addr_mcast_link*(inaddr: ptr In6Addr): bool {.importc: "$1", header: hdr.}

## *
##  @brief Check if the IPv6 address is a mesh-local scope multicast
##  address (FFx3::).
##
##  @param addr IPv6 address.
##
##  @return True if the address is a mesh-local scope multicast address,
##  false otherwise.
##

proc net_ipv6_is_addr_mcast_mesh*(inaddr: ptr In6Addr): bool {.importc: "$1", header: hdr.}

## *
##  @brief Check if the IPv6 address is a site scope multicast
##  address (FFx5::).
##
##  @param addr IPv6 address.
##
##  @return True if the address is a site scope multicast address,
##  false otherwise.
##

proc net_ipv6_is_addr_mcast_site*(inaddr: ptr In6Addr): bool {.importc: "$1", header: hdr.}

## *
##  @brief Check if the IPv6 address is an organization scope multicast
##  address (FFx8::).
##
##  @param addr IPv6 address.
##
##  @return True if the address is an organization scope multicast address,
##  false otherwise.
##

proc net_ipv6_is_addr_mcast_org*(inaddr: ptr In6Addr): bool {.importc: "$1", header: hdr.}

## *
##  @brief Check if the IPv6 address belongs to certain multicast group
##
##  @param addr IPv6 address.
##  @param group Group id IPv6 address, the values must be in network
##  byte order
##
##  @return True if the IPv6 multicast address belongs to given multicast
##  group, false otherwise.
##

proc net_ipv6_is_addr_mcast_group*(inaddr: ptr In6Addr; group: ptr In6Addr): bool {.importc: "$1", header: hdr.}


## *
##  @brief Check if the IPv6 address belongs to the all nodes multicast group
##
##  @param addr IPv6 address
##
##  @return True if the IPv6 multicast address belongs to the all nodes multicast
##  group, false otherwise
##

proc net_ipv6_is_addr_mcast_all_nodes_group*(inaddr: ptr In6Addr): bool {.importc: "$1", header: hdr.}

## *
##  @brief Check if the IPv6 address is a interface scope all nodes multicast
##  address (FF01::1).
##
##  @param addr IPv6 address.
##
##  @return True if the address is a interface scope all nodes multicast address,
##  false otherwise.
##

proc net_ipv6_is_addr_mcast_iface_all_nodes*(inaddr: ptr In6Addr): bool {.importc: "$1", header: hdr.}

## *
##  @brief Check if the IPv6 address is a link local scope all nodes multicast
##  address (FF02::1).
##
##  @param addr IPv6 address.
##
##  @return True if the address is a link local scope all nodes multicast
##  address, false otherwise.
##

proc net_ipv6_is_addr_mcast_link_all_nodes*(inaddr: ptr In6Addr): bool {.importc: "$1", header: hdr.}

## *
##   @brief Create solicited node IPv6 multicast address
##   FF02:0:0:0:0:1:FFXX:XXXX defined in RFC 3513
##
##   @param src IPv6 address.
##   @param dst IPv6 address.
##

proc net_ipv6_addr_create_solicited_node*(src: ptr In6Addr; dst: ptr In6Addr)  {.importc: "$1", header: hdr.}

## * @brief Construct an IPv6 address from eight 16-bit words.
##
##   @param addr IPv6 address
##   @param addr0 16-bit word which is part of the address
##   @param addr1 16-bit word which is part of the address
##   @param addr2 16-bit word which is part of the address
##   @param addr3 16-bit word which is part of the address
##   @param addr4 16-bit word which is part of the address
##   @param addr5 16-bit word which is part of the address
##   @param addr6 16-bit word which is part of the address
##   @param addr7 16-bit word which is part of the address
##

proc net_ipv6_addr_create*(inaddr: ptr In6Addr;
                          addr0: uint16; addr1: uint16; addr2: uint16; addr3: uint16;
                          addr4: uint16; addr5: uint16; addr6: uint16; addr7: uint16
                          ) {.importc: "$1", header: hdr.}

## *
##   @brief Create link local allnodes multicast IPv6 address
##
##   @param addr IPv6 address
##

proc net_ipv6_addr_create_ll_allnodes_mcast*(inaddr: ptr In6Addr) {.importc: "$1", header: hdr.}

## *
##   @brief Create link local allrouters multicast IPv6 address
##
##   @param addr IPv6 address
##

proc net_ipv6_addr_create_ll_allrouters_mcast*(inaddr: ptr In6Addr) {.importc: "$1", header: hdr.}

## *
##   @brief Create IPv6 address interface identifier
##
##   @param addr IPv6 address
##   @param lladdr Link local address
##

# TODO: FIXME
# proc net_ipv6_addr_create_iid*(inaddr: ptr In6Addr; lladdr: ptr net_linkaddr) {.importc: "$1", header: hdr.}

## *
##   @brief Check if given address is based on link layer address
##
##   @return True if it is, False otherwise
##

# TODO: FIXME
# proc net_ipv6_addr_based_on_ll*(inaddr: ptr In6Addr; lladdr: ptr net_linkaddr): bool {.importc: "$1", header: hdr.}

## *
##  @brief Get sockaddr_in6 from sockaddr. This is a helper so that
##  the code calling this function can be made shorter.
##
##  @param addr Socket address
##
##  @return Pointer to IPv6 socket address
##

proc net_sin6*(inaddr: ptr SockAddr): ptr Sockaddr_in6 {.importc: "$1", header: hdr.}

## *
##  @brief Get sockaddr_in from sockaddr. This is a helper so that
##  the code calling this function can be made shorter.
##
##  @param addr Socket address
##
##  @return Pointer to IPv4 socket address
##

proc net_sin*(inaddr: ptr SockAddr): ptr SockAddr_in {.importc: "$1", header: hdr.}

## *
##  @brief Get sockaddr_in6_ptr from sockaddr_ptr. This is a helper so that
##  the code calling this function can be made shorter.
##
##  @param addr Socket address
##
##  @return Pointer to IPv6 socket address
##
# proc net_sin6_ptr*(inaddr: ptr sockaddr_ptr): ptr sockaddr_in6_ptr =
  # return cast[ptr sockaddr_in6_ptr](`addr`)

## *
##  @brief Get sockaddr_in_ptr from sockaddr_ptr. This is a helper so that
##  the code calling this function can be made shorter.
##
##  @param addr Socket address
##
##  @return Pointer to IPv4 socket address
##
# proc net_sin_ptr*(inaddr: ptr sockaddr_ptr): ptr sockaddr_in_ptr =
  # return cast[ptr sockaddr_in_ptr](`addr`)

## *
##  @brief Get sockaddr_ll_ptr from sockaddr_ptr. This is a helper so that
##  the code calling this function can be made shorter.
##
##  @param addr Socket address
##
##  @return Pointer to linklayer socket address
##
# proc net_sll_ptr*(inaddr: ptr sockaddr_ptr): ptr sockaddr_ll_ptr =
  # return cast[ptr sockaddr_ll_ptr](`addr`)

## *
##  @brief Get sockaddr_can_ptr from sockaddr_ptr. This is a helper so that
##  the code needing this functionality can be made shorter.
##
##  @param addr Socket address
##
##  @return Pointer to CAN socket address
##
# proc net_can_ptr*(inaddr: ptr sockaddr_ptr): ptr sockaddr_can_ptr =
  # return cast[ptr sockaddr_can_ptr](`addr`)

## *
##  @brief Convert a string to IP address.
##
##  @param family IP address family (AF_INET or AF_INET6)
##  @param src IP address in a null terminated string
##  @param dst Pointer to struct InAddr if family is AF_INET or
##  pointer to struct In6Addr if family is AF_INET6
##
##  @note This function doesn't do precise error checking,
##  do not use for untrusted strings.
##
##  @return 0 if ok, < 0 if error
##

proc net_addr_pton*(family: TSa_Family;
                    src: cstring;
                    dst: pointer | ptr InAddr | ptr In6Addr
                    ): cint {.
    importc: "net_addr_pton", header: hdr.}

## *
##  @brief Convert IP address to string form.
##
##  @param family IP address family (AF_INET or AF_INET6)
##  @param src Pointer to struct InAddr if family is AF_INET or
##         pointer to struct In6Addr if family is AF_INET6
##  @param dst Buffer for IP address as a null terminated string
##  @param size Number of bytes available in the buffer
##
##  @return dst pointer if ok, NULL if error
##

proc net_addr_ntop*(family: TSa_Family;
                    src: pointer | ptr InAddr | ptr In6Addr;
                    dst: cstring; size: csize_t
                    ): cstring {.
    importc: "net_addr_ntop", header: hdr.}

## *
##  @brief Parse a string that contains either IPv4 or IPv6 address
##  and optional port, and store the information in user supplied
##  sockaddr struct.
##
##  @details Syntax of the IP address string:
##    192.0.2.1:80
##    192.0.2.42
##    [2001:db8::1]:8080
##    [2001:db8::2]
##    2001:db::42
##  Note that the str_len parameter is used to restrict the amount of
##  characters that are checked. If the string does not contain port
##  number, then the port number in sockaddr is not modified.
##
##  @param str String that contains the IP address.
##  @param str_len Length of the string to be parsed.
##  @param addr Pointer to user supplied struct sockaddr.
##
##  @return True if parsing could be done, false otherwise.
##

proc net_ipaddr_parse*(str: cstring; str_len: csize_t; inaddr: ptr SockAddr): bool {.
    importc: "net_ipaddr_parse", header: hdr.}

## *
##  @brief Compare TCP sequence numbers.
##
##  @details This function compares TCP sequence numbers,
##           accounting for wraparound effects.
##
##  @param seq1 First sequence number
##  @param seq2 Seconds sequence number
##
##  @return < 0 if seq1 < seq2, 0 if seq1 == seq2, > 0 if seq > seq2
##

proc net_tcp_seq_cmp*(seq1: uint32; seq2: uint32): int32 {.importc: "$1", header: hdr.}

## *
##  @brief Check that one TCP sequence number is greater.
##
##  @details This is convenience function on top of net_tcp_seq_cmp().
##
##  @param seq1 First sequence number
##  @param seq2 Seconds sequence number
##
##  @return True if seq > seq2
##

proc net_tcp_seq_greater*(seq1: uint32; seq2: uint32): bool {.importc: "$1", header: hdr.}

## *
##  @brief Convert a string of hex values to array of bytes.
##
##  @details The syntax of the string is "ab:02:98:fa:42:01"
##
##  @param buf Pointer to memory where the bytes are written.
##  @param buf_len Length of the memory area.
##  @param src String of bytes.
##
##  @return 0 if ok, <0 if error
##

proc net_bytes_from_str*(buf: ptr uint8; buf_len: cint; src: cstring): cint {.
    importc: "net_bytes_from_str", header: hdr.}

## *
##  @brief Convert Tx network packet priority to traffic class so we can place
##  the packet into correct Tx queue.
##
##  @param prio Network priority
##
##  @return Tx traffic class that handles that priority network traffic.
##

proc net_tx_priority2tc*(prio: net_priority): cint {.importc: "net_tx_priority2tc",
    header: hdr.}

## *
##  @brief Convert Rx network packet priority to traffic class so we can place
##  the packet into correct Rx queue.
##
##  @param prio Network priority
##
##  @return Rx traffic class that handles that priority network traffic.
##

proc net_rx_priority2tc*(prio: net_priority): cint {.importc: "net_rx_priority2tc",
    header: hdr.}

## *
##  @brief Convert network packet VLAN priority to network packet priority so we
##  can place the packet into correct queue.
##
##  @param priority VLAN priority
##
##  @return Network priority
##

proc net_vlan2priority*(priority: uint8): net_priority {.importc: "$1", header: hdr.}

## *
##  @brief Convert network packet priority to network packet VLAN priority.
##
##  @param priority Packet priority
##
##  @return VLAN priority (PCP)
##

proc net_priority2vlan*(priority: net_priority): uint8 {.importc: "$1", header: hdr.}

## *
##  @brief Return network address family value as a string. This is only usable
##  for debugging.
##
##  @param family Network address family code
##
##  @return Network address family as a string, or NULL if family is unknown.
##

proc net_family2str*(family: TSa_Family): cstring {.importc: "net_family2str",
    header: hdr.}

## *
##  @}
##
