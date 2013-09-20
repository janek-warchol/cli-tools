#!/bin/bash

# this will update all branches in LILYPOND_GIT repository.
# if any argument is specified, it will also delete merged branches
# (i.e. branches that were already pushed upstream or merged with master).

while getopts "w" opts; do
    case $opts in
    w)
        colors="--color=never";;
    esac
done

# define colors, unless the user turned them off.
if [ -z $colors ]; then
    violet="\e[00;35m"
    yellow="\e[00;33m"
    green="\e[00;32m"
    red="\e[00;31m"
    normal="\e[00m"
    dircolor=$violet
fi

die() {
    # in case of some error...
    echo -e "$red$@$normal Exiting."
    if [ $dirtytree != 0 ]; then
        echo -e "$red""Warning!$normal"
        echo "When this script was ran, the HEAD of \$LILYPOND_GIT"
        echo -e "repository was $yellow$prev_commit$normal"
        echo -e "(branch $yellow$prev_branch$normal)"
        echo "and there were uncommitted changes on top of that commit."
        echo "They were saved using 'git stash' and you should be able"
        echo "to get them back using 'git stash apply'."
        echo ""
        echo "Before doing that make sure that the repository"
        echo "is in good state - maybe the thing that caused this script"
        echo "to abort requires some cleanup."
    fi
    exit 1
}

cd $LILYPOND_GIT/
echo "========================================"
echo "If you have any uncommitted changes, they will be saved using"
echo "'git stash' and restored after the script finishes successfully..."
prev_branch=$(git branch --color=never | sed --quiet 's/* \(.*\)/\1/p')
prev_commit=$(git rev-parse HEAD)
# with --quiet, diff exits with 1 when there are any uncommitted changes.
git diff --quiet HEAD
dirtytree=$?
git stash
sleep 3

echo ""
echo -e "$green""FETCHING$normal--------------------------------"
git fetch
echo ""

echo -e "$green""UPDATING YOUR BRANCHES$normal------------------";
for branch in $(git branch --color=never | sed s/*//); do
    git checkout --quiet "$branch" || die;
    echo -e "On branch $yellow$branch$normal"

    # Try to rebase against respective upstream branch
    # (taken from config). If that fails, try to rebase
    # against origin/master, because that's usually what
    # you want anyway.
    git rebase
    if [ $? != 0 ]; then
        echo -e "\nThis means$red a warning: upstream branch" \
             "is not configured.$normal"
        echo "Don't worry, that's not dangerous."
        echo "Trying to rebase on origin/master..."
       # sleep 7
        git rebase origin/master || die;
       # sleep 3
    fi
    echo "";
done

# $# = number of arguments specified by user
if [ $# != 0 ]; then
    git checkout --quiet master;
    echo -e "$yellow""DELETING MERGED BRANCHES$normal----------------";
    for branch in $(git branch --color=never | sed s/*// | sed s/master//); do
        git branch -d "$branch"
        echo ""
    done
    echo ""
fi

git checkout --quiet $prev_commit || \
die "Problems with checking out previous HEAD."
# there may be errors when initial state was a detached HEAD
# (no branch), but that's not a problem
git checkout --quiet $prev_branch 2> /dev/null

if [ $dirtytree != 0 ]; then
    echo -e "\n$green""Restoring uncommitted changes" \
    "from stash.$normal"
    git stash apply
fi

echo "________________________________________"
echo ""

#aplay -q ~/src/sznikers.wav
