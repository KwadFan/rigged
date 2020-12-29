#!/bin/bash
#   Function Libary for
#
#   rigfetch - a little and simple shell script for
#              raspios or raspios derivates,
#              default for fullRigg3DPI,
#              like neofetch or pfetch.
#   and
#
#   rigpkg - wrapper for apt and github updates
#            on raspios or raspios derivates
#            (comming soon, WIP!)
#
# Copyright (C) 2020 Stephan Wendel <me@stephanwe.de>
#
# github: KwadFan
#
# This file may be distributed under the terms of the GNU GPLv3 license
#
#
# Signed-off-by: Stephan Wendel <me@stephanwe.de>
#
#shellcheck disable=SC2024
#shellcheck disable=SC2164


#### Status Messages

### Colors

fail="$(tput setaf 1)"
ok="$(tput setaf 2)"
warn="$(tput setaf 3)"
blue="$(tput setaf 4)"
debug="$(tput setaf 5)"
default="$(tput sgr0)"

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

### General
# Logging ( call log_msg "LOG_MSG" "PATHTOLOGFILE")
log_msg() {
    local logpath
    local logmsg
    logmsg="${1}"
    logpath="${2}"
    date >> "${logpath}"
    echo -e "${logmsg}\n" >> "${logpath}"
}

### Apt Helpers

# Last apt-get update
# Spits out seconds since epoche
last_apt_update() {
    local OUT
    OUT="$(stat -c %Y /var/cache/apt/pkgcache.bin)"
    echo "${OUT}"
}

# List upgradeable packages
# ( call count_sys_updates or
# count_sys_updates "PATHTOLOGFILE" if other file than default)
count_sys_updates() {
    local OUT
    # Log file
    local logpath
    logpath="${1}"
    if [ -z "${logpath}" ]
        then
            logpath="/tmp/system-updates.log"
    fi
    OUT="$(LC_ALL=C /usr/bin/apt-get -q -y --ignore-hold --allow-change-held-packages --allow-unauthenticated -s dist-upgrade | grep -c "^Inst" )"
    log_msg "${OUT} System Updates available!" "${logpath}"
    echo "${OUT}"
}


### Git Helpers

# git fetch
# fetch latest updates.
# ( call fetch_git_latest "PATHTOGITCLONEDFOLDER" )
fetch_git_latest() {
    local path
    path="${1}"
    if [ -d "${path}" ]
        then
            cd "${path}" 
            git fetch --tags --prune-tags --depth=1 > /dev/null 2>&1
        else
            return 1
    fi
}

# Check latest fetch
# Spits out seconds since last git fetch
# Useful to prevent fetch_git_latest runing if
# fetched recently
# ( call last_fetch "PATHTOGITCLONEDFOLDER" )
last_fetch() {
    local path
    path="${1}"
    if [ -f "${path}/.git/FETCH_HEAD" ]
        then
            echo "$(($(date +%s)-$(stat -c %Y "${path}"/.git/FETCH_HEAD)))"
        else
            #force fetch_git_latest
            echo "3700"
    fi
}

# Check local version
# ( call check_local_version "PATHTOGITCLONEDFOLDER" "PATHTOLOGFILE")
# Spits out local git cloned tag or latest commit
check_local_version() {
    local path
    local logpath
    local OUT
    path="${1}"
    logpath="${2}"
    if [ -d "${path}" ];
        then
            cd "${path}"
            OUT="$(git describe --always --tags | sed 's/-[a-z].*//')"
            if [ -n "${logpath}" ]
                then
                    log_msg "${path} Version: ${OUT}" "${logpath}"
            fi
        else
            OUT="N/A"
            if [ -n "${logpath}" ]
                then
                    log_msg "Warning! Directory ${path} not found, check configuration..." "${logpath}"
            fi
    fi
    echo "${OUT}"
}

# Check local version
# ( call check_remote_version "GITUSERNAME/GITNAME" "PATHTOLOGFILE")
# ex.: check_remote_version "KevinOConnor/klipper" "${RIGFETCH_LOG}"
# Spits out latest release tag
check_remote_version() {
    local gitrepo
    local logpath
    local OUT
    local version
    gitrepo="${1}"
    logpath="${2}"
    if [ -n "${gitrepo}" ]
        version="$(curl -s https://api.github.com/repos/"${gitrepo}"/tags | grep name | head -1 \
        | awk -F":" '{sub(/,/, ""); gsub(/"/, ""); gsub(/ /, ""); print $2}')"
        then
            if [ -n "${logpath}" ]
                then
                    log_msg "’${gitrepo}’ Version: ${version}" "${logpath}"
            fi
            OUT="${version}"
        else
            if [ -n "${logpath}" ]
                then
                    log_msg "Warning! Repository ${gitrepo} doesnt exist!" "${logpath}"
            fi
            OUT="N/A"
    fi
    echo "${OUT}"
}

# Read local Frontend Version
# Mangling Mainsail Frontend Version is shameless borrowed
# from the great th33xitus, who has made the "kiauh Suite"!
# Thanks and credits to him (https://github.com/th33xitus/kiauh)
# (call frontend_local_version "FRONTENDNAME" "PATHTOGITCLONEDDIR" "PATHTOLOGFILE")
frontend_local_version(){
    local frontend
    local path
    local logpath
    local OUT
    frontend="${1}"
    path="${2}"
    logpath="${3}"
    case "${frontend}" in
        fluidd)
            if [ -f "${path}/.version" ]
                then
                    OUT="$(cat "${path}"/.version)"
                else
                    OUT="N/A"
                    if [ -n "${logpath}" ]
                        then
                            log_msg "Warning! Could not detect 'fluidd' Version" "${logpath}"
                    fi
            fi
        ;;
        mainsail)
            # Thank you th33xitus
            # You are genious !
            local jsfile
            jsfile=$(find "${path}"/js -name "app.*.js" 2>/dev/null)
            if [ -f "${jsfile}" ]
                then
                    OUT="$(grep -o -E 'state:{packageVersion:.+' "${jsfile}" | cut -d'"' -f2)"
                else
                    OUT="N/A"
                    if [ -n "${logpath}" ]
                        then
                            log_msg "Warning! Could not detect 'mainsail' Version" "${logpath}"
                    fi
            fi
        ;;
        octoprint)
        OUT="N/A"
        ;;
    esac
    echo "${OUT}"
}


##########################################
###### DO NOT EDIT BELOW THIS LINE! ######
##########################################
