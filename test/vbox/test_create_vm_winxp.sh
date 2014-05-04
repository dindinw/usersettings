. ./_test_create_vm_common.sh
. ./create_vm.sh

# The ks.cfg file of centos can work with redhat directly.
#
function start_tftp_win(){
    # overwrriten the default version
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
        --memory 613 \
        --usb off \
        --audio none \
        --boot1 disk --boot2 net --boot3 none --boot4 none \
        --nictype1 Am79C973 --nic1 nat --natnet1 "${NATNET}" \
        --nattftpfile1 pxeserva.0 \
        --nattftpserver1 10.0.2.2 \
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

    VBoxManage createhd --filename "${HDD}" --size 8192

    VBoxManage storagectl ${NAME} \
        --name IDE --add ide

    VBoxManage storageattach ${NAME} \
        --storagectl IDE --port 0 --device 0 --type hdd --medium "${HDD}"
    VBoxManage storageattach ${NAME} \
        --storagectl IDE --port 1 --device 0 --type dvddrive --medium "${INSTALLER}"
    VBoxManage storageattach ${NAME} \
        --storagectl IDE --port 0 --device 1 --type dvddrive --medium "${GUESTADDITIONS}"
}

function main(){
    NAME=windowsxp-sp3-test
    TYPE=WindowsXP
    INSTALLER="/d/ISO/windows/WinXP-SP3.iso"
    GUESTADDITIONS="../../vagrant-centos/isos/VBoxGuestAdditions_4.3.10.iso"
    KS_CFG="ks_centos.cfg"
    main_template
}


function create_pxecfg_windowsxp-sp3-test() {
    echo call create_pxecfg_centos6 $1 $2
    create_pxecfg_centos6 "$1" "$2-"
}
main
