/*
 * CLISP thread functions - multiprocessing
 * Distributed under the GNU GPL as a part of GNU CLISP
 * Sam Steingold 2003-2008
 */

#include "lispbibl.c"

#ifdef MULTITHREAD

/* signals an error of obj is not thread. returns the thread*/
local maygc object check_thread(object obj)
{
  while (!threadp(obj)) {
    pushSTACK(NIL); /* no PLACE */
    pushSTACK(obj);       /* TYPE-ERROR slot DATUM */
    pushSTACK(S(thread)); /* TYPE-ERROR slot EXPECTED-TYPE */
    pushSTACK(obj); pushSTACK(subr_self);
    check_value(type_error,GETTEXT("~S: ~S is not a thread"));
    /*NB:  since the reader cannot read thread objects - let's eval 
     what the user has entered. It does not look nice - TBD. 
     may be allow just symbols and take their value or look for thread
     name ???
    */
    eval(value1);
    obj=value1;
  } 
  return obj;
}

/* releases the clisp_thread_t memory of the list of Thread records */
global void release_threads (object list) {
  while (!endp(list)) {
    clisp_thread_t *thread = TheThread(Car(list))->xth_globals;
    free(thread->_ptr_symvalues);
    free(thread);
    list = Cdr(list);
  }
}

/* All newly created threads start here.*/
local /*maygc*/ void *thread_stub(void *arg)
{
  #if USE_CUSTOM_TLS == 2
  tse __tse_entry;
  tse *__thread_tse_entry=&__tse_entry;
  #endif
  clisp_thread_t *me=(clisp_thread_t *)arg;
  var struct backtrace_t bt;
  set_current_thread(me);
  me->_SP_anchor=(void*)SP();
  /* initialize backtrace */
  bt.bt_next = NULL;
  bt.bt_function = L(make_thread); /* not exactly */
  bt.bt_stack = STACK STACKop -1;
  bt.bt_num_arg = -1;
  back_trace = &bt;
  /* establish driver frame so on thread exit by 
   thread-kill we can unwind the stack properly by reset(0); */
  var gcv_object_t *initial_bindings = &STACK_1;
  var gcv_object_t *funptr = &STACK_2;
  /* create the thread exit CATCH frame */
  var gcv_object_t* top_of_frame = STACK STACKop 1;
  var sp_jmp_buf returner; /* return point */
  finish_entry_frame(CATCH,returner,,{skipSTACK(3);goto end_of_thread;});
  {
    /* make "top" driver frame */
    var gcv_object_t* top_of_frame = STACK; /* pointer above frame */
    var sp_jmp_buf returner; /* remember entry point */
    /* driver frame in order to be able to kill the thread and unwind the stack 
       via reset(0) call. */
    finish_entry_frame(DRIVER,returner,,{skipSTACK(2+3);goto end_of_thread;});
    /* create special vars initial dynamic bindings. 
       we do not create DYNBIND frame since anyway we are at the 
       "top level" of the thread. */
    if (boundp(*initial_bindings) && !endp(*initial_bindings)) {
      while (!endp(*initial_bindings)) {
	var object pair=Car(*initial_bindings);
	if (consp(pair) && symbolp(Car(pair))) {
	  /* only if the symbol is special per thread variable */
	  if (TheSymbol(Car(pair))->tls_index != SYMBOL_TLS_INDEX_NONE) {
	    eval(Cdr(pair)); /* maygc */
	    pair=Car(*initial_bindings);
	    Symbol_thread_value(Car(pair)) = value1;
	  }
	}
      *initial_bindings = Cdr(*initial_bindings);
      }
    }
    funcall(*funptr,0); /* call fun */
    reset(0);  /* unwind what we have till now */
  }
 end_of_thread:
  skipSTACK(2); /* function + init bindings */
  /* the lisp stack should be unwound here. check it and complain. */
  if (!(eq(STACK_0,nullobj) && eq(STACK_1,nullobj))) {
    /* we should always have empty stack - this is an error. */
    NOTREACHED;
  }
  /* just unregister it from the active threads. the allocated memory
     will be released during GC (if there are no references to thread object)*/
  delete_thread(me,false); 
  xthread_exit(0);
  return NULL;
}

