#
DIR="$( cd "$( dirname "${BASH_SOURCE}" )" && pwd)"
. $DIR/../lib/core.sh
. func_create_vm.sh

me=`basename $0`

BOXCONF=".boxconfig"
BOXFOLDER=".mybox"
readonly MYBOX="mybox"
readonly DEFAULT_NODE="default_node"


######################
# _ERR Functions
######################
function _err_unknown_opts()
{
    echo "Error : Uknown opts " $@
}

function _err_unknown_command()
{
    echo "Error : Uknown Command " $1
}

function _err_file_not_found()
{
    echo "Error : File \"$1\" not found" 
}

function _err_box_not_found()
{
    echo "Error : MYBOX box \"$1\" not found"
}

function _err_vm_not_found(){
    echo "Error : VirtualBox VM \"$1\" not found"
}

function _err_vm_exist(){
    echo "Errro : VirtualBox VM \"$1\" exist"
}

function _err_not_null(){
    echo "Error : \"$1\" should not be null"
}
function _err_boxconf_exist_when_init(){
    echo "Error : MYBOX configuration file \"$BOXCONF\" already exists in this directory."
    echo "        Please remove it before running \"$me init\"."
}
function _err_boxconf_not_found(){
    echo "Error : MYBOX configuration file \"$BOXCONF\" not found in $(pwd) ."
    echo "        Please init your MYBOX environment by running \"$me init\"."
}
function _err_box_folder_not_found(){
    echo "Error : $BOXFOLDER is not found in this directory. need to redo \"$me init\"."
}

######################
# _CHECK Functions
######################
function _check_home()
{
    if [ -z "${MYBOX_HOME}" ] ; then
        MYBOX_HOME="D:\Boxes"
        echo "WARNING: env \"MYBOX_HOME\" not set! using default path under \"${MYBOX_HOME}\""
    fi
    MYBOX_HOME=$(to_unix_path $MYBOX_HOME)
    if [ ! -e "${MYBOX_HOME}" ]; then
        echo "ERROR: MYBOX_HOME=\"${MYBOX_HOME}\" not exist, exit"
        exit
    fi
    if [ -z "${VBOX_HOME}" ] ; then
        VBOX_HOME="${HOME}/VirtualBox VMs"
        echo "WARNING: env \"VBOX_HOME\" not set! using default path under \"${VBOX_HOME}\""
    fi
    if [ ! -e "${VBOX_HOME}" ]; then
        echo "ERROR: VBOX_HOME=\"{VBOX_HOME}\" not exist, exit"
        exit
    fi

}
_check_home

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
    pushd ${MYBOX_HOME} > /dev/null
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
    find ${MYBOX_HOME} -maxdepth 1 -type f -name "*.box" -printf "%f\n"|sed s'/.box//'

    #pushd ${MYBOX_HOME} > /dev/null
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
    local boxfile="${MYBOX_HOME}/${boxname}.box"

    extract_win "${boxfile}" "${boxname}.ovf" "${MYBOX_HOME}" > /dev/null

    if [[ $? == 0 ]];then
        echo 
        echo "====================================================================="
        echo "BOX NAME: $boxname"
        echo "---------------------------------------------------------------------" 
        cat "${MYBOX_HOME}/${boxname}.ovf" |grep "vbox:Machine"
    fi

    rm "${MYBOX_HOME}/${boxname}.ovf"
}

######################
#
#_import Functions
######################

