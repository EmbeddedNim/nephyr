import net
# import selectors
# import tables
# import posix

import nephyr/logs
import nephyr/net/tcpsocket

import router
import json

export tcpsocket, router

const TAG = "socketrpc"

initLogs("rpcsocket_json")

proc rpcMsgPackWriteHandler*(srv: TcpServerInfo[RpcRouter], result: ReadyKey, sourceClient: Socket, rt: RpcRouter) =
  raise newException(OSError, "the request to the OS failed")

proc rpcMsgPackReadHandler*(srv: TcpServerInfo[RpcRouter], result: ReadyKey, sourceClient: Socket, rt: RpcRouter) =

  try:

    var rcall: JsonNode

    block rxblock:
      logi("rpc server handler: router: %x", rt.buffer)

      let rx = sourceClient.recv(rt.buffer, -1)
      let msg = rx & "\n"
      logi("rpc recv done")

      if msg.len() == 0:
        logi("msg too short")
        raise newException(TcpClientDisconnected, "")
      else:
        echo("parse json: msgl: %d", msg.len())
        # echo "json:msg: ", msg
        # echo "json:msgdone "
        rcall = parseJson(msg)
        echo("json:done:parsed: ")

    block parseblock:
      echo("json:parsed: ")
      for (key, item) in rcall.pairs():
        echo "key: %s", key
        echo "item: %s", repr(key)
        echo " "
      echo("json:items:done: ")
      var res: JsonNode = rt.route( rcall )
      var rmsg: string = $res

      echo("sending to client: ", $sourceClient.getFd().int)
      discard sourceClient.send(addr rmsg[0], rmsg.len)

  except TimeoutError:
    echo("control server: error: socket timeout: ", $sourceClient.getFd().int)

proc startRpcSocketServer*(port: Port; router: var RpcRouter) =
  logi("starting json rpc server: buffer: %d", router.buffer)

  startSocketServer[RpcRouter](
    port,
    readHandler=rpcMsgPackReadHandler,
    writeHandler=rpcMsgPackWriteHandler,
    data=router)



when isMainModule:
    runTcpServer()