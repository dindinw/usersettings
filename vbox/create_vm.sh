#!/bin/bash
. ../lib/core.sh
. ./func_create_vm.sh

function host_arch_setup() 
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

function setup_vars() 
{
    NAME=${NAME:-"NOSET"}
    TYPE=${TYPE:-"NOSET"}
    INSTALLER=${INSTALLER:-"NOSET"}

    check_vars
    
    if [[ -z "${HDD}" ]]; then
        HDD="${HOME}/VirtualBox VMs/${NAME}/main.vdi"
    fi
    HDD_SWAP="${HOME}/VirtualBox VMs/${NAME}/swap.vdi"
    VBOX_FILE="${HOME}/VirtualBox VMs/${NAME}/${NAME}.vbox"
    VBOX_TFTP_DEFAULT="${HOME}/.VirtualBox/TFTP"
    NATNET=10.0.2.0/24
    PORT=${PORT:-"8088"} #default is 8088
    IP=`echo ${NATNET} | sed -nE 's/^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}).*/\1/p'`
    IP=${IP}.3 #default is 10.0.2.3
    KS_CFG=${KS_CFG:-"ks.cfg"} #default is ks.cfg
    TFTP_PATH=${TFTP_PATH:-$(pwd)/tftp}
    ISO_MOUNT_PATH=${ISO_MOUNT_PATH:-"$TFTP_PATH/$NAME"}

    echo "HOST ARCH      : ${arch}"
    echo "VM NAME        : ${NAME}"
    echo "VM TYPE        : ${TYPE}"
    echo "VM INSTALLER   : ${INSTALLER}"
    echo "GUESTADDITIONS : ${GUESTADDITIONS}"
    echo "HDD            : ${HDD}"
    echo "HDD_SWAP       : ${HDD_SWAP}"
    echo "VBOX_FILE      : ${VBOX_FILE}"
    echo "TFTP_PATH      : ${TFTP_PATH}"
    echo "HOST KS SERV   : ${IP}:${PORT}"
    echo "KS CFG FILE    : ${KS_CFG}"
    echo "ISO_MOUNT_PATH : ${ISO_MOUNT_PATH}"
}

function check_vars(){

    if [[ $NAME == "NOSET" || $TYPE == "NOSET" || $INSTALLER == "NOSET" ]]; then
        echo -e "check vars fails : make sure \$NAME \$TYPE \$INSTALLER are set."
        exit 1
    fi

    if [[ ! -e  "$INSTALLER" ]]; then
        echo -e "ERROR: $INSTALLER not exist."
        exit 1
    fi
    
    GUESTADDITIONS=${GUESTADDITIONS:-"./isos/VBoxGuestAdditions_4.3.10.iso"}
    if [[ ! -e  "$GUESTADDITIONS" ]]; then
        echo -e "ERROR: $GUESTADDITIONS not exist."
        exit 1
    fi
}


function main_template(){
    
    # prepare arch and vars
    host_arch_setup
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

    echo "Install Vbox GUESTADDITIONS into VM \"${NAME}\" ..."
    vbox_guestssh_setup ${NAME}
    vbox_attach_iso ${NAME} "${GUESTADDITIONS}"
    vbox_start_vm ${NAME}
    vbox_install_guestadditions
    vbox_wait_vm_shutdown ${NAME}
    vbox_guestssh_remove ${NAME}
    vbox_detach_iso ${NAME}
    
}