function _import_box_to_vbox_vm() {
    log_debug $FUNCNAME $@
    local boxname="$1"
    local boxfile="${MYBOX_HOME}/$boxname.box"
    local vm_name="$2"

    if [[ ! -e "${MYBOX_HOME}/${boxname}" ]]; then
        mkdir -p "${MYBOX_HOME}/${boxname}"
        untar_win "${boxfile}" "${MYBOX_HOME}/${boxname}"
    fi
    vbox_import_ovf "${MYBOX_HOME}/${boxname}/${boxname}.ovf" "$vm_name"
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
        _err_box_not_found ${boxname}
        return 1
    fi
    
    local vm_name=$(_build_uni_vm_name $node_name)

    _import_box_to_vbox_vm "${boxname}" "${vm_name}"

    if [ "$?" -eq 0 ]; then
        _set_vmid_to_myboxfolder $vm_name $node_name
        echo "Import \"${boxname}\" to MYBOX Node \"$node_name\" under VBOX VM \"${vm_name}\" successfully!"
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

    local id_file=$(_get_mybox_node_path $node_name)

    local id_dir=$(dirname "${id_file}")

    #echo $id_dir
    if [[ ! -e "$id_dir" ]]; then mkdir -p "${id_dir}" ; fi;
    echo "$vm_id" > $id_file
}

function _get_vmid_from_myboxfolder(){
    
    local node_name="$1"
    local id_file="$(_get_mybox_node_path $node_name)"    
    local vm_id=""

    if [[ -f "${id_file}" ]]; then 
        vm_id="$(cat "$id_file"|awk '{print $2}'|sed s'/{//'|sed s'/}//')"
    fi;

    echo $vm_id
}

# "$BOXFOLDER/nodes/$node_name/vbox/id"
function _get_mybox_node_path(){
    local node_name="$1"
    if [ -z ${node_name} ]; then
        node_name="${MYBOX}_${DEFAULT_NODE}"
    fi
    echo "${BOXFOLDER}/nodes/${node_name}/vbox/id"
}

function _get_all_node_name(){

    for node_name in $(ls ${BOXFOLDER}/nodes/ -m1)
    do
        echo $node_name
    done
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
    "mybox:init up down clean provision ssh status"
    "myboxsub:box node vbox vmware"
    "box:add list detail remove pkgvbox impvbox pkgvmware impvmware"
    "node:list import start stop modify remove provision ssh info"
    "vbox:list start stop modify remove provision ssh info"
    "vmware:list start stop modify remove provision ssh info"
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
    echo 
    help_mybox_box
    echo 
    help_mybox_node
    echo 
    help_mybox_vbox
    echo
    help_mybox_vmware
    echo 
    echo "!!! NOTE: Some Node/VM command is for internal test only. please use carefully "
    echo "    improperly usage may result a corrupted  MYBOX environment.          "
}

function version()
{
    echo "$me 1.0.0"
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
    echo "Usage: $me init [box_name]"
    echo "    -h, --help                       Print this help"
}
#==================================
# FUNCTION help_mybox_up 
#==================================
function help_mybox_up(){
    echo "Usage: $me up [node_name]"
    echo "    -h, --help                       Print this help"
}

