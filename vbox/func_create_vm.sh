##########################################
# FLOPPY functions 
##########################################

function floppy_create_win(){
    local floppy="$1"
    echo "creating $floppy and format"
    imdisk -a -f ${floppy} -s 1440K -m x: && cmd //C "format x: /Q"
    echo "umount $floppy"
    imdisk -D -m x:
}

function floppy_copy_file_win() {
    local floppy="$1"
    local file="$2"
    if [ ! -f "${floppy}" ]; then
        echo "floppy image : [ ${floppy} ] not found!"
    fi
    if [ ! -f "${file}" ]; then
        echo "to copy file : [ ${file} ] not found!"
    fi
    echo mount $floppy ...
    imdisk -a -f ${floppy} -m x:
    echo install $file to $floppy
    cmd //c "copy $(to_win_path $file) x:"
    echo "umount $floppy ..."
    imdisk -D -m x:
}


##########################################
# ISO functions 
##########################################

function iso_mount_win(){
    #${ISO_MOUNT_PATH:?"not set"}
    ISO_MOUNT_PATH=$(echo $ISO_MOUNT_PATH)
    
    if [[ -z "${ISO_MOUNT_PATH}" ]]; then
        echo "ERROR: ISO_MOUNT_PATH not set."
        exit 1
    fi

    if [[ ! -e "${ISO_MOUNT_PATH}" ]]; then
        echo "create ${ISO_MOUNT_PATH}"
        if [[ -f "${ISO_MOUNT_PATH}" ]]; then 
            rmdir ${ISO_MOUNT_PATH} #when -e not work, need to rmdir first
        fi
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

function iso_umount_win() {
    echo "umount ${ISO_MOUNT_PATH}" 
    imdisk -d -m "${ISO_MOUNT_PATH}"
    if [[ -e "${ISO_MOUNT_PATH}" ]]; then
        rmdir ${ISO_MOUNT_PATH}
        echo "removed mountpoint : ${ISO_MOUNT_PATH}"
    fi

}

##########################################
# TFTP functions 
##########################################

function tftp_start_win(){
    # Start TFTPD32
    TFTPD32=tftpd32.exe
    TFTPD32_INI=tftpd32.ini

    if [[ ! -e $TFTPD32 ]]; then
        echo "ERROR : $TFTPD32 not found!"
        exit 1
    fi
    start $TFTPD32 -i $TFTPD32_INI

}
function tftp_stop_win(){
    tftpd_pid=$(tasklist|grep $TFTPD32|awk '{print $2}')
    echo "Found the tftpd32 is started with pid=$tftpd_pid"
    taskkill //PID $tftpd_pid
}

function tftp_folder_prepare(){
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

function create_pxecfg_default() {
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

##########################################
# VBOX functions 
##########################################

function vbox_create_vm(){
    local vm_name="$1"
    local vm_type="$2"
    echo Create VM \"${vm_name}\" ... 
    VBoxManage createvm --name ${vm_name} --ostype ${vm_type} --register
    case "$vm_type" in
        RedHat*)
            vbox_create_vm_redhat "${vm_name}" "${vm_type}" 
            ;;
        Ubuntu*)
            vbox_create_vm_ubuntu "${vm_name}" "${vm_type}"
            ;;
        *)
            vbox_creat_vm_linux_default
    esac

}

function vbox_create_vm_redhat(){
    local vm_name="$1"
    local vm_type="$2"
    echo vbox_create_vm_redhat VM \"${vm_name}\" TYPE \"${vm_type}\"
    vbox_creat_vm_linux_default
}
function vbox_create_vm_ubuntu(){
    local vm_name="$1"
    local vm_type="$2"
    echo vbox_create_Vm_ubuntu VM \"${vm_name}\" TYPE \"${vm_type}\"

    vbox_creat_vm_linux_default
    
    # attach floppy to ubuntu, add a late_command.sh 
    
    local floopy="floppy.img"
    if [[ ! -f "${floopy}" ]]; then
        floppy_create_${arch} ${floopy}
    fi
    if [[ -f "late_command.sh" ]]; then
        floppy_copy_file_${arch} ${floopy} "late_command.sh"
    fi
    if [[ -f "${KS_CFG}" ]]; then
        floppy_copy_file_${arch} ${floopy} "${KS_CFG}"
    fi
    vbox_attach_floopy ${vm_name} ${floopy}
}


