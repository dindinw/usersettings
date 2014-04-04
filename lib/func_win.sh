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
    setx $key $value 2>&1 > /dev/null
}

################################################################################
# name : delUserEnv
# desc : del user's enviroment value by given key
#Usage : delUserEnv "FOO"
################################################################################
function delUserEnv(){
    local key=$1
    local result=$(queryRegByVarAndKey "$key")
    if [[ -n $result ]]; then 
        reg delete "$uvar" //v "$key" //f 2>&1 > /dev/null
    fi
}

function setSysEnv(){
    echo "...TODO"

}
function getSysEnv(){
    echo "...TODO"

}


