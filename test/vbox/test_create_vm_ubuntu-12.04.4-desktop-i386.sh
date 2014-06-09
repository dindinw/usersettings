. ./_test_create_vm_common.sh
. ./create_vm.sh

# The ks.cfg file of centos can work with redhat directly.
#
function main(){
    NAME=ubuntu-12.04.4-desktop-i386
    TYPE=Ubuntu
    #Note: You need to use alternate iso, since destop ISO don't support tftp boot.
    INSTALLER="/d/ISO/ubuntu/12.04/ubuntu-12.04.4-alternate-i386.iso"
    GUESTADDITIONS="/c/Program Files/Oracle/VirtualBox/VBoxGuestAdditions.iso"
    KS_CFG="ubuntu-12.04.4-desktop-amd64.preseed.cfg"
    main_template
}

function create_pxecfg_ubuntu-12.04.4-desktop-i386() {
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
    KERNEL /$NAME/install/vmlinuz
    APPEND vga=788 initrd=/$NAME/install/initrd.gz auto preseed/file=/floppy/${KS_CFG} \
        locale=en_US keymap=us \
        interface=eth0 hostname=localhost domain=localdomain --
EOL
}

main
