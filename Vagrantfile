Vagrant.configure("2") do |config|
  config.vm.box = "bento/centos-7.5"
  config.vm.network :private_network, ip: "172.16.16.10"

  config.vm.synced_folder ".", "/vagrant"
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end
  config.vm.provision "shell", path: "install-ckan.sh"
end
