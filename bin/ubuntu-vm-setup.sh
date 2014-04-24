#!/bin/bash

echo "This script installs the necessary details for this host to become a vagrant box."
echo -n "Press enter to continue..."
read

echo "Setting up grub timeout..."
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
sed -i 's/^GRUB_HIDDEN_TIMEOUT_QUIET=true/#\0/' /etc/default/grub
update-grub

echo "Setting up /etc/sudoers..."
apt-get install -y sudo
cat <<EOF > /etc/sudoers.d/vagrant
vagrant ALL=(ALL) NOPASSWD:ALL
EOF
chmod 0440 /etc/sudoers.d/vagrant

echo "Setting up ssh..."
mkdir /home/vagrant/.ssh
wget --no-check-certificate "https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub" -O - > /home/vagrant/.ssh/authorized_keys

echo "Installing packages..."
apt-get install -y less
apt-get install -y vim
update-alternatives --set editor /usr/bin/vim.basic
apt-get install -y zerofree
apt-get install -y lsof

apt-get install -y linux-headers-$(uname -r) build-essential dkms

echo
echo "Insert the Virtualbox Guest Addtion CD (HOST+D in console) and press enter..."
read
mount /dev/cdrom /media/cdrom
/media/cdrom/VBoxLinuxAdditions.run

# Fixing bug in some version of VBoxLinuxAdditions
mount_vboxsf="/sbin/mount.vboxsf"
if [ -h $mount_vboxsf ]; then
	echo "hej"
	if ! readlink -e $mount_vboxsf 2> /dev/null; then
		mount_vboxsf_target="$(ls -1d /opt/VBoxGuestAdditions-*/lib/VBoxGuestAdditions/mount.vboxsf|head -1)"
		if [ -n "$mount_vboxsf_target" ]; then
			echo "Fixing broken symlink: $(stat --format "%N" $mount_vboxsf)"
			rm $mount_vboxsf
			ln -s $mount_vboxsf_target $mount_vboxsf
		fi
	fi

	if ! readlink -e $mount_vboxsf 2> /dev/null; then
		echo "ERROR: Unable to fix broken symlink: $mount_vboxsf"
	fi
fi

apt-get clean
echo "Removing old kernels. Current kernel: $(uname -a)"
apt-get remove --purge $(dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d')

cat <<EOF
Done.

Manual steps left:

Compact disk
------------
Reboot in rescue mode as root and execute:

mount -n -o remount,ro -t ext4 /dev/sda1 /
zerofree /dev/sda1
shutdown -h now


On host system execute:

vboxmanage modifyhd ~/VirtualBox\ VMs/ubuntu-12.04/ubuntu-12.04.vdi --compact



Remove bash history
-------------------

Make sure to remove .bash_history from /root and /home/vagrant.
Log in as vagrant user and execute:


sudo rm /root/.bash_history 2>/dev/null
sudo rm /root/.lesshst  2>/dev/null
export HISTFILE=
rm /home/vagrant/.bash_history 2>/dev/null
rm /home/vagrant/.lesshst 2>/dev/null
exit
EOF

