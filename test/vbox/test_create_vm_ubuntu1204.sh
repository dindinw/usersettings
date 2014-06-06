. ./_test_create_vm_common.sh
. ./create_vm.sh

# The ks.cfg file of centos can work with redhat directly.
#
function main(){
    NAME=ubuntu-12.04.4-alternate-i386
    TYPE=Ubuntu
    INSTALLER="/d/ISO/ubuntu/12.04/ubuntu-12.04.4-alternate-i386.iso"
    GUESTADDITIONS="/c/Program Files/Oracle/VirtualBox/VBoxGuestAdditions.iso"
    KS_CFG="ks_centos.cfg"
    main_template
}

function create_pxecfg_ubuntu-12.04.4-alternate-i386() {
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
    APPEND initrd=/$NAME/install/initrd.gz ks=${ks}
EOL
}
main
