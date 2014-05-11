class lxc::params {
  case $::osfamily {
    'Archlinux': {
      $packages     = ['lxc', 'bridge-utils', 'netctl',
                       'arch-install-scripts', 'haveged']
      $service      = false
      $net_service  = 'lxcbridge'
      $dns          = '8.8.8.8'
      $bridge_iface = 'eth0'
      $bridge_ip    = '"10.7.1.1/24"'
      $template     = 'archlinux'
    }
    default: {
      fail("The ${module_name} module is not supported on an ${::osfamily} based system.")
    }
  }
}
