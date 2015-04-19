# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

# Config
domain = "vagrant.dev"

vdir = File.expand_path(File.dirname(__FILE__))

# Machines
machines = {
  'default' => {
    'vm' => {
      'box'      => "utopic64",
      'box_url'  => "https://cloud-images.ubuntu.com/vagrant/utopic/current/utopic-server-cloudimg-amd64-vagrant-disk1.box",
      'hostname' => domain,
      'private_network' => {
        'ip' => '192.168.2.2'
      },
      'forwarded_port' => [
        {
          'guest' => 3306,
          'host' => 33066
        }
      ],
      'synced_folder' => [
        {
          'id' => "vagrant-root",
          'host' => '..',
          'guest' => '/vagrant'
        }
      ],
      'puppet' => [
        {
          'module_path' => "puppet/modules",
          'manifests_path' => "puppet/manifests",
          'manifest_file' => "init.pp",
          'options' => ["--verbose", "--debug"],
          'facter' => {
            'env' => "dev"
          }
        }
      ]
    }
  }
}

# load default with 32 bits
if ENV["PROCESSOR_ARCHITECTURE"] == "x86"
  machines['default']['vm']['box']     = "utopic32"
  machines['default']['vm']['box_url'] = "https://cloud-images.ubuntu.com/vagrant/utopic/current/utopic-server-cloudimg-i386-vagrant-disk1.box"
end

# finds if machines was overwrited
if File.exists?(File.expand_path(File.join(vdir, '..', "machines.yaml")))
  machines = YAML::load_file(File.join(vdir, '..', "machines.yaml"))
end

# search for hiera.yaml
machines.each do |name, machine|
  machine['vm']['puppet'].each do |puppet|
    if puppet['options'].kind_of?(Array)
      if machines['default']['vm'].has_key?('synced_folder') && machines['default']['vm']['synced_folder'].any? && machines['default']['vm']['synced_folder'][0].has_key?('host') && File.exists?(File.expand_path(File.join(vdir, machines['default']['vm']['synced_folder'][0]['host'], "hiera.yaml")))
        puppet['options'] << "--hiera_config /vagrant/hiera.yaml"
      end
    end
  end
end

Vagrant.configure("2") do |config|
  # Virtualbox
  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--cpus", 1]
    v.customize ["modifyvm", :id, "--memory", 1024]
    v.customize ["modifyvm", :id, "--cpuexecutioncap", 50]
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    v.customize ["setextradata", :id, "VBoxInternal/Devices/ahci/0/LUN#[0]/Config/IgnoreFlush", "1"]
  end

  # machines
  machines.each do |name, vmconf|
    config.vm.define name do |machine|
      machine.vm.box      = vmconf['vm']['box']
      machine.vm.box_url  = vmconf['vm']['box_url']
      machine.vm.hostname = vmconf['vm']['hostname']

      # Aliases
      if vmconf['vm'].has_key?('aliases') && (vmconf['vm']['aliases'].respond_to? :each)
        if Vagrant.has_plugin?("vagrant-hostsupdater")
          machine.hostmanager.aliases = vmconf['vm']['aliases']
        end
      end

      # Private Network IP
      if vmconf['vm'].has_key?('private_network')
        machine.vm.network :private_network, ip: vmconf['vm']['private_network']['ip']
      else
        machine.vm.network 'public_network'
      end

      # Forwarded ports
      if vmconf['vm'].has_key?('forwarded_port') && (vmconf['vm']['forwarded_port'].respond_to? :each)
        vmconf['vm']['forwarded_port'].each do |ports|
          machine.vm.network :forwarded_port, guest: ports['guest'], host: ports['host']
        end
      end

      # Synced folder
      if vmconf['vm'].has_key?('synced_folder') && (vmconf['vm']['synced_folder'].respond_to? :each)
        vmconf['vm']['synced_folder'].each do |folder|
          machine.vm.synced_folder folder['host'], folder['guest'], id: folder['id'], nfs: folder.has_key?('nfs') ? folder['nfs'] : (RUBY_PLATFORM =~ /mingw32/).nil?
        end
      end

      # Puppet
      if vmconf['vm'].has_key?('puppet') && (vmconf['vm']['puppet'].respond_to? :each)
        # updates puppet before puppet provisions
        if File.exists?(File.expand_path(File.join(vdir, "shell/upgrade-puppet.sh")))
          machine.vm.provision :shell, :path => "shell/upgrade-puppet.sh"
        end

        vmconf['vm']['puppet'].each do |provision|
          machine.vm.provision :puppet do |puppet|
            provision.each do |key, value|
              puppet.send("#{key}=", value)
            end
          end
        end
      end

    end
  end

  # SSH Agent Forwarding
  #
  # Enable agent forwarding on vagrant ssh commands. This allows you to use ssh keys
  # on your host machine inside the guest. See the manual for `ssh-add`.
  config.ssh.forward_agent = true

  # vagrant-hostsupdater
  if Vagrant.has_plugin?("vagrant-hostsupdater")
    config.hostsupdater.remove_on_suspend = true
  end

  # vagrant-hostmanager
  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = true
  end

  # vagrant-cachier
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.auto_detect = true
  end
end
