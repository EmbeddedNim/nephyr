import nativesockets
import net
import selectors
import tables
import posix

export net, selectors, tables, posix

import nephyr/logs

initLogs("tcpsocket")

const
  TAG = "socketrpc"
  MsgChunk {.intdefine.} = 1400

proc sendChunks*(sourceClient: Socket, rmsg: string) =
  let rN = rmsg.len()
  # logd("rpc handler send client: %d bytes", rN)
  var i = 0
  while i < rN:
    var j = min(i + MsgChunk, rN) 
    # logd("rpc handler sending: i: %s j: %s ", $i, $j)
    var sl = rmsg[i..<j]
    sourceClient.send(move sl)
    i = j

proc sendLength*(sourceClient: Socket, rmsg: string) =
  var rmsgN: int = rmsg.len()
  var rmsgSz = newString(4)
  for i in 0..3:
    rmsgSz[i] = char(rmsgN and 0xFF)
    rmsgN = rmsgN shr 8

  sourceClient.send(move rmsgSz)

type 
  TcpClientDisconnected* = object of OSError
  TcpClientError* = object of OSError

  TcpServerInfo*[T] = ref object 
    select*: Selector[T]
    server*: Socket
    clients*: ref Table[SocketHandle, Socket]
    writeHandler*: TcpServerHandler[T]
    readHandler*: TcpServerHandler[T]

  TcpServerHandler*[T] = proc (srv: TcpServerInfo[T], selected: ReadyKey, client: Socket, data: T) {.nimcall.}


proc createServerInfo[T](server: Socket, selector: Selector[T]): TcpServerInfo[T] = 
  result = new(TcpServerInfo[T])
  result.server = server
  result.select = selector
  result.clients = newTable[SocketHandle, Socket]()

proc processWrites[T](selected: ReadyKey, srv: TcpServerInfo[T], data: T) = 
  var sourceClient: Socket = newSocket(SocketHandle(selected.fd))
  let data = getData(srv.select, selected.fd)
  if srv.writeHandler != nil:
    srv.writeHandler(srv, selected, sourceClient, data)

proc processReads[T](selected: ReadyKey, srv: TcpServerInfo[T], data: T) = 
  logd("process reads on: fd:%d srvfd:%d", selected.fd, srv.server.getFd().int)
  if SocketHandle(selected.fd) == srv.server.getFd():
    var client: Socket = new(Socket)
    srv.server.accept(client)

    client.getFd().setBlocking(false)
    srv.select.registerHandle(client.getFd(), {Event.Read}, data)
    srv.clients[client.getFd()] = client

    let id: int = client.getFd().int
    logd("client connected: %d", id)

  elif srv.clients.hasKey(SocketHandle(selected.fd)):
    let sourceClient: Socket = newSocket(SocketHandle(selected.fd))
    let sourceFd = selected.fd
    let data = getData(srv.select, sourceFd)

    try:
      if srv.readHandler != nil:
        srv.readHandler(srv, selected, sourceClient, data)

    except TcpClientDisconnected as err:
      var client: Socket
      discard srv.clients.pop(sourceFd.SocketHandle, client)
      srv.select.unregister(sourceFd)
      discard posix.close(sourceFd.cint)
      logd("client disconnected: fd: %s", $sourceFd)

    except TcpClientError as err:
      srv.clients.del(sourceFd.SocketHandle)
      srv.select.unregister(sourceFd)

      discard posix.close(sourceFd.cint)
      logd("client read error: %s", $(sourceFd))

  else:
    raise newException(OSError, "unknown socket id: " & $selected.fd.int)


proc echoReadHandler*(srv: TcpServerInfo[string], result: ReadyKey, sourceClient: Socket, data: string) =
  var message = sourceClient.recvLine()

  if message == "":
    raise newException(TcpClientDisconnected, "")

  else:
    logd("received from client: %s", message)

    for cfd, client in srv.clients:
      # if sourceClient.getFd() == cfd.getFd():
        # continue
      client.send(data & message & "\r\L")

proc startSocketServer*[T](port: Port, address: IpAddress, readHandler: TcpServerHandler[T], writeHandler: TcpServerHandler[T], data: var T) =
  var select: Selector[T] = newSelector[T]()

  logi "Server: starting "
  let domain = if address.family == IpAddressFamily.IPv6: Domain.AF_INET6 else: Domain.AF_INET6 
  var server: Socket = newSocket(domain=domain)
  server.setSockOpt(OptReuseAddr, true)
  server.getFd().setBlocking(false)
  server.bindAddr(port, $address)
  server.listen()

  logi "Server: started on: ip: ", $address, " port: ", $port
  select.registerHandle(server.getFd(), {Event.Read}, data)
  
  var srv = createServerInfo[T](server, select)
  srv.readHandler = readHandler
  srv.writeHandler = writeHandler

  while true:
    var results: seq[ReadyKey] = select.select(-1)
  
    for result in results:
      if Event.Read in result.events:
          result.processReads(srv, data)
      if Event.Write in result.events:
          result.processWrites(srv, data)
      # taskYIELD()
    # delayMillis(1)
    # vTaskDelay(1.TickType_t)

  
  select.close()
  server.close()

# when isMainModule:
  # startSocketServer(Port(5555), readHandler=echoReadHandler, writeHandler=nil)