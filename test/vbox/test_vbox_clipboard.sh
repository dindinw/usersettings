NAME=windowsxp-sp3-xp_mode

# design time
VBoxManage modifyvm ${NAME} --clipboard bidirectional

# runtime
VBoxManage controlvm ${NAME} clipboard bidirectional