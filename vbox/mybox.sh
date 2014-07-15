#!/bin/bash
MYBOX_HOME_DIR="$( cd "$( dirname "${BASH_SOURCE}" )" && pwd)"
. $MYBOX_HOME_DIR/../lib/core.sh
. func_create_vm.sh

me=`basename $0`

BOXCONF=".boxconfig"
BOXFOLDER=".mybox"
readonly MYBOX="mybox"
readonly DEFAULT_NODE="default_node"
MYBOX_USABLE_PORT_RANGE="2251..2300"
_VBOX_USED_PORT_LIST=""

######################
# _ERR Functions
######################
function _err_unknown_opts()
{
    log_err "Unknown OPTS " $@
}

function _err_unknown_command()
{
    log_err "Unknown Command " $1
}

function _err_file_not_found()
{
    log_err "File \"$1\" not found" 
}

function _err_box_not_found()
{
    log_err "MYBOX Box \"$1\" not found"
}

function _err_node_not_found()
{
    log_err "$1" "MYBOX Node not found"
}

function _err_vm_not_found(){
    log_err "VirtualBox VM \"$1\" not found"
}

function _err_vm_exist(){
    log_err "VirtualBox VM \"$1\" exist"
}

function _err_vm_ssh_not_setup(){
    log_err "VirtualBox VM \"$1\" guest ssh not setup. please use \"vbox ssh-setup <vm_name> <port>\" to setup."
}

function _err_not_null(){
    log_err "Parameter \"$1\" should not be null"
}
function _err_boxconf_exist_when_init(){
    log_err "MYBOX configuration file \"$BOXCONF\" already exists in this directory.\n Please remove it before running \"$me init\"."
}
function _err_boxconf_not_found(){
    log_err "MYBOX configuration file \"$BOXCONF\" not found in $(pwd).\n Please init your MYBOX environment by running \"$me init\"."
}
function _err_box_folder_not_found(){
    log_err "$BOXFOLDER is not found in this directory. need to redo \"$me init\"."
}

######################
# _CHECK Functions
######################
function _check_home()
{
    if [ -z "${MYBOX_REPO}" ] ; then
        MYBOX_REPO="${HOME}/Boxes"
        log_warn "Environment variable \"MYBOX_REPO\" not set! using default path under \"${MYBOX_REPO}\""
    fi
    MYBOX_REPO=$(to_unix_path $MYBOX_REPO)
    if [ ! -e "${MYBOX_REPO}" ]; then
        log_err "Environment variable \"MYBOX_REPO\"=\"${MYBOX_REPO}\", the folder not exist, exit"
        exit
    else
        export MYBOX_REPO="${MYBOX_REPO}"
    fi
    if [ -z "${VBOX_VM_HOME}" ] ; then
        VBOX_VM_HOME="${HOME}/VirtualBox VMs"
        log_warn "Environment variable \"VBOX_VM_HOME\" not set! using default path under \"${VBOX_VM_HOME}\""
    fi
    if [ ! -e "${VBOX_VM_HOME}" ]; then
        log_err "Environment variable VBOX_VM_HOME=\"${VBOX_VM_HOME}\", the folder not exist, exit"
        exit
    fi

}
_check_home


function _check_vbox_install_win()
{
    VBoxManage --version >/dev/null 2>&1
    if [ $? -eq 0 ]; then return 0; fi;
    #echo $(to_win_path "${VBOX_MSI_INSTALL_PATH}")
    if [ -e "$(to_win_path "${VBOX_MSI_INSTALL_PATH}")" ]; then
        VBoxManage --version >/dev/null 2>&1
        if ! [ $? -eq 0 ]; then
            export PATH=$PATH:"$(to_unix_path "${VBOX_MSI_INSTALL_PATH}")"
        fi
        VBoxManage --version >/dev/null 2>&1
        if ! [ $? -eq 0 ]; then
            log_err "VirtualBox environment set error."
            exit 1
        fi
    else
        log_err "VirtualBox is not installed!"
        exit 1
    fi
}
function _check_vbox_install_mac(){
    test -f /usr/bin/VBoxManage || exit
}

function _check_extractor_install_win(){
    7z >/dev/null 2>&1
    if [ $? -eq 0 ]; then return 0 ; fi;
    if [ -e "${PROGRAMW6432}/7-Zip" ]; then
        export PATH=$PATH:"$(to_unix_path "${PROGRAMW6432}/7-Zip")"
    elif [ -e "${PROGRAMFILES}/7-Zip" ];then 
        export PATH=$PATH:"$(to_unix_path "${PROGRAMFILES}/7-Zip")"
    fi
    7z >/dev/null 2>&1
    if ! [ $? -eq 0 ]; then
        log_err "7z not installed!"
        exit 1
    fi
}



function _check_install_win(){
    _check_vbox_install_win
    _check_extractor_install_win
}

function _check_install_linux(){
    _check_ssh_keys_permission
}

function _check_install_mac(){
    _check_vbox_install_mac
    _check_extractor_install_mac
    _check_gnused_install_mac
    _check_gnufind_install_mac
    _check_ssh_keys_permission
}

function _check_extractor_install_mac(){
    if [[ -f /usr/local/bin/gtar ]]; then
        export PATH=/usr/local/bin:$PATH
    else
        log_err "GNU tar not intalled, please install it by execute command :"
        log_err "\t brew install gnu-tar --default-names"
        __print_need_to_install_homebrew
       exit 1
    fi
}

function _check_gnused_install_mac(){
    if [[ -f /usr/local/bin/sed ]]; then
        export PATH=/usr/local/bin:$PATH
    else
        log_err "GNU sed not intalled, please install it by execute command :"
        log_err "\t brew install gnu-sed --default-names"
        __print_need_to_install_homebrew
       exit 1
    fi
}
function _check_gnufind_install_mac(){
    if [[ -f /usr/local/bin/find ]]; then
        export PATH=/usr/local/bin:$PATH
    else
        log_err "GNU find not intalled, please install it by execute command :"
        log_err "\t brew install findutils --default-names"
        __print_need_to_install_homebrew
       exit 1
    fi
}
function __print_need_to_install_homebrew(){
    log_err "You may need to install Homebrew (http://brew.sh) first before you can use 'brew install'"
    log_err "To install homebrew, try to execute command in terminal : "
    log_err "\t" 'ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"'
    log_err "See https://github.com/Homebrew/homebrew/wiki/Installation for more details"
 
}
function _check_ssh_keys_permission(){
    if [[ ! -f $MYBOX_HOME_DIR/keys/mybox ]]; then
        log_err "The private key of MYBOX ($MYBOX_HOME_DIR/keys/mybox) not found."
        exit 1
    else
        chmod 700 $MYBOX_HOME_DIR/keys/mybox
    fi
    if [[ ! -f $MYBOX_HOME_DIR/keys/mybox.pub ]]; then
        log_err "The public key of MYBOX ($MYBOX_HOME_DIR/keys/mybox.pub) not found."
        exit 1
    else
        chmod 700 $MYBOX_HOME_DIR/keys/mybox.pub
    fi
}

_check_install_${arch}

function _check_status(){
    _check_box_conf
    _check_box_folder
}

function _check_box_conf(){
    if [[ ! -f ${BOXCONF} ]]; then
        _err_boxconf_not_found ${BOXCONF}
        exit 0
    fi
}
function _check_box_folder(){
    # build $BOXFOLDER if not exist
    if [[ ! -d $BOXFOLDER ]]; then
        mkdir -p $BOXFOLDER
    fi
}

function _check_box_exist(){
    local box=$(basename "$1" ".box")
    _get_all_box_names|grep ^"$box"$ > /dev/null
    return $?
}

function _check_node_exist(){
    local node_name="$1"
    _get_all_node_name|grep ^"${node_name}"$ > /dev/null
    return $?
}

