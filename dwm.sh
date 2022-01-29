#!/usr/bin/env bash

###
### Install script for my DWM
###

SCRIPT_DIR="$(pwd)"
PATCHES_DIRECTORY="$(pwd)/patches"
DWM_DIRECTORY="$(pwd)/dwm"

patches=(
    "config.diff"
    "nomonocleborder.diff"
    "fullgaps.diff"
    "alwayscenter.diff"
    "cyclelayouts.diff"
    "focusonclick.diff"
    "movestack.diff"
    "pertag.diff"
    "colorbar.diff"
    "systray.diff"
    "conflict-colorbar-systray.diff"
    "conflict-statuspadding-barheight.diff"
    "steam.diff"
    "mybar.diff"
)

function config_install(){
    git checkout -b custom
    for branch in $(git for-each-ref --format='%(refname)' refs/heads/ | cut -d'/' -f3); do
    if [ "$branch" != "master" ] && [ "$branch" != "custom" ];then
        echo "Merging $branch"
        git merge $branch -m $branch || exit 1
    fi
    done

    make && sudo make clean install || exit 1

    config_clean
}

function config_load(){
    # Create a git branch per patch and apply them
    for patch in ${patches[@]}; do
    git checkout master &&
    git checkout -b $patch &&
    git apply $PATCHES_DIRECTORY/$patch &&
    git add -A &&
    git commit -m $patch || exit 1
    done

    git checkout master
}

function config_clean(){
    git checkout master &&
    make clean && git reset --hard origin/master &&
    for branch in $(git for-each-ref --format='%(refname)' refs/heads/ | cut -d'/' -f3); do
    if [ "$branch" != "master" ];then
        git branch -D $branch
    fi
    done
    for f in *.def.h; do
    [ -f "${f:0:${#f}-6}.h" ] && rm -f "${f:0:${#f}-6}.h" || continue
    done
}

function config_diff(){
    git checkout master && make clean && git reset --hard origin/master
    for f in *.def.h; do
    [ -f "${f:0:${#f}-6}.h" ] && rm -f "${f:0:${#f}-6}.h" || continue
    done
    for branch in $(git for-each-ref --format='%(refname)' refs/heads/ | cut -d'/' -f3); do
    if [ "$branch" != "master" ];then
        echo -e "" | cat "$PATCHES_DIRECTORY/headers/$branch" - > "$PATCHES_DIRECTORY/$branch" 2> /dev/null
        git diff master..$branch | sed -e '/^diff/,/^index/ {d}' | sed -e 's/\s\+$//' >> "$PATCHES_DIRECTORY/$branch"
    fi
    done
}

# Check the directory validity
[[ ! -d "$DWM_DIRECTORY" ]] && { echo 1>&2 "You are not in a valid directory"; exit 1; }
[[ ! -d "$PATCHES_DIRECTORY" ]] && { echo 1>&2 "You are not in a valid directory"; exit 1; }

cd $DWM_DIRECTORY

while [ "${1:-}" != "" ]; do
  case "$1" in
    -c|--clean)
      config_clean
      ;;
    -d|--diff)
      config_diff
      ;;
    -l|--load)
      config_load
      ;;
    -i|--install)
      config_install
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
  shift
done
