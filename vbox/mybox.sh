#
DIR="$( cd "$( dirname "${BASH_SOURCE}" )" && pwd)"
. $DIR/../lib/core.sh
. func_create_vm.sh

me=`basename $0`

readonly ${BOXCONF:=.boxconfig}
readonly ${BOXFOLDER:=.mybox}

readonly MYBOX="mybox"
readonly DEFAULT_NODE="default_node"

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
    if [ -z "${VBOX_HOME}"] ; then
        VBOX_HOME="${HOME}/VirtualBox VMs"
        echo "WARNING: env \"VBOX_HOME\" not set! using default path under \"${VBOX_HOME}\""
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
function _err_boxconf_exist_when_init(){
    echo "Error : \"$BOXCONF\" already exists in this directory."
    echo "        Remove it before running \"$me init\"."
}
function _err_box_folder_not_found(){
    echo "Error : $BOXFOLDER is not found in this directory. need to redo \"$me init\"."
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
# INIT
######################
# init a box config by box-template
function init()
{
    local box="$1"

    if [[ -z ${box} ]] ; then box="UnknownBox"; fi;

    if [ "$#" -gt 1 ] ; then 
        usage_init
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
    echo "Init a box config under `currentDir`/$BOXCONF successfully!"
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
    local node_name="$2"
    if [ ! -e "${box}" ]; then
        _err_file_not_found "${box}"
    fi
    local vm_name=$(_build_uni_vm_name $node_name)

    echo "import \"${box}\" "
    if [[ ! -e "${MYBOX_HOME}/${boxname}" ]]; then
        mkdir -p "${MYBOX_HOME}/${boxname}"
        untar_win "${box}" "${MYBOX_HOME}/${boxname}"
    fi
    local 
    vbox_import_vm ${MYBOX_HOME}/${boxname}/${boxname} $vm_name

    if [ "$?" -eq 0 ]; then
        local vm_id=$(list_vms|grep ^\"$vm_name\")
        local id_file=$(_get_mybox_node_path $node_name)
        local id_dir=$(dirname "${id_file}")
        echo $id_dir
        if [[ ! -e "$id_dir" ]]; then mkdir -p "${id_dir}" ; fi;
        echo "$vm_id" > $id_file
    else
        echo "Error : import $@"
        exit 0
    fi
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

# "$BOXFOLDER/nodes/$node_name/vbox/id"
function _get_mybox_node_path(){
    local node_name="$1"
    if [ -z ${node_name} ]; then
        node_name="${MYBOX}_${DEFAULT_NODE}"
    fi
    echo "${BOXFOLDER}/nodes/${node_name}/vbox/id"
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
    if [[ ! $(_check_vm_exist "$vm_name") ]]; then
        _err_vm_not_found $vm_name
        exit; 
    fi  
    echo start VM \"${vm_name}\" ...
    vbox_guestssh_setup ${vm_name} 2300
    vbox_start_vm ${vm_name} #"headless"


}
# Path like this ./.mybox/nodes/<node_name>/vbox/id
function start_node(){
    local node_name="$1"
    local box_name="$2"
    local id_file="$(_get_mybox_node_path $node_name)"
    local vm_id=""

    if [[ -f "${id_file}" ]]; then 
        vm_id="$(cat "$id_file"|awk '{print $2}'|sed s'/{//'|sed s'/}//')"
    fi;

    if [[ ! -z "${vm_id}" ]]; then
        start_vm ${vm_id}
    else
        if [[ -z "$box_name" ]];then
            echo "BOX name is not set, can't do import. exit"
            exit 1
        fi
        import "$box_name" "$node_name"
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
    _check_status
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
function usage_ini(){
    _print_usage "init [box_name]"
}
function usage_package(){
    _print_usage "package <box_name> [vm_name]"
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
            init*)
                shift
                init "$@"
                ;;
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