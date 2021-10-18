import json, tables, strutils, macros, options
import strformat
import net, os
import streams
import times
import stats
import sequtils
import locks
import sugar
import terminal 
import colors

import cligen
from cligen/argcvt import ArgcvtParams, argKeys         # Little helpers

# import nesper/servers/rpc/router
when not defined(TcpJsonRpcServer):
  import msgpack4nim/msgpack2json

enableTrueColors()
proc print*(text: varargs[string]) =
  stdout.write(text)
  stdout.write("\n")
  stdout.flushFile()

proc print*(color: Color, text: varargs[string]) =
  stdout.setForegroundColor(color)

  stdout.write text
  stdout.write "\n"
  # stdout.write "\e[0m\n"
  stdout.setForegroundColor(fgDefault)
  stdout.flushFile()


type 
  RpcOptions = object
    id: int
    showstats: bool
    count: int
    delay: int
    jsonArg: string
    ipAddr: IpAddress
    port: Port
    prettyPrint: bool
    quiet: bool
    dryRun: bool
    noprint: bool

var totalTime = 0'i64
var totalCalls = 0'i64

template timeBlock(n: string, opts: RpcOptions, blk: untyped): untyped =
  let t0 = getTime()
  blk

  let td = getTime() - t0
  if not opts.noprint:
    print colGray, "[took: ", $(td.inMicroseconds().float() / 1e3), " millis]"
  totalCalls.inc()
  totalTime = totalTime + td.inMicroseconds()
  allTimes.add(td.inMicroseconds())
  


var
  id: int = 1
  allTimes = newSeq[int64]()

proc execRpc( client: Socket, i: int, call: JsonNode, opts: RpcOptions): JsonNode = 
  {.cast(gcsafe).}:
    call["id"] = %* id
    inc(id)

    let mcall = 
      when defined(TcpJsonRpcServer):
        $call
      else:
        call.fromJsonNode()

    timeBlock("call", opts):
      client.send( mcall )
      var msgLenBytes = client.recv(4, timeout = -1)
      var msgLen: int32 = 0
      # echo grey, "[socket data:lenstr: " & repr(msgLenBytes) & "]"
      if msgLenBytes.len() == 0: return
      for i in countdown(3,0):
        msgLen = (msgLen shl 8) or int32(msgLenBytes[i])

      var msg = ""
      while msg.len() < msgLen:
        let mb = client.recv(4*1024, timeout = -1)
        if not opts.quiet and not opts.noprint:
          print("[read bytes: " & $mb.len() & "]")
        msg.add mb

    if not opts.quiet and not opts.noprint:
      print("[socket data: " & repr(msg) & "]")

    if not opts.quiet and not opts.noprint:
      print colGray, "[read bytes: ", $msg.len(), "]"
      print colGray, "[read: ", repr(msg), "]"

    var mnode: JsonNode = 
      when defined(TcpJsonRpcServer):
        msg.parseJson()
      else:
        msg.toJsonNode()

    if not opts.noprint:
      print("")

    if not opts.noprint: 
      if opts.prettyPrint:
        print(colAquamarine, pretty(mnode))
      else:
        print(colAquamarine, $(mnode))

    if not opts.quiet and not opts.noprint:
      print colGreen, "[rpc done at " & $now() & "]"

    if opts.delay > 0:
      os.sleep(opts.delay)

    mnode

proc initRpcCall(id=1): JsonNode =
  result = %* { "jsonrpc": "2.0", "id": id}
proc initRpcCall(name: string, args: JsonNode, id=1): JsonNode =
  result = %* { "jsonrpc": "2.0", "id": id, "method": name, "params": args}

proc runRpc(opts: RpcOptions, margs: JsonNode) = 
  {.cast(gcsafe).}:
    var call = initRpcCall()

    for (f,v) in margs.pairs():
      call[f] = v

    let domain = if opts.ipAddr.family == IpAddressFamily.IPv6: Domain.AF_INET6 else: Domain.AF_INET6 
    let client: Socket = newSocket(buffered=false, domain=domain)

    print(colYellow, "[connecting to server ip addr: ", repr opts.ipAddr,"]")
    client.connect($opts.ipAddr, opts.port)
    print(colYellow, "[connected to server ip addr: ", $opts.ipAddr,"]")
    print(colBlue, "[call: ", $call, "]")

    for i in 1..opts.count:
      discard client.execRpc(i, call, opts)
    client.close()

    print("\n")

    if opts.showstats: 
      print(colMagenta, "[total time: " & $(totalTime.float() / 1e3) & " millis]")
      print(colMagenta, "[total count: " & $(totalCalls) & " No]")
      print(colMagenta, "[avg time: " & $(float(totalTime.float()/1e3)/(1.0 * float(totalCalls))) & " millis]")

      var ss: RunningStat ## Must be "var"
      ss.push(allTimes.mapIt(float(it)/1000.0))

      print(colMagenta, "[mean time: " & $(ss.mean()) & " millis]")
      print(colMagenta, "[max time: " & $(allTimes.max().float()/1_000.0) & " millis]")
      print(colMagenta, "[variance time: " & $(ss.variance()) & " millis]")
      print(colMagenta, "[standardDeviation time: " & $(ss.standardDeviation()) & " millis]")

