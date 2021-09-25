
template check*(blk: untyped) =
  let ret = blk
  if ret < 0:
    raise newException(OSError, "error: " & $ret)

proc doCheck*(ret: int) =
  if ret < 0:
    raise newException(OSError, "error: " & $ret)


proc joinBytes32*[T](bs: openArray[uint8], count: range[0..4], top=false): T =
  var n = 0'u32
  let N = min(count, bs.len())
  for i in 0 ..< N:
    n = (n shl 8) or bs[i]
  if top:
    n = n shl (32-N*8)
  return cast[T](n)

proc joinBytes64*[T](bs: openArray[uint8], count: range[0..8], top=false): T =
  var n = 0'u64
  let N = min(count, bs.len())
  for i in 0 ..< N:
    n = (n shl 8) or bs[i]
  if top:
    n = n shl (64-N*8)
  return cast[T](n)

proc splitBytes*[T](val: T, count: range[0..8], top=false): seq[byte] =
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

