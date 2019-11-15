# == Define: ssl::generate_dh_key
#
# Generate a Diffie-Hellmann key.
# Output of $directory/$title.pem is created.
#
# This works on Debian and RedHat like systems.
# Puppet Version >= 3.4.0
#
# === Parameters
#
# [*numbits*]
#   Number of bits for parameter set.
#   *Optional* (defaults to 512)
#
# [*generator*]
#   Generator to use, valid 2 or 5.
#   *Optional* (defaults to 2)
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
define ssl::generate_dh_key (
  Numeric          $numbits          = 512,
  Numeric          $generator        = 2,
  Stdlib::Unixpath $directory        = '/etc/ssl',
  String           $owner            = 'root',
  String           $group            = 'root',
) {

  include ssl::install

  # basename for key
  $basename = "${directory}/${name}"

  ensure_resource('file', $directory, { ensure => directory })

  # create Diffie-Hellmann key
  exec {"create DH key ${name}.pem":
    command => "openssl dhparam -out ${basename}.pem -${generator} ${numbits}",
    creates => "${basename}.pem",
    path    => ['/usr/bin'],
    before  => File["${basename}.pem"],
  }
  file {"${basename}.pem":
    mode  => '0644',
    owner => $owner,
    group => $group,
  }
}
