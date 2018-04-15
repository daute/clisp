/* config.h.  Generated automatically by configure.  */
/* Bruno Haible 19.7.1998 */


/* UNIX variants */

/* AC_AIX */
/* Define if on AIX 3. */
#ifndef _ALL_SOURCE
#undef _ALL_SOURCE
#endif

/* AC_ISC_POSIX */
/* Define if you need to in order for stat and other things to work. */
#ifndef _POSIX_SOURCE
#undef _POSIX_SOURCE
#endif

/* AC_MINIX */
/* Define if you need to in order for stat and other things to work. */
#ifndef _POSIX_SOURCE
#undef _POSIX_SOURCE
#endif
/* Define if the system does not provide POSIX.1 features except
   with this defined. */
#ifndef _POSIX_1_SOURCE
#undef _POSIX_1_SOURCE
#endif
/* Define if on MINIX. */
#undef _MINIX


/* header files */

/* CL_OPENFLAGS */
/* Define if you need <sys/file.h> for using open() flags like O_RDWR. */
#undef OPEN_NEEDS_SYS_FILE_H


/* functions and declarations */

/* CL_MEMSET */
/* Define if you have the memset() function. */
#undef HAVE_MEMSET
/* Define as the return type of memset(). */
#define RETMEMSETTYPE char*

/* CL_MALLOC */
/* Define as the return type of malloc(). */
#define RETMALLOCTYPE void*
/* Define as the type of `size' in malloc() declaration. */
#define MALLOC_SIZE_T size_t

/* CL_TYPE_SIGNAL */
/* Define as the return type of signal handlers (int or void). */
#define RETSIGTYPE void
/* Define if the declaration of the signal handler function type needs dots. */
#undef SIGTYPE_DOTS

/* CL_SIGNALBLOCK */
/* how to block and unblock signals */
#undef SIGNALBLOCK_SYSV
#define SIGNALBLOCK_POSIX 1
#undef SIGNALBLOCK_BSD

/* CL_SIGNAL_REINSTALL */
/* Define if signal handlers need to be reinstalled when they are activated. */
#undef SIGNAL_NEED_REINSTALL

/* CL_SIGNAL_UNBLOCK */
/* Define if SIGNALBLOCK_BSD is defined above and
   signals need to be unblocked when signal handlers are left. */
#define SIGNAL_NEED_UNBLOCK 1

/* CL_SIGNAL_BLOCK_OTHERS */
/* Define if SIGNALBLOCK_BSD is defined above and
   other signals need to be unblocked when signal handlers are left. */
#undef SIGNAL_NEED_UNBLOCK_OTHERS

/* CL_SIGACTION */
/* Define if you have the sigaction() function. */
#define HAVE_SIGACTION 1

/* CL_SIGACTION_REINSTALL */
/* Define if signal handlers installed via sigaction()
   need to be reinstalled when they are activated. */
#undef SIGACTION_NEED_REINSTALL

/* CL_SIGACTION_UNBLOCK */
/* Define if signals need to be unblocked
   when signal handlers installed via sigaction() are left. */
#define SIGACTION_NEED_UNBLOCK 1

/* CL_SIGINTERRUPT */
/* Define if you have the siginterrupt() function. */
#undef HAVE_SIGINTERRUPT
/* Define if you don't have siginterrupt() or sigaction(), but sigvec(). */
#undef HAVE_SIGVEC

/* CL_SIGALTSTACK */
/* Define if you have the sigaltstack() function and the SA_ONSTACK macro. */
#undef HAVE_SIGALTSTACK

/* CL_GETPAGESIZE */
/* Define if you have getpagesize(). */
#undef HAVE_GETPAGESIZE
/* Define as the return type of getpagesize(). */
#undef RETGETPAGESIZETYPE

/* CL_VADVISE */
/* Define if you have the vadvise() system call. */
#undef HAVE_VADVISE

/* CL_MACH_VM */
/* Define if you have the vm_allocate() and task_self() functions. */
#undef HAVE_MACH_VM

/* CL_MMAP */
/* Define if you have <sys/mman.h> and the mmap() function. */
#undef HAVE_MMAP
/* Define as the return type of mmap(). */
#undef RETMMAPTYPE
/* Define as the type of `addr' in mmap() declaration. */
#undef MMAP_ADDR_T
/* Define as the type of `len' in mmap() declaration. */
#undef MMAP_SIZE_T
/* Define if <sys/mman.h> defines MAP_ANON and mmaping with MAP_ANON works. */
#undef HAVE_MMAP_ANON
/* Define if <sys/mman.h> defines MAP_ANONYMOUS and mmaping with MAP_ANONYMOUS
   works. */
#undef HAVE_MMAP_ANONYMOUS
/* Define if mmaping of the special device /dev/zero works. */
#undef HAVE_MMAP_DEVZERO
/* Define if mmaping of the special device /dev/zero works,
   but only on addresses < 2^29. */
#undef HAVE_MMAP_DEVZERO_SUN4_29

/* CL_MPROTECT */
/* Define if you have the mprotect() function. */
#undef HAVE_MPROTECT
/* Define if you have a working mprotect() function. */
#undef HAVE_WORKING_MPROTECT
/* Define as const if the declaration of mprotect() needs const. */
#define MPROTECT_CONST

/* CL_RLIMIT */
/* Define if you have the setrlimit() function. */
#undef HAVE_SETRLIMIT
/* Define as the type of `resource' in setrlimit() declaration. */
#undef RLIMIT_RESOURCE_T
/* Define as const if the declaration of setrlimit() needs const. */
#define SETRLIMIT_CONST
