#!/bin/bash -e
die(){ echo $1; exit; }
pushd master
git fetch --all -p
git checkout master
git reset --hard origin/master
popd
for a in REL*
do
    pushd $a
    git checkout $a
    git reset --hard origin/$a
    popd
done
pushd master
git diff-index --quiet HEAD || die "Skip updating dirty master"
u="$(git ls-files --exclude-standard --others)" && test -z "$u" || die "Skip unpdating dirty (untracked) master" 
git checkout master
git rebase origin/master
popd
