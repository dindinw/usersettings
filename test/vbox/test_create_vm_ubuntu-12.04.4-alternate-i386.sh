. ./_test_create_vm_common.sh
. ./create_vm.sh

# The ks.cfg file of centos can work with redhat directly.
#
function main(){
    NAME=ubuntu-12.04.4-alternate-i386
    TYPE=Ubuntu
    INSTALLER="/d/ISO/ubuntu/12.04/ubuntu-12.04.4-alternate-i386.iso"
    GUESTADDITIONS="/c/Program Files/Oracle/VirtualBox/VBoxGuestAdditions.iso"
    KS_CFG="ks_ubuntu_noupdate.preseed"
    main_template
}

function create_pxecfg_ubuntu-12.04.4-alternate-i386() {
    create_pxecfg_ubuntu-12.04.4-alternate-i386_floppy2 "$1" "$2"
}

function create_pxecfg_ubuntu-12.04.4-alternate-i386_url() {
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
    APPEND vga=788 initrd=/$NAME/install/initrd.gz auto preseed/url=${ks}/preseed.cfg \
        locale=en_US keymap=us \
        interface=eth0 hostname=localhost domain=localdomain --
EOL
}

# it works for 12.04
function create_pxecfg_ubuntu-12.04.4-alternate-i386_floppy() {
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

# add ks , not work
function create_pxecfg_ubuntu-12.04.4-alternate-i386_floppy2() {
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
    APPEND vga=788 initrd=/$NAME/install/initrd.gz ks="${ks}/preseed.cfg" auto preseed/file=/floppy/${KS_CFG} \
        locale=en_US keymap=us \
        interface=eth0 hostname=localhost domain=localdomain --
EOL
}

main
