. ./_test_create_vm_common.sh
. ./create_vm.sh

# The ks.cfg file of centos can work with redhat directly.
#
function main(){
    NAME=ubuntu-14.04-server-amd64
    TYPE=Ubuntu_64
    INSTALLER="/d/ISO/ubuntu/14.04/ubuntu-14.04-server-amd64.iso"
    GUESTADDITIONS="/c/Program Files/Oracle/VirtualBox/VBoxGuestAdditions.iso"
    KS_CFG="ks_ubuntu.preseed"
    main_template
}

function create_pxecfg_ubuntu-14.04-server-amd64() {
    create_pxecfg_ubuntu-14.04-server-amd64_worked "$1" "$2"
}

function create_pxecfg_ubuntu-14.04-server-amd64_worked() {
    local cfg_file="$1"
    local ks="$2"

cat > $cfg_file << EOL
default $NAME
LABEL $NAME
    KERNEL /$NAME/install/vmlinuz
    APPEND vga=788 initrd=/$NAME/install/initrd.gz auto preseed/url=${ks}/${KS_CFG} \
        locale=en_US keymap=us \
        interface=eth0 hostname=localhost domain=localdomain --
EOL
}
main


























########################
# Some testing backup
########################
function create_pxecfg_ubuntu-14.04-server-amd64_url() {
    local cfg_file=${1:-"NOSET"}
    if [[ $cfg_file == "NOSET" ]]; then
        echo "pxecfig is not set."
        exit 1
    fi
cat > $cfg_file << EOL
default $NAME
LABEL $NAME
    KERNEL /$NAME/install/vmlinuz
    APPEND vga=788 initrd=/$NAME/install/initrd.gz auto preseed/url=http://10.0.2.3:8088/ks_ubuntu.preseed \
        locale=en_US console-keymaps-at/keymap=us \
        interface=eth0 hostname=localhost domain=localdomain --
EOL
}

function create_pxecfg_ubuntu-14.04-server-amd64_withks_normal() {
    local cfg_file=${1:-"NOSET"}
    if [[ $cfg_file == "NOSET" ]]; then
        echo "pxecfig is not set."
        exit 1
    fi
cat > $cfg_file << EOL
default $NAME
LABEL $NAME
    KERNEL /$NAME/install/vmlinuz
    APPEND file=/floppy/${KS_PRESEED} vga=788 initrd=/$NAME/install/initrd.gz ks=floppy:/${KS_CFG}
EOL
}

function create_pxecfg_ubuntu-14.04-server-amd64_withoutks_normal() {
    local cfg_file=${1:-"NOSET"}
    if [[ $cfg_file == "NOSET" ]]; then
        echo "pxecfig is not set."
        exit 1
    fi
cat > $cfg_file << EOL
default $NAME
LABEL $NAME
    KERNEL /$NAME/install/vmlinuz
    APPEND file=/floppy/${KS_PRESEED} vga=788 initrd=/$NAME/install/initrd.gz
EOL
}


function create_pxecfg_ubuntu-14.04-server-amd64_withoutks() {
    local cfg_file=${1:-"NOSET"}
    if [[ $cfg_file == "NOSET" ]]; then
        echo "pxecfig is not set."
        exit 1
    fi
cat > $cfg_file << EOL
default $NAME
LABEL $NAME
    KERNEL /$NAME/install/netboot/ubuntu-installer/amd64/linux
    APPEND file=/floppy/${KS_PRESEED} vga=788 initrd=/$NAME/install/netboot/ubuntu-installer/amd64/initrd.gz
EOL
}

function create_pxecfg_ubuntu-14.04-server-amd64_withks() {
    local cfg_file=${1:-"NOSET"}
    if [[ $cfg_file == "NOSET" ]]; then
        echo "pxecfig is not set."
        exit 1
    fi
cat > $cfg_file << EOL
default $NAME
LABEL $NAME
    KERNEL /$NAME/install/netboot/ubuntu-installer/amd64/linux
    APPEND file=/floppy/${KS_PRESEED} vga=788 initrd=/$NAME/install/netboot/ubuntu-installer/amd64/initrd.gz ks=floppy:/${KS_CFG}
EOL
}
