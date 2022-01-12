
type 
  Bytes*[N: static[int]] = array[N, uint8]

proc sysReboot*(coldReboot: bool = false) = sys_reboot(if coldReboot: 1 else: 0)

proc doCheck*(ret: int): int {.discardable.} =
  if ret != 0:
    raise newException(OSError, "error id: " & $(ret))
  return ret

template check*(blk: untyped) =
  doCheck(blk)

template clen*(item: untyped): untyped =
  csize_t(len(item))

template ulen*(item: untyped): untyped =
  uint32(len(item))

template lenBytes*[T](item: openArray[T]): untyped =
  uint32(sizeof(T) * item.len())

template setOr*[T, F](flags: set[F]): T =
  var st: T
  for flg in flags:
    st = st or T(flg)
  st

template bytes*(args: varargs[uint8]): openArray[uint8] =
  args

proc joinBytes32*[T](bs: openArray[uint8], count: range[0..4], top=false): T =
  ## Join's an array of bytes into an integer
  var n = 0'u32
  let N = min(count, bs.len())
  for i in 0 ..< N:
    n = (n shl 8) or bs[i]
  if top:
    n = n shl (32-N*8)
  return cast[T](n)

proc joinBytes64*[T](bs: openArray[uint8], count: range[0..8], top=false): T =
  ## Join's an array of bytes into an integer
  var n = 0'u64
  let N = min(count, bs.len())
  for i in 0 ..< N:
    n = (n shl 8) or bs[i]
  if top:
    n = n shl (64-N*8)
  return cast[T](n)

proc splitBytes*[T](val: T, count: range[0..8], top=false): seq[byte] =
  ## Splits's an integer into an array of bytes
  let szT = sizeof(T)
  let N = min(count, szT)

  var x = val
  result = newSeqOfCap[byte](N)
  for i in 0 ..< N:
    if top == false:
      result.add(byte(x))
      x = x shr 8
    else:
      result.add( byte(x shr (8*szT-8) ))
      x = x shl 8

