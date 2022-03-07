#!/usr/bin/env bash

###
### Install script for my DWM
###

SCRIPT_DIR="$(pwd)"
PATCHES_DIRECTORY="$(pwd)/patches"
DWM_DIRECTORY="$(pwd)/dwm"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
# Styles
NC='\033[0m' # No Color
BOLD=$(tput bold)
NORMAL=$(tput sgr0)


patches=(
    "config.diff"
    "nomonocleborder.diff"
    "fullgaps.diff"
    "alwayscenter.diff"
    "cyclelayouts.diff"
    "movestack.diff"
    "pertag.diff"
    "bar-height.diff"
    "colorbar.diff"
    "status2d-systray.diff"
    "steam.diff"
    # "bar.diff"
)

function config_install(){
    print_message "Installing..." ${BLUE}

    config_clean
    config_load
    config_merge

    make && sudo make clean install || exit 1

    config_clean

    print_message "Install complete." ${GREEN}
}

function config_build(){
    print_message "Building..." ${BLUE}
    make
    print_message "Build complete." ${GREEN}
}

function config_load(){
    print_message "Merging..." ${BLUE}

    # Create a git branch per patch and apply them
    for patch in ${patches[@]}; do
    git checkout master &&
    git checkout -b $patch &&
    git apply $PATCHES_DIRECTORY/$patch &&
    git add -A &&
    git commit -m $patch || exit 1
    done

    git checkout master

    print_message "Merge complete." ${GREEN}
}

function config_merge(){
    print_message "Merging..." ${BLUE}

    git checkout -b custom
    for branch in $(git for-each-ref --format='%(refname)' refs/heads/ | cut -d'/' -f3); do
        if [ "$branch" == "master" ] || [ "$branch" == "custom" ];then
            continue
        fi
        echo "Merging $branch"
        git merge $branch -m $branch || exit 1
    done

    print_message "Merge complete."
}

function config_clean(){
    print_message "Cleaning..." ${BLUE}

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

    print_message "Clean complete." ${GREEN}
}

function config_diff(){
    print_message "Diff..." ${BLUE}

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
    print_message "Diff complete." ${GREEN}
}

function print_message() {
    echo -e "${BOLD}${2} ::${NC} ${BOLD}${1}${NORMAL}"
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
    -m|--merge)
      config_merge
      ;;
    -b|--build)
      config_build
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
