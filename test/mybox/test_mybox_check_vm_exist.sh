cd ../../vbox
. mybox.sh

function test_vm_exist()
{
    local vm_name="$1"
    if [[ $(_check_vm_exist "$vm_name") ]]; then
        echo $vm_name exist
    else 
        echo $vm_name not exist
    fi
}

for vm in "test" "test1" "test2"
do test_vm_exist $vm ; done