function _check_vm_exist(){
    if _check_vm_exist_by_name "$1"; then
        return 0
    fi
    if _check_vm_exist_by_id "$1"; then
        return 0
    fi
    return 1
}
function _check_vm_exist_by_name(){
    local vm_name="$1"
    vbox_list_vm|grep ^\"$vm_name\" > /dev/null
    if [ $? -eq 0 ]; then return 0; else return 1; fi

}
function _check_vm_exist_by_id(){
    local vm_id="$1"
    vbox_list_vm|grep \{$vm_id\}$ >/dev/null
    if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function _check_vm_running(){
    if _check_vm_running_by_name "$1"; then
        return 0
    fi
    if _check_vm_running_by_id "$1"; then
        return 0
    fi
    return 1
}
function _check_vm_running_by_name(){
    local vm_name="$1"
    vbox_list_running_vms|grep ^\"$vm_name\" >/dev/null
    if [ $? -eq 0 ]; then return 0; else return 1; fi

}
function _check_vm_running_by_id(){
    local vm_id="$1"
    vbox_list_running_vms|grep \{$vm_id\}$ >/dev/null
    if [ $? -eq 0 ]; then return 0; else return 1; fi
}


######################
# _DEL Functions
######################

function _del_box(){
    local box=$(basename "$1" ".box")
    pushd ${MYBOX_REPO} > /dev/null
        if [[ -e "${box}" ]];then
            rm -rf "${box}"
        fi
        rm "${box}.box"
        local ret=$?
    popd > /dev/null
    return $ret
}

#####################
# _GET Function
#####################

function _get_all_box_names()
{
    find ${MYBOX_REPO} -maxdepth 1 -type f -name "*.box" -printf "%f\n"|sed s'/.box//'

    #pushd ${MYBOX_REPO} > /dev/null
    #for f in $(ls -m1 *.box); do basename $f .box; done;
    #local ret=$?
    #popd > /dev/null
    #return $ret
}

function _get_all_box_details(){
    for box in $(_get_all_box_names) ;
    do
        __get_box_metadata "${box}"
    done
}

function _get_box_detail(){
    local box=$(basename "$1" ".box")
    if _check_box_exist ${box}; then
        __get_box_metadata "${box}"
    else
        _err_box_not_found "${box}"; return 1;
    fi
}
function __get_box_metadata()
{
    local boxname="$1"
    local boxfile="${MYBOX_REPO}/${boxname}.box"

    local ovfname="${boxname}.ovf"
    
    #Vagrant box competible
    log_debug "listtar_${arch} $boxfile |grep Vagrantfile"
    listtar_${arch} $boxfile |grep Vagrantfile > /dev/null
    if [[ $? -eq 0 ]]; then
        local vagrant=1
        #It's a Vagrant BOX
        log_debug "BOX : ${boxname} is a Vagrant box."
        # listtar using tar , not support file bigger than 2G
        # listtar_win uing 7z. 
        # awk format is like 
        # 7z  -->  2013-10-25 00:47:53 .....        14181        14336  .\box.ovf
        # tar -->  -rw------- pixline/staff     14181 2013-10-25 00:47 ./box.ovf
        # in mac
        # bsd-tar -->  -rw-------  0 501    20      14103 Sep 14  2012 box.ovf
        # it's not correct, need th gnu tar!
        # in both outputh file name is $6
        ovfname=$(listtar_${arch} $boxfile |grep box.ovf |awk '{print $6}')
    fi

    if [[ $vagrant -eq 1 ]]; then
        extracttar "${boxfile}" "${ovfname}" "${MYBOX_REPO}" >/dev/null
    else
        extract_${arch} "${boxfile}" "${ovfname}" "${MYBOX_REPO}" > /dev/null
    fi
     

    if [[ $? == 0 ]];then
        echo 
        echo "====================================================================="
        echo "BOX NAME: $boxname"
        echo "---------------------------------------------------------------------" 
        cat "${MYBOX_REPO}/${ovfname}" |grep "vbox:Machine"
    fi

    rm "${MYBOX_REPO}/${ovfname}"
}

######################
#
#_import Functions
######################

function _import_box_to_vbox_vm() {
    log_debug $FUNCNAME $@
    local boxname="$1"
    local boxfile="${MYBOX_REPO}/$boxname.box"
    local vm_name="$2"
    local ovfname="${boxname}.ovf"
    local is_vagrant=0

    #Vagrant box competible
    listtar_${arch} $boxfile |grep Vagrantfile > /dev/null
    if [[ $? -eq 0 ]]; then
        #It's a Vagrant BOX
        log_debug "BOX : ${boxname} is a Vagrant box."
        is_vagrant=1
        ovfname="box.ovf"
    fi

    if [[ ! -e "${MYBOX_REPO}/${boxname}" ]]; then
        mkdir -p "${MYBOX_REPO}/${boxname}"
        untar_${arch} "${boxfile}" "${MYBOX_REPO}/${boxname}" > /dev/null
    fi
    vbox_import_ovf "${MYBOX_REPO}/${boxname}/${ovfname}" "$vm_name"

    if [[ $is_vagrant -eq 1 ]]; then
        # try to migrate vagrent vm to mybox vm
        local port=$(__get_new_usable_port_for_mybox)
        if [[ -z $port ]]; then
            log_err "Can't get usable port for mybox."
            return 1
        fi
        mybox_vbox_ssh-setup "$vm_name" -a ${port}
        mybox_vbox_migrate "$vm_name"
        vbox_wait_vm_shutdown "$vm_name"
        mybox_vbox_ssh-setup "$vm_name" -d
    fi
    return $?
}

function _import_node_vbox(){
    log_debug $FUNCNAME $@
    local boxname="$1"
    local node_name="$2"
    local force="$3"

    if _check_node_exist $node_name; then
        if ! [[ $force -eq 1 ]]  && ! confirm "Node \"$node_name\" are already existed, import will overwrite, are yor sure to continue"; then
            return 1
        fi
    fi

    if ! _check_box_exist ${boxname}; then
        echo_n "$node_name" "$(_err_box_not_found ${boxname})"
        return 1
    fi
    
    local vm_name=$(_build_uni_vm_name $node_name)

    _import_box_to_vbox_vm "${boxname}" "${vm_name}"

    if [ "$?" -eq 0 ]; then
        # if import to vbox ok, then set up the metadata info in the mybox folder.
        __set_node_metadata $node_name "provider" "vbox"
        __set_node_metadata $node_name "box" $box_name
        _set_vmid_to_myboxfolder $vm_name $node_name
        echo_n $node_name "Import \"${boxname}\" into VBOX VM \"${vm_name}\" successfully!"
    else
        log_err "Error : Import \"${boxname}\" into VBOX VM \"${vm_name}\" failed!"
        return 1
    fi
}

function _import_node_vmware(){
     _print_not_support $FUNCNAME $@
}

function _set_vmid_to_myboxfolder(){
    local vm_name="$1"
    local node_name="$2"
    local vm_id=$(vbox_list_vm|grep ^\"$vm_name\")
    __set_node_metadata "$node_name" id "$vm_id"
}

#
# id file Format:
# Vbox : "vm_name" {vm_uuid}
#        "test1" {d21067ab-ea7f-42b0-a0db-a33ac8dc768e}
# VWMware : TODO
# 
function _get_vmid_from_myboxfolder(){
    local node_name="$1"
    local vm_id=$(__get_node_metadata "$node_name" "id")
    if [[ ! -z "$vm_id" ]]; then
        echo $vm_id|awk '{print $2}'|sed -e s'/{//' -e s'/}//'
    fi
}

# "$BOXFOLDER/nodes/$node_name/"
function __get_mybox_node_path(){
    local node_name="$1"
    if [ -z ${node_name} ]; then
        node_name="${MYBOX}_${DEFAULT_NODE}"
    fi
    echo "${BOXFOLDER}/nodes/${node_name}/"
}

function __get_mybox_node_id_path(){
    __get_mybox_node_path "$1" | sed 's/\(.*\)/\1id/'
}

function __set_node_metadata(){
    local node_name="$1"
    local key="$2"
    shift 2
    local value="$@"
    local metadata_file=$(__get_mybox_node_path $node_name | sed "s/\(.*\)/\1$key/")
    if [[ ! -e $metadata_file ]]; then
        mkdir -p $(dirname $metadata_file)
    fi
    echo "$value" > $metadata_file 
}

function __get_node_metadata(){
    local node_name="$1"
    local key="$2"
    local metadata_file=$(__get_mybox_node_path $node_name | sed "s/\(.*\)/\1$key/")
    if [[ -f $metadata_file ]]; then
        cat $metadata_file
    fi
}

function _remove_mybox_node_path(){
    local node_name="$1"
    if [[ ! -z $node_name ]] && [[ -e "${BOXFOLDER}/nodes/${node_name}" ]]; then
        rm -rf "${BOXFOLDER}/nodes/${node_name}"
    fi
}

function _get_all_node_name(){

    if [[ -e "${BOXFOLDER}/nodes" ]]; then
        for node_name in $(ls ${BOXFOLDER}/nodes/ )
        do
            echo $node_name
        done
    fi
    echo
}

function _build_uni_vm_name(){
    local node_name="$1"
    if [ -z $node_name ]; then
        node_name="${MYBOX}_${DEFAULT_NODE}"
    else
        node_name="${MYBOX}_${node_name}"
    fi
    echo "${node_name}_$(uuid)"
}




################################################################################
# 
# MYBOX COMMANDS USAGE
#
################################################################################

readonly COMMANDS=(
    "mybox:init config up down clean provision ssh status"
    "myboxsub:box node vbox vmware"
    "box:add list detail remove pkgvbox impvbox pkgvmware impvmware"
    "node:list import start stop modify remove provision ssh scp info"
    "vbox:list start stop modify remove ssh ssh-setup scp info status migrate"
    "vmware:list start stop modify remove ssh info"
    )

# Remember, # and ## work from the left end (beginning) of string,
#           % and %% work from the right end.
function __get_subcommands(){
    for line in "${COMMANDS[@]}" ; do
        local key=${line%%:*}
        local value=${line#*:}
        if [[ "$1" == "$key" ]]; then
            echo $value
            return 0
        fi
    done
    echo ""
}

readonly     MYBOX_CMDS=$(__get_subcommands "mybox")
readonly  MYBOX_SUBCMDS=$(__get_subcommands "myboxsub")
readonly    BOX_SUBCMDS=$(__get_subcommands "box")
readonly   NODE_SUBCMDS=$(__get_subcommands "node")
readonly   VBOX_SUBCMDS=$(__get_subcommands "vbox")
readonly VMWARE_SUBCMDS=$(__get_subcommands "vmware")

function usage()
{
    echo "Usage: $me [-v] [-h] command [<args>]"
    echo
    echo "    -v, --version           Print the version and exit."
    echo "    -h, --help              Print this help."
    echo 
    echo "User subcommands : The commands target for the MYBOX environment which defined" 
    echo "                   by a Mybox configration file. \"$BOXCONF\"  by default."
    echo "    init           initializes a new MYBOX environment by creating a \"$BOXCONF\""
    echo "    config         show/edit the MYBOX environment by \"$BOXCONF\""
    echo "    up             starts and provisions the MYBOX environment by \"$BOXCONF\""
    echo "    down           stops the MYBOX nodes in the MYBOX environment."
    echo "    clean          stops and deletes all MYBOX nodes in the MYBOX environment."
    echo "    provision      provisions the MYBOX nodes"
    echo "    ssh            connects to node via SSH"
    echo "    status         show status of the MYBOX nodes in the MYBOX environment"
    echo "    box            manages MYBOX boxes."
    echo
    echo "For help on any individual command run \"$me COMMAND -h\""
}
function usage_internal()
{
    echo "MYBOX Internal Commands help"
    echo "    -H                      Print this help (more internal commands)."
    echo "    -T command [<args]      report the elapsed time."
    echo 
    help_mybox_box
    echo 
    help_mybox_node
    echo 
    help_mybox_vbox
    echo
#    help_mybox_vmware
    echo 
    echo "!!! NOTE: Some Node/VM command is for internal test only. please use carefully "
    echo "    improperly usage may result a corrupted  MYBOX environment.          "
    echo "For help on any individual command run \"$me COMMAND -h\""
}

function version()
{
    echo "$me 1.2.1"
}

function _print_not_support(){
    echo "WARNNING! unspported function $1 : "
    local cmd=$(echo "$1"|sed 's/_/ /g')
    shift
    echo "command opts : $@"
    echo "Sorry, the command \"${cmd}\" is not supported now!"
}

################################################################################
#
# MYBOX HELPS COMMMANDS
#
################################################################################

#==================================
# FUNCTION help_mybox_init 
#==================================
function help_mybox_init(){
    echo "Usage: $me init                      initializes a new MYBOX environment by creating a \"$BOXCONF\""
    echo "    -b, --box-name                   the box name which the MYBOX environment is set up. the default is \"Trusty64\" ."
    echo "    -f, --force                      force to overwrite the \"$BOXCONF\"."
    echo "    -h, --help                       Print this help"
}

#==================================
# FUNCTION help_mybox_config
#==================================
function help_mybox_config(){
    echo "Usage: $me config                    config the \"$BOXCONF\""
    echo "    -p, --print                      print the clean-formated \"$BOXCONF\" file"
    echo "    -l, --list                       list all config items"
    echo "    -a, --add <sec_name [index]> <key> <value>"  
    echo "                                     add (or set if exist) a config item to box/node section, node section need a index number"
    echo "    -g, --get <sec_name [index]> <key>"
    echo "                                     get a config item in a section"
    echo "    -r, --remove <sec_name [index]> [key]"
    echo "                                     remove a config item or a section in config file"
    echo "    -h, --help                       Print this help"
}

#==================================
# FUNCTION help_mybox_up 
#==================================
function help_mybox_up(){
    echo "Usage: $me up                        start up the whole MYBOX environment"
    echo "    -h, --help                       Print this help"
}

#==================================
# FUNCTION help_mybox_down 
#==================================
function help_mybox_down(){
    echo "Usage: $me down                      shutdown the whole MYBOX environment"
    echo "    -h, --help                       Print this help"
}
#==================================
# FUNCTION help_mybox_clean 
#==================================
function help_mybox_clean(){
    echo "Usage: $me clean                     destory the whole MYBOX environment, all nodes will be deleted!"
    echo "    -f, --force                      force to destory"
    echo "    -h, --help                       Print this help"
}
#==================================
# FUNCTION help_mybox_provision 
#==================================
function help_mybox_provision(){
    echo "Usage: $me provision                 do the provision of the whole MYBOX environment."
    echo "    -f, --force                      force to do provision"
    echo "    -h, --help                       Print this help"
}
#==================================
# FUNCTION help_mybox_ssh 
#==================================
function help_mybox_ssh(){
    echo "Usage: $me ssh <node_name>           SSH to a MYBOX node."
    echo "    -h, --help                       Print this help"
}
#==================================
# FUNCTION help_mybox_status 
#==================================
function help_mybox_status(){
    echo "Usage: $me status                    show status of the MYBOX environment."
    echo "    -h, --help                       Print this help"
}
#==================================
# FUNCTION help_mybox_box 
#==================================
function help_mybox_box(){
    echo "Box subcommands : The commads to manage MYBOX boxes."
    echo "    box add           download a pre-build box into user's local box repository"
    echo "    box list          list boxes in user's local box repository."
    echo "    box detail        show a box's detail."
    echo "    box remove        remove a box from user's local box repository"
    echo "    box pkgvbox       create a box from VirtualBox VM"
    echo "    box impvbox       import a box into VirtualBox VM"
#    echo "    box pkgvmware     create a box from VMWare VM"
#    echo "    box impvmware     import a box into VMWare VM"
}
#----------------------------------
# FUNCTION help_mybox_box_add 
#----------------------------------
function help_mybox_box_add(){
    echo "MYBOX subcommand \"box add\" : Add a MYBOX box into local box repository from an URL or a file location."
    echo "Usage: $me box add <url>|<file_loc>"
    echo "    -h, --help                       Print this help"
}
#----------------------------------
# FUNCTION help_mybox_box_list 
#----------------------------------
function help_mybox_box_list(){
    echo "MYBOX subcommand \"box list\" : List MYBOX boxes in user's local MYBOX repository."
    echo "Usage: $me box list <opts>"
    echo "    -d|--detail                      Show Box details"
    echo "    -h, --help                       Print this help"

}
#----------------------------------
# FUNCTION help_mybox_box_detail 
#----------------------------------
function help_mybox_box_detail(){
    echo "MYBOX subcommand \"box detail\" : Show a MYBOX box in details."
    echo "Usage: $me box detail <box_name>"
    echo "    -h, --help                       Print this help"
}
#----------------------------------
# FUNCTION help_mybox_box_remove 
#----------------------------------
function help_mybox_box_remove(){
    echo "MYBOX subcommand \"box remove\" : Remove a existed MYBOX box by given box name from local MYBOX repository."
    echo "Usage: $me box remove <box_name>"
    echo "    -h, --help                       Print this help"
}
#----------------------------------
# FUNCTION help_mybox_box_pkgvbox 
#----------------------------------
function help_mybox_box_pkgvbox(){
    echo "MYBOX subcommand \"box pkgvbox\" : Create an new MYBOX box by exporting from an existed VirtualBox VM."
    echo "Usage: $me box pkgvbox <vbox_vm_name> <box_name>"
    echo "    -h, --help                       Print this help"
}


#----------------------------------
# FUNCTION help_mybox_box_impvbox 
#----------------------------------
function help_mybox_box_impvbox(){
    echo "MYBOX subcommand \"box impvbox\" : Import a MYBOX box into a VirtualBox VM."
    echo "Usage: $me box impvbox <box_name> [<vbox_vm_name>]" 
    echo "    -h, --help                       Print this help"
}
#----------------------------------
# FUNCTION help_mybox_box_pkgvmware 
#----------------------------------
function help_mybox_box_pkgvmware(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_box_impvmware 
#----------------------------------
function help_mybox_box_impvmware(){
    _print_not_support $FUNCNAME $@
}
#==================================
# FUNCTION help_mybox_node 
#==================================
function help_mybox_node(){
    echo "Node subcommands : The commands to manage MYBOX nodes."
    echo "    node list         list MYBOX nodes in the MYBOX environment"
    echo "    node import       import a MYBOX Box as a MYBox node"
    echo "    node start        start a MYBOX node by node name"
    echo "    node stop         stop a MYBOX node by node name"
 #   echo "    node modify       to modify the node settings."
    echo "    node remove       remove a MYBOX node from the MYBOX environment"
    echo "    node provision    pervision on a MYBOX node."
    echo "    node ssh          connects to a MYBOX node."
    echo "    node info         show detail information of a MYBOX node."
}
#----------------------------------
# FUNCTION help_mybox_node_list 
#----------------------------------
function help_mybox_node_list(){        
    echo "MYBOX subcommand \"node list\" : list all MYBOX nodes in the MYBOX environment."
    echo "Usage: $me node list" 
    echo "    -h, --help                       Print this help"
}
#----------------------------------
# FUNCTION help_mybox_node_import 
#----------------------------------
function help_mybox_node_import(){
    echo "MYBOX subcommand \"node import\" : import a MYBOX Box as a MYBox node."
    echo "Usage: $me node import <box_name> <node_name> [<OPTS>]"
    echo "    -p|--provider vbox|vmware        vbox (default) : start node as VirtualBox VM "
    echo "                                     vmware         : start node as VMware VM  "
    echo "    -f|--force                       force import even the node existed" 
    echo "    -h, --help                       Print this help"
}

#----------------------------------
# FUNCTION help_mybox_node_start 
#----------------------------------
function help_mybox_node_start(){
    echo "MYBOX subcommand \"node start\" : start a MYBOX node by node name."
    echo "Usage: $me node start <node_name>"
    echo "    -h, --help                       Print this help"
}
#----------------------------------
# FUNCTION help_mybox_node_stop 
#----------------------------------
function help_mybox_node_stop(){
    echo "MYBOX subcommand \"node stop\" : stop a MYBOX node by node name."
    echo "Usage: $me node stop <node_name>"
    echo "    -h, --help                       Print this help"
}
#----------------------------------
# FUNCTION help_mybox_node_modify 
#----------------------------------
# function help_mybox_node_modify(){
#     echo "MYBOX subcommand \"node modify\" : modify a MYBOX node by node name."
#     echo "Usage: $me node nodify <node_name> <--key> <value>"
#     echo "    -p|--provider vbox|vmware        vbox (default) : modify node, backend VM is VirtualBox VM "
#     echo "                                     vmware         : modify node, backend VM is  VMware VM  "
#     echo "    -f|--force                       force modify" 
#     echo "    -h, --help                       Print this help"
# }
#----------------------------------
# FUNCTION help_mybox_node_remove 
#----------------------------------
function help_mybox_node_remove(){
    echo "MYBOX subcommand \"node remove\" : remove a MYBOX node by node name."
    echo "Usage: $me node remove <node_name>"
    echo "    -p|--provider vbox|vmware        vbox (default) : remove node, backend VM is VirtualBox VM "
    echo "                                     vmware         : remove node, backend VM is  VMware VM  "
    echo "    -f|--force                       force remove" 
    echo "    -h, --help                       Print this help"
}
#----------------------------------
# FUNCTION help_mybox_node_provision 
#----------------------------------
function help_mybox_node_provision(){
    echo "MYBOX subcommand \"node provision\" : provision a MYBOX node by the node's index"
    echo "Usage: $me node provision <node-index>"
    echo "    -f, --force                       force to do the provision" 
    echo "    -h, --help                       Print this help"
}
#----------------------------------
# FUNCTION help_mybox_node_ssh 
#----------------------------------
function help_mybox_node_ssh(){
    echo "MYBOX subcommand \"node ssh\" : connect to a MYBOX node by SSH."
    echo "Usage: $me node ssh <node_name>"
    echo "    -h, --help                       Print this help"
}
#----------------------------------
# FUNCTION help_mybox_node_info 
#----------------------------------
function help_mybox_node_info(){
    echo "MYBOX subcommand \"node info\" : show information of a MYBOX node."
    echo "Usage: $me node ssh <node_name>"
    echo "    -h, --help                       Print this help"
}
#==================================
# FUNCTION help_mybox_vbox 
#==================================
function help_mybox_vbox(){
    echo "VBOX subcommands : The commands to manage VirtualBox VM"
    echo "    vbox list         list user's VirtualBox environment "
    echo "    vbox start        start a VirtualBox VM."
    echo "    vbox stop         stop a VirtualBox VM."
    echo "    vbox modify       modify a VirtualBox VM"
    echo "    vbox remove       remove a VM from the User's VirtualBox environment"
    echo "    vbox ssh          connects to a VirtualBox VM."
    echo "    vbox ssh-setup    setup geust ssh to a VirtualBox VM."
    echo "    vbox info         show detail information of a VirtualBox VM."
    echo "    vbox migrate      migrate a Vagrant VM into a MYBOX VM."
    echo "    vbox status       show the vm state (on/off) of a VirtualBox VM."
}
#----------------------------------
# FUNCTION help_mybox_vbox_list 
#----------------------------------
function help_mybox_vbox_list(){
    echo "MYBOX subcommand \"vbox list\" : list all user's VirtualBox VMs in host machine."
    echo "Usage: $me vbox list [<opts>]"
    echo "    -f,  --format  <name|uuid|        Format list result accordingly."
    echo "                    full|raw>           name : show vm's name"                                   
    echo "                                        uuid : show vm's uuid."
    echo "                                        full : show in a detail table, with vm's id, status, name."
    echo "                                        raw  : (default) show raw result from VirtualBox."
    echo "    -r,  --running                    List all running VirtualBox VMs."
    echo "    -os, --ostype  <ubuntu|redhat|    List VMs by os type."
    echo "                    windows>                               "
    echo "    -h,  --help                       Print this help"
}
#----------------------------------
# FUNCTION help_mybox_vbox_start 
#----------------------------------
function help_mybox_vbox_start(){
    echo "MYBOX subcommand \"vbox start\" : start a VirtualBox VM in host machine."
    echo "Usage: $me vbox start <vm_name>|<vm_id>"
    echo "    -h, --help                       Print this help"
}
#----------------------------------
# FUNCTION help_mybox_vbox_stop 
#----------------------------------
function help_mybox_vbox_stop(){
    echo "MYBOX subcommand \"vbox stop\" : stop a VirtualBox VM in host machine."
    echo "Usage: $me vbox stop <vm_name>|<vm_id>"
    echo "    -h, --help                       Print this help"
}
#----------------------------------
# FUNCTION help_mybox_vbox_modify 
#----------------------------------
function help_mybox_vbox_modify(){
    echo "MYBOX subcommand \"vbox modify\" : modify a VirtualBox VM in host machine."
    echo "Usage: $me vbox modify <vm_name>|<vm_id>"
    echo "    -f, --force                      force to do modify."
    echo "       [--name <name>]"
    echo "       [--groups <group>, ...]"
    echo "       [--ostype <ostype>]"
    echo "       [--iconfile <filename>]"
    echo "       [--memory <memorysize in MB>]"
    echo "       [--pagefusion on|off]"
    echo "       [--vram <vramsize in MB>]"
    echo "       [--acpi on|off]"
    echo "       [--pciattach 03:04.0]"
    echo "       [--pciattach 03:04.0@02:01.0]"
    echo "       [--pcidetach 03:04.0]"
    echo "       [--ioapic on|off]"
    echo "       [--hpet on|off]"
    echo "       [--triplefaultreset on|off]"
    echo "       [--hwvirtex on|off]"
    echo "       [--nestedpaging on|off]"
    echo "       [--largepages on|off]"
    echo "       [--vtxvpid on|off]"
    echo "       [--vtxux on|off]"
    echo "       [--pae on|off]"
    echo "       [--longmode on|off]"
    echo "       [--synthcpu on|off]"
    echo "       [--cpuidset <leaf> <eax> <ebx> <ecx> <edx>]"
    echo "       [--cpuidremove <leaf>]"
    echo "       [--cpuidremoveall]"
    echo "       [--hardwareuuid <uuid>]"
    echo "       [--cpus <number>]"
    echo "       [--cpuhotplug on|off]"
    echo "       [--plugcpu <id>]"
    echo "       [--unplugcpu <id>]"
    echo "       [--cpuexecutioncap <1-100>]"
    echo "       [--rtcuseutc on|off]"
    echo "       [--graphicscontroller none|vboxvga|vmsvga]"
    echo "       [--monitorcount <number>]"
    echo "       [--accelerate3d on|off]"
    echo "       [--accelerate2dvideo on|off]"
    echo "       [--firmware bios|efi|efi32|efi64]"
    echo "       [--chipset ich9|piix3]"
    echo "       [--bioslogofadein on|off]"
    echo "       [--bioslogofadeout on|off]"
    echo "       [--bioslogodisplaytime <msec>]"
    echo "       [--bioslogoimagepath <imagepath>]"
    echo "       [--biosbootmenu disabled|menuonly|messageandmenu]"
    echo "       [--biossystemtimeoffset <msec>]"
    echo "       [--biospxedebug on|off]"
    echo "       [--boot<1-4> none|floppy|dvd|disk|net>]"
    echo "       [--nic<1-N> none|null|nat|bridged|intnet|hostonly|"
    echo "                   generic|natnetwork]"
    echo "       [--nictype<1-N> Am79C970A|Am79C973|"
    echo "                       82540EM|82543GC|82545EM|"
    echo "                       virtio]"
    echo "       [--cableconnected<1-N> on|off]"
    echo "       [--nictrace<1-N> on|off]"
    echo "       [--nictracefile<1-N> <filename>]"
    echo "       [--nicproperty<1-N> name=[value]]"
    echo "       [--nicspeed<1-N> <kbps>]"
    echo "       [--nicbootprio<1-N> <priority>]"
    echo "       [--nicpromisc<1-N> deny|allow-vms|allow-all]"
    echo "       [--nicbandwidthgroup<1-N> none|<name>]"
    echo "       [--bridgeadapter<1-N> none|<devicename>]"
    echo "       [--hostonlyadapter<1-N> none|<devicename>]"
    echo "       [--intnet<1-N> <network name>]"
    echo "       [--nat-network<1-N> <network name>]"
    echo "       [--nicgenericdrv<1-N> <driver>"
    echo "       [--natnet<1-N> <network>|default]"
    echo "       [--natsettings<1-N> [<mtu>],[<socksnd>],"
    echo "                           [<sockrcv>],[<tcpsnd>],"
    echo "                           [<tcprcv>]]"
    echo "       [--natpf<1-N> [<rulename>],tcp|udp,[<hostip>],"
    echo "                     <hostport>,[<guestip>],<guestport>]"
    echo "       [--natpf<1-N> delete <rulename>]"
    echo "       [--nattftpprefix<1-N> <prefix>]"
    echo "       [--nattftpfile<1-N> <file>]"
    echo "       [--nattftpserver<1-N> <ip>]"
    echo "       [--natbindip<1-N> <ip>"
    echo "       [--natdnspassdomain<1-N> on|off]"
    echo "       [--natdnsproxy<1-N> on|off]"
    echo "       [--natdnshostresolver<1-N> on|off]"
    echo "       [--nataliasmode<1-N> default|[log],[proxyonly],"
    echo "                                    [sameports]]"
    echo "       [--macaddress<1-N> auto|<mac>]"
    echo "       [--mouse ps2|usb|usbtablet|usbmultitouch]"
    echo "       [--keyboard ps2|usb"
    echo "       [--uart<1-N> off|<I/O base> <IRQ>]"
    echo "       [--uartmode<1-N> disconnected|"
    echo "                        server <pipe>|"
    echo "                        client <pipe>|"
    echo "                        file <file>|"
    echo "                        <devicename>]"
    echo "       [--lpt<1-N> off|<I/O base> <IRQ>]"
    echo "       [--lptmode<1-N> <devicename>]"
    echo "       [--guestmemoryballoon <balloonsize in MB>]"
    echo "       [--audio none|null|dsound]"
    echo "       [--audiocontroller ac97|hda|sb16]"
    echo "       [--clipboard disabled|hosttoguest|guesttohost|"
    echo "                    bidirectional]"
    echo "       [--draganddrop disabled|hosttoguest"
    echo "       [--vrde on|off]"
    echo "       [--vrdeextpack default|<name>"
    echo "       [--vrdeproperty <name=[value]>]"
    echo "       [--vrdeport <hostport>]"
    echo "       [--vrdeaddress <hostip>]"
    echo "       [--vrdeauthtype null|external|guest]"
    echo "       [--vrdeauthlibrary default|<name>"
    echo "       [--vrdemulticon on|off]"
    echo "       [--vrdereusecon on|off]"
    echo "       [--vrdevideochannel on|off]"
    echo "       [--vrdevideochannelquality <percent>]"
    echo "       [--usb on|off]"
    echo "       [--usbehci on|off]"
    echo "       [--snapshotfolder default|<path>]"
    echo "       [--teleporter on|off]"
    echo "       [--teleporterport <port>]"
    echo "       [--teleporteraddress <address|empty>"
    echo "       [--teleporterpassword <password>]"
    echo "       [--teleporterpasswordfile <file>|stdin]"
    echo "       [--tracing-enabled on|off]"
    echo "       [--tracing-config <config-string>]"
    echo "       [--tracing-allow-vm-access on|off]"
    echo "       [--usbcardreader on|off]"
    echo "       [--autostart-enabled on|off]"
    echo "       [--autostart-delay <seconds>]"
    echo "       [--vcpenabled on|off]"
    echo "       [--vcpscreens [<display>],..."
    echo "       [--vcpfile <filename>]"
    echo "       [--vcpwidth <width>]"
    echo "       [--vcpheight <height>]"
    echo "       [--vcprate <rate>]"
    echo "       [--vcpfps <fps>]"
    echo "       [--defaultfrontend default|<name>]"
    echo "    -h, --help                       Print this help"

}
#----------------------------------
# FUNCTION help_mybox_vbox_remove 
#----------------------------------
function help_mybox_vbox_remove(){
    echo "MYBOX subcommand \"vbox remove\" : remove a VirtualBox VM in host machine."
    echo "Usage: $me vbox remove <vm_name>|<vm_id>"
    echo "    -f, --force                      force to remove." 
    echo "    -h, --help                       Print this help"
}

#----------------------------------
# FUNCTION help_mybox_vbox_ssh 
#----------------------------------
function help_mybox_vbox_ssh(){
    echo "MYBOX subcommand \"vbox ssh\" : connect to a VirtualBox VM in host machine by SSH."
    echo "Usage: $me vbox ssh <vm_name>|<vm_id>"
    echo "    -h, --help                       Print this help"
}

#----------------------------------
# FUNCTION help_mybox_vbox_ssh-setup
#----------------------------------
function help_mybox_vbox_ssh-setup(){
    echo "MYBOX subcommand \"vbox ssh-setup\" : set up guest SSH mapping port to a VirtualBox VM in the host machine ."
    echo "Usage: $me vbox ssh-setup <vm_name>|<vm_id>"
    echo "    -a, --add <port>                 Set Guset SSH port for the VM."
    echo "    -d, --delete                     Remove the Guest SSH from the VM."
    echo "    -s, --show                       Show current settings."
    echo "    -h, --help                       Print this help"
}
#----------------------------------
# FUNCTION help_mybox_vbox_info 
#----------------------------------
function help_mybox_vbox_info(){
    echo "MYBOX subcommand \"vbox info\" : Show the detail information of a VirtualBox VM in host machine."
    echo "Usage: $me vbox info <vm_name>|<vm_id>"
    echo "    -m, --machinereadable            Show machine-friendly output in the standard propreties format"
    echo "    -h, --help                       Print this help"
}

#----------------------------------
# FUNCTION help_mybox_vbox_status 
#----------------------------------
function help_mybox_vbox_migrate(){
    echo "MYBOX subcommand \"vbox migrate\" : migrate a Vagrant VM into a MYBOX VM.."
    echo "Usage: $me vbox migrate <vm_name>|<vm_id>"
    echo "    -h, --help                       Print this help"
}

#----------------------------------
# FUNCTION help_mybox_vbox_status 
#----------------------------------
function help_mybox_vbox_status(){
    echo "MYBOX subcommand \"vbox status\" : Show the vm state (on/off etc.) of a VirtualBox VM in host machine."
    echo "Usage: $me vbox status <vm_name>|<vm_id>"
    echo "    -h, --help                       Print this help"
}

#==================================
# FUNCTION help_mybox_vmware 
#==================================
function help_mybox_vmware(){
    echo "VMWare subcommands : The commands to manage VMWare VM"
    echo "    vmware list       list VMs in user's VMWare environment "
    echo "    vmware start      start a VMWare VM."
    echo "    vmware stop       stop a VMWare VM."
    echo "    vmware modify     modify a VMWare VM"
    echo "    vmware remove     remove a VM from user's VMWare environment"
    echo "    vmware ssh        connects to a VMWare VM."
    echo "    vmware info       show detail information of a VMWare VM."
}
#----------------------------------
# FUNCTION help_mybox_vmware_list 
#----------------------------------
function help_mybox_vmware_list(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_vmware_start 
#----------------------------------
function help_mybox_vmware_start(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_vmware_stop 
#----------------------------------
function help_mybox_vmware_stop(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_vmware_modify 
#----------------------------------
function help_mybox_vmware_modify(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_vmware_remove 
#----------------------------------
function help_mybox_vmware_remove(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_vmware_ssh 
#----------------------------------
function help_mybox_vmware_ssh(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_vmware_info 
#----------------------------------
function help_mybox_vmware_info(){
    _print_not_support $FUNCNAME $@
}

################################################################################
#
# MYBOX USER COMMMANDS
#
################################################################################

#=============================================================================
# FUNCTION mybox_init 
#   init a box config from box-template by the given box name (optional)
#
# OPTS: 
#   $1 (optional) -> box_name (if null , box_name = "UnknownBox")
# RESULT:
#   a file '.boxconfig' is created under current dir. if '.boxconfig' existed.
#   program error and exist. need to remove it manaually before running.
#=============================================================================
function mybox_init(){
    log_debug $@
    local box=
    local force=0
    local template="default"
    while [[ ! -z "$1" ]];do
        case "$1" in
            -f|--force) shift; force=1; ;;
            -b|--box-name) shift; box="$1"; shift; ;;
            -t|--template) shift; template="$1"; shift; ;;
            *) shift; help_$FUNCNAME; return 1; ;;
        esac
    done
    if [[ -z ${box} ]] ; then box="Trusty64"; fi;

    if [ "$#" -gt 1 ] ; then 
        help_mybox_init
        exit 0
    fi
    _check_box_folder #create box folder if not created

    if [[ -e "$BOXCONF" ]] && [[ $force -eq 0 ]]; then
        _err_boxconf_exist_when_init
        exit 0
    fi

    case "$template" in
        default)
cat <<"EOF" > "$BOXCONF"
# MYBOX box config file
[box] 
    box.name=Trusty64
    vbox.modify.memory=512
# node
[node 1 ]
    node.provision=<<INLINE_SCRIPT
        echo "exected provision script in $(hostname)"
    INLINE_SCRIPT

EOF
            ;;
        test1)
            cat <<"EOF" > "$BOXCONF"
# MYBOX box config file
[box] 
    box.name=Trusty64
    vbox.modify.memory=512
# node
[node 1 ]
    node.name="master"
    vbox.modify.nictype1="82540EM"

[node 2 ]
    node.name="slave"
    vbox.modify.memory=1024
EOF
            ;;
        test2)
            cat <<"EOF" > "$BOXCONF"
# MYBOX box config file
[box] 
    box.name=Trusty64
    vbox.modify.memory=512
# node
[node 1 ]
    node.name="master"
    vbox.modify.nictype1="82540EM"
    node.provision="c:\test.sh"

[node 2 ]
    box.name=REHL64
    vbox.modify.memory=1024

[node 3 ]
    box.name=CentOS65-64
    node.provision=<<INLINE_SCRIPT
        echo "exected provision script in $(hostname)"
    INLINE_SCRIPT
[node 4 ]
    box.name=Precise64
    vbox.modify.memory=1024
EOF
            ;;
    esac
    echo "Init a box config under $PWD/$BOXCONF successfully!"
}
#==================================
# FUNCTION mybox_config 
#==================================
function mybox_config(){
    _check_status

    while [[ ! -z "$1" ]];do
        case "$1" in
            -p|--print)
                shift
                if [[ -z "$1" ]];then 
                    _print_format_conf $BOXCONF
                    return $?
                fi
                ;;
            -l|--list)
                shift
                if [[ -z "$1" ]];then 
                    _list_all_in_conf $BOXCONF
                    return $?
                fi
                ;;
            -a|--add)
                shift
                log_debug "$@"
                _set_value_to_conf $BOXCONF "$@"
                return $?
                ;;
            -g|--get)
                shift
                # format clean
                _get_value_from_conf $BOXCONF "$@"
                return $?
                ;;
            -r|--remove)
                shift
                _remove_value_from_conf $BOXCONF "$@"
                return $?
                
                ;;
            *)
                help_$FUNCNAME; return 1;
                ;;
        esac
    done
    help_$FUNCNAME; return 1;
}

