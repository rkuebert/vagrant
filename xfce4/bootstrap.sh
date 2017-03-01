#!/usr/bin/env bash

if ! [ -L ~/src/xfce4 ]; then
	# Copy build script
	rm -rf ~/src/xfce4
	mkdir -p ~/src/xfce4
	cp /vagrant/xfce4-build.sh ~/src/xfce4
	chmod u+x ~/src/xfce4/xfce4-build.sh
fi

# Avoid error 'mesg: ttyname failed: Inappropriate ioctl for device'
# See http://superuser.com/questions/1160025/how-to-solve-ttyname-failed-inappropriate-ioctl-for-device-in-vagrant
echo "tty -s && mesg n" > /root/.profile

# Allow any user to start X
cp /vagrant/Xwrapper.config /etc

# Copy locale.gen - enable locales you need in there
cp /vagrant/locale.gen /etc/locale.gen
# Generate locales
/usr/sbin/locale-gen
# Copy default locale - make sure you have enabled it before
cp /vagrant/default-locale /etc/default/locale

# Copy keyboard layout file
cp /vagrant/default-keyboard /etc/default/keyboard