function vbox_creat_vm_linux_default(){
     # NIC Type includes :  [--nictype<1-N> Am79C970A|Am79C973|82540EM|82543GC|82545EM|virtio]
    # OS type get from commmand : VBoxMange list ostypes
         
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

    VBoxManage storagectl ${NAME} \
        --name SATA --add sata --portcount 2 --bootable on

    VBoxManage storageattach ${NAME} \
        --storagectl SATA --port 0 --type hdd --medium "${HDD}"
    VBoxManage storageattach ${NAME} \
        --storagectl SATA --port 1 --type dvddrive --medium "${INSTALLER}"

}

function vbox_attach_floopy(){
    local vm_name="$1"
    local floppy="$2"
    echo attach \"$floppy\" to VM \"${vm_name}\"

    VBoxManage storagectl ${vm_name} \
        --name "Floppy" --add floppy
    VBoxManage storageattach $NAME --storagectl "Floppy" --port 0 --device 0 --type fdd --medium "${floppy}"
}

function vbox_detach_floopy(){
    local vm_name="$1"
    echo detach floppy from VM \"${vm_name}\"
    VBoxManage storageattach $NAME --storagectl "Floppy" --port 0 --device 0 --type fdd --medium emptydrive
}


# Usage:
# VBoxManage startvm  <uuid|vmname> [--type gui|sdl|headless]
function vbox_start_vm(){
    local vm_name="$1"
    local s_type="$2"
    if [[ -z "$s_type" ]]; then
        #default is GUI
        s_type=gui
    fi
    log_info "Try to start VBox VM \"${vm_name}\" in \"${s_type}\" mode ..."
    VBoxManage startvm ${vm_name} --type ${s_type}
}

# Usage:
# VBoxManage controlvm <uuid|vmname> pause|resume|reset|poweroff|savestate|
#                                    acpipowerbutton|acpisleepbutton|
function vbox_stop_vm(){
    local vm_name="$1"
    log_info Stopping VBOX VM \"${vm_name}\" ...
    VBoxManage controlvm ${vm_name} poweroff
    if [[ $? -eq 0 ]]; then
        log_info VM \"${vm_name}\" has been successfully stopped.
    fi
}

function vbox_delete_vm(){
    local vm_name=$1
    log_info "Delete VBOX VM \"${vm_name}\" ..."
    VBoxManage unregistervm "$vm_name" --delete
    local ret=$?
    if [[ $ret -eq 0 ]]; then
        log_info VM \"${vm_name}\" has been successfully deleted.
    fi
    return $ret
}

function vbox_show_vm_info()
{
    local vm_name="$1"
    shift
    local opts="$@"
    log_debug "VBOX_CMD VBoxManage showvminfo $vm_name $opts"
    eval VBoxManage showvminfo "$vm_name $opts"
}

function vbox_show_vm_info_machinereadable()
{
    vbox_show_vm_info "$1" "--machinereadable"
}

function vbox_modifyvm(){
    local vm_name="$1"
    log_debug "VBoxManage modifyvm ${vm_name} $2 $3"
    VBoxManage modifyvm ${vm_name} $2 $3
}


# Usage:
# VBoxManage modifyvm [--natpf<1-N> [<rulename>],tcp|udp,[<hostip>],<hostport>,[<guestip>],<guestport>]
#                     [--natpf<1-N> delete <rulename>]
function vbox_guestssh_setup(){
    local vm_name="$1"
    local port="$2"
    local rule_name="$3"
    if [[ -z "$port" ]]; then port=2222; fi;
    if [[ -z "$rule_name" ]]; then rule_name="guestssh"; fi;
    log_info "Setup ssh service to VM \"${vm_name}\" ..."
    VBoxManage modifyvm ${vm_name} --natpf1 "${rule_name},tcp,,${port},,22"
}

