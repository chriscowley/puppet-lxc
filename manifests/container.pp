#
define lxc::container(
  $hostname      = $name,
  $template      = $lxc::params::template,
  $ensure        = 'present',
  $enable        = true,
  $mem_limit     = '512M',
  $mem_plus_swap_limit = '1024M',
  $ip            = '"10.7.1.2/24"',
  $gateway       = '10.7.1.1',
  $facts         = undef,
  $autoboot      = true,
  $backing_store = 'dir',
  $clone         = false,
  $snapshot      = false,
) {
  # directory of lxc_auto file is used to check if lxc container is created 
  $lxc_auto     = "/etc/lxc/auto/${name}.conf"
  # lxc configuration file
  $config_file  = "/var/lib/lxc/${name}/config"

  # lxc commands
  $lxc_stop     = "/usr/bin/lxc-stop -n ${name}"
  $lxc_start    = "/usr/bin/lxc-start -n ${name} -d"
  $lxc_destroy  = "/usr/bin/lxc-destroy -n ${name} -B ${backing_store}"
  $lxc_info     = "/usr/bin/lxc-info -n ${name}"
  $lxc_shutdown = "/usr/bin/lxc-stop -n ${name} -t 60"

  # use lxc-clone if clone is true
  if $clone != false {
    # add "-s" if backing_store is btrfs and snapshot is true
    if $backing_store == 'btrfs' {
      if $snapshot == true {
        $snap_args = '-s'
      } else {
        $snap_args = ''
      }
      $clone_args = '-s -B btrfs'
    } else {
      $clone_args = ''
    }
    $lxc_create   = "/usr/bin/lxc-clone -o $clone -n ${name} ${clone_args} ${snap_args}"
  } else {
    # use lxc-create
    $lxc_create   = "/usr/bin/lxc-create -n ${name} -t ${template} -B ${backing_store}"

  }

  case $ensure {
    'present': {

      if $autoboot == true {
        $cont_enable = 'true'
      } else {
        $cont_enable = 'manual'
      }

      service { "lxc@${name}":
        enable  => $cont_enable,
        require => Exec["lxc-create ${name}"],
      }

      file { $config_file:
        ensure  => 'present',
        content => template('lxc/container.config.erb'),
        require => [File['/etc/lxc/guests'], Exec["lxc-create ${name}"]]
      }

      exec { "lxc-create ${name}":
        creates   => "/var/lib/lxc/${name}",
        command   => "/usr/bin/haveged && ${lxc_create}",
        logoutput => 'on_failure',
        timeout   => 30000,
        require   => File['/usr/share/lxc/templates/lxc-archlinux'],
      }

      exec { "lxc-start ${name}":
        unless    => "${lxc_info} | grep State | grep RUNNING",
        command   => $lxc_start,
        logoutput => 'on_failure',
        require   => [Exec["lxc-create ${name}"],
                      File[$config_file]]
      }

      case $enable {
        true: {
          file { $lxc_auto:
            ensure  => 'link',
            target  => "/var/lib/lxc/${name}/config",
            require => Exec["lxc-create ${name}"]
          }
        }
        false: {
          file { $lxc_auto:
            ensure  => 'absent',
          }
        }
        default: {
          fail('enable must be true or false')
        }
      }

      if $facts != undef {
        file {
          "/var/lib/lxc/${name}/rootfs/etc/facter":
            ensure => 'directory';
          "/var/lib/lxc/${name}/rootfs/etc/facter/facts.d":
            ensure => 'directory';
          "/var/lib/lxc/${name}/rootfs/etc/facter/facts.d/lxc_module.yaml":
            ensure  => 'present',
            content => inline_template('<%= facts.to_yaml %>');
        }
      }
    }
    'stopped': {
      exec { "lxc-stop ${name}":
        unless  => "${lxc_info} | grep State | grep STOPPED",
        command => $lxc_shutdown
      }
    }

    'absent': {
      exec { "lxc-stop ${name}":
        unless  => "${lxc_info} | grep State | grep STOPPED",
        command => $lxc_shutdown
      }

      exec { "lxc-destroy ${name}":
        onlyif  => "/usr/bin/test -d /var/lib/lxc/${name}",
        command => $lxc_destroy,
        require => Exec["lxc-stop ${name}"]
      }

      file { $config_file:
        ensure => 'absent'
      }

      file { $lxc_auto:
        ensure => 'absent'
      }
    }

    default: {
      fail('ensure must be present, absent or stopped')
    }
  }

}
