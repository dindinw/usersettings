. ./_test_create_vm_common.sh
. ./create_vm.sh

function main(){
    NAME=centos65-x86_64
    TYPE=RedHat_64
    INSTALLER="../../vagrant-centos/isos/CentOS-6.5-x86_64-minimal.iso"
    GUESTADDITIONS="/c/Program Files/Oracle/VirtualBox/VBoxGuestAdditions.iso"
    KS_CFG="ks_centos.cfg"
    
     # prepare vars
    setup_vars 

    # prepare tftp and start
    iso_mount_$arch
    tftp_folder_prepare
    tftp_start_$arch

    # prepare vbox
    vbox_create_vm ${NAME} ${TYPE}


    # start vbox vm
    vbox_start_vm ${NAME}
    
    # kickstart service is so a marker for if tftp load is finished
    start_kickstart_service
    
    # stop tftp and umount iso
    tftp_stop_$arch
    iso_umount_$arch

    echo "Waiting for OS installion for VM \"${NAME}\" to finish ..."
    vbox_wait_vm_shutdown ${NAME}
}

function create_pxecfg_centos65-x86_64() {
    echo call create_pxecfg_centos6 $1 $2
    create_pxecfg_default "$1" "$2"
}
main
