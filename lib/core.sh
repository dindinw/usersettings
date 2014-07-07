#!/bin/bash

function trace_begin()
{
    set -x
}
function trace_end()
{
    set +x
}


################################################################################
# 
# Input check Functions
#
################################################################################
function is_number(){
    case $1 in
        ''|*[!0-9]*) 
            return 1 
            ;;
        *)  return 0 
            ;;
    esac
}

function is_port(){
    if is_number $1; then
        if [[ $1 -gt 0 && $1 -lt 65536 ]]; then
            return 0
        fi
    fi
    return 1
}


################################################################################
# 
# Time  Functions
#
################################################################################

function _time(){
    let length=${#@}
    #TIMEFORMAT="[Finished \"${@:2:${#@}}\" in %3lR]"
    TIMEFORMAT="
[Finished in %3lR]"
    time eval "$@"
    unset TIMEFORMAT
}

################################################################################
# 
# LOG Functions
#
################################################################################

readonly LOG_LEVEL_QUIET=0
readonly LOG_LEVEL_ERROR=1
readonly LOG_LEVEL_WARNING=2
readonly LOG_LEVEL_INFO=3
readonly LOG_LEVEL_DEBUG=4
readonly LOG_LEVEL_TRACE=5

if [[ -z $LOG_LEVEL ]]; then
    LOG_LEVEL=$LOG_LEVEL_ERROR
fi
LOG_OUTPUT=STDOUT
#LOG_STYLE="$(date)"

function _log() {
    if [[ $1 -le $LOG_LEVEL ]]; then
        if [[ -z ${LOG_OUTPUT} ]] || [[ ${LOG_OUTPUT} == "STDOUT" ]];then
            shift
            echo -e $LOG_STYLE $@ >&1 
        else
            shift
            echo -e $LOG_STYLE $@ > "${LOG_OUTPUT}"
        fi
    fi    
}
#default log func will always print
function log() { 
    _log $LOG_LEVEL_QUIET "$@"
}

function log_err(){
    _log $LOG_LEVEL_ERROR "ERROR: $@"
}

function log_warn(){
    _log $LOG_LEVEL_WARNING "WARNING: $@"
}

function log_info(){
    _log $LOG_LEVEL_INFO "INFO: $@"
}

function log_debug() {
    _log $LOG_LEVEL_DEBUG "DEBUG: $@"
}

function log_trace(){
    _log $LOG_LEVEL_TRACE "TRACE: $@"
}

function to_uppercase()
{
    echo "$1"| tr '[:lower:]' '[:upper:]'
}
function to_lowercase()
{
    echo "$1"| tr '[:upper:]' '[:lower:]'
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
# 
# read opts 
#  -p prompt  output the string PROMPT without a trailing newline before
#     attempting to read
#  -r do not allow backslashes to escape any characters
#  -s do not echo input coming from a terminal
#
function confirm(){
    local msg="$1"
    read -r -p "$msg ? [yes/no] " -s confirm
    echo
    case "${confirm}" in 
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

function is_port_open(){
    local ip="$1"
    local port="$2"
    nc -z "$ip" "$port"
    return $?
}

# TODO, fixed name, it's not current dir , but the script execute dir
function executeDir()
{
    local DIR=$( cd "$( dirname "$0" )" && pwd )
    echo $DIR
}

function _7z_extract()
{
    local archive_name="$1"
    local extract_file_name="$2"
    local output_dir="$3"
    log_debug 7z e $archive_name $extract_file_name -o$output_dir -y
    7za e $archive_name $extract_file_name -o$output_dir -y #2>&1>/dev/null
}

function _7z_archive()
{
    local archive_name="$1"
    local file_names="$2"
    log_debug 7z a archive_name "$file_names/*"
    7za a archive_name "$file_names/*"
}

function _7z_list()
{
    local archive_name="$1"
    log_debug 7z l $archive_name 
    7za l $archive_name 
}

function listtar_win(){
    _7z_list "$1"
}
function listtar(){
    local file=$(to_unix_path "$1")
    log_debug tar -tvf "$file"
    tar -tvf "$file"
}

function tar_win(){
    local archive_name="$1"
    local file_names="$2"
    log_debug 7z a -ttar "$archive_name" "$file_names/*" 
    7z a -ttar "$archive_name" "$file_names/*" 
}

function untar_win(){
    local archive_name="$1"
    local output_dir="$2"
    log_debug 7z e $archive_name "*" -o$output_dir
    7z e $archive_name "*" -o$output_dir
}

function extracttar(){
    local archive_name=$(to_unix_path "$1")
    local extract_file_name=$(to_unix_path "$2") 
    local output_dir=$(to_unix_path "$3")
    log_debug tar xvf "$archive_name" -C "$output_dir" "$extract_file_name"
    tar xvf "$archive_name" -C "$output_dir" "$extract_file_name"
}


function extract_win(){
    local archive_name=$(to_win_path "$1")
    local extract_file_name=$(to_win_path "$2")
    local output_dir=$(to_win_path "$3")
    _7z_extract $archive_name $extract_file_name $output_dir
}

function to_unix_path(){
    if [ -z "$1" ]; then
        echo "$@"
    else
        echo $1|grep ":" > /dev/null
        if [[ $? -eq 0 ]]; then
            echo "/$1" | sed 's/\\/\//g' | sed 's/://' | sed 's/\/\//\//g'
        else
            echo "$@"
        fi
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

    case "$OS" in
            Linux*)
                OS=$OS_LINUX
                FILE_EXT=$FILE_EXT_LINUX
                if [[ "$MACH" == "x86_64" ]]; then
                    #64 bit
                    MACH=$MACH_64
                else
                    #32 bit
                    MACH=$MACH_32
                fi
                ;;
            Darwin*)
                OS=$OS_MAC
                FILE_EXT=$FILE_EXT_MAC
                # TODO 32/64
                ;;
            MINGW*)
                #Mingw
                OS=$OS_WIN
                FILE_EXT=$FILE_EXT_WIN
                ;;
            CYGWIN*)
                # cygwin
                OS=$OS_WIN
                FILE_EXT=$FILE_EXT_WIN
                ;;
            *)
                # I like it to Windows :-)
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
                ;;
    esac
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