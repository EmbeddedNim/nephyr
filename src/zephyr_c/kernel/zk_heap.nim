import ../zkernel_fixes
import ../sys/zsys_heap

type

  k_heap* {.importc: "k_heap", header: "kernel.h", bycopy.} = object
    ##  kernel synchronized heap struct
    heap* {.importc: "heap".}: sys_heap
    wait_q* {.importc: "wait_q".}: z_wait_q_t
    lock* {.importc: "lock".}: k_spinlock

##  @addtogroup heap_apis
##  @{
##

## *
##  @brief Initialize a k_heap
##
##  This constructs a synchronized k_heap object over a memory region
##  specified by the user.  Note that while any alignment and size can
##  be passed as valid parameters, internal alignment restrictions
##  inside the inner sys_heap mean that not all bytes may be usable as
##  allocated memory.
##
##  @param h Heap struct to initialize
##  @param mem Pointer to memory.
##  @param bytes Size of memory region, in bytes
##
proc k_heap_init*(h: ptr k_heap; mem: pointer; bytes: csize_t) {.
    importc: "k_heap_init", header: "kernel.h".}


## * @brief Allocate aligned memory from a k_heap
##
##  Behaves in all ways like k_heap_alloc(), except that the returned
##  memory (if available) will have a starting address in memory which
##  is a multiple of the specified power-of-two alignment value in
##  bytes.  The resulting memory can be returned to the heap using
##  k_heap_free().
##
##  @note @a timeout must be set to K_NO_WAIT if called from ISR.
##  @note When CONFIG_MULTITHREADING=n any @a timeout is treated as K_NO_WAIT.
##
##  @funcprops \isr_ok
##
##  @param h Heap from which to allocate
##  @param align Alignment in bytes, must be a power of two
##  @param bytes Number of bytes requested
##  @param timeout How long to wait, or K_NO_WAIT
##  @return Pointer to memory the caller can now use
##
proc k_heap_aligned_alloc*(h: ptr k_heap; align: csize_t; bytes: csize_t;
                          timeout: k_timeout_t): pointer {.
    importc: "k_heap_aligned_alloc", header: "kernel.h".}


## *
##  @brief Allocate memory from a k_heap
##
##  Allocates and returns a memory buffer from the memory region owned
##  by the heap.  If no memory is available immediately, the call will
##  block for the specified timeout (constructed via the standard
##  timeout API, or K_NO_WAIT or K_FOREVER) waiting for memory to be
##  freed.  If the allocation cannot be performed by the expiration of
##  the timeout, NULL will be returned.
##
##  @note @a timeout must be set to K_NO_WAIT if called from ISR.
##  @note When CONFIG_MULTITHREADING=n any @a timeout is treated as K_NO_WAIT.
##
##  @funcprops \isr_ok
##
##  @param h Heap from which to allocate
##  @param bytes Desired size of block to allocate
##  @param timeout How long to wait, or K_NO_WAIT
##  @return A pointer to valid heap memory, or NULL
##
proc k_heap_alloc*(h: ptr k_heap; bytes: csize_t; timeout: k_timeout_t): pointer {.
    importc: "k_heap_alloc", header: "kernel.h".}


## *
##  @brief Free memory allocated by k_heap_alloc()
##
##  Returns the specified memory block, which must have been returned
##  from k_heap_alloc(), to the heap for use by other callers.  Passing
##  a NULL block is legal, and has no effect.
##
##  @param h Heap to which to return the memory
##  @param mem A valid memory block, or NULL
##
proc k_heap_free*(h: ptr k_heap; mem: pointer) {.importc: "k_heap_free",
    header: "kernel.h".}
