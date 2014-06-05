. ./_test_create_vm_common.sh
. ./create_vm.sh

# The ks.cfg file of centos can work with redhat directly.
#
function main(){
    NAME=ubuntu-14.04-server-amd64
    TYPE=Ubuntu_64
    INSTALLER="/d/ISO/ubuntu/14.04/ubuntu-14.04-server-amd64.iso"
    GUESTADDITIONS="/c/Program Files/Oracle/VirtualBox/VBoxGuestAdditions.iso"
    KS_CFG="ks_centos.cfg"
    main_template
}

function create_pxecfg_ubuntu-14.04-server-amd64() {
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
    KERNEL /$NAME/install/netboot/ubuntu-installer/amd64/linux
    APPEND vga=788 initrd=/$NAME/install/netboot/ubuntu-installer/amd64/initrd.gz ks=${ks} -- quiet 
EOL
}
main