LISPFUN(make_thread,seclass_default,1,0,norest,key,4,
	(kw(name),kw(initial_bindings),kw(cstack_size),kw(vstack_depth)))
{ /* (MAKE-THREAD function 
                  &key name 
                  (initial-bindings THREADS:*default-special-bindings*)
		  (cstack-size THREADS::*DEFAULT-CONTROL-STACK-SIZE*)
		  (vstack-depth THREADS::*DEFAULT-VALUE-STACK-DEPTH*))
   */
  var clisp_thread_t *new_thread;
  /* init the stack size if not specified */
  if (missingp(STACK_0)) STACK_0 = Symbol_value(S(default_value_stack_depth));
  if (missingp(STACK_1)) STACK_1 = Symbol_value(S(default_control_stack_size));
  /* vstack_size */
  var uintM vstack_depth = I_to_uint32(check_uint32(popSTACK()));
  /* cstack_size */
  var uintM cstack_size = I_to_uint32(check_uint32(popSTACK()));
  if (!vstack_depth) { /* lisp stack empty ??? */
    /* use the same as the caller */
    vstack_depth=STACK_item_count(STACK_bound,STACK_start); /*skip 2 nullobj*/
  }
  if (cstack_size > 0 && cstack_size < 0x10000) { /* cstack too small ? */
    /*TODO: or may be signal an error */
    /* lets allocate at least 64 K */
    cstack_size = 0x10000;
  }
  if (vstack_depth < ca_limit_1) {
    /* TODO: may be signal an error */
    vstack_depth=ca_limit_1;
  }
  /* check initial bindings */
  if (!boundp(STACK_0)) /* if not bound set to mt:*default-special-bidnings* */
    STACK_0 = Symbol_value(S(default_special_bindings));
  if (!listp(STACK_0))
    error_list(STACK_0);
  /* check thread name */
  if (!stringp(STACK_1)) 
    STACK_1 = check_string_replacement(STACK_1);

  /* do allocations before thread locking */ 
  pushSTACK(allocate_thread(&STACK_1)); /* put it in GC visible place */
  pushSTACK(allocate_cons());
  /* create the thread's exit tag*/
  pushSTACK(unbound);
  funcall(S(gensym),1);
  pushSTACK(value1);
  /* let's lock in order to create and register */
  begin_blocking_call(); /* give chance the GC to work while we wait*/
  lock_threads(); 
  end_blocking_call();
  /* create clsp_thread_t */
  new_thread=create_thread(vstack_depth);
  if (!new_thread) {
    unlock_threads();
    skipSTACK(6); VALUES1(NIL); return;
  }
  /* push 2 null objects in the thread stack in order to stop
     marking in GC while initializing the thread and stack unwinding
     in case of error. */
  NC_pushSTACK(new_thread->_STACK,nullobj);
  NC_pushSTACK(new_thread->_STACK,nullobj);
  /* push the function to be executed */ 
  NC_pushSTACK(new_thread->_STACK,STACK_5);
  /* push the initial bindings alist */
  NC_pushSTACK(new_thread->_STACK,STACK_3);
  /* push the exit tag */
  NC_pushSTACK(new_thread->_STACK,popSTACK());
  new_thread->_thread_exit_tag = new_thread->_STACK STACKop 1;
  
  if (register_thread(new_thread)<0) {
    /* total failure */
    unlock_threads();
    delete_thread(new_thread,true);
    VALUES1(NIL);
    skipSTACK(5); 
    return;
  }
  var object new_cons=popSTACK();
  var object lthr=popSTACK();
  skipSTACK(3);
  /* initialize the thread references */
  new_thread->_lthread=lthr;
  TheThread(lthr)->xth_globals=new_thread;
  /* add to all_threads global */
  Car(new_cons) = lthr;
  Cdr(new_cons) = O(all_threads);
  O(all_threads) = new_cons;
  unlock_threads(); /* allow GC and other thread creation. */
  /* create the OS thread */
  if (xthread_create(&TheThread(lthr)->xth_system, &thread_stub,new_thread,cstack_size)) {
    pushSTACK(lthr);
    delete_thread(new_thread,false); /* remove it from the list */
    lthr=popSTACK();
    VALUES1(NIL); 
  } else
    VALUES1(lthr);
}

