class central_file_server {
   notify { "This class requires a manual keytab to be created with {host,nfs,[cifs]}/$(hostname).physics.ox.ac.uk@PHYSICS.OX.AC.UK, ": }
   notify { "To do this: create a user in the Users part of the AD, name should be [svcname][hsotname] eg nfsCplxfs3.  Next log on to DC3, open an administrator command prompt, and run ktpass -princ [svc]/fqdn@PHYSICS.OX.AC.UK -mapuser {svcname}{hostname}@PHYSICS.OX.AC.UK -mapop add -out new.keytab.  Secure copy this from DC3 to /etc/krb5.keytab on the new file server" :}
   class { "central_file_server::generic" :}
   class { "central_file_server::nfs" :}
   class { "central_file_server::samba" :}
}

class central_file_server::nfs {

   secretspath = "modules/$module_name"
   configfilepath = "modules/$module_name"
   $central_nfs_packagelist = ['pam_krb5', 'openldap-clients','nfs-utils', 'nfs4-acl-tools']
   $servicelist = ['nfs', 'rpcgssd', 'rpcsvcgssd' ]
   ensure_packages ( $central_nfs_packagelist )
   service{  $servicelist:
                   ensure => running,
                   hasstatus => true,
                   hasrestart => true,
                   enable => true,
                   require => [Package[$central_nfs_packagelist], Class['central_file_server::generic']],
        }

       file { '/etc/sysconfig/nfs':

          source =>  "puppet:///$configfilepath/sysconfig.nfs.central_nfs_server",
          require => Package['nfs-utils'],
          owner   => 'root',
          group   => 'root',
          mode    => '0400',
          notify => Service['nfs']
       }

       
}

class central_file_server::generic {
      $servicelist = ['nslcd','rpcbind','rpcidmapd']
      $packages =  ['nss-pam-ldapd', 'openldap', 'pam_krb5', 'krb5-libs', 'krb5-workstation']
      ensure_packages ( $packages )
         service{$servicelist:
                   ensure => running,
                   hasstatus => true,
                   hasrestart => true,
                   enable => true,
        }
#Making it secret, it does give a few things away 
    file { '/etc/krb5.conf':
      ensure  => present,
      source  => "puppet:///$secretsfilepath/krb5.conf.central_file_server",
      require => Package['pam_krb5'],
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
  }
    file { '/etc/nscd.conf':
      ensure  => present,
      source  => "puppet:///$configfilepath/nscd.conf.central_file_server",
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
  }

    file { '/etc/nslcd.conf':
      ensure  => present,
      source  => "puppet:///$secretsfilepath/nslcd.conf.central_file_server",
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      require => Package['nss-pam-ldapd'],
      notify =>  Service['nslcd'],
   }
   file { '/etc/ldap' : 
        ensure => directory, 
        owner => 'root',
        group => 'root',
        mode => 755,
   }
   file { '/etc/ldap.conf':
         ensure =>present, 
         source  => "puppet:///$secretsfilepath/ldap.conf.central_file_server", 
         owner   => 'root',
         group   => 'root',
         mode    => '0400',
         notify =>  Service['nslcd'],
  }
   file { '/etc/openldap/ldap.conf':
         ensure =>present, 
         source  => "puppet:///$secretsfilepath/ldap.conf.central_file_server", 
         owner   => 'root',
         group   => 'root',
         mode    => '0400',
         require => Package['openldap'],
         notify =>  Service['nslcd'],
  }

  file {  '/etc/ldap/ldap.conf':
         ensure =>present,
         source  => "puppet:///$secretsfilepath/ldap.conf.central_file_server",
         owner   => 'root',
         group   => 'root',
         mode    => '0400',
         notify =>  Service['nslcd'],
  }
   file { '/etc/request-key.conf':
         ensure =>present,
         source  => "puppet:///$secretsfilepath/request-key.conf",
         owner   => 'root',
         group   => 'root',
         mode    => '0400',
         notify =>  [Service['nslcd'], Service['smb']],
  }

  #Not that secret, but can give a few things away
   file { '/etc/pam.d/system-auth':
         ensure =>present,
         source  => "puppet:///$secretsfilepath/pam.d.system-auth.central_file_server",
         owner   => 'root',
         group   => 'root',
         mode    => '0400',
  }

}
class central_file_server::samba {
   $central_samba_packagelist = ['samba', 'openldap-clients']
   $servicelist = ['nmb','smb']
   ensure_packages ( $central_samba_packagelist )
   service{  $servicelist:
                   ensure => running,
                   hasstatus => true,
                   hasrestart => true,
                   enable => true,
#                   subscribe => '/etc/samba/smb.conf',
                   require => Package[$central_samba_packagelist]
    }

 #     file { '/etc/samba/smb.conf' : 
 #          source  =>  "samba.smb.conf.central_samba_server", 
#           owner => 'root',
 #          group => 'root',
  #         mode => 0444,
   #   }
      file { '/etc/pam.d/samba' : 
           source  =>  "puppet:///$secretsfilepath/pam.d.samba.central_samba_server", 
           owner => 'root',
           group => 'root',
           mode => 0444,
      }

}
