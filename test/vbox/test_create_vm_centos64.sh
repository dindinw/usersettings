. ./_test_create_vm_common.sh
. ./create_vm.sh

function main(){
    NAME=centos65-x86_64
    TYPE=RedHat_64
    INSTALLER="../../vagrant-centos/isos/CentOS-6.5-x86_64-minimal.iso"
    GUESTADDITIONS="../../vagrant-centos/isos/VBoxGuestAdditions_4.3.10.iso"
    KS_CFG="ks_centos.cfg"
    main_template
}

function create_pxecfg_centos65-x86_64() {
    echo call create_pxecfg_centos6 $1 $2
    create_pxecfg_default "$1" "$2"
}
main
