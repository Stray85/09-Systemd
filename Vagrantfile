# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|
config.vm.synced_folder ".", "/vagrant"
config.vm.box = "centos/7"
config.vm.define "systemd" do |systemd|
systemd.vm.provision "shell", path: "systemd.sh"
end
end