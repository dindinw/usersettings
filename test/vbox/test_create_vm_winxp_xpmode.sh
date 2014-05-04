. ./_test_create_vm_common.sh
. ./create_vm.sh

# The ks.cfg file of centos can work with redhat directly.
#
function start_tftp_win(){
    # overwrriten the default version
    echo "do nothing"
}
function  mount_iso_win() {
    echo "do nothing"
}
function setup_tftp_folder() {
    echo "do nothing"
}
function setup_kickstart_service() {
    echo "do nothing"
}
function umount_iso_win() {
    echo "do nothing"
}
function stop_tftp_win() {
    echo "do nothing"
}

# overwirtten version 
function create_vm_vbox(){

    VBoxManage createvm --name ${NAME} --ostype ${TYPE} --register

    # NIC Type includes :  [--nictype<1-N> Am79C970A|Am79C973|82540EM|82543GC|82545EM|virtio]
    # OS type get from commmand : VBoxMange list ostypes

    # WinXP Notes: 
    # 1.) NIC must Am79C973
    # 2.) storage muse IDE
         
    VBoxManage modifyvm ${NAME} \
        --vram 12 \
        --accelerate3d off \
        --memory 512 \
        --usb off \
        --audio none \
        --boot1 disk --boot2 net --boot3 none --boot4 none \
        --nictype1 Am79C973 --nic1 nat --natnet1 "${NATNET}" \
        --nictype2 virtio \
        --nictype3 virtio \
        --nictype4 virtio \
        --acpi on --ioapic off \
        --chipset piix3 \
        --rtcuseutc on \
        --hpet on \
        --bioslogofadein off \
        --bioslogofadeout off \
        --bioslogodisplaytime 0 \
        --biosbootmenu disabled

    VBoxManage storagectl ${NAME} \
        --name IDE --add ide

    VBoxManage storageattach ${NAME} \
        --storagectl IDE --port 0 --device 0 --type hdd --medium "${HDD}"
    VBoxManage storageattach ${NAME} \
        --storagectl IDE --port 1 --device 0 --type dvddrive --medium "${GUESTADDITIONS}"

    VBoxManage storagectl ${NAME} \
        --name "Floppy" --add floppy
    VBoxManage storageattach $NAME --storagectl "Floppy" --port 0 --device 0 --type fdd --medium "C:\Users\yidwu\Downloads\floppy01.img"

    VBoxManage setextradata ${NAME} "VBoxInternal/Devices/pcbios/0/Config/BiosRom" "C:\Users\yidwu\Downloads\pcbios.bin"
}

# no need to do this, since winnt.sif is not work in the case
function create_unattened_floppy(){
    dd bs=512 count=2880 if=/dev/zero of=~/works/floppy01.img
    /sbin/mkfs.msdos ~/works/floppy01.img
    mount -o loop ~/works/floppy01.img /mnt
    cp winnt.sif /mnt
}

function modify_vhd(){
    devio 9999 /c/Users/yidwu/Downloads/VirtualXPVHD 1 1
    imdisk -a -t proxy -o ip -f 127.0.0.1:9999 -m L: -S 512
    #cp  ? /l/?/?
    imdisk -d -m L:
}

function extract_vhd(){
    rm -f /c/Users/yidwu/Downloads/VirtualXPVHD
    7z e /d/ISO/windows/WindowsXPMode_N_en-us.exe sources/xpm -o"C:\\Users\\yidwu\\Downloads\\" -y
    7z e /c/Users/yidwu/Downloads/xpm VirtualXPVHD -o"C:\\Users\\yidwu\\Downloads\\" -y
    rm -f /c/Users/yidwu/Downloads/xpm
}

function main(){
    main_template
}
function clean(){
    VBoxManage showvminfo ${NAME} --machinereadable|grep ^VMState=\"poweroff\"
    if [[ $? -eq 1 ]]; then
        echo "try to shutdown ${NAME}"
        VBoxManage controlvm ${NAME} poweroff
        sleep 1
    fi
    VBoxManage storageattach ${NAME} \
        --storagectl IDE --port 0 --device 0 --type hdd --medium none 
    VBoxManage unregistervm ${NAME} --delete
}

NAME=windowsxp-sp3-xp_mode
TYPE=WindowsXP
GUESTADDITIONS="../../vagrant-centos/isos/VBoxGuestAdditions_4.3.10.iso"
HDD="/c/Users/yidwu/Downloads/VirtualXPVHD"
INSTALLER="/d/ISO/windows/WinXP-SP3.iso"
KS_CFG="ks_centos.cfg"

if [[ -z "$1" ]]; then
    main
elif [[ "$1" == "clean" ]]; then
    clean
elif [[ "$1" == "extract" ]]; then
    extract_vhd
fi