function _print_format_conf(){
    local conf_file="$1"
    if [[ -e $conf_file ]]; then
        __clean_format_conf_with_comments $conf_file > tmp_$conf_file
        cat tmp_$conf_file
        rm tmp_$conf_file
    fi
}

function _list_all_in_conf(){
    local conf_file="$1"
    if [[ -e $conf_file ]]; then
        __clean_format_conf  $conf_file > tmp_$conf_file

        __get_value_from_config "tmp_$conf_file" "box" | sed -e "s/\(.*\)/box.\1/"
        for node_i in $(__get_node_index_list $tmp_$conf_file);do
            __get_value_from_config "tmp_$conf_file" "node" "$node_i" | sed -e "s/\(.*\)/node.$node_i.\1/"
        done
        rm tmp_$conf_file
    fi

    return $?
}

function _get_value_from_conf(){
    local conf_file="$1"
    shift
    if [[ -e $conf_file ]]; then
        
        __clean_format_conf  $conf_file > tmp_$conf_file
        
        __get_value_from_config "tmp_$conf_file" $@

        rm tmp_$conf_file
    fi
    return $?

}

function __clean_format_conf(){
    local conf_file="$1"
    if [[ -e $conf_file ]]; then
        sed -e '/\s*#.*/d' \
            -e '/^$/d' \
            -e 's/\s*\=\s*/=/g' \
            -e 's/\s*$//' \
            -e 's/^\s*//' \
            -e "s/^\(.*\)=\([^\"']*\)$/\1=\"\2\"/" \
            -e 's/^\(.*\)=\(.*\)$/    \1=\2/' < $conf_file
    fi
}