function vbox_guestssh_remove(){
    local vm_name="$1"
    local rule_name="$2"
    if [[ -z "$rule_name" ]]; then rule_name="guestssh"; fi;
    log_info "Remove guest ssh service to VM \"${vm_name}\" ..."
    VBoxManage modifyvm "${vm_name}" --natpf1 delete "$rule_name"
}

function vbox_wait_vm_shutdown() {
    local vm_id="$1"
    while VBoxManage list runningvms | grep "${vm_id}" >/dev/null; do
        sleep 1
        echo -n "."
    done
    echo ""
}

function vbox_wait_vm_started() {
    local vm_id="$1"
    local max_sec="$2"
    local count=0
    while ! VBoxManage list runningvms | grep "${vm_id}" >/dev/null; do
        sleep 1
        echo -n "."
        let count=count+1
        if [[ $count -gt $max_sec ]]; then
            return 1
        fi
    done
    echo ""

}
# install virtualbox guest additions by using vagrant ssh
function vbox_install_guestadditions(){

    curl --output mybox_id_rsa -L "https://raw.githubusercontent.com/dindinw/usersettings/master/vbox/keys/mybox"
    if [[ -f mybox_id_rsa ]]; then
        chmod 600 mybox_id_rsa
        ssh -i mybox_id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p 2222 mybox@127.0.0.1 "sudo mount /dev/cdrom /media/cdrom; sudo sh /media/cdrom/VBoxLinuxAdditions.run; sudo umount /media/cdrom; sudo shutdown -h now"
    fi
}

function vbox_attach_iso(){
    local vm_name="$1"
    local iso="$2"
    VBoxManage storageattach ${vm_name} \
        --storagectl SATA --port 1 --type dvddrive --medium "${iso}"
}

function vbox_detach_iso(){
    local vm_name="$1"
    VBoxManage storageattach ${vm_name} \
        --storagectl SATA --port 1 --type dvddrive --medium emptydrive
}

function vbox_export_vm(){
    local vm_name="$1"
    local box="$2"
    echo "export VM \"${vm_name}\" to \"${box}\"..."
    VBoxManage export ${vm_name} --output ${box}".ovf"
}

function vbox_import_ovf(){
    log_debug $FUNCNAME $@
    local ovf_file="$1"
    local vm_name="$2"

    if [[ -z "$vm_name" ]] || _check_vm_exist $vm_name; then
        return 1 
    fi
    local opts="--vsys 0 --vmname $vm_name"
    
    IFS=$'\n'
    local count=1
    for disk in $(VBoxManage import ${ovf_file} --dry-run 2>&1|grep "disk path"|awk -F "\"" '{print $2}'|sed s'/--vsys 0//'|sed s'/ path//')
    do 
        opts="$opts $disk \"${VBOX_VM_HOME}/$vm_name/disk$count.vmdk\""
        let count=count+1
    done
    unset IFS

    log_debug "The Vbox Import OPTS : [ $opts ]"
   
    if [[ -z "$3" ]]; then
        # the default, run directly and ignore output
        log_debug "VBoxManage import ${ovf_file} ${opts} --options keepnatmacs"
        eval VBoxManage import ${ovf_file} ${opts} --options keepnatmacs > /dev/null
    elif [[ "$3" == "--confirm" ]]; then
        # if dry-run
        eval VBoxManage import ${ovf_file} ${opts} --options keepnatmacs --dry-run
        if confirm "are your sure to import "; then
            eval VBoxManage import ${ovf_file} ${opts} --options keepnatmacs
        fi
    fi
    return $?
}

function vbox_list_vm(){
    VBoxManage list vms
}

function vbox_list_running_vms(){
    VBoxManage list runningvms
}




# NOT_IN_USE
# The orignal kisckstar is a web service set up in host machine, when guest boot
# ks=http://10.0.2.3:8088 will be called. 
# The way is not work for ubuntu linux, use floopy image with ks file installed instead
function start_kickstart_service(){
    local ip=${1:-$IP}
    local port=${2:-$PORT} #default is 8088
    local cfg=${3:-$KS_CFG} #default is ks.cfg
    echo 'At the boot prompt, hit <TAB> and then type:'
    echo " ks=http://${ip}:${port}"
    sh ./httpd.sh ${cfg} | nc -l -p ${port} > /dev/null
 }





