AC_INIT(src/pentawall.c)
AM_INIT_AUTOMAKE(libpentawall,0.0.1)
AC_GNU_SOURCE
AM_CONFIG_HEADER(config.h)
AM_PROG_LIBTOOL

AC_PROG_INSTALL

PKG_CHECK_MODULES([XCBSTUFF], [xcb])

AC_LANG_C
AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_MAKE_SET

AC_OUTPUT([
	   Makefile
	   src/Makefile
	   src/libpentawall-1.0.pc
	   ])