function __clean_format_conf_with_comments(){
    local conf_file="$1"
    if [[ -e $conf_file ]]; then
        sed -e 's/\s*\=\s*/=/g' \
            -e 's/\s*$//' \
            -e 's/^\s*//' \
            -e "s/^\(.*\)=\([^\"']*\)$/\1=\"\2\"/" \
            -e 's/^\(.*\)=\(.*\)$/    \1=\2/' < $conf_file
    fi
}

#
# The function can parse a config file in .ini format, with addtion support for index, like 
# [sec-name]
#    key=val
# [sec-name 1]
#    key1=val1
# [sec-name 2]
# How sed work:
#  remove comments line, # or ;
#  remove extra spaces at begin and end of the line
#  reomve extra spaces between =
# Sed's group command :
#   /begin/,/end/ {
#        s/old/new/
#   }
#  
function __get_value_from_config(){
    #log_debug $FUNCNAME "$@"
  
    local conf_file="$1"
    local sec_name="$2"
    
    if is_number "$3"; then
        # is a indexed section
        local sec_index="$3"
        local key="$4"

        if [[ -z $key ]]; then
            cat $conf_file \
                | sed -n -e " /^\[\s*$sec_name\s\s*$sec_index\s*\]/ , /^\s*\[/ {/^[^;].*\=.*/p;}" | sed -e "s/^\s*//"
        else
            cat $conf_file \
                | sed -n -e " /^\[\s*$sec_name\s\s*$sec_index\s*\]/ , /^\s*\[/ {/^[^;].*\=.*/p;}" | sed -e "s/^\s*//" | grep "^$key="
        fi
    else
        local key="$3"
        if [[ -z $key ]];then
            cat $conf_file \
                | sed -n -e " /^\[\s*$sec_name\s*\]/ , /^\s*\[/ {/^[^#].*\=.*/p} " | sed -e "s/^\s*//"
        else
            cat $conf_file \
                | sed -n -e " /^\[\s*$sec_name\s*\]/ , /^\s*\[/ {/^[^#].*\=.*/p} " | sed -e "s/^\s*//" | grep "^$key="
        fi
    fi
}

