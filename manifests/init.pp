class oxford_nfs_server (  )
inherits oxford_nfs_server::params 
{
   notify { "This class requires a manual keytab to be created with {host,nfs,[cifs]}/$(hostname).physics.ox.ac.uk@PHYSICS.OX.AC.UK, " : }
   notify { "To do this: create a user in the Users part of the AD, name should be [svcname][hsotname] eg nfsCplxfs3.  Next log on to DC3, open an administrator command prompt, and run ktpass -princ [svc]/fqdn@PHYSICS.OX.AC.UK -mapuser {svcname}{hostname}@PHYSICS.OX.AC.UK -mapop add -out new.keytab.  Secure copy this from DC3 to /etc/krb5.keytab on the new file server" : }
   class { "oxford_nfs_server::generic" : }
   class { "oxford_nfs_server::nfs" : }
}

class oxford_nfs_server::nfs (
   $secretsfilepath = $oxford_nfs_server::params::secretsfilepath,
   $configfilepath = $oxford_nfs_server::params::configfilepath
) inherits oxford_nfs_server::params 
{

   $central_nfs_packagelist = ['pam_krb5', 'openldap-clients','nfs-utils', 'nfs4-acl-tools']
   $servicelist = ['nfs', 'rpcgssd', 'rpcsvcgssd', 'rpcidmapd']
   ensure_packages ( $central_nfs_packagelist )
   service{  $servicelist:
                   ensure => running,
                   hasstatus => true,
                   hasrestart => true,
                   enable => true,
                   require => [Package[$central_nfs_packagelist], Class['oxford_nfs_server::generic']],
        }

       file { '/etc/sysconfig/nfs':

          source =>  "puppet:///$configfilepath/sysconfig.nfs",
          require => Package['nfs-utils'],
          owner   => 'root',
          group   => 'root',
          mode    => '0444',
          notify => Service['nfs']
       }

       file { '/etc/idmapd.conf':

          source =>  "puppet:///$idmapdfilepath/idmapd.conf",
          require => Package['nfs-utils'],
          owner   => 'root',
          group   => 'root',
          mode    => '0444',
          notify => Service['nfs']
      }
       #Actually need a reboot here
       file { '/etc/modprobe.d/nfs.conf':

          source =>  "puppet:///$configfilepath/nfs.conf",
          require => Package['nfs-utils'],
          owner   => 'root',
          group   => 'root',
          mode    => '0444',
          notify => Service['nfs']
      }
       
}

class oxford_nfs_server::generic   (
   $secretsfilepath = $oxford_nfs_server::params::secretsfilepath,
   $configfilepath = $oxford_nfs_server::params::configfilepath
) inherits oxford_nfs_server::params
{
      $servicelist = ['rpcbind']
      $packages =  [ 'krb5-libs', 'krb5-workstation']
      ensure_packages ( $packages )
   
  file { '/etc/nscd.conf':
      ensure  => present,
      source  => "puppet:///$configfilepath/nscd.conf",
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
  }

}