/* lock for the timeout_call_chain */
global spinlock_t timeout_call_chain_lock=0;
/* chain of sorted by expire time timeout_calls */
global timeout_call *timeout_call_chain=NULL;

/* returns true if p1 is before p2 (or equal) */
global bool timeval_less(struct timeval *p1, struct timeval *p2)
{
  return p1->tv_sec < p2->tv_sec ? true :
    (p1->tv_sec == p2->tv_sec) ? ((p1->tv_usec <= p2->tv_usec)) : false;
}

/* insert into sorted chain of timeout calls. 
   returns true if it was inserted as first element. 
   should be called with timeout_scheduler_lock held. */
local bool insert_timeout_call(timeout_call *tc)
{
  timeout_call **lastnextp=&timeout_call_chain,*chain=timeout_call_chain;
  while (chain != NULL && timeval_less(chain->expire, tc->expire)) {
    lastnextp=&chain->next; chain=chain->next;
  }
  *lastnextp=tc;
  tc->next=chain;
  return lastnextp == &timeout_call_chain;
}
/* removes a timeout_call from the chain */
local void remove_timeout_call(timeout_call *tc) 
{
   timeout_call **lastnextp=&timeout_call_chain,*chain=timeout_call_chain;
   while (chain && chain != tc) {
     lastnextp=&chain->next; chain=chain->next;
   }
   /* it's possible not to find the item here - if it has been 
      already removed by the signal handling thread */
   if (chain)
     *lastnextp=chain->next;
}

LISPFUNN(call_with_timeout,3)
{ /* (CALL-WITH-TIMEOUT timeout timeout-function body-function)
     It's too expensive to spawn a new OS thread here.
     Instead CATCH frame is established, a timeout_call is queued 
     in our signal handling thread and the body is executed. If the timeout
     elapses - the signal handling thread will interrupt the body 
     and the timeout function will be executed. */
#ifdef HAVE_SIGNALS
  var struct timeval tv;
  var struct timeval *tvp = sec_usec(STACK_2,unbound,&tv);
  if (tvp) {
    pushSTACK(unbound);
    funcall(S(gensym),1);
    pushSTACK(value1);
    var gcv_object_t* top_of_frame = STACK STACKop 1;
    var sp_jmp_buf returner; /* return point */
    finish_entry_frame(CATCH,returner,,{skipSTACK(3);goto timeout_function;});
    GC_SAFE_SPINLOCK_ACQUIRE(&timeout_call_chain_lock);
    /* start calculating the timeout after we get the spinlock ???
       may be before is better and not to try anything if we are delayed */
    var struct timeval now;
    var struct timeval timeout;
    gettimeofday(&now,NULL);
    timeout.tv_sec = now.tv_sec + tv.tv_sec;
    timeout.tv_usec = (now.tv_usec + tv.tv_usec);
    /* no more than a second of carry */
    if (timeout.tv_usec > 1000000) {
      timeout.tv_sec += 1;
      timeout.tv_sec -= 1000000;
    }
    var timeout_call tc={current_thread(),&STACK_2,&timeout,NULL};
    /* insert in sorted chain and signal if needed */
    if (insert_timeout_call(&tc)) {
      /* first item - let's signal the thread */
      raise(SIG_TIMEOUT_CALL);
    } else {
      /* not a first item in the chain - so no signal */
      spinlock_release(&timeout_call_chain_lock); 
    }
    {
      /* funcall in UNWIND_PROTECT frame in order to cleanup the 
	 chain */
      var gcv_object_t* top_of_frame = STACK;
      var sp_jmp_buf returner; /* return point */
      finish_entry_frame
	(UNWIND_PROTECT,returner,,
	 {
	   GC_SAFE_SPINLOCK_ACQUIRE(&timeout_call_chain_lock);
	   var restartf_t fun = unwind_protect_to_save.fun;
	   var gcv_object_t* arg = unwind_protect_to_save.upto_frame;
	   remove_timeout_call(&tc);
	   spinlock_release(&timeout_call_chain_lock); 
	   skipSTACK(2); /* unwind the frame */
	   fun(arg); /* jump further */
	 });
      funcall(STACK_5,0); /* call the body function */
      /* hmm - not timeout (or unwind_protect)*/
      skipSTACK(2); /* unwind_protect frame */
      GC_SAFE_SPINLOCK_ACQUIRE(&timeout_call_chain_lock);
      remove_timeout_call(&tc);
      spinlock_release(&timeout_call_chain_lock); 
      skipSTACK(3); /* skip the CATCH frame and the catch tag */
    }
  } else {
  timeout_function:
    funcall(STACK_1,0);
  }
  skipSTACK(3);
#else /* WIN32 has to wait */
  NOTREACHED;
#endif
}

