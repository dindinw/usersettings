function setup_vars() 
{
    NAME=${NAME:-"NOSET"}
    TYPE=${TYPE:-"NOSET"}
    INSTALLER=${INSTALLER:-"NOSET"}

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

    HDD="${HOME}/VirtualBox VMs/${NAME}/main.vdi"
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


function mount_iso_win(){
    #${ISO_MOUNT_PATH:?"not set"}
    ISO_MOUNT_PATH=$(echo $ISO_MOUNT_PATH)
    
    if [[ -z "${ISO_MOUNT_PATH}" ]]; then
        echo "ERROR: ISO_MOUNT_PATH not set."
        exit 1
    fi

    if [[ ! -e "${ISO_MOUNT_PATH}" ]]; then
        echo "create ${ISO_MOUNT_PATH}"
        rmdir ${ISO_MOUNT_PATH} #when -e not work, need to rmdir first
        mkdir -p ${ISO_MOUNT_PATH}
    fi
    
    imdisk -l -m "${ISO_MOUNT_PATH}" 2>&1|grep "^Not"

    if [[ $? -eq 0 ]]; then
        echo "mount iso ${INSTALLER} to ${ISO_MOUNT_PATH}" 
        imdisk -a -f "${INSTALLER}" -m "${ISO_MOUNT_PATH}"
    else
        echo "WARNING: ${ISO_MOUNT_PATH} already mounted"
        local info=$(imdisk -l -m "${ISO_MOUNT_PATH}")
        echo -e $info
    fi
}

function umount_iso_win() {
    echo "umount ${ISO_MOUNT_PATH}" 
    imdisk -d -m "${ISO_MOUNT_PATH}"
    if [[ -e "${ISO_MOUNT_PATH}" ]]; then
        rmdir ${ISO_MOUNT_PATH}
        echo "removed mountpoint : ${ISO_MOUNT_PATH}"
    fi

}

function start_tftp_win(){
    # Start TFTPD32
    TFTPD32=tftpd32.exe
    TFTPD32_INI=tftpd32.ini

    if [[ ! -e $TFTPD32 ]]; then
        echo "ERROR : $TFTPD32 not found!"
        exit 1
    fi
    start $TFTPD32 -i $TFTPD32_INI

}
function stop_tftp_win(){
    tftpd_pid=$(tasklist|grep $TFTPD32|awk '{print $2}')
    echo "Found the tftpd32 is started with pid=$tftpd_pid"
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
    local ip=${1:-$IP}
    local port=${2:-$PORT} #default is 8088
    local cfg=${3:-$KS_CFG} #default is ks.cfg
    echo 'At the boot prompt, hit <TAB> and then type:'
    echo " ks=http://${ip}:${port}"
    sh ./httpd.sh ${cfg} | nc -l -p ${port} > /dev/null
 }

function setup_tftp_folder(){
    #TFTP=${1:-"$VBOX_TFTP_DEFAULT"}
    local tftp_path=${1:-"$TFTP_PATH"}
    local ks=${2:-"http://$IP:$PORT"}

    if [[ -e "${tftp_path}" ]]; then
        echo ${tftp_path} exist, clean ${tftp_path}/pxelinux.cfg folder.
        rm -rf "${tftp_path}/pxelinux.cfg"
    fi
    mkdir -p "${tftp_path}/pxelinux.cfg"
    cp -p pxelinux.0 "${tftp_path}/."
    create_pxecfg "$NAME" "${tftp_path}/pxelinux.cfg/default" "${ks}"
}

function create_pxecfg() {
    
    local call=${1:-"NOSET"}
    local pxecfg_path=${2:-"$TFTP_PATH/pexlinux.cfg/defulat"}
    local ks=${3:-"http://$IP:$PORT"}

    if [[ "$call" == "NOSET" ]]; then
        call=${NAME:-"NOSET"}
        echo call is $call 
        if [[ "$call" == "NOSET" ]]; then
            echo -e "ERROR: \$NAME not set."
            exit 1
        fi
    fi
    create_pxecfg_${call} $pxecfg_path $ks
}

function create_pxecfg_centos6() {
    local cfg_file=${1:-"NOSET"}
    local ks=${2:-"NOSET"}
    if [[ $cfg_file == "NOSET" ]]; then
        echo "pxecfig is not set."
        exit 1
    fi
    if [[ $ks == "NOSET" ]]; then
        echo "ks is not set."
        exit 1
    fi
cat > $cfg_file << EOL
default $NAME
LABEL $NAME
    KERNEL /$NAME/images/pxeboot/vmlinuz
    APPEND initrd=/$NAME/images/pxeboot/initrd.img ks=${ks}
EOL
}
