# == Define: ssl::self_sigend_certificate
#
# This define creates a self_sigend certificate.
# No deeper configuration possible yet.
#
# This works on Debian and RedHat like systems.
# Puppet Version >= 3.4.0
#
# === Parameters
#
# [*numbits*]
#   Bits for private RSA key.
#   *Optional* (defaults to 2048)
#
# [*common_name*]
#   Common name for certificate.
#   *Optional* (defaults to $::fqdn)
#
# [*email_address*]
#   Email address for certificate.
#   *Optional* (defaults to undef)
#
# [*country*]
#   Country in certificate. Must be empty or 2 character long.
#   *Optional* (defaults to undef)
#
# [*state*]
#   State in certificate.
#   *Optional* (defaults to undef)
#
# [*locality*]
#   Locality in certificate.
#   *Optional* (defaults to undef)
#
# [*organization*]
#   Organization in certificate.
#   *Optional* (defaults to undef)
#
# [*unit*]
#   Organizational unit in certificate.
#   *Optional* (defaults to undef)
#
# [*subject_alt_name*]
#   SubjectAltName in certificate, e.g. for wildcard
#   set to 'DNS:..., DNS:..., ...'
#   *Optional* (defaults to undef)
#
# [*days*]
#   Days of validity.
#   *Optional* (defaults to 365)
#
# [*directory*]
#   Were to put the resulting files.
#   *Optional* (defaults to /etc/ssl)
#
# [*owner*]
#   Owner of files.
#   *Optional* (defaults to root)
#
# [*group*]
#   Group of files.
#   *Optional* (defaults to root)
#
define ssl::self_signed_certificate (
  Numeric          $numbits          = 2048,
  Stdlib::Fqdn     $common_name      = $::fqdn,
  Optional[String] $email_address    = undef,
  Optional[String] $country          = undef,
  Optional[String] $state            = undef,
  Optional[String] $locality         = undef,
  Optional[String] $organization     = undef,
  Optional[String] $unit             = undef,
  Optional[String] $subject_alt_name = undef,
  Numeric          $days             = 365,
  Stdlib::UnixPath $certdir          = '/etc/ssl',
  Stdlib::UnixPath $keydir           = '/etc/ssl',
  String           $owner            = root,
  String           $group            = root,
) {

  include ssl::install

  Exec {
    path => $::path,
  }

  # Define paths for ssl config, certificate and private key files
  # ---------------------------------------------------------------------------------------------------
  $cert = "${certdir}/${name}.crt"
  $conf = "${certdir}/${name}.cnf"
  $key  = "${keydir}/${name}.key"


  # Create directories (since they can be nested, first run mkdir -p)
  # ---------------------------------------------------------------------------------------------------
  ensure_resources('exec', 
  {
    "mkdir -p ${certdir}" => { creates => $certdir },
    "mkdir -p ${keydir}"  => { creates => $keydir  }
  })

  ensure_resource('file', [$certdir, $keydir],
  {
    ensure  => directory,
    require => Exec["mkdir -p ${certdir}", "mkdir -p ${keydir}"],
  })

  # Create ssl config file
  # ---------------------------------------------------------------------------------------------------
  file { $conf:
    content => template('ssl/cert.cnf.erb'),
    owner   => $owner,
    group   => $group,
    require => File[$certdir, $keydir],
    notify  => Exec["create certificate ${cert}"],
  }

  # Create private key
  # ---------------------------------------------------------------------------------------------------
  exec { "create private key ${key}":
    command => "openssl genrsa -out ${key} ${numbits}",
    creates => $key,
    require => File[$conf], # not really need, but for ordering
    before  => File[$key],
    notify  => Exec["create certificate ${cert}"]
  }
  file { $key:
    mode  => '0600',
    owner => $owner,
    group => $group,
  }

  # Create certificate
  # ---------------------------------------------------------------------------------------------------
  exec { "create certificate ${cert}":
    command     => "openssl req -new -x509 -days ${days} -config ${conf} -key ${key} -out ${cert}",
    refreshonly => true,
    before      => File[$cert],
  }
  file { $cert:
    mode  => '0644',
    owner => $owner,
    group => $group,
  }
}
