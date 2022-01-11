import sugar

import nephyr
import nephyr/times

proc test_times*() =
  # get time ... 
  let ts_us = micros()
  dump(ts_us.repr)
  let ts_ms = millis()
  dump(ts_ms.repr)

  let res: Millis = delay(100.Millis)
  if res.int == 0:
    echo "slept for 100 millis"
  else:
    echo "woke early, remain time to wait: ", res.int

  let res2: Micros = delay(100.Micros)
  if res2.int == 0:
    echo "slept for 100 micros"
  else:
    echo "woke early, remain time to wait: ", res2.int
  
  # variants
  # delayMicros(100)
  # let res3: bool = delayMicros(100)
  # echo "slept full amount: ", res3

  # delayMicros(100)
  # let res4: bool = delayMicros(100)
  # echo "slept full amount: ", res4



test_times()
