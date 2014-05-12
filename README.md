puppet-lxc
==========

Puppet module for managing LXC Host and LXC Containers (Linux Containers).

## Overview

Install, enable and configure LXC Host and brige device for LXC Containers.
This module enables iptables routing, sets up br0 device and enables ip
forwarding so containers can have internet access.

## Features

Supported OS:
* Arch Linux

Supported Filesystem Backends:
* Btrfs
* Dir
* None

Tested Containers:
* Arch Linux

## Examples

All examples assume that your eth0 device has internal IP of 10.7.7.101 and your
gateway being 10.7.7.1. Adjust it according to your network's configuration.

### Simple Container

This will configure a "container0" with default directory backing store. Use
this on non-Btrfs filesystems:

    node 'archlinux.example.org' {
        $containters = {
            'container0' =>   {
                hostname            => 'container0.archlinux.example.org',
                template            => 'archlinux',
                ensure              => 'present',
                mem_limit           => '256M',
                mem_plus_swap_limit => '512M',
                ip                  => '10.7.7.23/24',
                gateway             => '10.7.7.101',
                autoboot            => true, },
        }

        class { 'lxc':
            containers   => $cont,
            bridge_iface => 'eth0',
            bridge_ip    => '10.7.7.101/24',
            bridge_gw    => '10.7.7.1',
        }
    }

### Simple Container with Puppet

This will setup same container as in the example above, but with puppet
preinstalled and configured to use specified server. As an extra, the hostname
and ip combination will be added to /etc/hosts. This is ONE-TIME ONLY and
performed only during creation of new containers.

    node 'archlinux.example.org' {
        $containters = {
            'container0' =>   {
                hostname            => 'container0.archlinux.example.org',
                template            => 'archlinux',
                ensure              => 'present',
                mem_limit           => '256M',
                mem_plus_swap_limit => '512M',
                ip                  => '10.7.7.23/24',
                gateway             => '10.7.7.101',
                autoboot            => true,
                puppet              => true,
                puppet_package      => 'puppet',
                puppet_server_host  => 'puppet',
                puppet_server_ip    => '10.0.0.1',
                },
        }

        class { 'lxc':
            containers   => $cont,
            bridge_iface => 'eth0',
            bridge_ip    => '10.7.7.101/24',
            bridge_gw    => '10.7.7.1',
        }
    }


### Btrfs Containers

This will configure "container1" based on archlinux template. It will also setup
"container2" which will be created by snapshot of "container2". This will work
on Btrfs filesystem (backing_store):

    node 'archlinux.example.org' {
        $containters = {
            'container1' =>   {
                hostname            => 'container1.archlinux.example.org',
                template            => 'archlinux',
                ensure              => 'present',
                mem_limit           => '256M',
                mem_plus_swap_limit => '512M',
                ip                  => '10.7.7.24/24',
                gateway             => '10.7.7.101',
                autoboot            => true,
                backing_store       => 'btrfs',
                clone               => false,
                snapshot            => false, },
            'container2' =>   {
                hostname            => 'container2.archlinux.example.org',
                template            => 'archlinux',
                ensure              => 'present',
                mem_limit           => '256M',
                mem_plus_swap_limit => '512M',
                ip                  => '10.7.7.25/24',
                gateway             => '10.7.7.101',
                autoboot            => true,
                backing_store       => 'btrfs',
                clone               => 'container1',
                snapshot            => true, },

        }

        class { 'lxc':
            containers   => $cont,
            bridge_iface => 'eth0',
            bridge_ip    => '10.7.7.101/24',
            bridge_gw    => '10.7.7.11',
        }
    }

