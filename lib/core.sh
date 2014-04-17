#!/bin/bash

function currentDir()
{
    local DIR=$( cd "$( dirname "$0" )" && pwd )
    echo $DIR
}

################################################################################
#  name : sysInfo
#  desc : Get the Platform Information
# usage : if [[ "$OS" == "$OS_LINUX" ]] && [[ "$MACH" == "$MACH_64" ]]; then 
# 
################################################################################

# OS is Operation System Platform
OS_LINUX="Linux"
OS_MAC="Mac"
OS_WIN="Win"
OS="UNKNOWN"
OS_NAME="UNKNOWN"
OS_VERSION="UNKNOWN"

# MACH is the machine arch 32bit or 64bit
MACH_32="x86_32"
MACH_64="x86_64"
MACH="UNKNOWN"

# FILE_EXT is the file extension
FILE_EXT_LINUX=".tar.gz"
FILE_EXT_MAC=".dmg"
FILE_EXT_WIN=".exe"
FILE_EXT="UNKNOWN"

function sysInfo()
 {
    OS=$(uname)
    MACH=$(uname -m)

    if [[ "$OS" == "Linux" ]]; then
        OS=$OS_LINUX
        FILE_EXT=$FILE_EXT_LINUX
        if [[ "$MACH" == "x86_64" ]]; then
            #64 bit
            MACH=$MACH_64
        else
            #32 bit
            MACH=$MACH_32
        fi
    elif [[ "$OS" == "Darwin" ]]; then
        OS=$OS_MAC
        FILE_EXT=$FILE_EXT_MAC
        # TODO 32/64

    else #WIN
        OS="Win"
        FILE_EXT=$FILE_EXT_WIN
        if [[ "$(echo cpu get addresswidth|wmic 2> /dev/null |awk '$1 ~/64/ {print $1}')" == "64" ]]; then
            # 64 bit
            MACH=$MACH_64
        else
            # 32 bit
            MACH=$MACH_32
        fi

        OS_NAME=$(echo 'os get name'|wmic 2>/dev/null |awk -F "|" '$1 ~ /^Mic/ {print $1}')
        OS_VERSION=$(echo 'os get version' | wmic 2> /dev/null |awk '$1 ~ /^[0-9]/ {print $1}')
        
    fi
    if [[ "$OS" == "UNKNOWN" ]] || [[ "$MACH" == "UNKNOWN" ]] \
        || [[ "$FILE_EXT" == "UNKNOWN" ]]; then
        echo "ERROR : Get Platform Info Failed"
        exit -1
    fi
}
sysInfo


LIGHTGREEN="\[\033[1;32m\]"
LIGHTRED="\[\033[1;31m\]"
WHITE="\[\033[0;37m\]"
RESET="\[\033[0;00m\]"
function error_test {
    if [[ $? = "0" ]]; then
        echo -e "$LIGHTGREEN"
    else
        echo -e "$LIGHTRED"
    fi
}