LISPFUN(thread_wait,seclass_default,3,0,rest,nokey,0,NIL)
{ /* (THREAD-WAIT whostate timeout predicate &rest arguments)
   predicate may be a LOCK structure in which case we wait for its release
   timeout maybe NIL in which case we wait forever */
  /* set whostate! */
  /* Probbaly this will go entirely in LISP when locks are ready. */
  NOTREACHED;
}

LISPFUNN(thread_yield,0)
{ /* (THREAD-YIELD) */
  begin_blocking_system_call();
  xthread_yield();
  end_blocking_system_call();
  VALUES1(current_thread()->_lthread);
}

LISPFUNN(thread_kill,1)
{ /* (THREAD-KILL thread) */
  STACK_0=check_thread(STACK_0);
  /* locking the threads since _thread_exit_tag may become invalid meanwhile  */
  begin_blocking_call();
  lock_threads(); 
  end_blocking_call();
  var object thr=STACK_0; /*thread */
  /* exit throw tag */
  var gcv_object_t *exit_tag=(TheThread(thr)->xth_globals->_thread_exit_tag);
  if (exit_tag) { /* thread is alive */
    pushSTACK(S(thread_throw_tag));
    pushSTACK(*exit_tag);
    unlock_threads();
    funcall(S(thread_interrupt),3);
  } else { /* thread has gone */
    unlock_threads();
    skipSTACK(1);
    VALUES2(thr,NIL);
  }
}

LISPFUN(thread_interrupt,seclass_default,2,0,rest,nokey,0,NIL)
{ /* (THREAD-INTERRUPT thread function &rest arguments) */
#ifdef HAVE_SIGNALS
  var object thr=check_thread(STACK_(argcount+1));
  var xthread_t systhr=TheThread(thr)->xth_system;
  var clisp_thread_t *clt=TheThread(thr)->xth_globals; 
  var bool signal_sent=false;
  if (TheThread(thr)->xth_globals == current_thread()) {
    /* we want to interrupt ourselves ? strange but let's do it */
    funcall(Before(rest_args_pointer),argcount); skipSTACK(2);
    signal_sent=true;
  } else {
    /* we want ot interrupt different thread. */
    STACK_(argcount+1)=thr; /* gc may happen */
    /*TODO: may be check that the function argument can be 
      funcall-ed, since it is not very nice to get errors
      in interrupted thread (but basically this is not a 
      problem)*/
    WITH_STOPPED_THREAD
      (clt,true,
       {
	 /* be sure that the signal we send will be received */
	 spinlock_acquire(&clt->_signal_reenter_ok);
	 var gcv_object_t *saved_stack=clt->_STACK;
	 if (clt->_STACK != NULL) { /* thread is alive ? */
	   while (rest_args_pointer != args_end_pointer) {
	     var object arg = NEXT(rest_args_pointer);
	     NC_pushSTACK(clt->_STACK,arg);
	   }
	   NC_pushSTACK(clt->_STACK,posfixnum(argcount));
	   NC_pushSTACK(clt->_STACK,STACK_(argcount)); /* function */
	   signal_sent = (0 == xthread_signal(systhr,SIG_THREAD_INTERRUPT));
	   if (!signal_sent) {
	     /* for some reason we were unable to send the signal */
	     clt->_STACK=saved_stack; 
	     spinlock_release(&clt->_signal_reenter_ok);
	   } 
	 }
       });
    skipSTACK(2 + (uintL)argcount);
    /* TODO: may be signal an error if we try to interrupt
       terminated thread ???*/
  }
  /* return the thread and whether it was really interrupted*/
  VALUES2(clt->_lthread,signal_sent ? T : NIL); 
#else
  NOTREACHED; /* win32 not implemented */
#endif
}