function _set_value_to_conf(){
    log_debug $FUNCNAME "$@"
    local conf_file="$1"
    local sec_name="$2"
          
    local key
    local value
    local sec_index

    case $sec_name in 
        box) 
            key="$3"
            value="$4"
            ;;
        node)
            sec_index="$3"
            key="$4"
            value="$5"
            ;;
        *)
            log_err "Not support section name $sec_name."
            return 1
            ;;
    esac

    log_debug $sec_name $sec_index $key $value
    if [[ -z $key ]] || [[ -z $value ]]; then return 1; fi;

    if [[ -z "$sec_index" ]]; then
        # for section without index
        __clean_format_conf $conf_file \
            |sed -n -e " /^\[\s*$sec_name\s*\]/ , /^\s*\[./ {p}" |grep "^[[:space:]]\{4\}$key=" >/dev/null
        if [[ $? -eq 1 ]]; then # no-exist,add new
            log_debug "$key not exist in $sec_name , add new one"
            sed -e "/^\[\s*$sec_name\s*\]/a\ \ \ \ $key\=$value" < $conf_file > tmp_$conf_file
        else
            log_debug "$key exist in $sec_name, change the old one"
            sed -e " /^\[\s*$sec_name\s*\]/ , /^\s*\[.*$/ {s/^\(\s*$key\s*\)\=.*/\1\=$value/}" < $conf_file > tmp_$conf_file
        fi
    else
        # for indexed section
        __clean_format_conf $conf_file \
            |sed -n -e "/^\[\s*$sec_name\s\s*$sec_index\s*\]/ , /^\s*\[.*$/ {p}" |grep "^[[:space:]]\{4\}$key=" >/dev/null
        if [[ $? -eq 1 ]]; then # no-exist,add new
            log_debug "$key not exist in $sec_name $sec_index, add new one"
            sed -e " /^\[\s*$sec_name\s\s*$sec_index\s*\]/a\ \ \ \ $key\=$value" < $conf_file > tmp_$conf_file
        else
            log_debug "$key exist in $sec_name $sec_index, change the old one"
            sed -e " /^\[\s*$sec_name\s\s*$sec_index\s*\]/ , /^\s*\[.*$/ {s/^\(\s*$key\s*\)\=.*/\1\=$value/}" < $conf_file > tmp_$conf_file
        fi
    fi
    mv tmp_$conf_file $conf_file
}

function _remove_value_from_conf(){
    log_debug $FUNCNAME "$@"
    local conf_file="$1"
    local sec_name="$2"

    if is_number "$3";then
        local sec_index="$3"
        local key="$4"
    else
        local key="$3"
    fi

    log_debug $sec_name $sec_index $key

    if [[ ! -z $key ]]; then
        # remove by key in a section
        if [[ -z "$sec_index" ]];then
            sed -e " /^\[\s*$sec_name\s*\]/ , /^\s*\[.*$/ {/^\s*$key\s*\=.*/d}" < $conf_file > tmp_$conf_file
        else
            sed -e " /^\[\s*$sec_name\s\s*$sec_index\s*\]/ , /^\s*\[.*$/ {/^\s*$key\s*\=.*/d}" < $conf_file > tmp_$conf_file
        fi
    else
        # remove entire section
        if [[ -z "$sec_index" ]];then
            sed -e " /^\[\s*$sec_name\s*\]/ , /^\s*\[.*$/ {/^.*\s*\=.*/d}" \
                -e "/^\[\s*$sec_name\s*\]/d" < $conf_file > tmp_$conf_file
        else
            sed -e " /^\[\s*$sec_name\s\s*$sec_index\s*\]/ , /^\s*\[.*$/ {/^.*\s*\=.*/d}" \
                -e "/^\[\s*$sec_name\s\s*$sec_index\s*\]/d" < $conf_file > tmp_$conf_file
        fi
    fi

    mv tmp_$conf_file $conf_file
}

function __get_node_index_list(){
    local conf_file="$1"
    echo $(egrep "\[node.*" $conf_file|sed -e s'/\[node//' -e s'/]//')
}

#==================================
# FUNCTION mybox_up 
#==================================
function mybox_up(){
    _check_status
    echo
    echo UP MYBOX environment by using \"${BOXCONF}\" ...

    # Read confg
    #  1. find Box, and verify if exist
    #  2. find Node, node 1..n 
    #  3. for every node, decided if need to import or start vm
    #    1.) id not found or found not exist in vbox), import box, and save id into box_folder
    #    2.) start vms by id from box_folder

    local base_box=$(__get_box_config "box.name")
    local base_provider=$(__get_box_config "box.provider")

    echo "The base box name is $base_box"

    for node_index in $(__get_node_index_list "$BOXCONF") ; do
        local node_name=$(__get_node_config $node_index "node.name")
        local node_box=$(__get_node_config $node_index "box.name")
        if [[ -z $node_name ]]; then node_name="node$node_index"; fi;
        if [[ -z $node_box ]]; then node_box="$base_box"; fi;
        #default provider is vbox
        if [[ -z $base_provider ]]; then base_provider="vbox"; fi;
        
        echo
        echo_n $node_name "Try to start MYBOX Node [ $node_index ] : $node_name, box=$node_box, provider=$base_provider ..."
        
        # check if the node exist
        if ! _check_node_exist $node_name; then
            #import vm
            mybox_node_import "$node_box" "$node_name" -p "$base_provider"
            if [[ ! $? -eq 0 ]];then
                echo_n $node_name "$(log_err "MYBOX import $node_box to $base_provider failed.")"
                continue
            fi
        fi

        for modify_item in $(__get_modify_items $node_index); do
            local modify_key=${modify_item%%=*}
            local modify_value=${modify_item#*=}
            log_debug "$modify_item --> $modify_key , $modify_value"
            if _check_node_need_modify "$node_name" "$modify_key" "$modify_value"; then
                # modify only support vbox now
                mybox_node_modify "$node_name" "--$modify_key" "$modify_value" -p "$base_provider"
            fi
        done

        #do provision
        mybox_node_provision $node_index -q

        #start vm
        mybox_node_start "$node_name"

    done
}

function _check_node_need_modify(){
    local node_name="$1"
    local key="$2"
    local value="$3"
    local current_value=$(mybox_node_info $node_name | grep "$key" | sed -e "s/.*=//" -e "s/\"//g")
    log_debug "? $current_value == $value"
    if [[ "$current_value" == "$value" ]]; then
        return 1
    else
        echo_n $node_name "Setting item $key $current_value -> $value, need to modify"
        return 0
    fi
}

#TODO, support more modify keys add here!
readonly VBOX_MODIFYVM_KEYS="memory nictype1 nictype2 nictype3 nictype4"

function __get_modify_items(){
    local node_index="$1"
    for base in $(mybox_config -g box);do
        echo $base|grep "^vbox.modify." > /dev/null
        if [[ $? -eq 0 ]]; then
            eval $(echo $base|sed "s/vbox.modify.//")
        fi
    done
    for item in $(mybox_config -g node $node_index);do
        echo $item|grep "^vbox.modify." > /dev/null
        if [[ $? -eq 0 ]]; then
           eval $(echo $item|sed "s/vbox.modify.//")
        fi
    done
    for key in $VBOX_MODIFYVM_KEYS; do
        eval local value=\$"$key"
        #echo $value
        if [[ ! -z  "$value" ]];then
            echo $key=$value
            unset $key
        fi
    done

}

function __get_box_config() {
    local key="$1"
    mybox_config -g box $key | sed -e 's/.*=//' -e 's/"//g'
}

function __get_node_config() {
    local node_index="$1"
    local key="$2"
    mybox_config -g node $node_index $key | sed -e 's/.*=//' -e 's/"//g'
}
#==================================
# FUNCTION mybox_down 
#==================================
function mybox_down(){
    if [[ "$1" == "-f" ]] || confirm "Are your sure to shutdown all the VMs in your MYBOX environment"; then
        for node in $(mybox_node_list); do
            echo
            mybox_node_stop $node
        done
    fi
}
#==================================
# FUNCTION mybox_clean 
#==================================
function mybox_clean(){
    if [[ -z $(mybox_node_list) ]]; then return; fi;
    if [[ "$1" == "-f" ]] || confirm "Are your sure to remove all the VMs in your MYBOX environment"; then
        for node in $(mybox_node_list); do
            mybox_node_remove $node -f
        done

    fi
}
#==================================
# FUNCTION mybox_provision 
#==================================
function mybox_provision(){
    _check_status
    case $1 in ""|-f|--force|-q|--quiet) ;; *) help_$FUNCNAME; return 1; ;; esac;
    echo
    echo Provision MYBOX environment by using \"${BOXCONF}\" ...
    for node_index in $(__get_node_index_list "$BOXCONF") ; do
        mybox_node_provision $node_index $1
    done

}
#==================================
# FUNCTION mybox_ssh 
#==================================
function mybox_ssh(){
    if [[ -z $1 ]];then
        PS3="Type a number or 'q' to quit: "
        local NODES=$(mybox_node_list)
        select node in $NODES; do
            if [[ ! -z $node ]] && _check_node_exist $node; then
                mybox_node_ssh $node
            fi
            break
        done
    else
        if _check_node_exist $1; then
            mybox_node_ssh $1
        else
            _err_node_not_found $1
            return 1
        fi
    fi
}


#==================================
# FUNCTION mybox_status 
#==================================
function mybox_status(){
    if [[ -z $1 ]]; then
        for node in $(mybox_node_list);do
            _mybox_status $node
        done
    else
        if _check_node_exist $1;then
            _mybox_status $1
        else
            _err_node_not_found $1
            return 1
        fi
    fi
}

function _mybox_status(){
    local node="$1"
    local box=$(__get_node_metadata "$node" "box")
    local provider=$(__get_node_metadata "$node" "provider")
    local provision=$(__get_node_metadata "$node" "provision")
    echo
                                                                                       echo "NODE NAME: $node"
                                                                                       echo "    MYBOX: $box"
                                                                                       echo " PROVIDER: $provider"
    mybox_node_info $node >_tmp_${node}_info
    cat _tmp_${node}_info |grep ^ostype=      |sed -e "s/.*=//" -e "s/\"//g" -e "s/^/ GUEST OS: /"
    cat _tmp_${node}_info |grep ^name=        |sed -e "s/.*=//" -e "s/\"//g" -e "s/^/  VM NAME: /"
    cat _tmp_${node}_info |grep ^VMState=     |sed -e "s/.*=//" -e "s/\"//g" -e "s/^/ VM STATE: /"
                                                                                       echo "PROVISION: $provision"
    rm  _tmp_${node}_info
}

################################################################################
#
# MYBOX BOX COMMMANDS
#
################################################################################

#==================================
# FUNCTION mybox_box
#==================================
function mybox_box(){
    _print_not_support $FUNCNAME $@
}

#----------------------------------
# FUNCTION mybox_box_add 
#----------------------------------
function mybox_box_add(){
    while [[ ! -z "$1" ]];do
        case "$1" in
            *://*)
                url="$1"
                _download_box $url
                return $?
                shift
                ;;                
            *)
                file="$1"
                _copy_box_to_local_box_repo $file
                return $?
                shift
                ;;
        esac
    done
    help_$FUNCNAME
}

function _err_bad_url(){
    log_err "Bad URL : $1"
}

function _verify_http(){
    log_debug "curl -s -k --head -L "$1" |grep "^HTTP/1.[01] 200""
    curl -s -k --head -L "$1" |grep "^HTTP/1.[01] 200" >/dev/null
    return $?
}
function _verify_ftp(){
    curl -s -k --head -L "$1" |grep "^Content-Length" >/dev/null
    return $? 
}

function _download_box(){
    local boxname=$(basename $1)
    # verfiy url
    local url=$(to_lowercase "$1")
    
    case "$url" in
        http://*|https://*)
            _verify_http $url
            if [[ ! $? -eq 0 ]]; then
                _err_bad_url "$1"
                return 1
            fi
            ;;
        ftp://*)
            _verify_ftp $url
            if [[ ! $? -eq 0 ]]; then
                _err_bad_url "$1"
                return 1
            fi
            ;;
        *)
            _err_bad_url "$1"
            return 1
            ;;
    esac

    echo "Downloading $url ..."
    curl -k -o"./$boxname" -L "$url"

    if [[ $? -eq 0 ]] && [[ -f "./$boxname" ]]; then
        _copy_box_to_local_box_repo "./$boxname"
        if [[ $? -eq 0 ]]; then
            rm "./$boxname"
        fi
    fi
}

function _copy_box_to_local_box_repo(){
    #check if file exist
    if [[ ! -f "$1" ]]; then
        _err_file_not_found "$1"
        return 1
    fi 
    #verfiy it first
    local boxname=$(basename $(to_unix_path "$1"))
    local boxbase=${boxname%.*}
    local boxext=${boxname##*.}
    if [[ $(to_uppercase $boxext) == "BOX" ]]; then
        log_debug "$boxname is a standard box file."
        boxname=$boxbase
    fi
    listtar_${arch} "$1" |grep ".*ovf$" >/dev/null
    if [[ ! $? -eq 0 ]]; then
        log_err "Not a valid MYBOX or Vagrant box. \nPlease check the file \"$1\" manaually."
        return 1
    fi
    # do copy to mybox repo
    if [[ ! -f "$MYBOX_REPO/$boxname.box" ]]; then
        echo "Install $boxname to MYBOX local repository ..."
        log_debug "$1" "$MYBOX_REPO/$boxname.box"
        cp "$1" "$MYBOX_REPO/$boxname.box"
    else
        log_err "\"$MYBOX_REPO/$boxname.box\" already exist."
    fi
}
#----------------------------------
# FUNCTION mybox_box_list 
#----------------------------------
function mybox_box_list(){
    case "$@" in
        "")
            _get_all_box_names
            ;;
        -d|--detail)
            _get_all_box_details
            ;;
        *)
            help_$FUNCNAME
            ;;
    esac

}
#----------------------------------
# FUNCTION mybox_box_detail 
#----------------------------------
function mybox_box_detail(){
    if [[ "$#" -gt 1 ]] || [[ -z "$1" ]]; then
        help_$FUNCNAME
    else
        _get_box_detail "$1"
    fi
}
#----------------------------------
# FUNCTION mybox_box_remove 
#----------------------------------
function mybox_box_remove(){
    local box="$1"
    if [[ -z $box ]]; then help_mybox_box_remove; return 1; fi;
    if _check_box_exist ${box} ; then
        if [[ "$2" == "-f" ]] || confirm "Are your sure to remove MYBOX \"${box}\" ..."; then
            _del_box "${box}"
            if [[ $? -eq 0 ]]; then 
                echo "Deleted MYBOX box \"${box}\" successfully!"; 
            else
                echo "Failed to delete MYBOX box \"${box}\"!";
                return 1
            fi
        fi
    else
        _err_box_not_found ${box}
        return 1
    fi
}

