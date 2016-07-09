$server_network_ip_prefix = '10.0.6.'
$server_network_gateway = '10.0.6.1'
$server_network_netmask = 24
$server_network_dns = [ '10.0.6.1' ]

$storage_network_ip_prefix = '10.0.5.'
$storage_network_netmask = 24

node /^hyp(\d{1,2})$/ {
  $my_last_octet = 100 + $1
  $my_server_ip = "${server_network_ip_prefix}${my_last_octet}"
  $my_storage_ip = "${storage_network_ip_prefix}${my_last_octet}"

  # Network config
  kmod::load { 'bonding': }
  kmod::load { '8021q': }
  debnet::iface::loopback { 'lo': }
  debnet::iface::bond { 'bond0':
    ports   => [ 'eno1', 'eno2', 'eno3', 'eno4' ],
    method  => 'static',
    mode    => '802.3ad',
    address => $my_server_ip,
    netmask => $server_network_netmask,
    gateway => $server_network_gateway,
    require => Kmod::Load['bonding'],
  }
  debnet::iface::static { 'bond0.5':
    order   => 1000,
    address => $my_storage_ip,
    netmask => $storage_network_netmask,
    require => Kmod::Load['8021q'],
  }

  service { 'networking':
    ensure => running,
  }

  # Helpful user utilities
  package { [ 'htop', 'nmon', 'screen' ]:
    ensure  => installed,
    require => Service['networking'],
  }

  # Helpful management tools
  #class { 'megacli':
  #  repo_suite => 'wily', # Xenial not officially available yet
  #}
  package { 'lsscsi':
    ensure  => installed,
    require => Service['networking'],
  }

  user { 'brwyatt':
    ensure     => present,
    groups     => [ 'adm', 'cdrom', 'sudo', 'dip', 'plugdev', 'lxd',
      'lpadmin', 'sambashare' ],
    managehome => true,
    password   => '$6$04TmjJkg85OLxV$hiKHI1LSlvAFmqnUbVXXsmm.T91BZ11zWbVYkssR6Xs8q5uql0x1n6fELdgW9rLRcnLQluscXJ/owkAFzuAZA0',
    before     => Class['ssh'],
  }

  # System utils
  class { 'ntp':
    servers => $server_network_dns, #Same servers, for now
    require => Service['networking'],
  }
  class { 'resolvconf':
    nameservers   => $server_network_dns,
    domain        => 'infra.home.brwyatt.net',
    override_dhcp => true,
    require       => Service['networking'],
  }
  class { 'ssh':
    ssh_config_forward_x11    => false,
    ssh_config_forward_agent  => false,
    sshd_listen_address       => [ $my_server_ip ],
    sshd_config_banner        => '/etc/ssh/login_banner',
    sshd_banner_content       => join([
      " * Servername: ${::fqdn}",
      " * IP Address: ${::ipaddress}",
      ' * * This system is monitored and activities are recorded.',
      ' * * Unauthorized use is prohibited.',
      "\n",
    ], "\n"),
    sshd_allow_tcp_forwarding => 'no',
    sshd_x11_forwarding       => 'no',
    keys                      => {
      'brwyatt@brwyatt.net' => {
        'ensure' => 'present',
        'user'   => 'brwyatt',
        'type'   => 'ssh-rsa',
        'key'    => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDA3zFRckFN4FwVLOQOMzzW/VEquBskxUHj7olTrfRg2On8rCjURbvZXxofXzizuPC6v9hSc3qQhB4jJiVv67NJ3jzKNI7QuxwxNw0mPUknZvpF0tFepnIRJvUDLheXUO+UUM0EtX6Oi2f+C2b5+QRXufgFbjCB9JJIH3idDmesL1H+lRvwIBh2LWHn8OPh6ZmtmNhgWTMjtE8pueKSlBOS/QdzbWKqFFVU8xLJn8aNhgC7iTqygexYaW+ZdhGtzUikJy06lxzUqWq42dazLM9FJ107amZ0xA3tmdvVZIiuPbkqV1+gmFxfzzETLADOHOyX/swP12nwqwq/adv9663WgYUb5tWAU0SptRh8guVYGbB5elRfTPr0NglZrQPXotxc3PKRv8lmY9DRdv3VIwMKt1zFOqxX9CwJ+rRKhSGUy+Va8YHSc6Cbk4qhUygFJKkfWBdRdMkOsVVj3omSYANAdQeyYkBFVPk1WW+tgqGW/nTpsRnvknewjnuM0S+kaBRb0QvrYCzyAQmInkn4naWdDKjux1BbEaL3il+ZWeG53Sh/xXJcTUUxgBgw0lALrXYYyG8wheGu9ic2hiC6ubab2BZ67AJvknrjW7cm17jVVtmh9MFrhM37fXvnUnN91uTk31tzIo/v3qhuYizOzfe5CCqA1BQ9Yoqrdus7jw1YBQ==',
      },
    },
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
        'fsid'                      => '62ed9bd6-adf4-11e4-8fb5-3c970ebb2b86', # Don't use this default, use `uuidgen`!
        'mon_initial_members'       => 'hyp8,hyp10,hyp12',
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
    mon_key => 'AQA7yNlUMy3sFhAA62XHf57L0QhSI44qqqOVXA==', # Don't use this default, use `ceph-authtool --gen-key`
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
    disks   => parsejson(inline_template('
    {
      <% first = true -%>
      <% @diskinfo_blockdev_model_to_hctl["PERC H700"].each do |dev| -%>
      <% if(!first) then -%>,<% end -%>"<%= dev -%>/<%= @diskinfo_blockdev_model_to_hctl["Kingston SHPM228"][0] -%>": {}
      <% first = false -%>
      <% end -%>
    }')),
  }

  # Ordering
  Package['ntp'] -> Class['ceph']
  Class['resolvconf'] -> Class['ceph']
  Debnet::Iface::Bond['bond0'] -> Service['networking']
  Debnet::Iface::Static['bond0.5'] -> Service['networking']
  Concat['/etc/network/interfaces'] ~> Service['networking']
  Service['networking'] -> Class['ceph']
}
