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

  include git

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

  apt::source { 'google-chrome':
    location     => 'http://dl.google.com/linux/chrome/deb/',
    release      => 'stable',
    repos        => 'main',
    architecture => 'amd64',
    key          => {
      id     => 'EB4C1BFD4F042F6DDDCCEC917721F63BD38B4796',
      source => 'https://dl.google.com/linux/linux_signing_key.pub',
    },
  }

  apt::source { 'steam':
    location     => 'http://repo.steampowered.com/steam/',
    release      => 'precise',
    repos        => 'steam',
    architecture => 'amd64,i386',
    key          => {
      id     => 'BA1816EF8E75005FCF5E27A1F24AEA9FB05498B7',
      source => 'http://repo.steampowered.com/steam/signature.gpg',
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

  git::config { 'user.name':
    user  => 'brwyatt',
    value => 'Bryan Wyatt',
  }
  git::config { 'user.email':
    user  => 'brwyatt',
    value => 'brwyatt@gmail.com',
  }
  git::config { 'core.editor':
    user  => 'brwyatt',
    value => 'vim',
  }
  git::config { 'push.default':
    user  => 'brwyatt',
    value => 'simple',
  }

  package { 'system76-driver':
    ensure => installed,
  }
  package { 'system76-driver-nvidia':
    ensure => installed,
  }

  package { [ 'htop', 'nmon', 'screen', 'glipper', 'traceroute', 'whois' ]:
    ensure => installed,
  }
  package { 'vim-nox':
    ensure => installed,
  }
  package { [ 'python-pip', 'python3-pip' ]:
    ensure => installed,
  }

  package { [ 'syncthing', 'syncthing-inotify', 'syncthing-gtk' ]:
    ensure => latest,
  }

  package { 'google-chrome-stable':
    ensure => latest,
  }

  package { 'vlc':
    ensure => installed,
  }
  package { 'steam-launcher':
    ensure => latest,
  }

  package { [ 'virtualbox', 'virtualbox-dkms', 'virtualbox-ext-pack',
              'virtualbox-guest-additions-iso' ]:
    ensure => installed,
  }
  package { 'vagrant':
    ensure => installed,
  }
  package { 'zlib1g-dev':
    ensure => installed,
  }

  # Patch Vagrant for issue #7973
  #   https://github.com/mitchellh/vagrant/issues/7073
  $vagrant_bundler_patch = '/tmp/vagrant_bundler.patch'
  $vagrant_libs = '/usr/lib/ruby/vendor_ruby/vagrant/'
  file { $vagrant_bundler_patch:
    ensure => present,
    content => join([
			'--- bundler.rb',
			'+++ bundler.rb',
      '@@ -272,7 +272,6 @@ module Vagrant',
      ' ',
      '       # Reset the all specs override that Bundler does',
      '       old_all = Gem::Specification._all',
      '-      Gem::Specification.all = nil',
      ' ',
      '       # /etc/gemrc and so on.',
      '       old_config = nil',
      '@@ -286,6 +285,8 @@ module Vagrant',
      '       end',
      '       Gem.configuration = NilGemConfig.new',
      ' ',
      '+      Gem::Specification.reset',
      '+',
      '       # Use a silent UI so that we have no output',
      '       Gem::DefaultUserInteraction.use_ui(Gem::SilentUI.new) do',
      '         return yield',
      '',
    ], "\n"),
  }
  exec { 'Patch Vagrant Bundler':
    path    => '/usr/bin:/bin',
    command => "patch -N --silent bundler.rb ${vagrant_bundler_patch}",
    onlyif  => "patch -N --dry-run --silent bundler.rb ${vagrant_bundler_patch}",
    cwd     => $vagrant_libs,
    require => [ File[$vagrant_bundler_patch], Package['vagrant'] ],
  }

  Apt::Key['Launchpad webupd8'] -> Apt::Source['nilstimogard_webupd8']
  Apt::Source <| |> ~> Exec['apt_update']
  Exec['apt_update'] -> Package <| |>
}
