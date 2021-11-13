
const hdr = "<random/rand32.h>"

proc sys_rand32_get*(): uint32 {.importc: "$1", header: hdr.} #\
 #* @brief Return a 32-bit random value that should pass general
 #* randomness tests.


proc sys_rand_get*(dst: pointer, length: csize_t) {.importc: "$1", header: hdr.} #\
 #* @brief Fill the destination buffer with random data values that should
 #* pass general randomness tests.


proc sys_csrand_get*(dst: pointer, length: csize_t): int {.importc: "$1", header: hdr.} #\
 #* @brief Fill the destination buffer with cryptographically secure
 #* random data values.


