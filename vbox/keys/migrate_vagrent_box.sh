KEY_PUB_VAGRANT="https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub"
KEY_PRV_VAGRANT="https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant"

if [[ ! -f ./vagrant ]]; then
	curl -s -L $KEY_PRV_VAGRANT -O
fi
port=$1

if [[ -z $1 ]]; then
	#default port for mybox when testing
	port=2251
fi

SCRIPT="mybox_setup.sh"
mybox=$(cat ./mybox.pub)
cat <<EOF > $SCRIPT
# Create mybox user
cat /etc/passwd |grep ^mybox:
if [[ $? -eq 0 ]]; then
	deluser mybox --remove-home
fi
cat /etc/group |grep ^mybox:
if [[ ! $? -eq 0 ]]; then
	delgroup mybox
fi
groupadd mybox
useradd mybox -g mybox -G admin -s /bin/bash -m -d /home/mybox
if [[ -f /etc/lsb-release ]]; then
	echo mybox:mybox | /usr/sbin/chpasswd
else
	echo "mybox" | passwd --stdin mybox
fi

# Install mybox keys
mkdir -p /home/mybox/.ssh

cat <<EOM >/home/mybox/.ssh/authorized_keys
$mybox
EOM

chown -R mybox:mybox /home/mybox/.ssh
chmod -R u=rwX,go= /home/mybox/.ssh
EOF

scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ./vagrant -P "$port" "$SCRIPT" vagrant@127.0.0.1:~

if [[ $? -eq 0 ]];then
	rm $SCRIPT
fi
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ./vagrant vagrant@127.0.0.1 -p "$port" "sudo bash /home/vagrant/$SCRIPT; rm /home/vagrant/$SCRIPT"
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ./mybox mybox@127.0.0.1 -p "$port"