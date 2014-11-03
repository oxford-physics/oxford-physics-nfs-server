class oxford_nfs_server::params ( 
      $secretsfilepath = hiera("oxford_nfs_server::params::secretsfilepath",  "site_files/oxford_nfs_server"), 
      $configfilepath =  hiera("oxford_nfs_server::params::configfilepath", "modules/$module_name") ,
      $idmapdfilepath = hiera("oxford_nfs_server::params::idmapdfilepath", "modules/$module_name")
)
{ 
   notify { "This class requires a manual keytab to be created with {host,nfs,[cifs]}/$(hostname).physics.ox.ac.uk@PHYSICS.OX.AC.UK.. ": }
   notify { "To do this: create a user in the Users part of the AD, name should be [svcname][hsotname] eg nfsCplxfs3.  Next log on to DC3, open an administrator command prompt, and run ktpass -princ [svc]/fqdn@PHYSICS.OX.AC.UK -mapuser {svcname}{hostname}@PHYSICS.OX.AC.UK -mapop add -out new.keytab.  Secure copy this from DC3 to /etc/krb5.keytab on the new file server .. " : }

}
