# Handling of signal SIGSEGV (or SIGBUS on some platforms).

# ------------------------------ Specification ---------------------------------

#if defined(SELFMADE_MMAP) || defined(GENERATIONAL_GC)

# Install the signal handler for catching page faults.
  local void install_segv_handler (void);

#endif # SELFMADE_MMAP || GENERATIONAL_GC

#ifdef NOCOST_SP_CHECK

# Install the stack overflow handler.
# install_stackoverflow_handler(size);
# > size: size of substitute stack.
# This function must be called from main(); it allocates the substitute stack
# using alloca().
  local void install_stackoverflow_handler (uintL size);

#endif

# ------------------------------ Implementation --------------------------------

#if defined(SELFMADE_MMAP) || defined(GENERATIONAL_GC)

  # Put a breakpoint here if you want to catch CLISP just before it dies.
  global void sigsegv_handler_failed(address)
    var void* address;
    { asciz_out_1(DEUTSCH ? NLstring "SIGSEGV kann nicht behoben werden. Fehler-Adresse = 0x%x." NLstring :
                  ENGLISH ? NLstring "SIGSEGV cannot be cured. Fault address = 0x%x." NLstring :
                  FRANCAIS ? NLstring "SIGSEGV ne peut �tre relev�. Adresse fautive = 0x%x." NLstring :
                  "",
                  address
                 );
    }

  # Signal-Handler f�r Signal SIGSEGV u.�.:
  local int sigsegv_handler (void* fault_address)
    { set_break_sem_0();
      switch (handle_fault((aint)fault_address))
        { case handler_done:
            # erfolgreich
            clr_break_sem_0();
            return 1;
          case handler_failed:
            # erfolglos
            sigsegv_handler_failed(fault_address);
            # Der Default-Handler wird uns in den Debugger f�hren.
          default:
            clr_break_sem_0();
            return 0;
        }
    }

  # Alle Signal-Handler installieren:
  local void install_segv_handler (void);
  local void install_segv_handler()
    { sigsegv_install_handler(&sigsegv_handler); }

#endif # SELFMADE_MMAP || GENERATIONAL_GC

#ifdef NOCOST_SP_CHECK

  local void stackoverflow_handler (int emergency);
  local void stackoverflow_handler(emergency)
    var int emergency;
    { if (emergency)
        { asciz_out(DEUTSCH ? "Szenario Apollo 13: Stack-�berlauf-Behandlung ging schief. Beim n�chsten Stack-�berlauf kracht's!!!" NLstring :
                    ENGLISH ? "Apollo 13 scenario: Stack overflow handling failed. On the next stack overflow we will crash!!!" NLstring :
                    FRANCAIS ? "Sc�nario Apollo 13 : R�paration de d�bordement de pile a �chou�. Au prochain d�bordement de pile, �a cassera!!!" NLstring :
                    ""
                   );
        }
      SP_ueber();
    }

  # Must allocate room for a substitute stack for the stack overflow
  # handler itself. This cannot be somewhere in the regular stack,
  # because we want to unwind the stack in case of stack overflow.
  #define install_stackoverflow_handler(size)  \
    { var void* room = alloca(size);                                          \
      stackoverflow_install_handler(&stackoverflow_handler,(void*)room,size); \
    }

#endif
