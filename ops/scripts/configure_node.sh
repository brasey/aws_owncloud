#!/bin/bash

MV='sudo mv -v'

function fixperms {
  FILE=$1
  sudo chown -v root:root $FILE
  sudo chmod -v 664 $FILE
}


# Install EPEL, puppet and r10k and awscli

curl https://fedoraproject.org/static/8E1431D5.txt -o 8E1431D5
sudo rpm --import 8E1431D5

sudo yum -y install epel-release

sudo yum -y update
sudo yum -y install puppet git rubygems python-pip

pip install --upgrade pip

sudo pip install awscli
sudo gem install r10k --no-document


# Put puppet files in default locations

$MV /tmp/hiera.yaml /etc/puppet/hiera.yaml
fixperms /etc/puppet/hiera.yaml

$MV /tmp/owncloud.yaml /var/lib/hiera/owncloud.yaml
fixperms /var/lib/hiera/owncloud.yaml

$MV /tmp/Puppetfile /etc/puppet/Puppetfile
fixperms /etc/puppet/Puppetfile

sudo mkdir -pv /etc/puppet/manifests

$MV /tmp/site.pp /etc/puppet/manifests/site.pp
fixperms /etc/puppet/manifests/site.pp

sudo mkdir -pv /etc/puppet/files

$MV /tmp/files/* /etc/puppet/files/
fixperms /etc/puppet/files/*

$MV /tmp/fileserver.conf /etc/puppet/fileserver.conf
fixperms /etc/puppet/fileserver.conf


# Run r10k and puppet

cd /etc/puppet
sudo /usr/local/bin/r10k puppetfile install -v

sudo puppet apply --modulepath=/etc/puppet/modules \
  /etc/puppet/manifests/site.pp
