#!/bin/bash

set -e

ARGS=

if which port > /dev/null
then
    ARGS="$ARGS --with-libraries=/opt/local/lib --with-includes=/opt/local/include"
elif which brew > /dev/null
then
    ARGS="$ARGS --with-libraries=/usr/local/opt/openssl/lib:/usr/local/opt/readline/lib"
    ARGS="$ARGS --with-includes=/usr/local/opt/openssl/include:/usr/local/opt/readline/include"
fi

ARGS="$ARGS --with-tcl --with-libxml --with-openssl"
DEBUG_ARGS="--enable-depend --enable-cassert --enable-debug"
CFLAGS="-O0 -g -fno-omit-frame-pointer"

# openSUSE and SUSE have tclConfig.sh in /usr/lib64 for x86_64 machines
if [ -f "/etc/SuSE-release" ] && [ "$(uname -m)" == 'x86_64' ]; then
	ARGS="$ARGS --with-tclconfig=/usr/lib64"
fi

if (which ccache && which clang ) > /dev/null
then
    ARGS="$ARGS CC='ccache clang -Qunused-arguments -fcolor-diagnostics'"
fi

for a in dev master REL*
do
    # if the directory doesn't exist skip it
    [ -d $a ] || continue

    # if an argument is provided install only that version
    [ -n "$1" ] && [ "$1" != "$a" ] && [ "REL${1/./_}_STABLE" != "$a" ] &&  continue

    instdir="$HOME/.pgenv/versions/$a"
    pushd $a
    ./configure --prefix="$instdir" ${DEBUG_ARGS} ${ARGS} CFLAGS="$CFLAGS"
    popd
done
