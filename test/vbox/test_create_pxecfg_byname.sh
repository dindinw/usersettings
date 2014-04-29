. ./_test_create_vm_common.sh

function main(){
    NAME=centos65-x86_64
    TYPE=RedHat_64
    INSTALLER="../../vagrant-centos/isos/CentOS-6.5-x86_64-minimal.iso"
    setup_vars
}
function create_pxecfg_centos65-x86_64() {
   echo create_pxecfg_centos6 $1 $2 $3 $4
}
main
create_pxecfg
