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
    echo "Error : Box \"$1\" not found"
}

function _err_vm_not_found(){
    echo "Error : VM \"$1\" not found"
}

function _err_vm_exist(){
    echo "Errro : VM \"$1\" exist"
}

function _err_not_null(){
    echo "Error : \"$1\" should not be null"
}
function _err_boxconf_exist_when_init(){
    echo "Error : \"$BOXCONF\" already exists in this directory."
    echo "        Remove it before running \"$me init\"."
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
    if [ ! -e "${MYBOX_HOME}" ]; then
        echo "ERROR: MYBOX_HOME=\"{MYBOX_HOME}\" not exist, exit"
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

function _check_box_exist(){
    list_boxes|grep ^"$1"$
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
    list_vms|grep ^\"$vm_name\" > /dev/null
    if [ $? -eq 0 ]; then return 0; else return 1; fi

}
function _check_vm_exist_by_id(){
    local vm_id="$1"
    list_vms|grep \{$vm_id\}$ >/dev/null
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
    list_running_vms|grep ^\"$vm_name\" >/dev/null
    if [ $? -eq 0 ]; then return 0; else return 1; fi

}
function _check_vm_running_by_id(){
    local vm_id="$1"
    list_running_vms|grep \{$vm_id\}$ >/dev/null
    if [ $? -eq 0 ]; then return 0; else return 1; fi
}

function _check_box_conf(){
    if [[ ! -f ${BOXCONF} ]]; then
        _err_file_not_found ${BOXCONF}
        exit 0
    fi
}
function _check_box_folder(){
    # build $BOXFOLDER if not exist
    if [[ ! -d $BOXFOLDER ]]; then
        mkdir -p $BOXFOLDER
    fi
}

######################
# LIST
######################
# list all box template
function list(){
    case "$@" in
        vms)
            list_vms "$@"
            ;;
        nodes)
            list_nodes
            ;;
        boxes)
            list_boxes
            ;;
        boxes*)
            shift
            if [[ "$1" == "--detail" ]]; then
                show_box_detail
            else
                usage_list
            fi
            ;;
        *)
            usage_list
            ;;
    esac
}
function list_boxes()
{
    pushd ${MYBOX_HOME} > /dev/null
    for f in $(ls -m1 *.box); do basename $f .box; done;
    popd > /dev/null
}

function show_box_detail(){
    for box in $(find ${MYBOX_HOME} -type f -name "*.box")
    do
        local boxname=$(basename $(to_unix_path $box) .box)
        echo 
        echo "====================================================================="
        echo "BOX NAME: $boxname"
        echo "---------------------------------------------------------------------"
        extract_win "${box}" "${boxname}.ovf" "${MYBOX_HOME}" > /dev/null
        cat "${MYBOX_HOME}/${boxname}.ovf" |grep "vbox:Machine"
        rm "${MYBOX_HOME}/${boxname}.ovf"
    done
}

function list_nodes(){
    _check_status
    _get_all_node_name
}

function list_vms(){
    vbox_list_vm
}

function list_running_vms(){
    vbox_list_running_vms
}

######################
# STATUS
######################
function status()
{
    _check_status

}

function _check_status(){
    _check_box_conf
    _check_box_folder
}

