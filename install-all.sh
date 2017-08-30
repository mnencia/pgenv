#!/bin/bash

set -e
trap 'echo ERROR: installing $a FAILED!' ERR

cd ~/pgsql

for a in dev master REL*
do
    # if the directory doesn't exist skip it
    [ -d $a ] || continue

    # if an argument is provided install only that version
    [ -n "$1" ] && [ "$1" != "$a" ] && [ "REL${1/./_}_STABLE" != "$a" ] && [ "REL_${1}_STABLE" != "$a" ]&&  continue

    instdir="$HOME/.pgenv/versions/$a"
    rm -fr $a/DemoInstall "$instdir"
    pushd $a
    make -j$(nproc)
    make install
    make -C contrib -j$(nproc)
    make -C contrib install
    popd
done
