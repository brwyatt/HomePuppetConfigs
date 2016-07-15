node 'devtop' {
  class { 'apt':
    update => {
      frequency => 'daily',
    },
  }

  apt::source { 'System76 Development':
    location => 'http://ppa.launchpad.net/system76-dev/stable/ubuntu',
    repos    => 'main',
    key      => {
      id     => '5D1F3A80254F6AFBA254FED5ACD442D1C8B7748B',
      server => 'hkp://keyserver.ubuntu.com',
    },
  }

  apt::source { 'Syncthing':
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

  apt::source { 'nilstimogard webupd8':
    location => 'http://ppa.launchpad.net/nilarimogard/webupd8/ubuntu',
    repos    => 'main',
  }

  apt::source { 'Google Chrome':
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
    mode   => '755',
  }
  file { '/etc/lightdm/lightdm.conf.d/50-no-guest.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '755',
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

  Apt::Key <| |> -> Apt::Source <| |>
  Apt::Source <| |> -> Class['apt::update']
  Class['apt::update'] -> Package <| provider == 'apt' |>
}
