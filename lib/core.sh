#!/bin/bash

function trace_begin()
{
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! BASH EXECUTION TRACE BEGIN                                    !!!"
    echo "!!!                                                               !!!"
    cmd /c sleep -m 1 1>/dev/null
    set -x
}
function trace_end()
{
    set +x
    cmd /c sleep -m 1 1>/dev/null
    echo "!!!                                                               !!!"
    echo "!!! BASH EXECUTION TRACE END                                      !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
}

function uuid()
{
    local N B C='89ab'

    for (( N=0; N < 16; ++N ))
    do
        B=$(( $RANDOM%256 ))

        case $N in
            6)
                printf '4%x' $(( B%16 ))
                ;;
            8)
                printf '%c%x' ${C:$RANDOM%${#C}:1} $(( B%16 ))
                ;;
            3 | 5 | 7 | 9)
                printf '%02x-' $B
                ;;
            *)
                printf '%02x' $B
                ;;
        esac
    done

    echo
}

function confirm(){
    local msg="$1"
    read -r -p "$msg?[yes/no]" confirm
    case "${confirm}" in 
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}


function currentDir()
{
    local DIR=$( cd "$( dirname "$0" )" && pwd )
    echo $DIR
}

function _7z_extract()
{
    local archive_name="$1"
    local extract_file_name="$2"
    local output_dir="$3"
    7z e $archive_name $extract_file_name -o$output_dir -y #2>&1>/dev/null
}

function _7z_archive()
{
    local archive_name="$1"
    local file_names="$2"
    7z a archive_name "$file_names/*"
}

function tar_win(){
    local archive_name="$1"
    local file_names="$2"
    7z a -ttar "$archive_name" "$file_names/*" 
}

function untar_win(){
    local archive_name="$1"
    local output_dir="$2"
    7z e $archive_name "*" -o$output_dir
}

function extract_win(){
    local archive_name="$1"
    local extract_file_name="$2"
    local output_dir="$3"
    _7z_extract $archive_name $extract_file_name $output_dir
}

function to_unix_path(){
    if [ -z "$1" ]; then
        echo "$@"
    else
        echo "/$1" | sed 's/\\/\//g' | sed 's/://'
    fi
}

# /foo/bar -> \foo\bar
function to_win_path(){
    if [ -z "$1" ]; then
        echo "$@"
    else
        echo "$1" | sed 's|^/\(.\)/|\1:\\|g; s|/|\\|g';
        # if [ -f "$1" ]; then
        #     local dir=$(dirname "$1")
        #     # Note, dirname will always return ".", if a windows path given
        #     if [[ "$dir" == "." ]] && [[ ! "$1" == "." ]]; then 
        #         echo "$1" | sed 's|^/\(.\)/|\1:\\|g; s|/|\\|g';
        #         return
        #     fi
        #     local fn=$(basename "$1")
        #     echo "$(cd "$dir"; echo "$(pwd -W)/$fn")" | sed 's|/|\\|g';
        # else
        #     if [ -d "$1" ]; then
        #         echo "$(cd "$1"; pwd -W)" | sed 's|/|\\|g';
        #     else
        #         echo "$1" | sed 's|^/\(.\)/|\1:\\|g; s|/|\\|g';
        #     fi
        # fi
    fi
}
# /foo/bar -> \\foo\\bar
function to_win_path2(){
    if [ -z "$1" ]; then
        echo "$@"
    else
        echo "$1" | sed 's|^/\(.\)/|\1:\\\\|g; s|/|\\\\|g';
        # if [ -f "$1" ]; then
        #     local dir=$(dirname "$1")
        #     local fn=$(basename "$1")
        #     echo "$(cd "$dir"; echo "$(pwd -W)/$fn")" | sed 's|/|\\\\|g';
        # else
        #     if [ -d "$1" ]; then
        #         echo "$(cd "$1"; pwd -W)" | sed 's|/|\\\\|g';
        #     else
        #         echo "$1" | sed 's|^/\(.\)/|\1:\\\\|g; s|/|\\\\|g';
        #     fi
        # fi
    fi
}

# Need to remove wmic calling grabage, a file named 'TempWmicBatchFile.bat',
# in Windows platfrom.
function clean_wmi_tmp_file()
{
    rm -f "TempWmicBatchFile.bat" &> /dev/null
}

################################################################################
#  name : ostype
#  desc : Get the Platform Information
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

function ostype()
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
        OS=$OS_WIN
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

function host_arch_setup() 
{
    if [[ $OS == "UNKNOWN" ]]; then echo ERROR; exit -1; fi
    if [[ "$OS" == "$OS_LINUX" ]]; then
        readonly arch="linux"
    elif [[ "$OS" == "$OS_MAC" ]]; then
        readonly arch="mac"
    elif [[ "$OS" == "$OS_WIN" ]]; then
        readonly arch="win"
    fi
}

ostype
host_arch_setup
clean_wmi_tmp_file

if [[ "$OS" == "$OS_WIN" ]]; then
    if [[ -z ${HOME} ]]; then HOME="${HOMEDRIVE}${HOMEPATH}"; fi
    if [[ -z ${HOME} ]]; then HOME="${USERPROFILE}"; fi
fi

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