. ./_test_create_vm_common.sh
. ./create_vm.sh

# The ks.cfg file of centos can work with redhat directly.
#
function main(){
    NAME=rhel-server-6.4-x86_64
    TYPE=RedHat_64
    INSTALLER="/d/ISO/redhat/rhel-server-6.4-x86_64-dvd.iso"
    GUESTADDITIONS="../../vagrant-centos/isos/VBoxGuestAdditions_4.3.10.iso"
    KS_CFG="ks_centos.cfg"
    main_template
}

function create_pxecfg_rhel-server-6.4-x86_64() {
    echo call create_pxecfg_centos6 $1 $2
    create_pxecfg_centos6 "$1" "$2-"
}
main