proc doRpcCall(client: Socket, opts: var RpcOptions, name: string, args: JsonNode): JsonNode =
  opts.id.inc()
  let
    call = initRpcCall(name, args)
    res = client.execRpc(opts.id, call, opts)

  try:
    result = res["result"]
  except KeyError:
    raise newException(ValueError, fmt"missing result key from: {$res} for call: {$call}")

proc doRpcCall(client: Socket, opts: var RpcOptions, name: string, args: varargs[JsonNode]): JsonNode =
  let jargs = % args
  doRpcCall(client, opts, name, jargs)

proc call(ip: IpAddress, cmdargs: seq[string], port=Port(5555), dry_run=false, quiet=false, pretty=false, count=1, delay=0, rawJsonArgs="") =
  var opts = RpcOptions(count: count, delay: delay, ipAddr: ip, port: port, quiet: quiet, dryRun: dry_run, prettyPrint: pretty)

  ## Some API call
  let
    name = cmdargs[0]
    args = cmdargs[1..^1]
    # cmdargs = @[name, rawJsonArgs]
    pargs = collect(newSeq):
      for ca in args:
        parseJson(ca)
    jargs = if rawJsonArgs == "": %pargs else: rawJsonArgs.parseJson() 
  
  echo fmt("rpc call: name: '{name}' args: '{args}' ip:{repr ip} ")
  echo fmt("rpc params: {repr jargs}")
  echo fmt("rpc params: {$jargs}")

  let margs = %* {"method": name, "params": % jargs }
  if not opts.dryRun:
    opts.runRpc(margs)

import progress

proc upload(filenames: seq[string], ip: IpAddress, block_size = 0, port=Port(5555), permanent=false) = 
  var opts = RpcOptions(count: 1, ipAddr: ip, port: port, quiet: true,  noprint: true)

  assert filenames.len() == 1, "can only upload one file at a time"
  let filename = filenames[0]
  print colAquamarine, fmt"opening firmware: {repr filename}"

  if not filename.fileExists():
    print colRed, fmt"not a valid file: {repr filename}"
    print "...aborting"
    quit(1)

  let flSizeBytes = getFileSize(filename).int

  var strm = openFileStream(filename, fmRead)
  # Close the file object when you are done with it
  defer: strm.close()

  let client: Socket = newSocket(buffered=false)
  defer: client.close()

  client.connect($opts.ipAddr, opts.port)
  print(colYellow, "[connected to server ip addr: ", $opts.ipAddr,"]")

  let chunkSize =
    if block_size > 0:
      block_size
    else:
      let res = client.doRpcCall(opts, "fw-info")
      res["block_size"].getInt()

  block begin_firmware_uploads:
    let res = client.doRpcCall(opts, "fw-init")
    assert res.getBool() == true

  let chunks = flSizeBytes div chunkSize
  var bar = newProgressBar(chunks)
  bar.start()

  var idx = 0
  while not strm.atEnd():
    let data = strm.readStr(length=chunkSize)
    let isLast = strm.atEnd()
    # print colDarkGray, fmt"read: {data.len()} / {strm.getPosition()} data: {data.toHex()[0..min(60,data.len())]}..."

    let res = client.doRpcCall(opts, "fw-write", %* [idx, data, isLast])
    idx.inc()
    # print(colSeaGreen, fmt"fw-write got: {$res}")
    bar.increment()
    
  bar.finish()
    # var call = initRpcCall("fw-", % [])
    # let res = client.execRpc(1, call, opts)
  block finish_firmware_uploads:
    # let res = client.doRpcCall(opts, "fw-finish", %* [{"permanent": permanent}])
    # print(colSeaGreen, fmt"fw-finish got: {$res}")
    let res = client.doRpcCall(opts, "fw-upgrade", %* [{"permanent": permanent}])
    print(colSeaGreen, fmt"fw-upgrade got: {$res}")

  block check_firmware_uploads:
    let hdr = client.doRpcCall(opts, "fw-header", %* [2])
    print(colSeaGreen, fmt"fw-hdr got: {$hdr}")
    let res = client.doRpcCall(opts, "fw-status")
    print(colSeaGreen, fmt"fw-status got: {$res}")

# runRpc()

when isMainModule:
  proc argParse(dst: var IpAddress, dfl: IpAddress, a: var ArgcvtParams): bool =
    try:
      dst = a.val.parseIpAddress()
    except CatchableError:
      return false
    return true

  proc argHelp(dfl: IpAddress; a: var ArgcvtParams): seq[string] =
    argHelp($(dfl), a)

  proc argParse(dst: var Port, dfl: Port, a: var ArgcvtParams): bool =
    try:
      dst = Port(a.val.parseInt())
    except CatchableError:
      return false
    return true
  proc argHelp(dfl: Port; a: var ArgcvtParams): seq[string] =
    argHelp($(dfl), a)

  dispatchMulti([call], [upload])
