# -*- mode: ruby -*-
# vi: set ft=ruby :

shared_dir="/var/shared"

transit_node = {
  :id => "node0",
  :ip => "192.168.56.160",
  :hostname => "transit-host"
}

leader_node = {
  :id => "node1",
  :ip => "192.168.56.150",
  :hostname => "vault-leader",
  :api_addr => "http://192.168.56.150:8200"
}

followers = [
  {
    :id => "node2",
    :ip => "192.168.56.151",
    :hostname => "vault-follower1"    
  },
  {
    :id => "node3",
    :ip => "192.168.56.152",
    :hostname => "vault-follower2"    
  }
]


Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", "512"]
    vb.customize ["modifyvm", :id, "--cpus", "1"]
    vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
    vb.customize ["modifyvm", :id, "--chipset", "ich9"]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
  end
  config.vm.define "transit_node" do |vault_transit|
    vault_transit.vm.box = "bento/centos-7.9"
    vault_transit.vm.box_version = "202110.25.0"
    vault_transit.vm.hostname = transit_node[:hostname]
    vault_transit.vm.network "private_network", ip: transit_node[:ip]
    vault_transit.vm.network "forwarded_port", guest: 8200, host: 8200, auto_correct: true
    vault_transit.vm.provision "shell", path: "scripts/setup-user.sh", args: "vault"
    vault_transit.vm.synced_folder "data/", shared_dir
    vault_transit.vm.provision "shell", path: "scripts/common.sh"
    vault_transit.vm.provision "shell", path: "scripts/install-vault.sh", args: transit_node[:ip]
    vault_transit.vm.provision "shell", path: "scripts/create-systemd-unit.sh"
    vault_transit.vm.provision "shell", path: "scripts/create-configs.sh", args: [ transit_node[:id], transit_node[:ip], transit_node[:id], leader_node[:id] ]
    vault_transit.vm.provision "shell", inline: "sudo systemctl enable vault.service"
    vault_transit.vm.provision "shell", inline: "sudo systemctl start vault"
    vault_transit.vm.provision "shell", path: "scripts/setup-transit-node.sh", args: shared_dir
  end
  config.vm.define "vault_leader" do |vault_leader|
    vault_leader.vm.box = "bento/centos-7.9"
    vault_leader.vm.box_version = "202110.25.0"
    vault_leader.vm.hostname = leader_node[:hostname]
    vault_leader.vm.network "private_network", ip: leader_node[:ip]
    vault_leader.vm.network "forwarded_port", guest: 8200, host: 8200, auto_correct: true
    vault_leader.vm.provision "shell", path: "scripts/setup-user.sh", args: "vault"
    vault_leader.vm.synced_folder "data/", shared_dir
    vault_leader.vm.provision "shell", path: "scripts/common.sh"
    vault_leader.vm.provision "shell", path: "scripts/install-vault.sh", args: leader_node[:ip]
    vault_leader.vm.provision "shell", path: "scripts/setup-unwrap-token.sh", args: [ transit_node[:ip], shared_dir ]
    vault_leader.vm.provision "shell", path: "scripts/create-systemd-unit.sh"
    vault_leader.vm.provision "shell", path: "scripts/create-configs.sh", args: [leader_node[:id], leader_node[:ip], transit_node[:id], leader_node[:id], transit_node[:ip]]
    vault_leader.vm.provision "shell", inline: "sudo systemctl enable vault.service"
    vault_leader.vm.provision "shell", inline: "sudo systemctl start vault"
    vault_leader.vm.provision "shell", path: "scripts/setup-leader-node.sh", args: shared_dir
  end

  followers.each do |follower|
    config.vm.define follower[:id] do |follower_node|
      follower_node.vm.box = "bento/centos-7.9"
      follower_node.vm.box_version = "202110.25.0"
      follower_node.vm.hostname = follower[:hostname]
      follower_node.vm.network "private_network", ip: follower[:ip]
      follower_node.vm.network "forwarded_port", guest: 8200, host: 8201, auto_correct: true
      follower_node.vm.provision "shell", path: "scripts/setup-user.sh", args: "vault"
      follower_node.vm.synced_folder "data/", shared_dir
      follower_node.vm.provision "shell", path: "scripts/common.sh"
      follower_node.vm.provision "shell", path: "scripts/install-vault.sh", args: follower[:ip]
      follower_node.vm.provision "shell", path: "scripts/create-systemd-unit.sh"
      follower_node.vm.provision "shell", path: "scripts/create-configs.sh", args: [follower[:id], follower[:ip], transit_node[:id], leader_node[:id], transit_node[:ip], leader_node[:api_addr]]
      follower_node.vm.provision "shell", inline: "sudo systemctl enable vault.service"
      follower_node.vm.provision "shell", inline: "sudo systemctl start vault"
    end
  end

end
