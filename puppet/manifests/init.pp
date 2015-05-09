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
    tries   => 3,
    require => Apt::Ppa['ppa:ondrej/php5']
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
  $apache_docroot = hiera('apache_docroot', '/vagrant')
  class { 'apache':
    mpm_module    => 'prefork',
    default_vhost => false,
    docroot       => $apache_docroot,
    require       => Apt::Ppa['ppa:ondrej/php5']
  }

  # Change user
  exec { "ApacheUserChange" :
    command => "sed -i 's/APACHE_RUN_USER=www-data/APACHE_RUN_USER=vagrant/' /etc/apache2/envvars",
    onlyif  => "grep -c 'APACHE_RUN_USER=www-data' /etc/apache2/envvars",
    require => Package["apache2"],
    notify  => Service["apache2"]
  }

  # Change group
  exec { "ApacheGroupChange" :
    command => "sed -i 's/APACHE_RUN_GROUP=www-data/APACHE_RUN_GROUP=vagrant/' /etc/apache2/envvars",
    onlyif  => "grep -c 'APACHE_RUN_GROUP=www-data' /etc/apache2/envvars",
    require => Package["apache2"],
    notify  => Service["apache2"]
  }

  $apache_vhosts = hiera('apache_vhosts', {
    'vagrant.dev' => {
      default_vhost => true,
      vhost_name    => '*',
      port          => '80',
      docroot       => '/vagrant',
      override      => 'All',
      serveraliases => [
        'www.vagrant.dev'
      ]
    }
  })

  create_resources(apache::vhost, $apache_vhosts)

  apache::mod { 'rewrite': }

  # php
  class { 'php':
    version => 'latest',
    service => 'apache2',
    require => Class['apache']
  }

  $php_modules = hiera('php_modules', [
    'cli',
    'curl',
    'gd',
    'intl',
    'mcrypt',
    'mysqlnd',
    'xsl'
  ])

  php::module { $php_modules: }

  php::module { 'apc':
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
    require => Class['php']
  }

  # mysql
  $mysql_root_password = hiera('mysql_root_pass', '123456')
  class { 'mysql::server':
    root_password => $mysql_root_password,
  }

  $mysql_db = hiera('mysql_db', {
    'db' => {
      user     => 'dev',
      password => '123456',
      host     => 'localhost',
      grant    => ['all'],
      charset  => 'utf8'
    }
  })

  create_resources(mysql::db, $mysql_db, {require => File['/root/.my.cnf']})

  # node.js
  class { 'nodejs': }

  $npm_modules = hiera('npm_modules', [
    'bower',
    'gulp',
    'stylus'
  ])

  package { $npm_modules:
    ensure   => 'present',
    provider => 'npm',
    require  => Class['nodejs']
  }

}
