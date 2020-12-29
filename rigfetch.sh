#!/usr/bin/env bash
#
#   rigfetch - a little and simple shell script for
#            raspios or raspios derivates,
#            default for fullRigg3DPI,
#            like neofetch or pfetch.
#
#   Inspired by "pfetch" <https://github.com/dylanaraps/pfetch.git>
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

# shellcheck disable=SC1090
# shellcheck disable=SC2034
# shellcheck disable=SC2154

### Error Handling
set -e

### Set Colors
# Foreground
fg_black="$(tput setaf 0)"
fg_red="$(tput setaf 1)"
fg_green="$(tput setaf 2)"
fg_yellow="$(tput setaf 3)"
fg_blue="$(tput setaf 4)"
fg_purple="$(tput setaf 5)"
fg_cyan="$(tput setaf 6)"
fg_white="$(tput setaf 7)"


# Background

bg_black="$(tput setab 0)"
bg_red="$(tput setab 1)"
bg_green="$(tput setab 2)"
bg_yellow="$(tput setab 3)"
bg_blue="$(tput setab 4)"
bg_purple="$(tput setab 5)"
bg_cyan="$(tput setab 6)"
bg_white="$(tput setab 7)"

# reset colors
reset="$(tput sgr0)"


### Functions
# Be sure not running as privileged user.
verify_ready()
{
    if [ "$EUID" -eq 0 ]; then
        fail_msg "WARNING: DO NOT RUN AS ROOT!"
        log_msg "WARNING: ${LOGNAME} TRIED TO RUN AS ROOT!" "${RIGFETCH_LOG}"
        exit 1
    fi
}

# Debugging
enable_debugging(){
case $RIG_DEBUG in
    
    Y | y | YES | yes) 
        warn_msg "DEBUG ON"
        set -x
    ;;
esac
}

# Self check and setup
locate_self() {
    # In case of called by symolic link
    local SELF=
    if [ -f "${HOME}/rigged/rigfetch.sh" ]
        then
            SELF="${HOME}/rigged"
        else
            SELF="$(dirname "$(readlink -nf "$0")")"
    fi
    echo "$SELF"
}

### Set colors
set_color() {
    # BC1 Color
    case $BENCHY_FG_COLOR in
        black)
            BC1=$fg_black
            ;;
        red)
            BC1=$fg_red
            ;;
        green)
            BC1=$fg_green
            ;;
        yellow)
            BC1=$fg_yellow
            ;;
        blue)
            BC1=$fg_blue
            ;;
        purple)
            BC1=$fg_purple
            ;;
        cyan)
            BC1=$fg_cyan
            ;;
        white)
            BC1=$fg_white
            ;;
        auto)
            case $CHECK_FOR_UPDATES in
                Y | y | YES | yes)
                    if [ "$(count_sys_updates)" = "0" ]
                        then
                            case $AUTO_COLOR in
                                black)
                                    BC1=$fg_black
                                    ;;
                                red)
                                    BC1=$fg_red
                                    ;;
                                green)
                                    BC1=$fg_green
                                    ;;
                                yellow)
                                    BC1=$fg_yellow
                                    ;;
                                blue)
                                    BC1=$fg_blue
                                    ;;
                                purple)
                                    BC1=$fg_purple
                                    ;;
                                cyan)
                                    BC1=$fg_cyan
                                    ;;
                                white)
                                    BC1=$fg_white
                                    ;;
                                    *)
                                    BC1=$fg_purple
                                    ;;
                            esac
                        else
                        BC1=$fg_red
                    fi
                ;;
                *)
                    BC1=$fg_purple
                    log_msg "You have to enable CHECK_FOR_UPDATES to use 'auto' color" "${RIGFETCH_LOG}"
                ;;
            esac
            ;;
        *)
            BC1=$reset
            ;;
    esac
    # BC2 Color - Benchys Background   
    case $BENCHY_BG_COLOR in
        black)
            BC2=$bg_black
            ;;
        red)
            BC2=$bg_red
            ;;
        green)
            BC2=$bg_green
            ;;
        yellow)
            BC2=$bg_yellow
            ;;
        blue)
            BC2=$bg_blue
            ;;
        purple)
            BC2=$bg_purple
            ;;
        cyan)
            BC2=$bg_cyan
            ;;
        white)
            BC2=$bg_white
            ;;
        *)
            BC2=""
            ;;
    esac
    # TC Color - Text Color
    case $TEXT_FG_COLOR in
        black)
            TC=$fg_black
            ;;
        red)
            TC=$fg_red
            ;;
        green)
            TC=$fg_green
            ;;
        yellow)
            TC=$fg_yellow
            ;;
        blue)
            TC=$fg_blue
            ;;
        purple)
            TC=$fg_purple
            ;;
        cyan)
            TC=$fg_cyan
            ;;
        white)
            TC=$fg_white
            ;;
        *)
            TC=$reset
            ;;
    esac
    # TB Color - Text Background Color   
    case $TEXT_BG_COLOR in
        black)
            TB=$bg_black
            ;;
        red)
            TB=$bg_red
            ;;
        green)
            TB=$bg_green
            ;;
        yellow)
            TB=$bg_yellow
            ;;
        blue)
            TB=$bg_blue
            ;;
        purple)
            TB=$bg_purple
            ;;
        cyan)
            TB=$bg_cyan
            ;;
        white)
            TB=$bg_white
            ;;
        *)
            TB=""
            ;;
    esac
    case $AT_SYMBOL_COLOR in
        black)
            ATC=$fg_black
            ;;
        red)
            ATC=$fg_red
            ;;
        green)
            ATC=$fg_green
            ;;
        yellow)
            ATC=$fg_yellow
            ;;
        blue)
            ATC=$fg_blue
            ;;
        purple)
            ATC=$fg_purple
            ;;
        cyan)
            ATC=$fg_cyan
            ;;
        white)
            ATC=$fg_white
            ;;
        *)
            ATC=$fg_white
            ;;
    esac
}

