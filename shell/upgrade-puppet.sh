#!/bin/bash

apt-get install lsb-release -y > /dev/null
DISTRIB_CODENAME=$(lsb_release --codename --short)
DEB="puppetlabs-release-${DISTRIB_CODENAME}.deb"
DEB_PROVIDES="/etc/apt/sources.list.d/puppetlabs.list" # Assume that this file's existence means we have the Puppet Labs repo added

if [ ! -e $DEB_PROVIDES ]
then
    # Print statement useful for debugging, but automated runs of this will interpret any output as an error
    # print "Could not find $DEB_PROVIDES - fetching and installing $DEB"
    wget -q http://apt.puppetlabs.com/$DEB > /dev/null
    sudo dpkg -i $DEB > /dev/null
fi

sudo apt-get update -qq > /dev/null
sudo apt-get install -y puppet > /dev/null