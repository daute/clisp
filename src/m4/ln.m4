dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2008, 2017, 2021 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ([2.13])

AC_DEFUN([CL_PROG_LN],
[
  AC_CACHE_CHECK([how to make hard links], [cl_cv_prog_LN],
    [rm -f conftestdata conftestfile
     echo data > conftestfile
     if ln conftestfile conftestdata 2>/dev/null; then
       cl_cv_prog_LN=ln
     else
       cl_cv_prog_LN="cp -p"
     fi
     rm -f conftestdata conftestfile
    ])
  LN="$cl_cv_prog_LN"
  AC_SUBST([LN])
])

AC_DEFUN([CL_PROG_LN_S],
[
  AC_REQUIRE([CL_PROG_LN])
  dnl Make a symlink if possible; otherwise try a hard link. On filesystems
  dnl which support neither symlink nor hard link, use a plain copy.
  AC_CACHE_CHECK([whether ln -s works], [cl_cv_prog_LN_S_works],
    [rm -f conftestdata
     if ln -s X conftestdata 2>/dev/null; then
       cl_cv_prog_LN_S_works=yes
     else
       cl_cv_prog_LN_S_works=no
     fi
     rm -f conftestdata
    ])
  if test $cl_cv_prog_LN_S_works = yes; then
    LN_S="ln -s"
  else
    LN_S="$cl_cv_prog_LN"
  fi
  AC_SUBST([LN_S])
])

AC_DEFUN([CL_PROG_HLN],
[
  AC_REQUIRE([CL_PROG_LN_S])
  dnl according to the Linux ln(1):
  dnl   "making a hard link to a symbolic link is not portable":
  dnl SVR4 (Solaris, Linux) create symbolic links
  dnl   (breaks when the target is relative)
  dnl Cygwin (1.3.12) is even worse: it makes hard links to the symbolic link,
  dnl   instead of resolving the symbolic link.
  dnl Good behavior means creating a hard link to the symbolic link's target.
  dnl To avoid this, use the "hln" program.
  dnl cf gl_AC_FUNC_LINK_FOLLOWS_SYMLINK in gnulib/m4/link-follow.m4
  AC_CACHE_CHECK([how to make hard links to symlinks], [cl_cv_prog_hln],
    [cl_cv_prog_hln="ln"
     if test "$cl_cv_prog_LN_S_works" = "yes"; then
       echo "blabla" > conftest.x
       ln -s conftest.x conftest.y
       mkdir conftest.d
       cd conftest.d
       ln ../conftest.y conftest.z 2>&AS_MESSAGE_LOG_FD
       data=`cat conftest.z 2>/dev/null`
       if test "$data" = "blabla"; then
         # conftest.z contains the correct data -- good!
         cl_cv_prog_hln="ln"
       else
         # ln cannot link to symbolic links
         cl_cv_prog_hln="hln"
       fi
       cd ..
       rm -fr conftest.*
     else
       # If there are no symbolic links, the problem cannot occur.
       cl_cv_prog_hln="ln"
     fi
    ])
  HLN="$cl_cv_prog_hln"
  AC_SUBST([HLN])
])
