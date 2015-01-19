. ./create_vm.sh

function main(){
    NAME=centos66-x86_64
    TYPE=RedHat_64
    INSTALLER="${HOME}/Downloads/CentOS-6.6-x86_64-minimal.iso" 
    GUESTADDITIONS="/Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso"
    KS_CFG="ks_centos66.cfg"
    #KS_CFG="ks_centos-6.6.cfg"
    main_template
}

function create_pxecfg_centos66-x86_64() {
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
    KERNEL $NAME/images/pxeboot/vmlinuz
    APPEND initrd=$NAME/images/pxeboot/initrd.img ks=${ks}
EOL
}

main
