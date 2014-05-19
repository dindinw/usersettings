NAME=windowsxp-sp3-xp_mode

# Add
VBoxManage sharedfolder add ${NAME} --name "DOWN" --hostpath "${HOME}\Downloads" --transient

# remove
VBoxManage sharedfolder remove ${NAME} --name "DOWN" --transient