### Arg parser
arg_parse() {
    while [[ $# -gt 0 ]]
        do
            case "$@" in
                -h | --help)
                    echo -e "Syntax: "$0" [Options]\n"
                    echo -e "Available Options are:\n"
                    echo -e "-l or \--showlog\tShould be obvious :)"
                    echo -e "-d or \--deletelog\tDeletes rigfetch's log file"
                    echo -e "\t\t\t(Usualy in /tmp/rigfetch.log)\v"
                    echo -e "-e or --editconfig\tOpens rigfetch's config file"
                    echo -e "If EDITOR Variable is set it opens with your Editor of Choice"
                    echo -e "Otherwise it uses 'nano' as fallback solution.\v"
                    echo -e "-b or --backup\tWill do a backup of the rigfetch.conf"
                    echo -e "--debug\tRIPS OUT ALL OF IT'S CUTENESS!"
                    echo -e "\tand show you his naked Pants oO ( equal to set -x )\v"
                    echo -e "-h or --help ... must I really?\v"
                    echo -e "Without options it throws a benchy :)"
                    echo -e "Now you are on your own..."
                    exit 0
                    ;;
                -b | --backup)
                    ok_msg "Copying rigfetch.conf to rigfetch.conf.bak"
                    cp --preserve=mode -f "${RIGFETCH_PATH}/config/rigfetch.conf" "${RIGFETCH_PATH}/config/rigfetch.conf.bak"
                    ;;
                -d | --deletelog)
                    if [ -f "${RIGFETCH_LOG}" ]
                        then
                            std_msg "You are about to delete logfile..."
                            rm -i "${RIGFETCH_LOG}"
                        else
                            ok_msg "There is no Log to delete..."
                    fi
                    exit 0
                    ;;
                -e | --editconfig)
                    if [ -n "$EDITOR" ]
                        then
                            $EDITOR "${RIGFETCH_PATH}/config/rigfetch.conf"
                        else
                            /usr/bin/nano "${RIGFETCH_PATH}/config/rigfetch.conf"
                    fi
                    exit 0
                    ;;
                -l | --showlog)
                    less "${RIGFETCH_LOG}"
                    exit 0
                    ;;
                --debug)
                    set -x
                    RIG_DEBUG=YES
                    return 0
                    ;;
                *)
                    fail_msg "Syntax Error!"
                    std_msg "Please try "$0" --help or -h\n"
                    exit 1
                    ;;
            esac
    done
}


