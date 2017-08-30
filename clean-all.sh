#!/bin/bash

for a in dev master REL*
do
    # if the directory doesn't exist skip it
    [ -d $a ] || continue

    # if an argument is provided install only that version
    [ -n "$1" ] && [ "$1" != "$a" ] && [ "REL${1/./_}_STABLE" != "$a" ] && [ "REL_${1}_STABLE" != "$a" ]&&  continue

    rm -fr "$HOME/.pgenv/versions/$a" "$HOME/.pgenv/data/$a/*"
    pushd $a
    make clean distclean
    popd
done
