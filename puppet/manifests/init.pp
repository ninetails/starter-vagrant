node 'default' {
  group { 'puppet': ensure => present }
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }
  File { owner => 0, group => 0, mode => 0644 }

  class { 'apt':
    always_apt_update => true
  }

  exec { 'apt-get update':
    command => 'apt-get update -qq',
    path    => '/usr/bin/',
    timeout => 60,
    tries   => 3
  }

  apt::ppa { 'ppa:ondrej/php5':
    before  => Class['php']
  }

  $basic_packages = hiera('basic_package', [
    'build-essential',
    'python-software-properties',
    'aptitude',
    'curl',
    'vim',
    'zip'
  ])

  package { $basic_packages:
    ensure => present,
    require => Exec['apt-get update']
  }

  # apache
  class { 'apache':
    require => Apt::Ppa['ppa:ondrej/php5']
  }

  apache::vhost { 'default':
    docroot  => '/vagrant'
  }

  apache::module { 'rewrite': }

  # php
  class { 'php':
    version => 'latest',
    service => 'apache',
    require => Package['apache']
  }

  $php_modules = hiera('php_modules', [
    'cli',
    'curl',
    'intl',
    'mcrypt',
    'mysqlnd'
  ])

  php::module { $php_modules: }

  php::module { ["apc"]:
    module_prefix => "php-"
  }

  class { 'php::pear':
    require => Class['php']
  }

  class { 'php::devel':
    require => Class['php']
  }

  php::ini { 'default':
    value  => [
      'date.timezone = America/Sao_Paulo',
      'display_errors = On',
      'error_reporting = -1'
    ],
    target => 'error_reporting.ini'
  }

  class { 'xdebug':
    require => Class['php']
  }

  class { 'composer':
    require => Package['php5']
  }

}