LISPFUNN(threadp,1)
{ /* (THREADP object) */
  var object obj = popSTACK();
  VALUES_IF(threadp(obj));
}

LISPFUNN(thread_name,1)
{ /* (THREAD-NAME thread) */
  var object obj=check_thread(popSTACK());
  VALUES1(TheThread(obj)->xth_name);
}

LISPFUNN(thread_active_p,1)
{ /* (THREAD-ACTIVE-P thread) */
  var object obj=check_thread(popSTACK());
  VALUES_IF(TheThread(obj)->xth_globals->_STACK != NULL);
}

LISPFUNN(thread_state,1)
{ /* (THREAD-STATE thread) */
  NOTREACHED;
}

LISPFUNN(thread_whostate,1)
{ /* (THREAD-WHOSTATE thread) */
  NOTREACHED;
}

LISPFUNN(current_thread,0)
{ /* (CURRENT-THREAD) */
  VALUES1(current_thread()->_lthread);
}

LISPFUNN(list_threads,0)
{ /* (LIST-THREADS) */
  /* we cannot copy the all_threads list, since it maygc 
     and while we hold the threads lock - deadlock will occur. */
  var uintC count=0;
  begin_blocking_call();
  lock_threads(); /* stop GC and thread creation*/
  end_blocking_call();
  var object list=O(all_threads);
  while (!endp(list)) {
    count++;
    pushSTACK(Car(list));
    list=Cdr(list);
  }
  unlock_threads();
  VALUES1(listof(count));
}

/* helper function that returns pointer to the symbol's symvalue 
   in a thread. If the symbol is not bound in the thread - NULL is 
   returned */
local maygc gcv_object_t* thread_symbol_place(gcv_object_t *symbol, 
					      gcv_object_t *thread)
{
  var object sym=check_symbol(*symbol);
  if (eq(*thread,NIL)) {
    /* global value */
    return &TheSymbol(sym)->symvalue;
  } else {
    var clisp_thread_t *thr;
    if (eq(*thread,T)) {
      /* current thread value */
      thr=current_thread();
    } else {
      /* thread object */
      pushSTACK(sym); 
      *thread=check_thread(*thread);
      sym = popSTACK();
      thr=TheThread(*thread)->xth_globals;
    }
    *thread=thr->_lthread; /* for error reporting if needed */
    var uintL idx=TheSymbol(sym)->tls_index;
    if (idx == SYMBOL_TLS_INDEX_NONE ||
	eq(thr->_ptr_symvalues[idx], SYMVALUE_EMPTY))
      return NULL; /* not per thread special, or no bidning in thread */
    return &thr->_ptr_symvalues[idx];
  }
}

LISPFUNNR(symbol_value_thread,2)
{ /* (MT:SYMBOL-VALUE-THREAD symbol thread) */
  gcv_object_t *symval=thread_symbol_place(&STACK_1, &STACK_0);
  if (!symval || eq(unbound,*symval)) {
    VALUES2(NIL,NIL); /* not bound */
  } else {
    VALUES2(*symval,T);
  }
  skipSTACK(2);
}

LISPFUNN(set_symbol_value_thread,3)
{ /* (SETF (MT:SYMBOL-VALUE-THREAD symbol thread) value) */
  gcv_object_t *symval=thread_symbol_place(&STACK_2, &STACK_1);
  if (!symval) {
    var object symbol=STACK_2;
    var object thread=STACK_1;
    pushSTACK(symbol); /* CELL-ERROR Slot NAME */
    pushSTACK(thread);
    pushSTACK(symbol); pushSTACK(S(set_symbol_value_thread));
    error(unbound_variable,GETTEXT("~S: variable ~S has no binding in thread ~S"));
  } else {
    *symval=STACK_0;
    VALUES1(*symval);
  }
  skipSTACK(3);
}


#endif  /* MULTITHREAD */
