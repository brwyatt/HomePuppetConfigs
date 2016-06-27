$server_network_ip_prefix = '10.0.6.'
$server_network_gateway = '10.0.6.1'
$server_network_netmask = 24
$server_network_dns = [ '10.0.6.1' ]

$storage_network_ip_prefix = '10.0.5.'
$storage_network_netmask = 24

node /^hyp\d{1,2}-(\d{1,2})$/ {
  $my_ip = 100 + $1

	# Network config
  kmod::load { 'bonding': }
  kmod::load { '8021q': }
  debnet::iface::loopback { 'lo': }
  debnet::iface::bond { 'bond0':
    ports   => [ 'eno1', 'eno2', 'eno3', 'eno4' ],
    method  => 'static',
    mode    => '802.3ad',
    address => "${server_network_ip_prefix}${my_ip}",
    netmask => $server_network_netmask,
    gateway => $server_network_gateway,
    require => Kmod::Load['bonding'],
  }
  debnet::iface::static { 'bond0.5':
    address => "${storage_network_ip_prefix}${my_ip}",
    netmask => $storage_network_netmask,
    require => Kmod::Load['8021q'],
  }
  anchor { 'networking': }

  # Helpful user utilities
  package { [ 'htop', 'nmon', 'screen' ]:
    ensure  => installed,
    require => Anchor['networking'],
  }

  # Helpful management tools
  #class { 'megacli':
  #  repo_suite => 'wily', # Xenial not officially available yet
  #}
  package { 'lsscsi':
    ensure  => installed,
    require => Anchor['networking'],
  }

  # System utils
  package { 'ntp': # needed by Ceph Monitors
    ensure  => installed,
    require => Anchor['networking'],
  }
  class { 'resolvconf':
    nameservers   => $server_network_dns,
    domain        => 'infra.home.brwyatt.net',
    override_dhcp => true,
    require       => Anchor['networking'],
  }

  # Ceph
  Exec {
    path => '/bin:/usr/bin:/sbin:/usr/sbin',
  }
  class { 'ceph':
    mon     => true,
    osd     => true,
    conf    => {
      'global' => {
        #'fsid'                      => '62ed9bd6-adf4-11e4-8fb5-3c970ebb2b86', # Don't use this default, use `uuidgen`!
        'mon_initial_members'       => 'hyp7-8',
        'mon_host'                  => '10.0.6.108,10.0.6.110,10.0.6.112',
        'public_network'            => "${server_network_ip_prefix}0/24",
        'cluster_network'           => "${storage_network_ip_prefix}0/24",
        'auth_supported'            => 'cephx',
        'filestore_xattr_use_omap'  => true,
        'osd_crush_chooseleaf_type' => 0,
      },
      'osd'    => {
        'osd_journal_size' => '15000',
      },
    },
    #mon_key => 'AQA7yNlUMy3sFhAA62XHf57L0QhSI44qqqOVXA==', # Don't use this default, use `ceph-authtool --gen-key`
    keys    => {
      '/etc/ceph/ceph.client.admin.keyring'          => {
        'user'     => 'client.admin',
        'key'      => 'AQBAyNlUmO09CxAA2u2p6s38wKkBXaLWFeD7bA==', # Don't use this default, use `ceph-authtool --gen-key`
        'caps_mon' => 'allow *',
        'caps_osd' => 'allow *',
        'caps_mds' => 'allow',
      },
      '/etc/ceph/ceph.client.radosgw.puppet.keyring' => {
        'user'     => 'client.radosgw.puppet',
        'key'      => 'AQD+zXZVDljeKRAAKA30V/QvzbI9oUtcxAchog==', # Don't use this default, use `ceph-authtool --gen-key`
        'caps_mon' => 'allow rwx',
        'caps_osd' => 'allow rwx',
      },
      '/var/lib/ceph/bootstrap-osd/ceph.keyring'     => {
        'user'     => 'client.bootstrap-osd',
        'key'      => 'AQDLGtpUdYopJxAAnUZHBu0zuI0IEVKTrzmaGg==', # Don't use this default, use `ceph-authtool --gen-key`
        'caps_mon' => 'allow profile bootstrap-osd',
      },
      '/var/lib/ceph/bootstrap-mds/ceph.keyring'     => {
        'user'     => 'client.bootstrap-mds',
        'key'      => 'AQDLGtpUlWDNMRAAVyjXjppZXkEmULAl93MbHQ==', # Don't use this default, use `ceph-authtool --gen-key`
        'caps_mon' => 'allow profile bootstrap-mds',
      },
    },
    disks   => {
      '2:2:0:0/5:0:0:0' => {},
      '2:2:1:0/5:0:0:0' => {},
      '2:2:2:0/5:0:0:0' => {},
      '2:2:3:0/5:0:0:0' => {},
      '2:2:4:0/5:0:0:0' => {},
      '2:2:5:0/5:0:0:0' => {},
    },
  }

  # Ordering
  Package['ntp'] -> Class['ceph']
  Class['resolvconf'] -> Class['ceph']
  Debnet::Iface::Bond['bond0'] -> Anchor['networking']
  Debnet::Iface::Static['bond0.5'] -> Anchor['networking']
  Anchor['networking'] -> Class['ceph']
}
