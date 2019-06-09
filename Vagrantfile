# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'emptybox/ubuntu-bionic-amd64-lxc'

  config.vm.network 'private_network', ip: '192.168.64.4', lxc__bridge_name: 'vlxcbr1'
  config.vm.network 'forwarded_port',  guest: 3000, host: 3000

  config.ssh.forward_agent = true

  config.vm.provision 'shell', path: 'provision/provision.sh'

  config.vm.provider 'lxc' do |lxc|
    lxc.container_name = 'local-devenv'
    lxc.customize 'cgroup.cpuset.cpus', '0,1'
  end
end
