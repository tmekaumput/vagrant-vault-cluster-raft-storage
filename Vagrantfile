# -*- mode: ruby -*-
# vi: set ft=ruby :

shared_dir="/var/shared"
GID=1001
UID=1001

transit_node = {
  :id => "node0",
  :ip => "192.168.56.160",
  :hostname => "transit-host"
}

vault_nodes = [
  {
    :id => "node1",
    :ip => "192.168.56.150",
    :hostname => "vault-node1",
    :port => "8200",
    :forward_port => 8202 
  },
  {
    :id => "node2",
    :ip => "192.168.56.151",
    :hostname => "vault-node2",    
    :port => "8200",
    :forward_port => 8204 
  },
  {
    :id => "node3",
    :ip => "192.168.56.152",
    :hostname => "vault-node3", 
    :port => "8200",
    :forward_port => 8206 
  },
  {
    :id => "node4",
    :ip => "192.168.56.153",
    :hostname => "vault-node4", 
    :port => "8200",
    :forward_port => 8208 
  },
  {
    :id => "node5",
    :ip => "192.168.56.154",
    :hostname => "vault-node5",
    :port => "8200",
    :forward_port => 8210 
  }
]

node_ips = ""

for node in vault_nodes do
  if node_ips == "" then
    node_ips = "http://" + node[:ip] + ":" + node[:port]
  else
    node_ips += ",http://" + node[:ip] + ":" + node[:port]
  end 
end

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]
    vb.customize ["modifyvm", :id, "--cpus", "1"]
    vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
    vb.customize ["modifyvm", :id, "--chipset", "ich9"]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
  end
  config.vm.define "transit_node" do |vault_transit|
    vault_transit.vm.box = "bento/centos-7.9"
    vault_transit.vm.box_version = "202110.25.0"
    vault_transit.vm.hostname = transit_node[:hostname]
    vault_transit.vm.network "private_network", ip: transit_node[:ip]
    vault_transit.vm.network "forwarded_port", guest: 8200, host: 8200, auto_correct: true
    vault_transit.vm.provision "shell", path: "scripts/setup-user.sh", args: ["vault", UID, GID]
    vault_transit.vm.synced_folder "data/", shared_dir, owner: "vault",  group: "vault", :mount_options => ["uid=#{UID},gid=#{GID},dmode=744,fmode=744"]
    vault_transit.vm.provision "file", source: "./license.txt", destination: "/tmp/license.txt"
    vault_transit.vm.provision "shell", path: "scripts/common.sh"
    vault_transit.vm.provision "shell", path: "scripts/install-vault.sh", args: [transit_node[:ip], shared_dir]
    vault_transit.vm.provision "shell", path: "scripts/create-systemd-unit.sh"
    vault_transit.vm.provision "shell", path: "scripts/create-configs.sh", args: [ transit_node[:id], transit_node[:ip], transit_node[:id], vault_nodes[0][:id] ]
    vault_transit.vm.provision "shell", inline: "sudo systemctl enable vault.service"
    vault_transit.vm.provision "shell", inline: "sudo systemctl start vault"
    vault_transit.vm.provision "shell", path: "scripts/setup-transit-node.sh", args: shared_dir
  end

  vault_nodes.each do |vault_node|
    config.vm.define vault_node[:id] do |node|
      node.vm.box = "bento/centos-7.9"
      node.vm.box_version = "202110.25.0"
      node.vm.hostname = vault_node[:hostname]
      node.vm.network "private_network", ip: vault_node[:ip]
      node.vm.network "forwarded_port", guest: 8200, host: vault_node[:forward_port]
      node.vm.provision "shell", path: "scripts/setup-user.sh", args: ["vault", UID, GID]
      node.vm.synced_folder "data/", shared_dir, owner: "vault",  group: "vault", :mount_options => ["uid=#{UID},gid=#{GID},dmode=744,fmode=744"]
      node.vm.provision "file", source: "./license.txt", destination: "/tmp/license.txt"
      node.vm.provision "shell", path: "scripts/common.sh"
      node.vm.provision "shell", path: "scripts/install-vault.sh", args: [vault_node[:ip], shared_dir]
      if vault_node[:id] == "node1" then
        node.vm.provision "shell", path: "scripts/setup-unwrap-token.sh", args: [ transit_node[:ip], shared_dir ]
      end
      node.vm.provision "shell", path: "scripts/create-systemd-unit.sh"
      node.vm.provision "shell", path: "scripts/create-configs.sh", args: [vault_node[:id], vault_node[:ip], transit_node[:id], vault_nodes[0][:id], transit_node[:ip], node_ips]
      node.vm.provision "shell", inline: "sudo systemctl enable vault.service"
      node.vm.provision "shell", inline: "sudo systemctl start vault"
      if vault_node[:id] == "node1" then
        node.vm.provision "shell", path: "scripts/setup-leader-node.sh", args: shared_dir
      end
    end
  end

end