### Gathering Informations

first_line() {
    local OUTPUT
    if [ -x "/usr/bin/hostname" ]
        then
            OUTPUT="${TC}${TB}$(whoami)${ATC}@${reset}${TC}${TB}$(hostname -A)${reset}${TB} $(hostname -I)${reset}"
        else
            fail_msg "Command 'hostname' not found! Exiting..."
            exit 1
    fi
    echo "${OUTPUT}"
}

rig_uptime() {
    local UP
    UP="$(LC_ALL=C uptime -p | tr -d ',' | sed 's/.*up.//; s/.week./W /; s/.day./d /; s/.hour./h /; s/.minut.*/m/')"
    echo "  ${UP}"
}

rig_host() {
    local product_name
    local product_version
    local product_model
    if [ -f "/sys/devices/virtual/dmi/id/product_name" ]
        then
            read -r product_name < /sys/devices/virtual/dmi/id/product_name
    fi
    if [ -f "/sys/devices/virtual/dmi/id/product_version" ]
        then
            read -r product_version < /sys/devices/virtual/dmi/id/product_version
    fi
    if [ -f "/sys/firmware/devicetree/base/model" ]
        then
            read -r product_model < /sys/firmware/devicetree/base/model
    fi
    echo "$product_name $product_version $product_model"
}

rig_mem() {
    local mem_avail
    mem_avail=$(LC_ALL=C free -m | grep Mem | awk '{print $2}')
    local mem_used
    mem_used=$(LC_ALL=C free -m | grep Mem | awk '{print $3}')
    echo "  ${mem_used}M/${mem_avail}M"
}

rig_fs() {
    local fs
    fs="$(LC_ALL=C df -h / | grep -e "/" | awk -F" " '{OFS="/" ;print $3,$2" ("$5")"}')"
    echo " ${fs}"
}

rig_load() {
    local load_avg
    load_avg=$(LC_ALL=C uptime | rev | cut -d":" -f1 | rev | sed '-es/,/./'{1,2,3} | sed 's/ //1' )
    echo "  ${load_avg}"
}


rig_pkgs() {
    local OUT
    local updates_avail
    # To speed up, parse log for aviable updates
    case $CHECK_FOR_UPDATES in
        Y | y | YES | yes)
            if [ -f "${RIGFETCH_LOG}" ]
                then
                    updates_avail="$(grep "System Updates" "${RIGFETCH_LOG}" | awk '{print $1}')"
                else
                    updates_avail="$(count_sys_updates "${RIGFETCH_LOG}")"
            fi
            case "${updates_avail}" in
                *0*)
                    OUT="$(dpkg -l | grep -c "^ii") (${fg_red}No Upgrades${reset})"
                ;;
                *)
                    OUT="$(dpkg -l | grep -c "^ii") (${fg_red}${updates_avail} Upgradable${reset})"
                ;;
            esac
            echo -e "  ${OUT}"
        ;;
        *)
            OUT="$(dpkg-query -f '.\n' -W | wc -l)"
            echo -e "  ${OUT}"
        ;;
    esac
}

# Fetch Versions
# ( call rig_git_fetch "GITREPO" )
# ex.: rig_git_fetch "${RIG_KLIPPER_REPO}"
rig_git_fetch() {
    local gitrepo
    local gitpath
    local OUT
    local logpath
    gitrepo="${1}"
    logpath="${RIGFETCH_LOG}"
    case "${gitrepo}" in
        *klipper*)
            gitpath="${RIG_KLIPPER_PATH}"
        ;;
        *moonraker*)
            gitpath="${RIG_MOONRAKER_PATH}"
        ;;
    esac
    case $CHECK_FOR_UPDATES in
                Y | y | YES | yes)
                    OUT="$(check_local_version "${gitpath}" "${logpath}") (${fg_red}$(check_remote_version "${gitrepo}" "${logpath}")${reset})"
                    ;;
                 *)
                    OUT="$(check_local_version "${gitpath}" "${logpath}")"
                    ;;
    esac
    echo "${OUT}"

}



