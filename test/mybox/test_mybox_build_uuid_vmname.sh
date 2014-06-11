cd ../../vbox
. mybox.sh

function test_build_uuid(){
local vm_name=$(_build_uni_vm_name $1)
echo $vm_name
}
test_build_uuid
test_build_uuid "test"