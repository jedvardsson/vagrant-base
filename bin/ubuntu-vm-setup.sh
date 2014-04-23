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
cat <<EOF > /etc/sudoers.d/vagrant.sudo
%sudo ALL=NOPASSWD: ALL
EOF

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

apt-get clean

cat <<EOF
Done.

Manual steps left:

Remove bash history
-------------------

Make sure to remove .bash_history from /root and /home/vagrant.
Log in as vagrant user and execute:


sudo rm /root/.bash_history
export HISTFILE=
rm /home/vagrant/.bash_history
exit
EOF