# Show Frontend Version
rig_frontend() {
    local gitrepo
    local path
    local frontend
    local OUT
    gitrepo="${RIG_FRONTEND_REPO}"
    path="${RIG_FRONTEND_PATH}"
    frontend="${RIG_FRONTEND}"
    # Testing out as array
    case $CHECK_FOR_UPDATES in
            Y | y | YES | yes)
                OUT="$(frontend_local_version "${frontend}" "${path}" "${RIGFETCH_LOG}")"
                OUT+=" (${fg_red}$(check_remote_version "${gitrepo}" "${logpath}")${reset})"
            ;;
            *)
                OUT="$(frontend_local_version "${frontend}" "${path}" "${RIGFETCH_LOG}")"
            ;;
    esac
    echo " ${OUT}"

}

### Print output
print_benchy() {
    #local vars
    local RS="${reset}"
    if [ -z "${RIG_FRONTEND}" ]
        then
            RIG_FRONTEND="frontend"
    fi
    # Clear Screen
    tput clear
    # Print Stuff
    echo -e "${BC1}${BC2}\v      |3D|                    \t$(first_line)"
    echo -e "${BC1}${BC2}       3D                     ${RS} ${TC}${TB}host\t${RS}$(rig_host)"
    echo -e "${BC1}${BC2}     MOONRAKER                ${RS} ${TC}${TB}uptime\t${RS}$(rig_uptime)"
    echo -e "${BC1}${BC2}      3O°'°OD     ___________ ${RS} ${TC}${TB}mem\t${RS}$(rig_mem)${TC}${TB} sd${RS}$(rig_fs)"
    echo -e "${BC1}${BC2}      3D   3D   _/DKLIPPER3D/ ${RS} ${TC}${TB}loadavg\t${RS}$(rig_load)"
    echo -e "${BC1}${BC2} o__3D3D___3D__/3D3D3D(O)3D/  ${RS} ${TC}${TB}pkgs\t${RS}$(rig_pkgs)"
    echo -e "${BC1}${BC2} \3DOCTOPRINT3D3DRIGGED3D3/   ${RS} ${TC}${TB}klipper\t${RS}  $(rig_git_fetch "${RIG_KLIPPER_REPO}")"
    echo -e "${BC1}${BC2}  \3DWC23D3DFLUIDDD3D3D3D/    ${RS} ${TC}${TB}moonraker${RS}  $(rig_git_fetch "${RIG_MOONRAKER_REPO}")"
    echo -e "${BC1}${BC2}   \3D3D3D3DMAINSAIL3D3D/     ${RS} ${TC}${TB}${RIG_FRONTEND}\t${RS} $(rig_frontend)\v"
}

### Main

RIGFETCH_PATH="$(locate_self)"

# Includes
source "${RIGFETCH_PATH}/scripts/functions.sh"
source "${RIGFETCH_PATH}/config/rigfetch.conf"

# Check debugging on?
enable_debugging

# Are you root ? Forget it.. exiting
verify_ready

# Parse Args
arg_parse "$@"

# Set Colors
set_color

# Print Benchy
print_benchy

### Hints & Error Messages

# 'CHECK_FOR_UPDATES' auto color error
if [ "$(grep -c 'CHECK_FOR_UPDATES' "${RIGFETCH_LOG}")" -gt "0" ]
    then
        fail_msg "OOPS, something went wrong! Check '${RIGFETCH_LOG}'!"
fi

# Last apt Update more than 12h ago
if [ "$(($(date +%s)-$(last_apt_update)))" -ge "43200" ]
    then
        warn_msg "Your last 'apt update' was more than 12h ago!"
fi
# If something went wrong
if [ "$(grep -c 'Warning!' "${RIGFETCH_LOG}")" -gt "0" ]
    then
        fail_msg "OOPS, something went wrong! Check '${RIGFETCH_LOG}'!"
fi

# exit
exit 0
