# test usage of ovf tool util
# need to install VMware-ovftool-3.5.1-1747221-win.x86_64.msi first to get 'ovftool.exe'
# See https://my.vmware.com/web/vmware/details?productId=353&downloadGroup=OVFTOOL351
#set -x
. _test_vmware_common.sh

SOURCE_OVF_FILE="your_ovf_file_to_import"
VCENTER_PATH="target_path_in_vcenter" #ovftool_find_path will help
VCENTER_DATA_STORAGE="date_storge_to_save_vm_files"
VCENTER_NETWORK="the_network_name_the_vm_is_setup"
VM_NAME="the_name_of_created_vm"
VM_FOLDER="the_folder_existed_in_vcenter_to_hold_the_vm"

if [[ -f _CONFIG_OVERWRITE ]]; then . _CONFIG_OVERWRITE; fi
ovftool_import "$SOURCE_OVF_FILE" "$VCENTER_PATH" "$VCENTER_DATA_STORAGE" "$VCENTER_NETWORK" "$VM_NAME" "$VM_FOLDER"

