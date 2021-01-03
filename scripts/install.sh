#!/usr/bin/env bash
#
#   https://github.com/KwadFan/rigged
#   
#   rigsuite  Installer
#   
#   This script should be used to Install
#   and update the rigged tools
#
# Copyright (C) 2020 Stephan Wendel <me@stephanwe.de>
#
#
# This file may be distributed under the terms of the GNU GPLv3 license
#
#
# Signed-off-by: Stephan Wendel <me@stephanwe.de>
#
# shellcheck disable=SC2034

# Error Handling
set -e

### Vars

# Git Repo
RIG_GIT_REPO="https://github.com/KwadFan/rigged.git"

# Dependencies
DEPENDS=(curl git)

### Status Messages
# Colors
fail="$(tput setaf 1)"
ok="$(tput setaf 2)"
warn="$(tput setaf 3)"
blue="$(tput setaf 4)"
debug="$(tput setaf 5)"
default="$(tput sgr0)"
RS="$(tput sgr0)"
# Styling

### Message Helpers

std_msg() {
    echo -e "\n${default}$1"
}

blue_msg() {
    echo -e "\n--- ${blue}$1${default} ---"
}

ok_msg() {
    echo -e "\n### ${ok}$1${default} ###"
}

warn_msg() {
    echo -e "\n >>> ${warn}$1${default} <<<"
}

fail_msg() {
    echo -e "\n !>> ${fail}$1${default} <<!"
}

debug_msg() {
    echo -e "\n${debug}++++ $1 ++++${default}"
}

### Functions
# Check EUID
verify_ready()
{
    if [ "$EUID" -eq 0 ]; then
        fail_msg "DO NOT RUN AS ROOT! YOU WILL BE PROMPTED IF NEEDED!"
        exit 1
    fi
}

# ping github.com to check online and reachable
check_online() {
    ping -c1 github.com > /dev/null 2>&1
    echo "$?"
}

### Some Decoration :)
print_topline(){
    local style
    style="$(tput cup 0 $((($(tput cols)/33)*10)); tput setaf 0; tput bold)"
    tput clear
    echo -e "\e[0;105m\e[K${style}rigged Suite Installer\e[0m\v"
}

github_clone() {
    pushd "${HOME}" > /dev/null 2>&1
    echo -e "${ok}${PWD}${default}\n"
    git clone "${RIG_GIT_REPO}"
    popd > /dev/null 2>&1
}


### Main
# Check EUID
verify_ready
# Print Output
print_topline
# Check online
if [ "$(check_online)" -eq 0 ]
        then
            echo "github.com reachable...   [${ok}OK${default}]"
        else
            echo "github.com reachable...   [${fail}FAIL${default}]"
            fail_msg "https://github.com could not be reached,
            check your Internet Connection!"
            exit 1
fi
# Check Dependencies
NOTINSTALLED=()
for checkdeps in "${DEPENDS[@]}"
    do
        if [ -x "$(whereis "${checkdeps}" | awk '{print $2}')" ]
            then
                echo "Dependency ${checkdeps} found...  [${ok}OK${default}]"
            else
                echo "Dependency ${checkdeps} found...  [${fail}FAIL${default}]"
                NOTINSTALLED+=("${checkdeps}")
        fi
done
if [ "${#NOTINSTALLED[@]}" -ge 1 ]
    then
        while :; do
        read -r -p  "Do you want to install dependencies? " installdeps
            case "${installdeps}" in
                [Yy]*)
                sudo apt-get update && \
                sudo apt-get install "${NOTINSTALLED[@]}" -y
                ;;
                [Nn]*)
                    fail_msg "Installation failed, please install Dependencies!"
                    fail_msg "Dependends on: '${NOTINSTALLED[*]}'"
                    exit 1
                ;;
                *) echo "Please answer Y(ES) or N(O)."
                ;;
            esac
        done
fi
# Github Clone Check
if [ -d "${HOME}/rigged" ]
    then
        ok_msg "Git Repository already cloned, skipping..."
    else
        echo -e "Cloning Git Repository to:\n"
        github_clone
fi
# Set Link in /usr/bin
while :; do
read -r -p  "Do you want to set a link in /usr/bin/ ? " makelink
    case "${makelink}" in
        [Yy]*)
            if [ -x "${HOME}/rigged/rigfetch.sh" ]
                then
                    sudo ln -s "${HOME}/rigged/rigfetch.sh" /usr/bin/rigfetch
                    break
                else
                    fail_msg "rigfetch.sh not found..."
                    fail_msg "Please set link by yourself..."
                    break
            fi
        ;;
        [Nn]*)
            warn_msg "Link will not be created..."
            ok_msg "Please launch rigfetch by typing /path/to/rigfetch.sh"
            break
        ;;
        *) echo "Please answer Y(ES) or N(O)."
        ;;
    esac
done
# Adding to .bashrc?!
while :; do
read -r -p  "Do you want to add to .bashrc (runs on login) ? " addbashrc
    case "${addbashrc}" in
        [Yy]*)
            if [ -h "/usr/bin/rigfetch" ]
                then
                    echo -e "\n#### Rigfetch\nrigfetch" >> "${HOME}/.bashrc"
                else
                    echo -e "\n#### Rigfetch\n${HOME}/rigged/rigfetch.sh" \
                    >> "${HOME}/.bashrc"
                    
            fi
            break
        ;;
        [Nn]*)
            warn_msg "Not added to .bashrc..."
            ok_msg "Please launch rigfetch by typing /path/to/rigfetch.sh"
            break
        ;;
        *) echo "Please answer Y(ES) or N(O)."
        ;;
    esac
done
# HINT
ok_msg "Installation completed..."
warn_msg "Please edit Config File for rigfetch!"
warn_msg "Simply launch rigfetch -e :)"
ok_msg "Happy Printing!!!"
#EOF
exit 0