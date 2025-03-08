# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['ANSIBLE_CALLBACK_RESULT_FORMAT'] = 'yaml'

DEFAULT_MACHINE = {
  :domain => 'internal',
  :box => 'bento/ubuntu-24.04/202502.21.0',
  :cpus => 1,
  :memory => 1024,
  :disks => {},
  :networks => {},
  :intnets => {},
  :forwarded_ports => [],
  :modifyvm => []
}

MACHINES = {
  :'iscsi-01' => {
    :disks => { :disk01 => '10GB' },
    :intnets => {
      :iscsi1 => { :ip => '10.130.1.11' },
      :iscsi2 => { :ip => '10.130.2.11' },
    },
    :networks => { :private_network => { :ip => '192.168.56.12' } },
  },
  :'gfs-01' => {
    :intnets => {
      :iscsi1 => { :ip => '10.130.1.12' },
      :iscsi2 => { :ip => '10.130.2.12' },
    },
    :networks => { :private_network => { :ip => '192.168.56.12' } },
  },
  :'gfs-02' => {
    :intnets => {
      :iscsi1 => { :ip => '10.130.1.13' },
      :iscsi2 => { :ip => '10.130.2.13' },
    },
    :networks => { :private_network => { :ip => '192.168.56.13' } },
  },
  :'gfs-03' => {
    :intnets => {
      :iscsi1 => { :ip => '10.130.1.14' },
      :iscsi2 => { :ip => '10.130.2.14' },
    },
    :networks => { :private_network => { :ip => '192.168.56.14' } },
  },
}

ANSIBLE_GROUPS = {
  :iscsi => ['iscsi-01'],
  :gfs => ['gfs-01', 'gfs-02', 'gfs-03'],
}
ANSIBLE_HOSTVARS = MACHINES.keys.each_with_object({}) {
  |key, obj| obj[key] = {
    'ip_address' => MACHINES[key][:networks][:private_network][:ip],
    'ip_address_iscsi1' => MACHINES[key][:intnets][:iscsi1][:ip],
    'ip_address_iscsi2' => MACHINES[key][:intnets][:iscsi2][:ip],
  }
}

def provisioned?(host_name)
  return File.exist?('.vagrant/machines/' + host_name.to_s +
    '/virtualbox/action_provision')
end

Vagrant.configure('2') do |config|
  MACHINES.each do |host_name, host_config|
    host_config = DEFAULT_MACHINE.merge(host_config)
    config.vm.define host_name do |host|
      host.vm.box = host_config[:box]
      if not provisioned?(host_name)
        host.vm.host_name = host_name.to_s + '.' + host_config[:domain].to_s
      end

      host.vm.provider :virtualbox do |vb|
        vb.cpus = host_config[:cpus]
        vb.memory = host_config[:memory]

        if !host_config[:modifyvm].empty?
          vb.customize ['modifyvm', :id] + host_config[:modifyvm]
        end
      end

      host_config[:disks].each do |name, size|
        host.vm.disk :disk, name: name.to_s, size: size
      end

      host_config[:intnets].each do |name, intnet|
        intnet[:virtualbox__intnet] = name.to_s
        host.vm.network(:private_network, **intnet)
      end
      host_config[:networks].each do |network_type, network_args|
        host.vm.network(network_type, **network_args)
      end
      host_config[:forwarded_ports].each do |forwarded_port|
        host.vm.network(:forwarded_port, **forwarded_port)
      end

      if MACHINES.keys.last == host_name
        host.vm.provision :ansible do |ansible|
          ansible.playbook = 'provision.yml'
          ansible.groups = ANSIBLE_GROUPS
          ansible.host_vars = ANSIBLE_HOSTVARS
          ansible.limit = 'all'
          ansible.compatibility_mode = '2.0'
          ansible.raw_arguments = ['--diff']
          ansible.tags = 'all'
        end
      end

      host.vm.synced_folder '.', '/vagrant', disabled: true
    end
  end
end
