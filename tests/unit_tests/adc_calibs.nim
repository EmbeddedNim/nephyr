import strformat, strutils, typetraits
import patty

variantp Test:
  Alpha(a: int)
  Beta(b: float)

var
  arr: array[3, byte]
  test: Test = Alpha(a = 123)
  other: Test

copyMem(other.addr, test.addr, sizeof(Test))

echo "other: ", repr other

proc testing() =
  for name, value in test.fieldPairs():
    echo "name: ", repr name, " v: ", repr value, " sz: ", sizeof(value)

testing()

