dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2008, 2010, 2017 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ([2.13])

dnl CL_PROTO(IDENTIFIER, ACTION-IF-NOT-FOUND, FINAL-PROTOTYPE)
AC_DEFUN([CL_PROTO],
[
  AC_MSG_CHECKING([for $1 declaration])
  AC_CACHE_VAL([cl_cv_proto_$1],
    [$2
     cl_cv_proto_$1="$3"
    ])
  cl_cv_proto_$1=`echo "[$]cl_cv_proto_$1" | tr -s ' ' | sed -e 's/( /(/'`
  AC_MSG_RESULT([$][cl_cv_proto_$1])
])

dnl CL_PROTO_RET(INCLUDES, DECL, CACHE-ID, TYPE-IF-OK, TYPE-IF-FAILS)
AC_DEFUN([CL_PROTO_RET],
[
  AC_TRY_COMPILE([
    $1
    ]AC_LANG_EXTERN[
    $2
    ],
    [],
    [$3="$4"],
    [$3="$5"])
])

dnl CL_PROTO_TRY(INCLUDES, DECL, ACTION-IF-OK, ACTION-IF-FAILS)
AC_DEFUN([CL_PROTO_TRY],
[
  AC_TRY_COMPILE([
    $1
    ]AC_LANG_EXTERN[
    $2
    ],
    [],
    [$3],
    [$4])
])

dnl CL_PROTO_CONST(INCLUDES, DECL, CACHE-ID)
AC_DEFUN([CL_PROTO_CONST],
[
  CL_PROTO_TRY([$1], [$2], [$3=""], [$3="const"])
])

dnl CL_PROTO_MISSING(function_name)
AC_DEFUN([CL_PROTO_MISSING],
[
  AC_MSG_FAILURE([please report the $1() declaration on your platform to $PACKAGE_NAME developers at $PACKAGE_BUGREPORT])
])

m4_define([CONST_VARIANTS], ['' 'const' '__const'])
m4_define([SIZE_VARIANTS], ['unsigned int' 'int' 'unsigned long' 'long' 'size_t' 'socklen_t'])
