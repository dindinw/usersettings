. ./_test_create_vm_common.sh

NAME=centos65-x86_64
TYPE=RedHat_64
INSTALLER="../../vagrant-centos/isos/CentOS-6.5-x86_64-minimal.iso"
GUESTADDITIONS="../../vagrant-centos/isos/VBoxGuestAdditions_4.3.10.iso"
KS_CFG="ks_centos.cfg"
    
setup_vars

setup_kickstart_service