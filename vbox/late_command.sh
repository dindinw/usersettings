#!/bin/bash
# tell ks service we are finished, please stop tftp server
# TODO, remove hardcoding url
wget -qO - http://10.0.2.3:8088

# passwordless sudo
echo "%sudo   ALL=NOPASSWD: ALL" >> /etc/sudoers

# public ssh key for mybox user
mkdir /home/mybox/.ssh
wget -O /home/mybox/.ssh/authorized_keys "https://raw.githubusercontent.com/dindinw/usersettings/master/vbox/keys/mybox.pub"
chmod 755 /home/mybox/.ssh
chmod 644 /home/mybox/.ssh/authorized_keys
chown -R mybox:mybox /home/mybox/.ssh

# speed up ssh
echo "UseDNS no" >> /etc/ssh/sshd_config

# display login promt after boot
sed "s/quiet splash//" /etc/default/grub > /tmp/grub
mv /tmp/grub /etc/default/grub

# set GRUB_RECORDFAIL_TIMEOUT=0 to avoid recovery menu is being displayed.
grep -q "^GRUB_RECORDFAIL_TIMEOUT=" /etc/default/grub \
    && sed "s/^GRUB_RECORDFAIL_TIMEOUT=.*/GRUB_RECORDFAIL_TIMEOUT=0/" /etc/default/grub > /tmp/grub \
    || sed "$ a\GRUB_RECORDFAIL_TIMEOUT=0" /etc/default/grub > /tmp/grub
mv /tmp/grub /etc/default/grub

update-grub

# clean up
apt-get clean
dd if=/dev/zero of=/zero bs=1M
rm -f /zero