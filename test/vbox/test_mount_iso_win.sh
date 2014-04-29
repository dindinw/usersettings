. ./_test_create_vm_common.sh

INSTALLER="../../vagrant-centos/isos/CentOS-6.5-x86_64-minimal.iso"
ISO_MOUNT_PATH="$(pwd)/tftp/centos65-x86_64"

mount_iso_win
sleep 1
umount_iso_win