##  Hand-calculated minimum heap sizes needed to return a successful
##  1-byte allocation.  See details in lib/os/heap.[ch]
##
var Z_HEAP_MIN_SIZE* {.importc: "Z_HEAP_MIN_SIZE", header: "kernel.h".}: int
## *
##  @brief Define a static k_heap in the specified linker section
##
##  This macro defines and initializes a static memory region and
##  k_heap of the requested size in the specified linker section.
##  After kernel start, &name can be used as if k_heap_init() had
##  been called.
##
##  Note that this macro enforces a minimum size on the memory region
##  to accommodate metadata requirements.  Very small heaps will be
##  padded to fit.
##
##  @param name Symbol name for the struct k_heap object
##  @param bytes Size of memory region, in bytes
##  @param in_section __attribute__((section(name))
##
# proc Z_HEAP_DEFINE_IN_SECT*(name: cminvtoken; bytes: static[int]; in_section: cminvtoken) {.
    # importc: "Z_HEAP_DEFINE_IN_SECT", header: "kernel.h".}


## *
##  @brief Define a static k_heap
##
##  This macro defines and initializes a static memory region and
##  k_heap of the requested size.  After kernel start, &name can be
##  used as if k_heap_init() had been called.
##
##  Note that this macro enforces a minimum size on the memory region
##  to accommodate metadata requirements.  Very small heaps will be
##  padded to fit.
##
##  @param name Symbol name for the struct k_heap object
##  @param bytes Size of memory region, in bytes
##
proc K_HEAP_DEFINE*(name: cminvtoken; bytes: static[int]) {.importc: "K_HEAP_DEFINE",
    header: "kernel.h".}


## *
##  @brief Define a static k_heap in uncached memory
##
##  This macro defines and initializes a static memory region and
##  k_heap of the requested size in uncache memory.  After kernel
##  start, &name can be used as if k_heap_init() had been called.
##
##  Note that this macro enforces a minimum size on the memory region
##  to accommodate metadata requirements.  Very small heaps will be
##  padded to fit.
##
##  @param name Symbol name for the struct k_heap object
##  @param bytes Size of memory region, in bytes
##
proc K_HEAP_DEFINE_NOCACHE*(name: cminvtoken; bytes: static[int]) {.
    importc: "K_HEAP_DEFINE_NOCACHE", header: "kernel.h".}


## *
##  @}
##
## *
##  @defgroup heap_apis Heap APIs
##  @ingroup kernel_apis
##  @{
##
## *
##  @brief Allocate memory from the heap with a specified alignment.
##
##  This routine provides semantics similar to aligned_alloc(); memory is
##  allocated from the heap with a specified alignment. However, one minor
##  difference is that k_aligned_alloc() accepts any non-zero @p size,
##  wherase aligned_alloc() only accepts a @p size that is an integral
##  multiple of @p align.
##
##  Above, aligned_alloc() refers to:
##  C11 standard (ISO/IEC 9899:2011): 7.22.3.1
##  The aligned_alloc function (p: 347-348)
##
##  @param align Alignment of memory requested (in bytes).
##  @param size Amount of memory requested (in bytes).
##
##  @return Address of the allocated memory if successful; otherwise NULL.
##
proc k_aligned_alloc*(align: csize_t; size: csize_t): pointer {.
    importc: "k_aligned_alloc", header: "kernel.h".}


## *
##  @brief Allocate memory from the heap.
##
##  This routine provides traditional malloc() semantics. Memory is
##  allocated from the heap memory pool.
##
##  @param size Amount of memory requested (in bytes).
##
##  @return Address of the allocated memory if successful; otherwise NULL.
##
proc k_malloc*(size: csize_t): pointer {.importc: "k_malloc", header: "kernel.h".}


## *
##  @brief Free memory allocated from heap.
##
##  This routine provides traditional free() semantics. The memory being
##  returned must have been allocated from the heap memory pool or
##  k_mem_pool_malloc().
##
##  If @a ptr is NULL, no operation is performed.
##
##  @param ptr Pointer to previously allocated memory.
##
##  @return N/A
##
proc k_free*(`ptr`: pointer) {.importc: "k_free", header: "kernel.h".}


## *
##  @brief Allocate memory from heap, array style
##
##  This routine provides traditional calloc() semantics. Memory is
##  allocated from the heap memory pool and zeroed.
##
##  @param nmemb Number of elements in the requested array
##  @param size Size of each array element (in bytes).
##
##  @return Address of the allocated memory if successful; otherwise NULL.
##
proc k_calloc*(nmemb: csize_t; size: csize_t): pointer {.importc: "k_calloc",
    header: "kernel.h".}