#==================================
# FUNCTION help_mybox_down 
#==================================
function help_mybox_down(){
    _print_not_support $FUNCNAME $@
}
#==================================
# FUNCTION help_mybox_clean 
#==================================
function help_mybox_clean(){
    _print_not_support $FUNCNAME $@
}
#==================================
# FUNCTION help_mybox_provision 
#==================================
function help_mybox_provision(){
    _print_not_support $FUNCNAME $@
}
#==================================
# FUNCTION help_mybox_ssh 
#==================================
function help_mybox_ssh(){
    _print_not_support $FUNCNAME $@
}
#==================================
# FUNCTION help_mybox_status 
#==================================
function help_mybox_status(){
    _print_not_support $FUNCNAME $@
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
    echo "    box pkgvmware     create a box from VMWare VM"
    echo "    box impvmware     import a box into VMWare VM"
}
#----------------------------------
# FUNCTION help_mybox_box_add 
#----------------------------------
function help_mybox_box_add(){
    _print_not_support $FUNCNAME $@
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
    echo "    node modify       to modify the node settings."
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
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_node_modify 
#----------------------------------
function help_mybox_node_modify(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_node_remove 
#----------------------------------
function help_mybox_node_remove(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_node_provision 
#----------------------------------
function help_mybox_node_provision(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_node_ssh 
#----------------------------------
function help_mybox_node_ssh(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_node_info 
#----------------------------------
function help_mybox_node_info(){
    _print_not_support $FUNCNAME $@
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
    echo "    vbox provision    pervision on a VirtualBox VM."
    echo "    vbox ssh          connects to a VirtualBox VM."
    echo "    vbox info         show detail information of a VirtualBox VM."
}
#----------------------------------
# FUNCTION help_mybox_vbox_list 
#----------------------------------
function help_mybox_vbox_list(){
    echo "MYBOX subcommand \"vbox list\" : list all user's VirtualBox VMs in host machine."
    echo "Usage: $me vbox list"
    echo "    -r|--running                     list all running VirtualBox VMs."
    echo "    -h, --help                       Print this help"
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
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_vbox_remove 
#----------------------------------
function help_mybox_vbox_remove(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_vbox_provision 
#----------------------------------
function help_mybox_vbox_provision(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_vbox_ssh 
#----------------------------------
function help_mybox_vbox_ssh(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_vbox_info 
#----------------------------------
function help_mybox_vbox_info(){
    _print_not_support $FUNCNAME $@
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
    echo "    vmware provision  pervision on a VMWare VM."
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
# FUNCTION help_mybox_vmware_provision 
#----------------------------------
function help_mybox_vmware_provision(){
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
    local box="$1"

    if [[ -z ${box} ]] ; then box="UnknownBox"; fi;

    if [ "$#" -gt 1 ] ; then 
        help_mybox_init
        exit 0
    fi
    _check_box_folder #create box folder if not created

    if [[ -e "$BOXCONF" ]]; then
        _err_boxconf_exist_when_init
        exit 0
    fi

cat <<EOF > "$BOXCONF"
    # box config 
[box] 
    box=${box}
    
    node.name=${MYBOX}_${DEFAULT_NODE}
    vbox.modifyvm.memory=512
# node
[node 1]
    vbox.modifyvm.name="another_name_node1"
    vbox.modifyvm.memory=1024
    vbox.modifyvm.nictype1="82540EM"

[node 2]
    box=REHL64
    vbox.modifyvm.memory=2048
EOF
    echo "Init a box config under $PWD/$BOXCONF successfully!"
}

#==================================
# FUNCTION mybox_up 
#==================================
function mybox_up(){
    _check_status

    echo UP MYBOX environment by using \"${boxconf}\" ...


    # Read confg
    #  1. find Box, and verify if exist
    #  2. find Node, node 1..n 
    #  3. for every node, decided if need to import or start vm
    #    1.) id not found or found not exist in vbox), import box, and save id into box_folder
    #    2.) start vms by id from box_folder

}
#==================================
# FUNCTION mybox_down 
#==================================
function mybox_down(){
    _print_not_support $FUNCNAME $@
}
#==================================
# FUNCTION mybox_clean 
#==================================
function mybox_clean(){
    _print_not_support $FUNCNAME $@
}
#==================================
# FUNCTION mybox_provision 
#==================================
function mybox_provision(){
    _print_not_support $FUNCNAME $@
}
#==================================
# FUNCTION mybox_ssh 
#==================================
function mybox_ssh(){
    _print_not_support $FUNCNAME $@
}
#==================================
# FUNCTION mybox_status 
#==================================
function mybox_status(){
    _print_not_support $FUNCNAME $@
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
    _print_not_support $FUNCNAME $@
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
    local box="${MYBOX_HOME}/${boxname}"
    
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
    tar_$arch "${box}.box" "${box}"
    rm -rf "${box}"
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
        _start_node $node_name
        return $?
    fi
    help_$FUNCNAME
}

function _start_node(){
    log_debug $FUNCNAME $@
    local node_name="$1"
    local vm_id=$(_get_vmid_from_myboxfolder $node_name)

    if [[ ! -z "${vm_id}" ]]; then
        echo "Start MYBOX Node \"$node_name\" with VBOX vm_id {$vm_id} ..."
        if _check_vm_exist_by_id $vm_id; then
            mybox_vbox_start ${vm_id}
            if [ $? -eq 0 ]; then echo "MYBOX Node \"$node_name\" started OK!"; fi
            return $?
        else
            log_warn "MYBOX Node \"$node_name\" with a obsoleted VBOX vm_id $vm_id, consider to remove it or re-import."
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
        echo "MYBOX Node \"$node_name\" not found!"
        return 1
    fi
    local vm_id=$(_get_vmid_from_myboxfolder $node_name)
    
    if [[ ! -z "${vm_id}" ]]; then
        echo "Stopping MYBOX Node \"$node_name\" with VBOX vm_id {$vm_id} ..."
        if _check_vm_exist_by_id $vm_id; then
            mybox_vbox_stop ${vm_id}
            if [ $? -eq 0 ]; then echo "MYBOX Node \"$node_name\" stopped OK!"; fi
            return $?
        else
            log_warn "MYBOX Node \"$node_name\" with a obsoleted VBOX vm_id $vm_id, consider to remove it or re-import."
        fi
    fi
}

#----------------------------------
# FUNCTION mybox_node_modify 
#----------------------------------
function mybox_node_modify(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_node_remove 
#----------------------------------
function mybox_node_remove(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_node_provision 
#----------------------------------
function mybox_node_provision(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_node_ssh 
#----------------------------------
function mybox_node_ssh(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_node_info 
#----------------------------------
function mybox_node_info(){
    _print_not_support $FUNCNAME $@
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
    case "$1" in
        "")
            vbox_list_vm
            return $?
            ;;
        -r|--running)
            vbox_list_running_vms
            return $?
            ;;
        *)
            help_$FUNCNAME
            ;;
    esac
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
        echo "VBox VM \"$vm_name\" is already started!"
        return 1;
    fi
    vbox_start_vm ${vm_name} "headless"
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
        echo stop VBOX VM \"${vm_name}\" ...
        vbox_stop_vm "$vm_name"
        return $?
    else
        echo VBOX VM \"${vm_name}\" not running.
        return 1
    fi  

}

#----------------------------------
# FUNCTION mybox_vbox_modify 
#----------------------------------
function mybox_vbox_modify(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_vbox_remove 
#----------------------------------
function mybox_vbox_remove(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_vbox_provision 
#----------------------------------
function mybox_vbox_provision(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_vbox_ssh 
#----------------------------------
function mybox_vbox_ssh(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_vbox_info 
#----------------------------------
function mybox_vbox_info(){
    _print_not_support $FUNCNAME $@
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
            echo "verify command $@ ok!"
            if [[ "$last_opt" == "-h" || "$last_opt" == "--help" ]]; then 
                eval help_mybox_$1
                return $?
            else
                local cmd=$1
                shift
                eval mybox_$cmd $@
                return $?
            fi

        fi
    done
    for cmd_subs in $MYBOX_SUBCMDS; do
        # if found, need to go subcomds
        if [[ "$1" == "$cmd_subs" ]]; then
            if [[ -z "$2" || "$2" == "-h" || "$2" == "--help" ]] ; then
                eval help_mybox_$1
                return $?
            fi
            for subcmd in $(__get_subcommands $cmd_subs); do
                if [[ "$2" == "$subcmd" ]]; then
                    if [[ "$last_opt" == "-h" || "$last_opt" == "--help" ]]; then
                        eval help_mybox_$1_$2
                        return $?
                    else
                        local cmd=$1_$2
                        shift
                        shift
                        eval mybox_$cmd $@
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
                usage
                usage_internal
                ;;
            *)
                _call_command $@
                ;;
    esac
}
main $@