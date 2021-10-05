

type

  Vec[N: static[int]] = object
    arr: array[N, uint8]

template testArg(args: varargs[untyped]) =
  for arg in args:
    echo "testArg: ", repr(arg)


proc test() =
  var x: Vec[4]
  echo "x: ", x
  testArg( 
    ([0x1, 0x2], 42'u32),
    (x, 42'u32) 
  )

test()