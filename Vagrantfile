# -*- mode: ruby -*-
# vi: set ft=ruby :

provision_env = {
  :ES_VER       => "2.4.4",
  :KB_VER       => "4.6.6",
  :NUM_NODES    => "3",
  :ES_HEAP_SIZE => "1G",
}

Vagrant.configure("2") do |config|

  # Lock to current version of box to avoid updates
  config.vm.box = "bento/ubuntu-16.04"
  config.vm.box_version = "201708.22.0"
  # OR Use 2017 GM version with data preloaded
  #config.vm.box = "2017gm"
  #config.vm.box_url = "file://../2017gm.box"

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
  config.vm.define "elastic" do |elastic|
    elastic.vm.hostname = "elastic.local"
    elastic.vm.network "forwarded_port", guest: 9201, host: 9200
    elastic.vm.network "forwarded_port", guest: 5601, host: 5600

    # Provision VM
    elastic.vm.provision :shell, :path => "provision/srv-stop.sh",
      env: provision_env, run: "always"
    elastic.vm.provision :shell, :path => "install.sh",
      env: provision_env
    elastic.vm.provision :shell, :path => "provision/srv-start.sh",
      env: provision_env, run: "always"
  end

end
