# posix math functions in <math.h>
# Sam Steingold <sds@gnu.org> 1999+
# configure --export-syscalls to access these in the package posix

#ifdef EXPORT_SYSCALLS

## trying to include math.h

#ifdef __sun__
#define decimal_string solaris_decimal_string
#endif

#ifdef __linux__
#undef floor
#endif

#include <math.h>

#ifdef __sun__
#undef decimal_string
#endif

#ifdef __linux__
#define floor(a,b)  ((a) / (b))
#endif

## done with math.h

local double to_double (object x);
local double to_double(x)
  var object x;
{ check_real(x);
 { dfloatjanus fj;
   DF_to_c_double(R_rationalp(x) ? RA_to_DF(x) : F_to_DF(x), &fj);
   { double ret; *(dfloatjanus*)&ret = fj; return ret; }
}}

local int to_int (object x);
local int to_int(x)
  var object x;
{ check_integer(x); return I_to_L(x); }

#define D_S           to_double(popSTACK())
#define I_S           to_int(popSTACK())
#define N_D(n,v)  \
 { double x=n; dfloatjanus t=*(dfloatjanus*)&x; v=c_double_to_DF(&t); }
#define VAL_D(func)   double res=func(D_S); N_D(res,value1)
#define VAL_ID(func)  \
 double xx=D_S; int nn=I_S; double res=func(nn,xx); N_D(res,value1)

LISPFUNN(erf,1)
{ VAL_D(erf); mv_count=1; }

LISPFUNN(erfc,1)
{ VAL_D(erfc); mv_count=1; }

LISPFUNN(j0,1)
{ VAL_D(j0); mv_count=1; }

LISPFUNN(j1,1)
{ VAL_D(j1); mv_count=1; }

LISPFUNN(jn,2)
{ VAL_ID(jn); mv_count=1; }

LISPFUNN(y0,1)
{ VAL_D(y0); mv_count=1; }

LISPFUNN(y1,1)
{ VAL_D(y1); mv_count=1; }

LISPFUNN(yn,2)
{ VAL_ID(yn); mv_count=1; }

LISPFUNN(gamma,1)
{ VAL_D(gamma); mv_count=1; }

LISPFUNN(lgamma,1)
{
#ifdef _REENTRANT
  int sign;
  double res = lgamma_r(D_S,&sign);
  value2 = sfixnum(sign);
#else
  double res = lgamma(D_S);
  value2 = sfixnum(signgam);
#endif
  N_D(res,value1); mv_count=2;
}

#include <time.h>

LISPFUNN(bogomips,0)
# (POSIX:BOGOMIPS)
{
  var unsigned long loops = 1, ticks, ii;

  mv_count=1;
  if ((clock_t)-1 == clock()) {
    N_D(-1.0,value1);
    return;
  }
  while ((loops <<= 1)) {
    ticks = clock();
    for (ii = loops; ii > 0; ii--);
    ticks = clock() - ticks;
    if (ticks >= CLOCKS_PER_SEC) {
      double bogo = (1.0 * loops / ticks) * (CLOCKS_PER_SEC / 500000.0);
      N_D(bogo,value1);
      return;
    }
  }
  N_D(-1.0,value1);
}

#undef D_S
#undef I_S
#undef N_D
#undef VAL_D
#undef VAL_ID

#endif # EXPORT_SYSCALLS