#----------------------------------------------------------
# FUNCTION mybox_box_pkgvbox 
#   generate a box from a vbox vm
# OPTS:
#   $1 -> vbox vm name 
#   $2 -> box name
#----------------------------------------------------------
function mybox_box_pkgvbox(){
    local vm_name="$1"
    local boxname="$(basename "$2" ".box")"
    local box="${MYBOX_REPO}/${boxname}"
    
    if [ ! "$#" -eq 2 ] || [ -z "$vm_name" ] || [ -z "$box" ]; then 
        _err_unknown_opts $@
        help_mybox_box_pkgvbox; 
        exit 1
    fi
    if ! _check_vm_exist $vm_name; then
        _err_vm_not_found $vm_name
        exit 1
    fi
    if [[ -f ${box}".box" ]]; then
        if confirm "WARNING: BOX named \"$2\" already exist, Do you want to overwrite it"; then
            rm ${box}".box"
        else
            exit
        fi
    fi
    mkdir -p ${box}
    echo create Box \"${box}.box\" from VM \"${vm_name}\" ...

    vbox_export_vm $vm_name "${box}/${boxname}"
    tar_$arch "${box}.box" "${box}" >/dev/null
    rm -rf "${box}"
    if [[ $? -eq 0 ]]; then 
        echo "Create Box \"${box}\" successfully!"
    fi
}

#----------------------------------
# FUNCTION mybox_box_impvbox 
#----------------------------------
function mybox_box_impvbox(){
    if [[ "$#" -eq 0 ]]; then help_$FUNCNAME; return 1 ; fi;
    local box="$1"
    local vm_name="$2"
    if ! _check_box_exist ${box}; then
        _err_box_not_found ${box}
        return 1
    fi
    if [[ -z "$vm_name" ]]; then 
        _err_not_null "vm_name"
        return 1
    fi;
    if _check_vm_exist "${vm_name}"; then
        _err_vm_exist "${vm_name}"
        return 1
    else
        _import_box_to_vbox_vm "${box}" "$vm_name"
    fi
}

#----------------------------------
# FUNCTION mybox_box_pkgvmware 
#----------------------------------
function mybox_box_pkgvmware(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_box_impvmware 
#----------------------------------
function mybox_box_impvmware(){
    _print_not_support $FUNCNAME $@
}

################################################################################
#
# MYBOX NODE COMMMANDS
#
################################################################################

#==================================
# FUNCTION mybox_node
#==================================
function mybox_node(){
    _print_not_support $FUNCNAME $@
}

# the speical echo command for all node commands
# the format like : [nodename] msgs
function echo_n(){
    local node_name="$1"
    shift
    log "[$node_name] " "$@"
}

#----------------------------------
# FUNCTION mybox_node_list 
#----------------------------------
function mybox_node_list(){
    if ! [[ -z "$1" ]]; then help_$FUNCNAME; return 1;fi
    _check_status
    _get_all_node_name
}

#----------------------------------
# FUNCTION mybox_node_import
#----------------------------------
function mybox_node_import(){
    log_debug $FUNCNAME $@
    if [[ ! -z "$2" ]]; then
        local box_name="$1"
        local node_name="$2"
        local provider="vbox"
        local force=0
        shift
        shift
        while [[ ! -z "$1" ]]; do
            case $1 in
                -p|--provider)
                    shift
                    provider=$1
                    ;;
                -f|--force)
                    force=1
                    shift
                    ;;
                 *)
                    shift
                    ;;
            esac
        done
        if [[ ! -z $provider ]]; then
            case $provider in
                vbox|vmware)
                    _import_node_${provider} $box_name $node_name $force
                    return $?
                    ;;
                *)
                    log_err "UNKNOWN provider : $provider"
                    ;;
            esac
        fi
    fi
    help_$FUNCNAME
}



#----------------------------------
# FUNCTION mybox_node_start 
#----------------------------------
function mybox_node_start(){
    log_debug $FUNCNAME $@
    if [[ ! -z "$1" ]]; then
        local node_name="$1"
        if _check_node_exist "${node_name}" ; then
            _start_node $node_name
            if [[ $? -eq 0 ]]; then
                echo_n $node_name "MYBOX Node started successfully!"
                return 0
            else
                return $?
            fi
        else
            _err_node_not_found ${node_name}
            return 1
        fi
    fi
    help_$FUNCNAME
}

function _start_node(){
    log_debug $FUNCNAME $@
    local node_name="$1"
    local vm_id=$(_get_vmid_from_myboxfolder $node_name)

    if [[ ! -z "${vm_id}" ]]; then
        echo_n $node_name "Start MYBOX Node with VBOX vm_id {$vm_id} ..."
        if _check_vm_exist_by_id $vm_id; then
            mybox_vbox_start ${vm_id}
            if [ $? -eq 0 ]; then echo_n $node_name "MYBOX Node started OK!"; fi
            return $?
        else
            log_warn "MYBOX Node \"$node_name\" with a obsoleted VBOX vm_id $vm_id, consider to remove it or re-import."
            return 1
        fi
    fi
}




#----------------------------------
# FUNCTION mybox_node_stop 
#----------------------------------
function mybox_node_stop(){

    if [[ -z "$1" ]]; then help_$FUNCNAME; fi;
    local node_name="$1" 
    if ! _check_node_exist $node_name; then
        echo_n $node_name "$(_err_node_not_found ${node_name})"
        return 1
    fi
    local vm_id=$(_get_vmid_from_myboxfolder $node_name)
    
    if [[ ! -z "${vm_id}" ]]; then
        echo_n $node_name  "Stopping MYBOX Node ..."
        if _check_vm_exist_by_id $vm_id; then
            mybox_vbox_stop ${vm_id}
            if [ $? -eq 0 ]; then echo_n $node_name "MYBOX Node stopped OK!"; fi
            return $?
        else
            echo_n $node_name "$(log_warn "MYBOX Node with a obsoleted VBOX vm_id $vm_id, consider to remove it or re-import.")"
            return 1
        fi
    fi
}

#----------------------------------
# FUNCTION mybox_node_modify 
#----------------------------------
function mybox_node_modify(){
    log_debug $FUNCNAME $@
    local node_name="$1"
    local force=0
    local provider="vbox"
    shift

    while [[ ! -z "$1" ]]; do
            case $1 in
                -p|--provider)
                    shift;
                    case "$1" in
                        vbox|vmware)
                            provider="$1"
                            ;;
                        *)
                            log_err "UNKNOWN provider : $1"
                            help_$FUNCNAME; return 1 ;
                            ;;
                    esac
                    shift
                    ;;
                -f|--force)
                    force=1
                    shift
                    ;;
                 *)
                    local key="$1"
                    local value="$2"
                    shift 2
                    ;;
            esac
    done
    if ! _check_node_exist $node_name; then
        _err_node_not_found ${node_name}
        return 1
    fi
    local vm_id=$(_get_vmid_from_myboxfolder $node_name)
    if [[ ! -z "${vm_id}" ]]; then
        if _check_vm_exist_by_id $vm_id; then
            mybox_${provider}_modify "$vm_id" -f "$key" "$value"
            return $?
        else
            log_err "MYBOX Node \"$node_name\" with a obsoleted VBOX vm_id $vm_id, consider to remove it or re-import."
            return 1
        fi
    else
        log_err "MYBOX Node \"$node_name\" can find metadata vm_id. the VBOX environment may damaged, please clean up it."
        return 1
    fi
}

#----------------------------------
# FUNCTION mybox_node_remove 
#----------------------------------
function mybox_node_remove(){
    log_debug $FUNCNAME $@
    local node_name="$1"
    local force=0
    local provider="vbox"
    shift

    while [[ ! -z "$1" ]]; do
            case $1 in
                -p|--provider)
                    shift;
                    case "$1" in
                        vbox|vmware)
                            provider=$1
                            ;;
                        *)
                            log_err "UNKNOWN provider : $1"
                            help_$FUNCNAME; return 1 ;
                            ;;
                    esac
                    ;;
                -f|--force)
                    force=1
                    shift
                    ;;
                 *)
                    help_$FUNCNAME; return 1 ;
                    ;;
            esac
    done

    if ! _check_node_exist $node_name; then
        echo_n $node_name "$(_err_node_not_found ${node_name})"
        return 1
    fi
    local vm_id=$(_get_vmid_from_myboxfolder $node_name)

    if [[ ! -z "${vm_id}" ]];then
        if [ $force -eq 1 ] || confirm "are your sure to remove MYBOX Node \"$node_name\""; then
            echo_n $node_name "Removing MYBOX Node ..."
            mybox_${provider}_remove "${vm_id}" --force
            if [[ ! $? -eq 0 ]]; then
                echo_n $node_name "$(log_warn "Error when try to removing Node \"$node_name\"'s backend $(to_uppercase $provider) VM \"{$vm_id}\"")"
            else 
                _remove_mybox_node_path ${node_name}
                if [[ $? -eq 0 ]]; then
                    echo_n $node_name "Removing MYBOX Node done!"
                fi
            fi
        fi
    fi
    

}
#----------------------------------
# FUNCTION mybox_node_provision 
#----------------------------------

readonly _INLINE_PROVISION_SCRIPT_NAME="mybox_inline_provision_script.sh"

function mybox_node_provision(){
    log_debug $FUNCNAME $@

    local node_index="$1"
    if [[ -z $node_index ]] || ! is_number $node_index; then
        help_$FUNCNAME; return 1;
    fi

    local force=0
    local quiet=0

    case $2 in "") ;; -f|--force) force=1; ;; -q|--quiet) quiet=1; ;; *) help_$FUNCNAME; return 1; ;; esac

    local node_name=$(__get_node_config $node_index "node.name")
    if [[ -z $node_name ]]; then node_name="node$node_index"; fi;


    log_debug force is $force, quiet is $quiet


    local provision=$(__get_node_config $node_index "node.provision")

    if [[ $arch == "win" ]]; then
        provision=$(to_unix_path $provision)
    fi

    echo_n $node_name "Try to provision MYBOX Node ..."
    if ! _check_node_exist $node_name; then
        echo_n $node_name $(log_err "MYBOX Node \"$node_name\" not exist, the Node maybe not created or a corrupted MYBOX environment.")
        echo_n $node_name $(log_err "Please execute 'mybox up' command to re-build your environment.")
        return 1
    fi
    if [[ ! -z $provision ]]; then
        local marker=$(__get_node_metadata "$node_name" "provision")
        log_debug "provision marker is $marker"
        if [[ $marker == "done" ]];then
            if [[ $force -eq 0 ]]; then
                echo_n $node_name "MYBOX Node has been provisioned already."
                if [[ $quiet -eq 1 ]] || ! confirm "Are your sure you want to do it again"; then
                    return 1
                fi
            fi
        fi
        local script="$provision"
        if [[ $provision == "<<INLINE_SCRIPT" ]];then
            _mybox_gen_provision_script $node_index
            script="$_INLINE_PROVISION_SCRIPT_NAME"
        fi
        log_debug "provision script is $script"
        if [[ -f $script ]]; then
            echo_n $node_name "Preparing provision ... " 
            mybox_node_scp $node_name $script
            if [[ ! $? -eq 0 ]];then
                log_err "Failed to send provison script \"$script\" to node."
                __set_node_metadata $node_name "provision" "failed"
                return 1
            fi
            echo_n $node_name "Do the provision ... "
            mybox_node_ssh $node_name "sh ~/$(basename $script)"
            if [[ $? -eq 0 ]]; then
                # tag it
                __set_node_metadata $node_name "provision" "done"
                # clean
                if [[ -f $_INLINE_PROVISION_SCRIPT_NAME ]];then
                   rm $_INLINE_PROVISION_SCRIPT_NAME
                fi
                # say success
                echo_n $node_name "Provision MYBOX Node done successfully!"
            else
                log_err "Failed when executing provison script \"$script\" under Node \"$node_name\"."
                __set_node_metadata $node_name "provision" "failed"
            fi
        else
            echo_n $node_name "provision script : $script not found!"
        fi
    else
        echo_n $node_name "No provision task found. passed-by."
    fi
}

