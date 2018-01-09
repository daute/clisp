

  #ifdef _MSC_VER
    #include "asmi386.h"
    #undef ALIGN
    #define ALIGN
  #else
    #ifdef ASM_UNDERSCORE /* defined(__EMX__) || defined(__GO32__) || defined(linux) || defined(__386BSD__) || defined(__NetBSD__) || ... */
      #define C(entrypoint) _##entrypoint
    #else /* defined(sun) || defined(COHERENT) || ... */
      #define C(entrypoint) entrypoint
    #endif


    #if defined(ASM_UNDERSCORE) && !(defined(__CYGWIN__) || defined(__MINGW32__))

      #define ALIGN  .align 3
    #else

      #define ALIGN  .align 8
    #endif
  #endif

        TEXT()

        GLOBL(C(asm_getSP))


        ALIGN
FUNBEGIN(asm_getSP)
        INSN2(lea,l	,X4 MEM_DISP(esp,4),R(eax))
        ret
FUNEND()

#if defined __linux__ || defined __FreeBSD__ || defined __FreeBSD_kernel__ || defined __DragonFly__
        .section .note.GNU-stack,"",@progbits
#endif


