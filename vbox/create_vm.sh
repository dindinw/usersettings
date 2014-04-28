#!/bin/bash

function setup_vars()
{
    NAME=centos65-x86_64
    TYPE=RedHat_64
    INSTALLER="./isos/CentOS-6.5-x86_64-minimal.iso"
    GUESTADDITIONS="./isos/VBoxGuestAdditions_4.3.10.iso"
    HDD="${HOME}/VirtualBox VMs/${NAME}/main.vdi"
    HDD_SWAP="${HOME}/VirtualBox VMs/${NAME}/swap.vdi"
    VBOX_FILE="${HOME}/VirtualBox VMs/${NAME}/${NAME}.vbox"
    VBOX_TFTP_DEFAULT="${HOME}/.VirtualBox/TFTP"
    NATNET=10.0.2.0/24
}

function mount_iso_win(){
    imdisk -l -m "${VBOX_TFTP}/centos-6" 2>&1|grep "^Not" >/dev/null

    if [[ $? -eq 0 ]]; then 
        imdisk -a -f "${INSTALLER}" -m "${VBOX_TFTP}/centos-6"
    fi
}

function umount_iso_win() {
    imdisk -d -m "${VBOX_TFTP}/centos-6"
}

function start_tftp32(){
    # Start TFTPD32
    start tftpd32.exe -i tftpd32.ini

}
function stop_tftp32(){
    tftpd_pid=$(tasklist|grep tftpd32.exe|awk '{print $2}')
    echo the tftpd job is started with pid=$pid
    taskkill //PID $tftpd_pid
}

function create_vm_vbox(){

    VBoxManage createvm --name ${NAME} --ostype ${TYPE} --register

    # NIC Type includes :  [--nictype<1-N> Am79C970A|Am79C973|82540EM|82543GC|82545EM|virtio]
    #     
    VBoxManage modifyvm ${NAME} \
        --vram 12 \
        --accelerate3d off \
        --memory 613 \
        --usb off \
        --audio none \
        --boot1 disk --boot2 net --boot3 none --boot4 none \
        --nictype1 Am79C973 --nic1 nat --natnet1 "${NATNET}" \
        --nattftpfile1 pxelinux.0 \
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
    # Swap is recommended to be double the size of RAM.
    VBoxManage createhd --filename "${HDD_SWAP}" --size 1226

    VBoxManage storagectl ${NAME} \
        --name SATA --add sata --portcount 2 --bootable on

    VBoxManage storageattach ${NAME} \
        --storagectl SATA --port 0 --type hdd --medium "${HDD}"
    VBoxManage storageattach ${NAME} \
        --storagectl SATA --port 1 --type hdd --medium "${HDD_SWAP}"
    VBoxManage storageattach ${NAME} \
        --storagectl SATA --port 2 --type dvddrive --medium "${INSTALLER}"
    VBoxManage storageattach ${NAME} \
        --storagectl SATA --port 3 --type dvddrive --medium "${GUESTADDITIONS}"
}


# Usage:
# VBoxManage startvm  <uuid|vmname> [--type gui|sdl|headless]
function start_vm_vbox(){
    VBoxManage startvm ${NAME} --type gui
}

# Usage:
# VBoxManage controlvm <uuid|vmname> pause|resume|reset|poweroff|savestate|
#                                    acpipowerbutton|acpisleepbutton|
function stop_vm_vbox(){
    VBoxManage controlvm ${NAME} poweroff
}


# Usage:
# VBoxManage modifyvm [--natpf<1-N> [<rulename>],tcp|udp,[<hostip>],<hostport>,[<guestip>],<guestport>]
#                     [--natpf<1-N> delete <rulename>]
function setup_ssh_vbox(){
    VBoxManage modifyvm ${NAME} --natpf1 "guestssh,tcp,,2222,,22"
}


function setup_kickstart_service(){
    IP=`echo ${NATNET} | sed -nE 's/^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}).*/\1/p'`
    KS_CFG=${1:-"ks.cfg"}
    PORT=${2:-"8088"} #default is 8088
    echo 'At the boot prompt, hit <TAB> and then type:'
    echo " ks=http://${IP}.3:${PORT}"
    sh ./httpd.sh ${KS_CFG} | nc -l -p ${PORT} >/dev/null
}

function setup_tftp_folder(){
    #TFTP=${1:-"$VBOX_TFTP_DEFAULT"}
    TFTP=${1:-"$(pwd)/tftp"}

    if [ -e ${TFTP} ]; then
        echo ${TFTP} exist, clean by remove all.
        rm -rf ${TFTP}
    fi
    mkdir -p "${TFTP}/pxelinux.cfg"
    cp -p pxelinux.0 "${TFTP}/."
    create_pxecfg_$2 ${TFTP}/pxelinux.cfg/default ${3}
}

function create_pxecfg_centos6() {
cat > $1 << EOL
default centos6
LABEL centos6
    KERNEL images/centos/5/x86/vmlinuz
    APPEND initrd=images/centos/5/x86_64/initrd.img ks=${2}
EOL
}

function main(){
    setup_vars

}
#. ../lib/core.sh
#main
#setup_vars
#setup_ki#!/bin/sh -eckstart_service ks_centos.cfg
setup_tftp_folder "" "centos6" "http://10.0.2.2:8088"
