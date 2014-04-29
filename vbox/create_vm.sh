#!/bin/bash
. ../lib/core.sh
. ./func_create_vm.sh
function arch_setup() 
{
    if [[ $OS == "UNKNOWN" ]]; then echo ERROR; exit -1; fi
    if [[ "$OS" == "$OS_LINUX" ]]; then
        readonly arch="linux"
    elif [[ "$OS" == "$OS_MAC" ]]; then
        readonly arch="mac"
    elif [[ "$OS" == "$OS_WIN" ]]; then
        readonly arch="win"
    fi
}

function main_template(){
    arch_setup
    setup_vars
    start_tftp_$arch
    mount_iso_$arch
    create_vm_vbox
    setup_ssh_vbox
    setup_tftp_folder 
    start_vm_vbox
    setup_kickstart_service
    umount_iso_$arch
    stop_tftp_$arch
}