######################
# PACKAGE
######################
# generate a box template from a vbox vm
function package()
{
    
    local vm_name="$1"
    local boxname="$(basename "$2" ".box")"
    local box="${MYBOX_HOME}/${boxname}"
    
    if [ ! "$#" -eq 2 ] || [ -z "$vm_name" ] || [ -z "$box" ]; then 
        _err_unknown_opts package $@
        usage_package; exit
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

######################
# IMPORT
######################
## A Testing for import
function import(){
    local boxname="$1"
    local box="${MYBOX_HOME}/${boxname}.box"
    local node_name="$2"
    if [ ! -e "${box}" ]; then
        _err_box_not_found "${boxname}"
        exit 1
    fi
    local vm_name=$(_build_uni_vm_name $node_name)

    if [[ ! -e "${MYBOX_HOME}/${boxname}" ]]; then
        mkdir -p "${MYBOX_HOME}/${boxname}"
        untar_win "${box}" "${MYBOX_HOME}/${boxname}"
    fi

    echo "Import MYBOX \"${boxname}\" into VBOX VM \"${vm_name}\""

    vbox_import_vm "${MYBOX_HOME}/${boxname}/${boxname}" "$vm_name"

    if [ "$?" -eq 0 ]; then
        _set_vmid_to_myboxfolder $vm_name $node_name
    else
        echo "Error : Import \"${boxname}\" into VBOX VM \"${vm_name}\" failed! Exit."
        exit 1
    fi
}

function _set_vmid_to_myboxfolder(){
    
    local vm_name="$1"
    local node_name="$2"

    local vm_id=$(list_vms|grep ^\"$vm_name\")

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


######################
# START
######################
function start_()
{
     case "$1" in
        vm*)
            shift
            start_vm $@
            ;;
        node*)
            shift
            start_node $@
            ;;
        ""|-d|-D)
            shift
            start_boxes $@
            ;;
        *)
            usage_start
            ;;
    esac 
} 
function start_vm()
{
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

# Path like this ./.mybox/nodes/<node_name>/vbox/id
function start_node(){
    local node_name="$1"
    local box_name="$2"
    local vm_id=$(_get_vmid_from_myboxfolder $node_name)

    if [[ ! -z "${vm_id}" ]]; then
        echo "Start MYBOX Node \"$node_name\" with VBOX vm_id {$vm_id} ..."
        if _check_vm_exist_by_id $vm_id; then
            start_vm ${vm_id}
            if [ $? -eq 0 ]; then echo "MYBOX Node \"$node_name\" started OK!"; fi
            return $?
        fi
    fi
    if [[ -z "$box_name" ]];then
        echo "BOX name is not set, can't do import. exit"
        exit 1
    fi
    import "$box_name" "$node_name"
    if [[ $? -eq 0 ]]; then #import ok
        start_node "$node_name" "$box_name"
    fi
}

function start_boxes()
{
    _check_status

    echo start BOXes using \"${boxconf}\" ...


    # Read confg
    #  1. find Box, and verify if exist
    #  2. find Node, node 1..n 
    #  3. for every node, decided if need to import or start vm
    #    1.) id not found or found not exist in vbox), import box, and save id into box_folder
    #    2.) start vms by id from box_folder
    
}

function _read_box_conf(){
    local boxconf="$1"
    # read [box] selection
    # read [node] selection
}


######################
# STOP
######################
function stop()
{
     case "$1" in
        vm*)
            shift
            stop_vm $@
            ;;
        node*)
            shift
            stop_node $@
            ;;
        ""|-d|-D)
            shift
            stop_boxes $@
            ;;
        *)
            usage_stop
            ;;
    esac 
} 
function stop_vm()
{
    local vm_name="$1"
    if [[ -z "$vm_name" ]]; then 
        _err_not_null "vm_name"
        exit
    fi
    if ! _check_vm_exist "$vm_name"; then
        _err_vm_not_found $vm_name
        exit; 
    fi  
    echo stop VBOX VM \"${vm_name}\" ...
    vbox_stop_vm "$vm_name"
}

function stop_node()
{
    local node_name="$1"
    local vm_id=$(_get_vmid_from_myboxfolder $node_name)
    if [[ ! -z "${vm_id}" ]]; then
        echo "Stopping MYBOX Node \"$node_name\" with VBOX vm_id {$vm_id} ..."
        if _check_vm_exist_by_id $vm_id; then
            if _check_vm_running_by_id $vm_id; then
                stop_vm ${vm_id}
                if [ $? -eq 0 ]; then echo "MYBOX Node \"$node_name\" stopped OK!"; fi
                return $?
            else
                echo "MYBOX Node \"$node_name\" is not running!"
                return 1
            fi
        fi
    fi
    echo "MYBOX Node \"$node_name\" not found!"
    return 1
}

function stop_boxes()
{
    _check_status
    echo stop BOXes ...
}


######################
# REMOVE
######################
function remove_vm()
{
    local vm_name="$1"
    echo remove VBOX VM \"${vm_name}\" ...
}
function remove_node()
{
    local node_name="$1"
    echo remove MYBOX Node \"${node_name}\" ...

}
function remove_box()
{
    local box="$1"
    echo remove MYBOX \"${box}\" ...
}

