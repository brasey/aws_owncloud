# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  config.vm.network "private_network", type: "dhcp"
  config.vm.hostname = "owncloud"

  config.vm.provider "virtualbox" do |v|
    v.name = "owncloud"
  end

  [
    'owncloud.yaml',
    'hiera.yaml',
    'Puppetfile',
    'site.pp',
    'fileserver.conf',
    'files/'
  ].each do |file|
    src = "ops/files_to_provision/#{file}"
    dest = "/tmp/#{file}"
    config.vm.provision "file", source: src, destination: dest
  end

  config.vm.provision "file", source: "ops/scripts/configure_node.sh", destination: "/tmp/configure_node.sh"
  config.vm.provision "shell", inline: "/tmp/configure_node.sh"

end
