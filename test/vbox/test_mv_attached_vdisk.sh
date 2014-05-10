
function list_vm() {
    VBoxManage list vms
}

function list_storge(){
    VBoxManage list hdds
}

function show_vm() {
    local vm_name="$1"
    VBoxManage showvminfo $vm_name --machinereadable
}

function list_vdi() {
    show_vm $1 |grep vdi
}

function stop_vm() {
    VBoxManage controlvm $1 poweroff
}

function is_poweroff() {
    VBoxManage showvminfo $1 --machinereadable |grep poweroff
}

function mv_vdisk(){
    list_vdi $1
    if [ ! $? -eq 0 ]; then
        echo "ERROR : no attached vdi found in VM $1"
    fi
    local $UUID=$2
    list_storge | grep $UUID
    if [ ! $? -eq 0 ]; then
        echo "ERROR : no hdd found by $UUID"
        exit
    fi

    is_poweroff $1 || stop_vm $1
    old_vdi_path=$(list_vdi $1 |awk -F'=' '{print $2}'|sed 's/"//g')
    if [ -f $old_vdi_path ]; then 
        echo ERROR: not vdi found!
        exit 1
    fi
    vdi_file=${old_vdi_path##*\\}
    new_vdi_path=$2\\${vdi_file}
    echo Old Virtual Disk File path is $old_vdi_path
    echo New Virtual Disk File path is $new_vdi_path
    # Note
    # Get 'cp: cannot lseek' error when file size over 2GB. don't use mingw cp for this
    # cp -p "${old_vdi_path}" "${new_vdi_path}"
    if [ -f $new_vdi_path ]; then
        echo Warning: $new_vdi_path exist.
    else
        start //wait cmd /c copy "${old_vdi_path}" "${new_vdi_path}" && echo "copy done!"
    fi
    show_vm $1

    VBoxManage storageattach $1 \
        --storagectl "SATA Controller" --port 0 --type hdd --medium none

    VBoxManage closemedium disk $UUID 

    VBoxManage storageattach $1 \
       --storagectl "SATA Controller" --port 0 --type hdd --medium "${new_vdi_path}"

    VBoxManage startvm $1 --type gui

}
list_vm
list_storge
#mv_vdisk "ubuntu-12.04" 9092aad6-ac6f-4088-a186-7a057b2fd33e "E:\Ubuntu\12.04"