######################
# MODIFY
######################
function modify_vm(){
    local vm_name="$1"
    echo modify VM \"${vm_name}\" ...
    # vbox_guestssh_setup ${vm_name} 2300
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
    "node:list start stop modify remove provision ssh info"
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
    echo
    echo "For help on any individual command run \"$me COMMAND [SUBCOMMAND] -h\""
}
function usage_internal()
{
    echo 
    echo "Box subcommands : The commads to manage MYBOX boxes."
    echo "    box add           download a pre-build box into user's local box repository"
    echo "    box list          list boxes in user's local box repository."
    echo "    box detail        show a box's detail."
    echo "    box remove        remove a box from user's local box repository"
    echo "    box pkgvbox       create a box from VirtualBox VM"
    echo "    box impvbox       import a box into VirtualBox VM"
    echo "    box pkgvmware     create a box from VMWare VM"
    echo "    box impvmware     import a box into VMWare VM"
    echo 
    echo "Node subcommands : The commands to manage MYBOX nodes."
    echo "    node list         list MYBOX nodes in the MYBOX environment"
    echo "    node start        start a MYBOX node by node name"
    echo "    node stop         stop a MYBOX node by node name"
    echo "    node modify       to modify the node settings."
    echo "    node remove       remove a MYBOX node from the MYBOX environment"
    echo "    node provision    pervision on a MYBOX node."
    echo "    node ssh          connects to a MYBOX node."
    echo "    node info         show detail information of a MYBOX node."
    echo 
    echo "VBOX subcommands : The commands to manage VirtualBox VM"
    echo "    vbox list         list user's VirtualBox environment "
    echo "    vbox start        start a VirtualBox VM."
    echo "    vbox stop         stop a VirtualBox VM."
    echo "    vbox modify       modify a VirtualBox VM"
    echo "    vbox remove       remove a VM from the User's VirtualBox environment"
    echo "    vbox provision    pervision on a VirtualBox VM."
    echo "    vbox ssh          connects to a VirtualBox VM."
    echo "    vbox info         show detail information of a VirtualBox VM."
    echo
    echo "VMWare subcommands : The commands to manage VMWare VM"
    echo "    vmware list       list VMs in user's VMWare environment "
    echo "    vmware start      start a VMWare VM."
    echo "    vmware stop       stop a VMWare VM."
    echo "    vmware modify     modify a VMWare VM"
    echo "    vmware remove     remove a VM from user's VMWare environment"
    echo "    vmware provision  pervision on a VMWare VM."
    echo "    vmware ssh        connects to a VMWare VM."
    echo "    vmware info       show detail information of a VMWare VM."
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
    _print_not_support $FUNCNAME $@
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
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_box_detail 
#----------------------------------
function help_mybox_box_detail(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_box_remove 
#----------------------------------
function help_mybox_box_remove(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_box_pkgvbox 
#----------------------------------
function help_mybox_box_pkgvbox(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_box_impvbox 
#----------------------------------
function help_mybox_box_impvbox(){
    _print_not_support $FUNCNAME $@
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
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_node_list 
#----------------------------------
function help_mybox_node_list(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_node_start 
#----------------------------------
function help_mybox_node_start(){
    _print_not_support $FUNCNAME $@
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
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_vbox_list 
#----------------------------------
function help_mybox_vbox_list(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_vbox_start 
#----------------------------------
function help_mybox_vbox_start(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION help_mybox_vbox_stop 
#----------------------------------
function help_mybox_vbox_stop(){
    _print_not_support $FUNCNAME $@
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
    _print_not_support $FUNCNAME $@
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
    _print_not_support $FUNCNAME $@
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
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_box_detail 
#----------------------------------
function mybox_box_detail(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_box_remove 
#----------------------------------
function mybox_box_remove(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_box_pkgvbox 
#----------------------------------
function mybox_box_pkgvbox(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_box_impvbox 
#----------------------------------
function mybox_box_impvbox(){
    _print_not_support $FUNCNAME $@
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
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_node_start 
#----------------------------------
function mybox_node_start(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_node_stop 
#----------------------------------
function mybox_node_stop(){
    _print_not_support $FUNCNAME $@
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
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_vbox_start 
#----------------------------------
function mybox_vbox_start(){
    _print_not_support $FUNCNAME $@
}
#----------------------------------
# FUNCTION mybox_vbox_stop 
#----------------------------------
function mybox_vbox_stop(){
    _print_not_support $FUNCNAME $@
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

function usage_package(){
    _print_usage "package <box_name> <vm_name>"

}

function usage_start()
{
    _print_usage "start "
    _print_usage "start -d <boxconfig>"
    _print_usage "start node <node_name> [box_name]"
    _print_usage "start vm <vm_name>"
}
function usage_stop()
{
    _print_usage "stop "
    _print_usage "stop -d <boxconfig>"
    _print_usage "stop vm <vm_name>"
}
function usage_list(){
    _print_usage "list boxes"
    _print_usage "list boxes --detail"
    _print_usage "list vms"
}

function _print_usage(){
    echo Usage : $me $1 
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
    # case $cmd in
    #         init*)
    #             shift
    #             init "$@"
    #             ;;
    #         package*)
    #             shift
    #             package "$@"
    #             ;;
    #         list*)
    #             shift
    #             list $@
    #             ;;
    #         import*)
    #             shift
    #             import $@
    #             ;;
    #         start*)
    #             shift
    #             start_ $@
    #             ;;
    #         stop*)
    #             shift
    #             stop $@
    #             ;;
    #         -h|--help)
    #             usage
    #             ;;
    #         -v)
    #             version
    #             ;;
    #         -H)
    #             usage
    #             usage_internal
    #             ;;
    #         *)
    #             usage
    #             ;;
    # esac
}
main $@