function _mybox_gen_provision_script(){
    local node_index="$1"
    sed -n -e "/^\[\s*node\s*$node_index\s*\]/,/^\s*INLINE_SCRIPT/ {/.*/p}" < "$BOXCONF" | \
        sed -n -e "/.*<<INLINE_SCRIPT/,/^\s*INLINE_SCRIPT/ {/.*/p}" | \
        sed -e "/INLINE_SCRIPT/d" > "$_INLINE_PROVISION_SCRIPT_NAME"
}
#----------------------------------
# FUNCTION mybox_node_ssh 
#----------------------------------
function mybox_node_ssh(){
    if [[ -z "$1" ]]; then help_$FUNCNAME; fi;
    local node_name="$1" 
    if ! _check_node_exist $node_name; then
        _err_node_not_found $node_name
        return 1
    fi
    local vm_id=$(_get_vmid_from_myboxfolder $node_name)
    if [[ ! -z "${vm_id}" ]]; then
        if _check_vm_exist_by_id $vm_id; then
            # set up the ssh guest automatically
            local current_port=$(_get_vbox_fowarding_port $vm_id)

            log_debug "current guest ssh port is $current_port"

            if [[ ! -z $current_port ]] && is_port_open "127.0.0.1" "$current_port";then
                log_debug "$current_port is Ok to connect."
            else
                # get a new port
                local port=$(__get_new_usable_port_for_mybox)
                mybox_vbox_ssh-setup "${vm_id}" -a "$port" -f
            fi
            shift
            mybox_vbox_ssh "$vm_id" "$@"
            return $?
        else
            log_warn "MYBOX Node \"$node_name\" with a obsoleted VBOX vm_id $vm_id, consider to remove it or re-import."
        fi
    fi

}

__get_new_usable_port_for_mybox(){
    local port
    for p in $(_mybox_usable_ports); do
        if _check_port_usable $p;then
            port=$p
            break;
        fi
    done
    echo "$port"

}

#==================================
# FUNCTION mybox_node_scp
#==================================
function mybox_node_scp(){
    log_debug $FUNCNAME $@
    local node_name="$1"
    if ! _check_node_exist $node_name; then
        _err_node_not_found $node_name
        return 1
    fi
    let count=0
    while [[ $count -lt 3 ]]; do
        log_debug $FUNCNAME : excute mybox_node_ssh "$1" "echo 31415926"
        local pi=$(mybox_node_ssh "$1" "echo 31415926" |grep ^31415926)
        if [[ pi -eq 31415926 ]]; then
            log_debug "ssh connection to VM \"$1\" tested ok"
            local vm_id=$(_get_vmid_from_myboxfolder $node_name)
            shift
            mybox_vbox_scp $vm_id "$@"
            return $?
        else
            log_debug "ssh connection failed $count."
            let count=count+1
        fi
    done

}

#----------------------------------
# FUNCTION mybox_node_info 
#----------------------------------
function mybox_node_info(){
    log_debug $FUNCNAME $@
    local node_name="$1"
    local provider="vbox"

    if ! _check_node_exist $node_name; then
        _err_node_not_found ${node_name}
        return 1
    fi
    local vm_id=$(_get_vmid_from_myboxfolder $node_name)

    if [[ ! -z "${vm_id}" ]];then
        mybox_vbox_info ${vm_id} -m
    fi

}

################################################################################
#
# MYBOX VBOX COMMMANDS
#
################################################################################

#==================================
# FUNCTION mybox_vbox
#==================================
function mybox_vbox(){
    _print_not_support $FUNCNAME $@
}

#----------------------------------
# FUNCTION mybox_vbox_list 
#----------------------------------
function mybox_vbox_list(){
    local format=""
    local running=0
    local os=""
    while [[ ! -z "$1" ]];do
        case "$1" in
        -f|--format)
            shift
            format="$1"
            case "$format" in
                name|uuid|full|raw)
                    shift
                    ;;
                *)
                    _err_unknown_opts "--foramt $format"
                    help_$FUNCNAME;return 1
                    ;; 
            esac
            ;;
        -r|--running)
            running=1
            shift
            ;;
        -os|--ostype)
            shift
            os="$1"
            case "$os" in
                ubuntu|redhat|windows)
                    shift
                    ;;    
                *)
                    _err_unknown_opts "--ostype $os"
                    help_$FUNCNAME;return 1
                    ;; 
            esac
            ;;
        *)
            help_$FUNCNAME
            return 1
            ;;
        esac
    done

    # raw result will save to the temp file
    local vm_list="./_tmp_mybox_vbox_vm_list"

    # first get raw result from vbox, "vm_name" {vm_uuid}
    if [ $running -eq 1 ]; then
        vbox_list_running_vms > $vm_list
    else
        vbox_list_vm > $vm_list
    fi
    
    if [[ -z $format || "$format" == "raw" ]]; then
        cat $vm_list
    else
        if [[ $format == "full" ]]; then
            echo "VBOX_VM_ID                            STATE     VBOX_VM_NAME                                                "
            echo "------------------------------------  --------  ------------------------------------------------------------" 
        fi    
        #for evey line in raw result
        cat $vm_list|while read line; do
       
            log_trace "line read : $line"
            local vm_name=$(echo $line|awk -F'" ' '{print $1}'|sed s'/"//g')
            local vm_id=$(echo $line|awk -F'" ' '{print $2}'|sed s'/{//'|sed s'/}//')
            local filter_out=0    
            # if need to fiter the line
            if ! [ -z $os ];then
                filter_out=1
                log_trace "The selected ostype is \"$os\""
                log_trace "Checking the ostype for VM \"$vm_name\" uuid \"$vm_id\""
                local ostype=$(mybox_vbox_info $vm_name -m|grep ostype|sed s'/ostype=//')
                log_trace "-----------> ostype $ostype"
                local ostype_s=$(to_lowercase $(echo $ostype|sed s'/"//g'))
                log_trace "-----------> ostype $ostype_s"
                if [[ $ostype_s == $os ]]; then
                    #reformat output
                    filter_out=0
                fi
            fi
            # if can print out
            if [[ $filter_out -eq 0 ]];then 
                if [[ $format == "name" ]]; then
                    echo $vm_name
                elif [[ $format == "uuid" ]];then
                    echo $vm_id
                elif [[ $format == "full" ]];then
                    local vm_status=$(mybox_vbox_status "${vm_id}")
                    printf "%-36s  %-8s  %s \n" "$vm_id" "$vm_status" "$vm_name"
                fi
            fi
        done
    fi
    rm $vm_list
}
#----------------------------------
# FUNCTION mybox_vbox_start 
#----------------------------------
function mybox_vbox_start(){
    local vm_name="$1"
    if [[ -z "$vm_name" ]]; then 
        _err_not_null "vm_name"
        exit
    fi
    if ! _check_vm_exist "$vm_name"; then
        _err_vm_not_found $vm_name
        return 1; 
    fi
    if _check_vm_running "$vm_name"; then
        log_info "VBox VM \"$vm_name\" is already started!"
        return 1;
    fi
    vbox_start_vm ${vm_name} "headless"
    vbox_wait_vm_started ${vm_id} 60
    return $?
}

#----------------------------------
# FUNCTION mybox_vbox_stop 
#----------------------------------
function mybox_vbox_stop(){
    local vm_name="$1"
    if [[ -z "$vm_name" ]]; then 
        _err_not_null "vm_name"
        return 1
    fi
    if ! _check_vm_exist "$vm_name"; then
        _err_vm_not_found $vm_name
        return 1
    fi

    if _check_vm_running $vm_name; then
        log_info stop VBOX VM \"${vm_name}\" ...
        vbox_stop_vm "$vm_name"
        return $?
    else
        log_info VBOX VM \"${vm_name}\" not running.
    fi  

}

#----------------------------------
# FUNCTION mybox_vbox_modify 
#----------------------------------
function mybox_vbox_modify(){
    log_debug $FUNCNAME INPUT OPTS : $@
    if [[ -z "$1" ]]; then help_$FUNCNAME; return 1 ;fi #error when null
    case "$1" in -*|--*) help_$FUNCNAME; return 1 ; ;; esac; # error when start with - or --
    local vm_name="$1"
    local force=0
    shift
    while [[ ! -z "$1" ]];do
        case "$1" in
            -f|--force)
                shift
                force=1
                ;;
            **)
                local key="$1"
                local value="$2"
                shift 2
                ;;
        esac
    done
    if [[ -z "$key" ]] || [[ -z "$value" ]]; then help_$FUNCNAME; return 1 ;fi
    if ! _check_vm_exist $vm_name; then
        _err_vm_not_found $vm_name
        return 1
    fi
    if _check_vm_running $vm_name; then
        if [[ $force -eq 1 ]] || confirm "VM \"$vm_name\" is running, need to stop it before it can be modified, continue to stop it"; then
            vbox_stop_vm $vm_name
        else
            #cancle modify and exit
            return 1
        fi
    fi
    vbox_modifyvm ${vm_name} "$key" "$value" 2>./modifyvm_err_out
    cat ./modifyvm_err_out|grep error|sed s'/VBoxManage.*error:/Error:/'
    rm ./modifyvm_err_out
}

function _mybox_usable_ports(){
    local start=$(echo $MYBOX_USABLE_PORT_RANGE|sed 's/\.\..*//')
    local end=$(echo $MYBOX_USABLE_PORT_RANGE|sed 's/.*\.\.//')
    #log_debug $start $end
    for ((port=$start; port<=$end; port++));do
        echo -n "$port "
    done
}

function _vbox_used_ports(){
    local ports=$(echo $_VBOX_USED_PORT_LIST|sed s'/,/ /g')
    echo -n "$ports "
}

function _check_port_usable(){
    _mybox_usable_ports|grep "$1 " > /dev/null
    if [ $? -eq 0 ];then #if in usable ports, now test if already used
        _vbox_used_ports|grep "$1 " > /dev/null
        if [ $? -eq 0 ]; then
            return 1; #port used, not usable
        else
            # still need to check with nc under localhost
            if is_port_open "127.0.0.1" "$1"; then
                return 1; # port open under localhost, not usable
            fi
            return 0; #port not used, ok to use 
        fi
    fi
    return 1 ; #port not in usable list
}
# the idea is , the port should always cleaned before we started the node, so, every time we removed the guest ssh
# rule and add a new rule with avalible port. user don't need to know what the port it's. 
# so the solution is : (We only consider TCP port for guestssh)
# 1. set up a range of port usable for MYBOX. so we can check. use {2251,2300} since vagrant use {2200,2250}
# 2. get all used port (search forwording rule in all *RUNNING* VM ? or ALL VM?) in vbox 
# 3. remove the used port form our MYBOX usable port list.
# 4. try the first one in the list, and check if it used by nc, if not, try next one
# 5. if ok, add the forwarding rule by the port. 
# 6. if still fail, error that the usable ports had been used up.
function _modify_vbox_guestssh(){
    local vm_name="$1"
    local port="$2"
    if _check_vbox_guestssh_rule_exist $vm_name ; then
        vbox_guestssh_remove $vm_name "mybox_guestssh"
    fi
    vbox_guestssh_setup $vm_name $port "mybox_guestssh"
}
function _delete_vbox_guestssh(){
    local vm_name="$1"
    local port="$2"
    if _check_vbox_guestssh_rule_exist $vm_name ; then
        vbox_guestssh_remove $vm_name "mybox_guestssh"
    fi
}

function _check_vbox_guestssh_rule_exist(){
    local vm_name="$1"
    mybox_vbox_info $vm_name -m|grep "mybox_guestssh" > /dev/null
    return $?
}
function _get_all_vbox_fowarding_rules(){
    for vm_name in $(mybox_vbox_list -f uuid); do
        _get_vbox_fowarding_rule "$vm_name"
    done
}
function _get_vbox_fowarding_rule(){
    local vm_id="$1"
    mybox_vbox_info $vm_id -m | grep "Forwarding.*="
}
function _get_mybox_guestssh_fowarding_rule(){
    local vm_id="$1"
    mybox_vbox_info $vm_id -m | grep "Forwarding.*=.*mybox_guestssh"
}
function _get_all_vbox_used_fowarding_ports(){
    for vm_id in $(mybox_vbox_list -f name); do 
        #Forwarding(0)="guestssh,tcp,,2222,,22"-->2222
        _get_vbox_fowarding_port "$vm_id"
    done
}
function _get_vbox_fowarding_port(){
    local vm_id="$1"
    _get_vbox_fowarding_rule "$vm_id"|sed s'/.*=//'|sed s'/"//g'|awk -F',' '{print $4}'
}
function _get_mybox_guestssh_fowarding_port(){
    local vm_id="$1"
    _get_mybox_guestssh_fowarding_rule "$vm_id"|sed s'/.*=//'|sed s'/"//g'|awk -F',' '{print $4}'
}


