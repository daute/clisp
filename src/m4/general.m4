dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2011 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ(2.61)

dnl without AC_MSG_...:   with AC_MSG_... and caching:
dnl   AC_COMPILE_IFELSE      CL_COMPILE_CHECK
dnl   AC_LINK_IFELSE         CL_LINK_CHECK
dnl Usage:
dnl AC_xxx_IFELSE(PROGRAM, ACTION-IF-FOUND [, ACTION-IF-NOT-FOUND])
dnl CL_xxx_CHECK(ECHO-TEXT, CACHE-ID, PROGRAM,
dnl              ACTION-IF-FOUND [, ACTION-IF-NOT-FOUND])

dnl the next macro avoids aclocal warnings about wrong macro order
dnl when making aclocal.m4, see Makefile.devel.
dnl note that this macro cannot call AC_CONFIG_AUX_DIR directly because
dnl the required macros are evaluated BEFORE the macro itself
dnl and some of them require AC_CONFIG_AUX_DIR.
dnl <http://article.gmane.org/gmane.comp.lib.gnulib.bugs/16312>
AC_DEFUN([CL_MODULE_COMMON_CHECKS],[dnl
AC_REQUIRE([CL_CLISP],[CL_CLISP($1)])dnl
AC_REQUIRE([AC_CONFIG_AUX_DIR],
[AC_CONFIG_AUX_DIR([$cl_cv_clisp_libdir/build-aux])])dnl
AC_REQUIRE([AC_PROG_CC])dnl
AC_REQUIRE([AC_PROG_CPP])dnl
AC_REQUIRE([CL_PROG_LN_S])dnl
AC_REQUIRE([AC_GNU_SOURCE])dnl
AC_REQUIRE([AC_USE_SYSTEM_EXTENSIONS])dnl
AC_CHECK_HEADERS(time.h sys/time.h)dnl
])

AC_DEFUN([CL_CHECK],[dnl
  AC_CACHE_CHECK([for $2],[$3],
    [$1([AC_LANG_PROGRAM([$4],[$5])],[$3=yes],[$3=no])])
  AS_IF([test $$3 = yes], [$6], [$7])
])

AC_DEFUN([CL_COMPILE_CHECK], [CL_CHECK([AC_COMPILE_IFELSE],$@)])
AC_DEFUN([CL_LINK_CHECK], [CL_CHECK([AC_LINK_IFELSE],$@)])

dnl Expands to the "extern ..." prefix used for system declarations.
dnl AC_LANG_EXTERN()
AC_DEFUN([AC_LANG_EXTERN],
[extern
#ifdef __cplusplus
"C"
#endif
])

AC_DEFUN([CL_CC_WORKS],
[AC_CACHE_CHECK(whether CC works at all, cl_cv_prog_cc_works, [
AC_LANG_PUSH(C)
AC_RUN_IFELSE([AC_LANG_PROGRAM([],[])],
[cl_cv_prog_cc_works=yes], [cl_cv_prog_cc_works=no],
AC_LINK_IFELSE([AC_LANG_PROGRAM([],[])],
[cl_cv_prog_cc_works=yes], [cl_cv_prog_cc_works=no]))
AC_LANG_POP(C)
])
if test "$cl_cv_prog_cc_works" = no; then
AC_MSG_FAILURE([Installation or configuration problem: C compiler cannot create executables.])
fi
])
