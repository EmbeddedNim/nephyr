import
  net_private, ipv6

proc join_coap_multicast_group*(): bool =
  var my_addr: in6_addr
  var mcast_addr: sockaddr_in6
  var ifaddr: ptr net_if_addr
  var iface: ptr net_if
  var ret: cint
  iface = net_if_get_default()
  if not iface:
    LOG_ERR("Could not get te default interface\n")
    return false
  var lladdr: ptr in6_addr
  ##  if (net_addr_pton(AF_INET6,
  ##  		  CONFIG_NET_CONFIG_MY_IPV6_ADDR,
  ##  		  &my_addr) < 0) {
  ##  	LOG_ERR("Invalid IPv6 address %s",
  ##  		CONFIG_NET_CONFIG_MY_IPV6_ADDR);
  ##  }
  ifaddr = net_if_ipv6_addr_add(iface, addr(my_addr), NET_ADDR_MANUAL, 0)
  if not ifaddr:
    LOG_ERR("Could not add unicast address to interface")
    return false
  ifaddr.addr_state = NET_ADDR_PREFERRED
  ret = net_ipv6_mld_join(iface, addr(mcast_addr.sin6_addr))
  if ret < 0:
    LOG_ERR("Cannot join %s IPv6 multicast group (%d)",
            log_strdup(net_sprint_ipv6_addr(addr(mcast_addr.sin6_addr))), ret)
    return false
  return true
