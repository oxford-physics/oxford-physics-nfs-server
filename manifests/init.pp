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


   case $::operatingsystem {
      /Scientific/, /CentOS/: {
         case $::operatingsystemmajrelease {
           default : {}
           /6/: {
             $servicelist = ['nfs', 'rpcgssd', 'rpcsvcgssd', 'rpcidmapd']
             $central_nfs_packagelist = ['pam_krb5', 'openldap-clients','nfs-utils', 'nfs4-acl-tools']
             $nfsservicenotifylist = Service['nfs']

           }
           /7/: {
            $servicelist = ['rpcbind', "nfs-server", "nfs-secure-server", "nfs-lock", "nfs-idmap" ]
            $central_nfs_packagelist = ['nfs-utils', 'nfs-utils-lib', "rdma"]
            $nfsservicenotifylist = Service['nfs-secure-server']
           }
         }
      }
   }

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
          notify => $nfsservicenotifylist
       }

       file { '/etc/idmapd.conf':

          source =>  "puppet:///$idmapdfilepath/idmapd.conf",
          require => Package['nfs-utils'],
          owner   => 'root',
          group   => 'root',
          mode    => '0444',
          notify => $nfsservicenotifylist
      }
       #Actually need a reboot here
       file { '/etc/modprobe.d/nfs.conf':

          source =>  "puppet:///$configfilepath/nfs.conf",
          require => Package['nfs-utils'],
          owner   => 'root',
          group   => 'root',
          mode    => '0444',
          notify => $nfsservicenotifylist
      }
       
}

class oxford_nfs_server::generic   (
   $secretsfilepath = $oxford_nfs_server::params::secretsfilepath,
   $configfilepath = $oxford_nfs_server::params::configfilepath
) inherits oxford_nfs_server::params
{
      $packages =  [ 'krb5-libs', 'krb5-workstation']
      ensure_packages ( $packages )
      case $::operatingsystem {
      /Scientific/, /CentOS/: {
         case $::operatingsystemmajrelease {
           default : {}
           #Lets try sl7 without nscd
           /6/: {

                 file { '/etc/nscd.conf':
                       ensure  => present,
                       source  => "puppet:///$configfilepath/nscd.conf",
                       owner   => 'root',
                       group   => 'root',
                       mode    => '0444',
                 }
           }
         }
     }}

}
