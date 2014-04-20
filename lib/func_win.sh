#!/bin/bash
uvar="HKCU\Environment"
mvar="HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"

function getAllUserEnv(){
    reg query "$uvar"
}
function getAllSysEnv(){
    reg query "$mvar"
}

function queryRegByVarAndKey(){
    local var=$1
    local key=$2
    local result=$(reg query "$var" //v "$key" 2>&1)
    echo $result |grep $key 2>&1 > /dev/null
    if [[ $? -eq 0 ]]; then
        echo $result |grep $key | sed -e "s/^.*$key.*REG.*SZ\s//"
        return 0
    fi
    return -1
}

function getUserEnv(){
    local key=$1
    queryRegByVarAndKey $uvar $key
    return $?

}
function getSysEnv(){
    local key=$1
    queryRegByVarAndKey "$mvar" "$key"
    return $?
}

function setUserEnv(){
    local key=$1
    local value=$2
    echo $OS_VERSION|grep ^5.1 2>&1 > /dev/null # if XP
    if [[ $? -eq 0 ]]; then
        setUserEnvXP $key $value
    else
        setx "$key" "$value" 2>&1 > /dev/null
    fi
}

function setUserEnvXP(){
    local key=$1
    local value=$2
    setRegByVarAndKey "$uvar" "$key" "$value" "force"
    return $?
}
function setRegByVarAndKey(){
    local root=$1
    local key=$2
    local value=$3
    local force=$4
    local opt=
    echo 'Path PATH TEMP TMP'|grep $key 2>&1 > /dev/null
    if [[ $? -eq 0 ]]; then
        opt=" //t REG_EXPAND_SZ"
    fi
    if [ "$force" == "force" ]; then 
        opt="$opt //f"
    fi
    reg add "$root" //v "$key" //d "$value" $opt 2>&1 > /dev/null
    return $?
}

################################################################################
# name : delUserEnv
# desc : del user's enviroment value by given key
#Usage : delUserEnv "FOO"
################################################################################
function delUserEnv(){
    local key=$1
    local result=$(getUserEnv "$key")
    if [[ -n $result ]]; then 
        reg delete "$uvar" //v "$key" //f 2>&1 > /dev/null
    fi
}

function setSysEnv(){
    local key=$1
    local value=$2
    echo $OS_VERSION|grep ^5.1 2>&1 > /dev/null # if XP
    if [[ $? -eq 0 ]]; then
        setUserEnvXP $key $value
    else
        setx "$key" "$value" //M  2>&1 >/dev/null
    fi
}

function setUserEnvXP(){
    local key=$1
    local value=$2
    setRegByVarAndKey "$mvar" "$key" "$value" "force"
    return $?
}

function delSysEnv(){
    local key=$1
    local result=$(getSysEnv "$key")
    if [[ -n $result ]]; then 
        reg delete "$mvar" //v "$key" //f 2>&1 > /dev/null
    fi

}