#----------------------------------
# FUNCTION mybox_vbox_remove 
#----------------------------------
function mybox_vbox_remove(){
    local vm_name="$1"
    local force=0
    if [[ ! -z "$1" ]]; then
        if [[ ! -z "$2" ]]; then
            if [[ "$2" == "-f" || "$2" == "--force" ]];then
                force=1
            else
                help_$FUNCNAME;return 1;
            fi
        fi
    else
        help_$FUNCNAME;return 1;
    fi

    if _check_vm_exist $vm_name; then
        if _check_vm_running $vm_name; then
            if [[ $force -eq 1 ]] || confirm "VirtualBox VM \"${vm_name}\" is running, do you want to stop and delete"; then
                mybox_vbox_stop $vm_name
            else
                return 1
            fi
        fi
        if [[ $force -eq 1 ]] || confirm "Are you sure to delete VirtualBox VM \"${vm_name}\""; then
           vbox_delete_vm $vm_name
        fi
    else
        _err_vm_not_found $vm_name
    fi   
}

#----------------------------------
# FUNCTION mybox_vbox_ssh 
#----------------------------------
function mybox_vbox_ssh(){
    log_debug $FUNCNAME INPUT OPTS : $@
    if [ -z "$1" ];then help_$FUNCNAME;return 1;fi; 
    local vm_name="$1"
    local port=$(_get_mybox_guestssh_fowarding_port $vm_name)
    if _check_vm_exist $vm_name; then
        if [[ -z $port ]];then
            #port not found
            _err_vm_ssh_not_setup "$vm_name" 
            return 1
        fi
        if ! _check_vm_running $vm_name; then
            mybox_vbox_start $vm_name
        fi
    else
        _err_vm_not_found $vm_name
        return 1
    fi

    # "-o", "LogLevel=quiet", // suppress "Warning: Permanently added '[localhost]:2022' (ECDSA) to the list of known hosts."
    if [ -z "$2" ];then
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet -i $MYBOX_HOME_DIR/keys/mybox mybox@127.0.0.1 -p "$port"
    else
        if [ -e "$2" ];then
            log_debug ssh $2
            ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet -i $MYBOX_HOME_DIR/keys/mybox mybox@127.0.0.1 -p "$port" < "$2"
        else
            shift
            log_warn "Execute remote call directly is dangerous, make sure the commands are included by ' ' "
            log_debug input is $@
            echo -n "$@" > debug.sh
            ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet -i $MYBOX_HOME_DIR/keys/mybox mybox@127.0.0.1 -p "$port" < debug.sh
            if [ ! $? -eq 0 ]; then return 1; fi; #exit directly if error
        fi

    fi

    # or delete the line in ~/.ssh/known_hosts by 
    # linenumber=$(cat ~/.ssh/known_hosts |grep -n 127.0.0.1]:$port|awk -F':' '{print $1}')
    # sed -i $line_numberd .ssh/known_hosts
}

function mybox_vbox_scp(){
    
    log_debug $FUNCNAME : $@
    
    local vm=$1
    local file=$2
    local target=$3

    local port=$(_get_mybox_guestssh_fowarding_port $vm)

    if [[ ! -e $file ]];then
        return 1
    fi

    if [[ -z $target ]];then
        target=/home/mybox
    fi

    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $MYBOX_HOME_DIR/keys/mybox -P "$port" "$file" mybox@127.0.0.1:"$target" 2>/dev/null

}

#----------------------------------
# FUNCTION mybox_vbox_ssh-setup
#----------------------------------
function mybox_vbox_ssh-setup(){
    log_debug $FUNCNAME INPUT OPTS : $@
    if [[ -z "$1" ]]; then help_$FUNCNAME; return 1 ;fi #error when null
    case "$1" in -*|--*) help_$FUNCNAME; return 1 ; ;; esac; # error when start with - or --
    
    local vm_name="$1"
    local force=0

    shift
    if [[ -z "$1" ]]; then help_$FUNCNAME; return 1 ;fi #error when null
    while [[ ! -z "$1" ]];do
        case "$1" in
            -f|--force)
                shift
                force=1
                ;;
            -a|--add)
                shift
                if [[ ! -z "$1" ]] && is_port "$1";then
                    local ssh_add=1
                    local ssh_port=$1
                    shift
                else
                    help_$FUNCNAME; return 1 ;
                fi
                ;;
            -d|--delete)
                shift
                local ssh_delete=1
                ;;
            -s|--show)
                shift
                local ssh_show=1
                ;;
            **)
                shift
                help_$FUNCNAME; return 1 ;
                ;;
        esac
    done
    if ! _check_vm_exist $vm_name; then
        _err_vm_not_found $vm_name
        return 1
    fi

    if [[ $ssh_show -eq 1 ]];then
        _get_vbox_fowarding_rule "$vm_name"
        return $?
    fi
    
    if _check_vm_running $vm_name; then
        if [[ $force -eq 1 ]] || confirm "VM \"$vm_name\" is running, need to stop it before it can be modified, continue to stop it"; then
            vbox_stop_vm $vm_name
        else
            #cancle modify and exit
            return 1
        fi
    fi

    if [[ $ssh_add -eq 1 ]];then
        _modify_vbox_guestssh $vm_name $ssh_port
        return $?
    fi
    if [[ $ssh_delete -eq 1 ]];then
        _delete_vbox_guestssh $vm_name $ssh_port
        return $?
    fi

    # should not here
    help_$FUNCNAME; return 1 ;

}

#----------------------------------
# FUNCTION mybox_vbox_info 
#----------------------------------
function mybox_vbox_info(){
    local vm_name="$1"
    local machineread=0
    if ! [[ -z "$1" ]]; then 
        if [[ ! -z "$2" ]]; then
            if [[ "$2" == "-m" || "$2" == "--machinereadable" ]];then
                machineread=1
            else
                help_$FUNCNAME; return 1 ;
            fi
        fi
    else
        help_$FUNCNAME; return 1 ;
    fi
    if _check_vm_exist $vm_name; then
        if [[ $machineread -eq 1 ]]; then
            vbox_show_vm_info_machinereadable "$vm_name"
        else
            vbox_show_vm_info "$vm_name"
        fi
    else
        _err_vm_not_found $vm_name
    fi

}
#----------------------------------
# FUNCTION mybox_vbox_migrate
#----------------------------------
function mybox_vbox_migrate(){
    local vm_name="$1"

    if [[ -z "$vm_name" ]]; then 
        help_$FUNCNAME
        return 1
    fi
    if ! _check_vm_exist "$vm_name"; then
        _err_vm_not_found $vm_name
        return 1
    fi
    if ! _check_vm_running $vm_name; then
        log_info "VBOX VM \"${vm_name}\" neet to be started..."
        vbox_start_vm "$vm_name" "headless"
    fi
    log_info "Checking if \"$vm_name\" is a Vagrant VM ..."
    if _check_vagrant $vm_name; then
        log_info "Vagrent VM check OK, try to do migration ..."
        _migrate_to_mybox $vm_name
        if [[ $? -eq 0 ]]; then
            log_info "VBOX VM \"${vm_name}\" migrate to MYBOX VM OK!"
        fi
    fi
}

function _check_vagrant(){
    local vm_name=$1
    local KEY_PRV_VAGRANT="https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant"
    if [[ ! -f $MYBOX_HOME_DIR/keys/vagrant ]]; then
        curl -s -o$MYBOX_HOME_DIR/keys/vagrant -L $KEY_PRV_VAGRANT
    fi
    # need to chmod for no-windown platform for vagrant key
    if [[ ! "${arch}" == "win" ]]; then
        chmod 700 $MYBOX_HOME_DIR/keys/vagrant
    fi
    local port=$(_get_mybox_guestssh_fowarding_port $vm_name)
    if [[ -z $port ]]; then
        log_err "The VM guest ssh not setup. can not process"
        return 1
    fi 
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet -i $MYBOX_HOME_DIR/keys/vagrant vagrant@127.0.0.1 -p $port "whoami" |grep ^vagrant$ 

    if [[ $? -eq 0 ]]; then
        return 0
    else
        log_err "The VM is not a Vagrant VM."
        return 1
    fi
}

function _migrate_to_mybox(){
    local vm_name=$1
    local SCRIPT="_migrate_to_mybox_script.sh"
    local mybox_pub_key=$(cat $MYBOX_HOME_DIR/keys/mybox.pub)
cat <<EOF > "./$SCRIPT"
# Create mybox user
# userdel mybox -r
groupadd mybox
useradd mybox -g mybox -G admin -s /bin/bash -m -d /home/mybox
if [[ -f /etc/lsb-release ]]; then
    echo mybox:mybox | /usr/sbin/chpasswd
else
    echo "mybox" | passwd --stdin mybox
fi

# Install mybox keys
mkdir -p /home/mybox/.ssh

cat <<EOM >/home/mybox/.ssh/authorized_keys
$mybox_pub_key
EOM

chown -R mybox:mybox /home/mybox/.ssh
chmod -R u=rwX,go= /home/mybox/.ssh
EOF
    local port=$(_get_mybox_guestssh_fowarding_port $vm_name)
    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet -i $MYBOX_HOME_DIR/keys/vagrant -P "$port" ./$SCRIPT vagrant@127.0.0.1:~
    if [[ $? -eq 0 ]]; then rm ./$SCRIPT ; fi;
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet -i $MYBOX_HOME_DIR/keys/vagrant vagrant@127.0.0.1 -p "$port" "sudo bash /home/vagrant/$SCRIPT; rm /home/vagrant/$SCRIPT; sudo shutdown -h now"
}
#----------------------------------
# FUNCTION mybox_vbox_status
#----------------------------------
function mybox_vbox_status(){
    if [[ -z "$1" ]]; then help_$FUNCNAME; return 1 ;fi
    local vm_name="$1"
    # etc, VMState="poweroff" -> poweroff
    mybox_vbox_info "${vm_name}" "-m"|grep VMState=|sed s'/^.*=//'|sed s'/"//g'
}

################################################################################
#
# MYBOX VMWARE COMMMANDS
#
################################################################################

#==================================
# FUNCTION mybox_vmware
#==================================
function mybox_vmware(){
    _print_not_support $FUNCNAME $@
}

#----------------------------------
# FUNCTION mybox_vmware_list 
#----------------------------------
function mybox_vmware_list(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_vmware_start 
#----------------------------------
function mybox_vmware_start(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_vmware_stop 
#----------------------------------
function mybox_vmware_stop(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_vmware_modify 
#----------------------------------
function mybox_vmware_modify(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_vmware_remove 
#----------------------------------
function mybox_vmware_remove(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_vmware_provision 
#----------------------------------
function mybox_vmware_provision(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_vmware_ssh 
#----------------------------------
function mybox_vmware_ssh(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_vmware_info 
#----------------------------------
function mybox_vmware_info(){
    _print_not_support $FUNCNAME $@
}


################################################################################
#
# MYBOX MAIN
#
################################################################################

function _call_command()
{
    local opts=$@
    local opts_size=${#@}
    local last_opt=${@: -1}
    local verify_ok=1

    #echo inputs   : $opts
    #echo size     : $opts_size
    #echo last one : $last_opt

    for cmd_user in $MYBOX_CMDS; do
        if [[ "$1" == "$cmd_user" ]]; then
            log_debug "verify command $@ ok!"
            if [[ "$last_opt" == "-h" || "$last_opt" == "--help" ]]; then 
                help_mybox_$1
                return $?
            else
                local cmd=$1
                shift
                if [[ ! $cmd == "init" ]];then
                    # need to check if a vaild box environment for every box command except init.
                    _check_status
                fi
                mybox_$cmd $@
                return $?
            fi

        fi
    done
    for cmd_subs in $MYBOX_SUBCMDS; do
        # if found, need to go subcomds
        if [[ "$1" == "$cmd_subs" ]]; then
            if [[ -z "$2" || "$2" == "-h" || "$2" == "--help" ]] ; then
                help_mybox_$1
                return $?
            fi
            for subcmd in $(__get_subcommands $cmd_subs); do
                if [[ "$2" == "$subcmd" ]]; then
                    if [[ "$last_opt" == "-h" || "$last_opt" == "--help" ]]; then
                        help_mybox_$1_$2
                        return $?
                    else
                        local cmd=$1_$2
                        if [[ "$1" == "node" ]]; then
                            # for every node commands also need to check MYBOX environment before execution.
                            _check_status
                        fi
                        shift
                        shift
                        log_debug call mybox_$cmd "$@"
                        mybox_$cmd "$@"
                        return $?
                    fi
                fi
            done
        fi
    done
    #echo "verify command $@ failed!"
    usage
    return 1
}

function main(){
    local cmd="$1"
    case $cmd in
            ""|-h|--help)
                usage
                ;;
            -v)
                version
                ;;
            -H)
                usage_internal
                ;;
            *)
                local opt=$1;
                if [ $opt == "-T" ];then # a hiden opt to report executed time for brenchmark
                    shift
                    _time _call_command $@
                else
                    _call_command $@
                fi
                ;;
    esac
}
main $@
