Package {
  allow_virtual => true,
}

node default {

  include wget

  $db_root_password           = hiera('db_root_password')
  $owncloud_database          = hiera('owncloud_database')
  $owncloud_db_user           = hiera('owncloud_db_user')
  $owncloud_db_user_password  = hiera('owncloud_db_user_password')
  $gmail_address              = hiera('gmail_address')
  $gmail_app_password         = hiera('gmail_app_password')

  package { [
    'owncloud',
    'mod_ssl',
    'php-pecl-apc',
    'php-mysql',
    'mod_xsendfile',
    'ntp',
    'sendmail-cf',
    ]:
    ensure  => installed,
  }

  class { '::mysql::server':
    root_password           => $db_root_password,
    remove_default_accounts => true,
  }

  mysql::db { $owncloud_database :
    user     => $owncloud_db_user,
    password => $owncloud_db_user_password,
    host     => 'localhost',
    grant    => 'ALL',
  }

  file { '/etc/httpd/conf.d/welcome.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0664',
    source  => 'puppet:///files/welcome.conf',
    require => Package[ 'owncloud' ],
  }

  file { '/etc/httpd/conf.d/owncloud-99.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0664',
    source  => 'puppet:///files/owncloud-99.conf',
    require => Package[ 'owncloud' ],
  }

  file { '/usr/share/owncloud/assets':
    ensure  => directory,
    owner   => 'root',
    group   => 'apache',
    mode    => '0775',
    require => Package[ 'owncloud' ],
  }

  cron { 'owncloud':
    command => '/usr/bin/php -f /usr/share/owncloud/cron.php',
    user    => 'apache',
    minute  => '*/15',
    require => Package[ 'owncloud' ],
  }

  file { '/etc/mail/authinfo/gmail-auth':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    require => Package[ 'sendmail-cf' ],
  }

  file_line { 'gmail-auth':
    path    => '/etc/mail/authinfo/gmail-auth',
    line    => "AuthInfo: \"U:root\" \"I:${gmail_address}\" \"P:${gmail_app_password}\"",
    require => File[ '/etc/mail/authinfo/gmail-auth' ],
  }

  file { '/etc/mail/sendmail.mc':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///files/sendmail.mc',
    require => Package[ 'sendmail-cf' ],
  }

  file { '/etc/mail/authinfo':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package[ 'sendmail-cf' ],
  }

  exec { 'sendmail makemap':
    command => '/sbin/makemap hash gmail-auth < gmail-auth',
    cwd     => '/etc/mail/authinfo',
    user    => 'root',
    require => [ File_line[ 'gmail-auth' ],
                File[ '/etc/mail/sendmail.mc' ],
                File[ '/etc/mail/authinfo' ] ],
  }

  exec { 'sendmail make':
    command => '/usr/bin/make -C /etc/mail',
    cwd     => '/etc/mail',
    user    => 'root',
    require => Exec[ 'sendmail makemap' ],
  }

  exec { 'sendmail unmask':
    command => '/usr/bin/systemctl unmask sendmail',
    user    => 'root',
    require => Exec[ 'sendmail make' ],
  }

  selboolean { 'httpd_can_sendmail':
    persistent => true,
    value      => on,
  }

  selboolean { 'logging_syslogd_can_sendmail':
    persistent => true,
    value      => on,
  }

  service { 'ntpd':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package[ 'ntp' ],
  }

  service { 'sendmail':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package[ 'sendmail-cf' ],
  }

  service { 'httpd':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package[ 'owncloud' ],
  }

# Configure the firewall

  class { 'firewalld::configuration':
    default_zone  => 'public',
  }

  firewalld::zone { 'public':
    services => ['ssh', 'dhcpv6-client'],
    ports    => [
                  {
                    port     => '80',
                    protocol => 'tcp',
                  },
                  {
                    port     => '443',
                    protocol => 'tcp',
                  }
                ],
  }

}
