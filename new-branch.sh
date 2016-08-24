#!/bin/bash

git --git-dir=master/.git/ config gc.auto 0

case "$1" in
  "")
    echo "ERROR: missing argument" >&2
    exit 1
    ;;
  master|10)
    BRANCH=master
    VER=10
    ;;
  *)
    BRANCH="REL${1/./_}_STABLE"
    VER="$1"
    ;;
esac

if [ ! -d master ]; then
    echo "ERROR: missing master directory" >&2
    exit 1
fi

if [ -d "$BRANCH" ]; then
    echo "Nothing to do"
    exit 0
fi

if [ ! -e git-new-workdir ]; then
   curl -L https://raw.github.com/git/git/master/contrib/workdir/git-new-workdir > git-new-workdir
fi

bash git-new-workdir master/.git/ $BRANCH $BRANCH
