node 'devtop' {
  class { 'apt':
    purge  => {
      'sources.list'   => true,
      'sources.list.d' => true,
    },
    update => {
      frequency => 'daily',
    },
  }

  file { '/etc/apt/sources.list.d/canonical_ubuntu.list':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => join([
      'deb http://us.archive.ubuntu.com/ubuntu/ xenial main restricted',
      'deb http://us.archive.ubuntu.com/ubuntu/ xenial-updates main restricted',
      'deb http://us.archive.ubuntu.com/ubuntu/ xenial universe',
      'deb http://us.archive.ubuntu.com/ubuntu/ xenial-updates universe',
      'deb http://us.archive.ubuntu.com/ubuntu/ xenial multiverse',
      'deb http://us.archive.ubuntu.com/ubuntu/ xenial-updates multiverse',
      'deb http://us.archive.ubuntu.com/ubuntu/ xenial-backports main restricted universe multiverse',
      'deb http://archive.canonical.com/ubuntu xenial partner',
      'deb-src http://archive.canonical.com/ubuntu xenial partner',
      'deb http://security.ubuntu.com/ubuntu xenial-security main restricted',
      'deb http://security.ubuntu.com/ubuntu xenial-security universe',
      'deb http://security.ubuntu.com/ubuntu xenial-security multiverse',
    ], "\n"),
    notify  => Exec['apt_update'],
  }

  apt::source { 'system76_development':
    location => 'http://ppa.launchpad.net/system76-dev/stable/ubuntu',
    repos    => 'main',
    key      => {
      id     => '5D1F3A80254F6AFBA254FED5ACD442D1C8B7748B',
      server => 'hkp://keyserver.ubuntu.com',
    },
  }

  apt::source { 'syncthing':
    location => 'http://apt.syncthing.net/',
    release  => 'syncthing',
    repos    => 'release',
    key      => {
      id     => '37C84554E7E0A261E4F76E1ED26E6ED000654A3E',
      source => 'https://syncthing.net/release-key.txt',
    },
  }

  apt::key { 'Launchpad webupd8':
    id     => '1DB29AFFF6C70907B57AA31F531EE72F4C9D234C',
    server => 'hkp://keyserver.ubuntu.com',
  }

  apt::source { 'nilstimogard_webupd8':
    location => 'http://ppa.launchpad.net/nilarimogard/webupd8/ubuntu',
    repos    => 'main',
  }

  apt::source { 'google_chrome':
    location     => 'http://dl.google.com/linux/chrome/deb/',
    release      => 'stable',
    repos        => 'main',
    architecture => 'amd64',
    key          => {
      id     => 'EB4C1BFD4F042F6DDDCCEC917721F63BD38B4796',
      source => 'https://dl.google.com/linux/linux_signing_key.pub',
    },
  }

  file { '/etc/lightdm/lightdm.conf.d':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { '/etc/lightdm/lightdm.conf.d/50-no-guest.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => join([
      '[SeatDefaults]',
      'allow-guest=false',
      '',
    ], "\n"),
  }

  package { 'system76-driver':
    ensure => installed,
  }
  package { 'system76-driver-nvidia':
    ensure => installed,
  }

  package { 'vim-nox':
    ensure => installed,
  }

  package { [ 'syncthing', 'syncthing-inotify', 'syncthing-gtk' ]:
    ensure => latest,
  }

  package { 'google-chrome-stable':
    ensure => latest,
  }

  Apt::Key['Launchpad webupd8'] -> Apt::Source['nilstimogard_webupd8']
  Apt::Source <| |> ~> Exec['apt_update']
  Exec['apt_update'] -> Package <| |>
}
