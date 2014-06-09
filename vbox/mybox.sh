#
DIR="$( cd "$( dirname "${BASH_SOURCE}" )" && pwd)"
. $DIR/../lib/core.sh
. func_create_vm.sh


function _err_unknown_opts()
{
    echo "Error : Uknown opts " $@
}

function _err_unknown_command()
{
    echo "Error : Uknown Command " $1
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

# generate a box template from a vbox vm
function package()
{
    
    local vm_name="$1"
    local box="$2"
    if [ ! "$#" -eq 2 ] || [ -z "$vm_name" ] || [ -z "$box" ]; then 
        _err_unknown_opts package $@
        usage_package; exit
    fi
    if [[ -f "$box".box ]]; then
        if [[ $(_confirm "WARNING : BOX \"$box\" already exist, Do you want to overwrite it") -eq 0 ]] ; then
            rm "$box".box
        else
            exit
        fi
    fi
    echo create Box \"${box}\" from VM \"${vm_name}\" ...
    vbox_export_vm $vm_name $box
}

# list all box template
function list(){
    list_vms
}

function list_boxes()
{
    echo "list boxes"
}

function list_vms(){
    vbox_list_vm
}

# init a box by box-template
function init(){
    echo 
}


# remove a vm named 
function remove(){
    local box="$1"
    echo start BOX \"${box}\" ...
}

function start(){
    local box="$1"
    echo start BOX \"${box}\" ...

}

function stop(){
    local box="$1"
    echo stop BOX \"${box}\" ...
}

function usage(){
    #echo "usage all"
    for cmd in "package" "list"
    do 
        usage_$cmd 
    done
}
function usage_package(){
    echo "usage package"
}
function usage_list(){
    echo "usage list"
}

function main(){
    local cmd="$1"
    local opts=$@
    #echo inputs : $opts
    case $cmd in
            package*)
                shift
                package $@
                ;;
            list*)
                shift
                list $@
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