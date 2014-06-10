#
DIR="$( cd "$( dirname "${BASH_SOURCE}" )" && pwd)"
. $DIR/../lib/core.sh
. func_create_vm.sh

me=`basename $0`

BOXCONF_DEFAULT="./.boxconfig"

function _check_home()
{
    if [ -z "${MYBOX_HOME}" ] ; then
        MYBOX_HOME="D:\Boxes"
        echo "WARNING: env \"MYBOX_HOME\" not set! using Default \"${MYBOX_HOME}\""
    fi
    if [ ! -e "${MYBOX_HOME}" ]; then
        echo "ERROR: MYBOX_HOME=\"{MYBOX_HOME}\" not exist, exit"
        exit
    fi
    if [ -z "${VBOX_HOME}"] ; then
        VBOX_HOME="${HOME}/VirtualBox VMs"
        echo "WARNING: env \"VBOX_HOME\" not set! using Default \"${VBOX_HOME}\""
    fi
    if [ ! -e "${VBOX_HOME}" ]; then
        echo "ERROR: VBOX_HOME=\"{VBOX_HOME}\" not exist, exit"
        exit
    fi

}
_check_home

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

function _err_vm_not_found(){
    echo "Error : VM \"$1\" not found"
}

function _err_vm_exist(){
    echo "Errro : VM \"$1\" exist"
}

function _err_not_null(){
    echo "Error : \"$1\" should not be null"
}

function _confirm(){
    local msg="$1"
    read -r -p "$msg?[yes/no]" confirm
    case "${confirm}" in 
        [yY][eE][sS]|[yY])
            echo 0
            ;;
        *)
            echo 1
            ;;
    esac
}

function _print_usage(){
    echo Usage : $me $1 
}

function _check_vm_exist(){
    local vm_name="$1"
    list_vms|grep ^\"$vm_name\"
    if [ $? -eq 0 ];then
        echo "$vm_name exist"
        return 1
    fi
    return 0
}
function _check_box_conf(){
    local boxconf="$1"
    if [[ ! -e $boxconf ]]; then
        _err_file_not_found $boxconf
        exit 0
    fi
}


######################
# INIT
######################
# init a box config by box-template
function init()
{
    local box = "$1"
    echo "init a box config by a box-template"

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
        if [[ $(_confirm "WARNING: BOX named \"$2\" already exist, Do you want to overwrite it") -eq 0 ]] ; then
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
    local vm_name="$2"
    if [ ! -e "${box}" ]; then
        _err_file_not_found "${box}"
    fi
    if [[ ! -z "$vm_name" ]] && [[ $(_check_vm_exist "$vm_name") ]]; then
        _err_vm_exist $vm_name
        exit 0
    fi
    echo "import \"${box}\" "
    if [[ ! -e "${MYBOX_HOME}/${boxname}" ]]; then
        mkdir -p "${MYBOX_HOME}/${boxname}"
        untar_win "${box}" "${MYBOX_HOME}/${boxname}"
    fi
    vbox_import_vm ${MYBOX_HOME}/${boxname}/${boxname} $vm_name
}

######################
# LIST
######################
# list all box template
function list(){
    case "$1" in
        vms)
            list_vms
            ;;
        boxes)
            list_boxes
            ;;
        *)
            usage_list
            ;;
    esac
}
function list_boxes()
{
    echo "List boxes ..."
    for box in $(find ${MYBOX_HOME} -type f -name "*.box")
    do
        show_box $box
    done
}
function show_box(){
    local box="$1"
    local boxname=$(basename $(to_unix_path $box) .box)
    echo 
    echo "====================================================================="
    echo "BOX NAME: $boxname"
    echo "---------------------------------------------------------------------"
    extract_win "${box}" "${boxname}.ovf" "${MYBOX_HOME}" > /dev/null
    cat "${MYBOX_HOME}/${boxname}.ovf" |grep "vbox:Machine"
    rm "${MYBOX_HOME}/${boxname}.ovf"
}
function list_vms(){
    vbox_list_vm
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
    if [[ ! $(_check_vm_exist "$vm_name") ]]; then
        _err_vm_not_found $vm_name
        exit; 
    fi  
    echo start VM \"${vm_name}\" ...
    vbox_start_vm ${vm_name} "headless"

}

function start_boxes()
{
    local boxconf="$1"
    if [[ -z $boxconf ]]; then
        boxconf="${BOXCONF_DEFAULT}"
    fi
    _check_box_conf $boxconf
    echo start BOXes using \"${boxconf}\" ...
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
    if [[ ! $(_check_vm_exist "$vm_name") ]]; then
        _err_vm_not_found $vm_name
        exit; 
    fi  
    echo stop VM \"${vm_name}\" ...
    vbox_stop_vm "$vm_name"
}

function stop_boxes()
{
    local boxconf="$1"
    if [[ -z $boxconf ]]; then
        boxconf="${BOXCONF_DEFAULT}"
    fi
    _check_box_conf $boxconf
    echo stop BOXes using \"${boxconf}\" ...
}


######################
# REMOVE
######################
function remove_vm()
{
    local vm_name="$1"
    echo remove VM \"${vm_name}\" ...
}
function remove_box()
{
    local box="$1"
    echo remove BOX \"${box}\" ...
}


######################
# USAGE
######################
function usage()
{
    #echo "usage all"
    for cmd in "package" "list" "start" 
    do usage_$cmd; done
}

function usage_package(){
    _print_usage "package <BOXNAME>"
}

function usage_start()
{
    _print_usage "start "
    _print_usage "start -d <boxconfig>"
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
    _print_usage "list vms"
}




######################
# MAIN
######################
function main(){
    local cmd="$1"
    local opts=$@
    #echo inputs : $opts
    case $cmd in
            package*)
                shift
                package "$@"
                ;;
            list*)
                shift
                list $@
                ;;
            import*)
                shift
                import $@
                ;;
            start*)
                shift
                start_ $@
                ;;
            stop*)
                shift
                stop $@
                ;;
            -h|--help)
                usage
                ;;
            *)
                _err_unknown_opts $@
                usage
                ;;
    esac
}
main $@