

import json
import strutils
import sequtils

import nephyr/net/json_rpc/router

const TAG = "server"
const MaxRpcReceiveBuffer {.intdefine.}: int = 1400

## Note:
## Nim uses `when` compile time constructs
## these are like ifdef's in C and don't really have an equivalent in Python
## setting the flags can be done in the Makefile `simplewifi-rpc  Makefile
## for example, to compile the example to use JSON, pass `-d:TcpJsonRpcServer` to Nim
## the makefile has several example already defined for convenience
## 
# import rpc/rpcsocket_json
import nephyr/net/json_rpc/rpcsocket_mpack

const VERSION* = staticRead("../VERSION").strip()


# Setup RPC Server #
proc run_server*() =

  # Setup an RPC router
  var rt = createRpcRouter(MaxRpcReceiveBuffer)

  rpc(rt, "version") do() -> string:
    result = VERSION

  rpc(rt, "hello") do(input: string) -> string:
    # example: ./rpc_cli --ip:$$IP -c:1 '{"method": "hello", "params": ["world"]}'
    result = "Hello " & input

  rpc(rt, "addInt") do(a: int, b: int) -> int:
    # example: ./rpc_cli --ip:$$IP -c:1 '{"method": "add", "params": [1, 2]}'
    result = a + b

  rpc(rt, "addFloat") do(a: float, b: float) -> float:
    # example: ./rpc_cli --ip:$$IP -c:1 '{"method": "add", "params": [1, 2]}'
    result = a + b

  rpc(rt, "addAll") do(vals: seq[int]) -> int:
    # example: ./rpc_cli --ip:$$IP -c:1 '{"method": "add", "params": [1, 2, 3, 4, 5]}'
    echo("run_rpc_server: done: " & repr(addr(vals)))
    result = 0
    for x in vals:
      result += x


  startRpcSocketServer(Port(5555), router=rt)

when isMainModule:
  run_server()
