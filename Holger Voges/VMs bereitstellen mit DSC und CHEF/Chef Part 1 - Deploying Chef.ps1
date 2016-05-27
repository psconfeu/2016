<#
    The following scripts are examples from the European Powershell Conference 2016
    
    Track-Title: "VMs bereitstellen mit DSC und Chef"
    Part 4: Installing Chef 
    
    Author: Holger Voges
    web: www.netz-weise-it.training
    email: holger.voges(at)netz-weise.de
    twitter: @HolgerVoges
#>

# the following script is a short version of the chef-tutorial from chef.io. For 
# the comprehensive lab, go to the chef-tutorial.
# https://learn.chef.io/manage-a-node/windows/get-set-up/

$startdir = "$home\learn-Chef"
if ( -not ( test-path $startdir ))
{ mkdir $startdir }
Set-Location $startdir
$cookbooksDir = (mkdir cookbooks ).FullName

# Install Chef Development Kit
# Install Knife Windows Plugin
chef gem install knife-windows


Start-process -filepath https://manage.chef.io
# knife.rb und Zertifikat im .Chef-Ordner bereitstellen
# Der .Chef-Ordner kann im Root liegen (default) oder in einem Unterordner von Knife


# Kochbuch bei Chef herunterladen
knife cookbook site download learn_chef_iis
tar.exe -zxvf learn_chef_iis-0.2.1.tar.gz -C cookbooks
Remove-Item learn_chef_iis*.tar.gz

# Kochbuch zu Chef hochladen
knife cookbook upload learn_chef_iis


# Host Boostrapen
$Computer = 'Hostname'
$cert = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -DnsName $Computer

# https-Listener entfernen
winrm delete winrm/config/Listener?Address=*+Transport=HTTPS

# neuen https-Listener mit Zertifikat anlegen
New-Item -Address * -Force -Path wsman:\localhost\listener -Port 5986 -HostName ($cert.subject -split '=')[1] -Transport https -CertificateThumbPrint $cert.Thumbprint

# winrm konfigurieren
Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB 1024
Set-Item WSMan:\localhost\MaxTimeoutms 1800000

# Firewall öffnen
netsh advfirewall firewall add rule name="WinRM-HTTPS" dir=in localport=5986 protocol=TCP action=allow

# Verbindung von Admin-Workstation aus testen, Zeritifikatsüberprüfung deaktivieren
knife wsman test $Computername --manual-list --winrm-transport ssl --winrm-ssl-verify-mode verify_none

# Knoten bootstrappen
Knife bootstrap windows winrm ADDRESS --winrm-user USER --winrm-password 'PASSWORD' --node-name node1 --run-list 'recipe[learn_chef_iis]' --winrm-transport ssl --winrm-ssl-verify-mode verify_none

# Erfolg anzeigen 
knife node list

# Metadaten anzeigen
knife node list


