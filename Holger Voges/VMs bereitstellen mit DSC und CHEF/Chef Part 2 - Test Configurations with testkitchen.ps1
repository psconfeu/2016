<#
    The following scripts are examples from the European Powershell Conference 2016
    
    Track-Title: "VMs bereitstellen mit DSC und Chef"
    Part 5: Using test-kitchen to test your Configuration before deployment
    
    Author: Holger Voges
    web: www.netz-weise-it.training
    email: holger.voges(at)netz-weise.de
    twitter: @HolgerVoges
#>

# the following script is a short version of the chef-tutorial from chef.io. For 
# the comprehensive lab, go to the chef-tutorial.
# https://learn.chef.io/local-development/windows/

$startdir = "$home\learn-Chef"
if ( -not ( test-path $startdir ))
{ mkdir $startdir }
Set-Location $startdir
$cookbooksDir = (mkdir cookbooks ).FullName

# 1. Management Workstation bereitstellen
        # Chef DK installieren
        # Text-Editor aufsetzen
# Chef-Zero-scheduled-task Plugin installieren (startet Jobs lokal als geplante Tasks, nicht über winrm)
chef gem install chef-zero-scheduled-task
# Testkitchen VM für Hyper-V einrichten
# kitchen-hyperv-Treiber installieren
chef gem install kitchen-hyperv

# Hyper-V auf VM installieren

# WimRm konfigurieren
# winrm quickconfig -qwinrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
# winrm set winrm/config '@{MaxTimeoutms="1800000"}'
# winrm set winrm/config/service '@{AllowUnencrypted="true"}'
# winrm set winrm/config/service/auth '@{Basic="true"}' 
# netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
# netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in localport=5986 action=allow 
# net stop winrm
# sc.exe config winrm st



# Kochbuch generieren
chef generate cookbook cookbooks/settings_windows

# template-file genieren
chef generate template cookbooks/settings_windows server-info.txt

# Die Serverinfo wird aus Node-Attributen ausgelesen
$serverinfoErb = @"
fqdn:      <%= node['fqdn'] %>
hostname:  <%= node['hostname'] %>
platform:  <%= node['platform'] %> - <%= node['platform_version'] %>
cpu count: <%= node['cpu']['total'] %>
"@

$serverinfoErb | out-file $cookbooksDir\Settings_windows\templates\default\server-info.txt.erb -Append -Encoding utf8
code "$cookbooksDir\Settings_windows\templates\default\server-info.txt.erb" 

# Default-Recipe erstellen 
$defaultRecipe = @"
directory 'C:/temp'

template 'C:/temp/server-info.txt' do
  source 'server-info.txt.erb'
end
"@

$defaultRecipe | out-file $cookbooksDir\Settings_Windows\recipes\default.rb -Encoding utf8
code $cookbooksDir\Settings_Windows\recipes\default.rb

# Testkitchen 
code $cookbooksDir\Settings_Windows\.kitchen.yml
code 'C:\Users\hvoge\ChefTemplate\.kitchen.yml'
Copy-Item -Path 'C:\Users\hvoge\ChefTemplate\.kitchen.yml' -Destination $cookbooksDir\Settings_Windows\.kitchen.yml -Force
# Mehr zur .kitchen.yml unter:
# https://docs.chef.io/config_yml_kitchen.html

Set-Location $cookbooksDir\Settings_Windows 
kitchen list

kitchen create

kitchen list 

kitchen converge
$LASTEXITCODE

# Datei Server-info in Testkitchen überprüfen
$pw = ConvertTo-SecureString -String 'Passw0rd' -AsPlainText -Force
$username = 'administrator'
$cred = New-Object pscredential ($username,$pw)
Enter-PSSession -ComputerName testkitchen -Credential $cred
Get-Content C:\temp\server-info.txt
Exit-PSSession

# Testkitchen entfernen
Kitchen destroy