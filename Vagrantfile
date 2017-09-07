# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # Lock to current version of box to avoid updates
  config.vm.box = "bento/ubuntu-16.04"
  config.vm.box_version = "201708.22.0"
  # Box also provided in the INSTALL dir if needed:
  # config.vm.box_check_update = false
  # config.vm.box_url = "file:///.../INSTALL/boxes/virtualbox.box"

  # Use password auth
  config.ssh.username = "vagrant"
  config.ssh.password = "vagrant"

  # 4GB memory and 50% of host CPU max
  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
    v.customize ["modifyvm", :id, "--memory", "4096"]
  end

  # Sync a folder
  config.vm.synced_folder ".", "/vagrant",
    :id => "vagrant-synced",
    :mount_options => ['dmode=777', 'fmode=777']

  # Keep it simple; just 1 VM to reduce memory use
  config.vm.define "es" do |es|
    es.vm.hostname = "es.local"
    es.vm.network "forwarded_port", guest: 9201, host: 9200
    es.vm.network "forwarded_port", guest: 5601, host: 5600
    es.vm.provision :shell, :path => "install.sh"
  end

end
