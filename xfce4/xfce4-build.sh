#!/bin/bash
#
#      xfce4-build.sh
#
#      Copyright 2006-2009 Enrico Tröger <enrico@xfce.org>
#
#      This program is free software; you can redistribute it and/or modify
#      it under the terms of the GNU General Public License as published by
#      the Free Software Foundation; either version 2 of the License, or
#      (at your option) any later version.
#
#      This program is distributed in the hope that it will be useful,
#      but WITHOUT ANY WARRANTY; without even the implied warranty of
#      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#      GNU General Public License for more details.
#
#      You should have received a copy of the GNU General Public License
#      along with this program; if not, write to the Free Software
#      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#

# TODO Missing xfce4-terminal
# TODO Missing xfburn (gstreamer-pbutils?)
# TODO Missing xfce4-dict (xfce4-panel?)
# TODO Missing xfce4-mixer (gstreamer-plugins-base-0.10?)

# (only tested with bash)

# might be needed depending on the state of the code
cflags="-Wno-error -Wno-deprecated-declarations"

# set this to the desired prefix, e.g. /usr/local
prefix="/usr/local"
global_options="--enable-maintainer-mode --disable-debug"

# additional configure arguments for certain packages
# to add options for other packages use opts_$packagename=...
opts_libxfce4util="--enable-gtk-doc"
opts_libxfce4ui="--enable-gtk-doc --disable-gladeui"
#opts_libxfce4menu="--enable-gtk-doc"
opts_libexo="--enable-gtk-doc"
opts_squeeze="--disable-gtk-doc"
#opts_xfce4_session="--disable-session-screenshots --enable-libgnome-keyring"
opts_xfdesktop="--enable-thunarx --enable-exo"
opts_xfce4_panel="--enable-gtk3 --enable-gtk-doc"
#opts_xfce_utils="--with-xsession-prefix=$prefix --disable-debug"
opts_xfconf="--enable-gtk-doc"
opts_xfce4_settings="--enable-sound-settings --enable-pluggable-dialogs"
opts_midori="--enable-userdocs --disable-unique"
opts_exo="--with-gio-module-dir=$prefix/lib/gio/modules"


# you should not need to change this
export PATH="$prefix/bin:$PATH"
export MAKEFLAGS="-j2"
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig:$PKG_CONFIG_PATH"
pwd="`pwd`"

# these packages are must be available on http://git.xfce.org/
# see init() for details
xfce4_modules="\
xfce/xfce4-dev-tools \
xfce/libxfce4util \
xfce/xfconf \
xfce/libxfce4ui \
xfce/exo \
xfce/gtk-xfce-engine \
xfce/garcon \
xfce/thunar \
xfce/xfce4-panel \
xfce/xfce4-appfinder \
xfce/xfce4-session \
xfce/xfce4-settings \
xfce/xfdesktop \
xfce/xfwm4 \
xfce/tumbler \
xfce/thunar-volman \
xfce/xfce4-power-manager \
apps/gigolo \
apps/mousepad \
apps/orage \
apps/ristretto \
apps/xfce4-mixer \
apps/xfce4-notifyd \
apps/xfce4-screenshooter \
apps/xfce4-taskmanager \
apps/xfce4-terminal \
art/xfce4-icon-theme \
panel-plugins/xfce4-calculator-plugin \
panel-plugins/xfce4-clipman-plugin \
panel-plugins/xfce4-cpufreq-plugin \
panel-plugins/xfce4-datetime-plugin \
panel-plugins/xfce4-netload-plugin \
panel-plugins/xfce4-sensors-plugin \
panel-plugins/xfce4-systemload-plugin \
"

# Currently not buildable
# xfce4-vala -> depends on wrong vala version 0.26 versus debian stable 0.34
# xfce4-notes-plugin -> depends on xfce4-vala
# xfce4-radio-plugin -> depends on libxfcegui4-1.0


log="/vagrant/xfce-build.log"
elog="/vagrant/xfce-ebuild.log"


function run_make()
{
	echo "==================== $1 make $2 ====================" >> $log;
	echo "==================== $1 make $2 ====================" >> $elog;
	if [ -x waf -a -f wscript ]
	then
		./waf $2 >>$log 2>>$elog
	else
		make CFLAGS="${cflags}" $2 >>$log 2>>$elog
	fi
	if [ ! "x$?" = "x0" ]
	then
		exit 1;
	fi
}

function build()
{
	echo "====================configuring and building in $1===================="
	cd "$1"

	# configuring
	if [ ! -f Makefile -o wscript -nt .lock-wscript -o configure.ac -nt configure \
		-o configure.ac.in -nt configure -o configure.in -nt configure \
		-o configure.in.in -nt configure ]
	then
		# prepare and read package-specific options
		base_name=`basename $1`
		clean_name=`echo $base_name | sed 's/-/_/g'`
		options=`eval echo '$opts_'$clean_name`

		echo "Additional arguments for configure: $global_options $options"

		if [ -x waf -a -f wscript ]
		then
			./waf configure --prefix=$prefix $options >>$log 2>>$elog
		else
			if [ ! -x configure -o configure.ac -nt configure -o configure.ac.in -nt configure \
				-o configure.in -nt configure -o configure.in.in -nt configure ]
			then
				./autogen.sh --prefix=$prefix $global_options $options >>$log 2>>$elog
			else [ configure.ac -nt configure ]
				./configure --prefix=$prefix $global_options $options >>$log 2>>$elog
			fi
		fi
	fi
	if [ ! "x$?" = "x0" ]
	then
		exit 1;
	fi

	# building
	run_make $1

	# installing
	run_make $1 install

	cd $pwd
}

function clean()
{
	echo "====================cleaning in $1===================="
	cd "$1"
	if [ -f Makefile -o -f wscript ]
	then
		run_make $1 clean
	fi
	cd $pwd
}

function distclean()
{
	echo "====================cleaning in $1===================="
	cd "$1"
	if [ -f Makefile -o -f wscript ]
	then
		run_make $1 distclean
	fi
	cd $pwd
}

function update()
{
	echo "====================updating in $1===================="
	cd "$1"
	git pull
	cd $pwd
}

function init()
{
	if [ ! -d "$1" ]
	then
		git clone git://git.xfce.org/$1 $1
	fi
}

# main()  ;-)

# run init before package lists are merged
if [ "x$1" = "x" ]
then
	echo "You should enter a command. Here is a list of possible commands:"
	echo
	echo "syntax: $0 command [packages...]"
	echo
	echo "commands:"
	echo "init      - download all needed packages from the GIT server"
	echo "update    - runs 'git pull' on all package subdirectories"
	echo "clean     - runs 'make clean' on all package subdirectories"
	echo "distclean - runs 'make distclean' on all package subdirectories"
	echo "build     - runs 'configure', 'make' and 'make install' on all package subdirectories"
	echo "echo      - just prints all package modules"
	echo
	echo "The commands update, clean, build and echo takes as second argument a comma separated list of package names, e.g."
	echo "$0 build xfcalendar xfmedia"
	echo "(this is useful if you updated all packages and there were only changes in some packages, so you don't have to rebuild all packages)"
	echo "If the second argument is omitted, the command takes all packages."
	echo
	exit 1
else
	cmd="$1"
	shift
	if [ $# -gt 0 ]
	then
		xfce4_modules="$@"
	fi
	for i in $xfce4_modules
	do
		"$cmd" $i
	done
fi
