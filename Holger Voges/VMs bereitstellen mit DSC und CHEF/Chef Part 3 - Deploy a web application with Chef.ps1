<#
    The following scripts are examples from the European Powershell Conference 2016
    
    Track-Title: "VMs bereitstellen mit DSC und Chef"
    Part 6: Deploy a web-application with SQL Server using a chef cookbook
    
    Author: Holger Voges
    web: www.netz-weise-it.training
    email: holger.voges(at)netz-weise.de
    twitter: @HolgerVoges
#>

# the following script is a short version of the chef-tutorial from chef.io. For 
# the comprehensive lab, go to the chef-tutorial.
# https://learn.chef.io/manage-a-web-app/windows/

break;
#requires -Version 3 -Modules chef, PSDesiredStateConfiguration
$pw = ConvertTo-SecureString -String 'Passw0rd' -AsPlainText -Force
$username = 'administrator'
$cred = New-Object pscredential ($username,$pw)

$startdir = "$home\learn-Chef"
if ( -not ( test-path $startdir ))
{ mkdir $startdir }
Set-Location $startdir
$cookbooksDir = (Get-Item .\cookbooks  ).FullName

# neues cookbook erzeugen
chef generate cookbook cookbooks/awesome_customers_windows

# Testkitchen Konfiguration kopieren 
Copy-Item -Path 'C:\Users\hvoge\ChefTemplate\.kitchen2.yml' -Destination $cookbooksDir\awesome_customers_windows\.kitchen.yml -Force

# testkitchen anlegen und testen
Set-Location $cookbooksDir\awesome_customers_windows
kitchen list
kitchen converge
Enter-PSSession -ComputerName testkitchen -Credential $cred
(Get-DscLocalConfigurationManager).ConfigurationMode
Exit-PSSession

# Rezept zum Setzen des LCM erzeugen
Set-Location $startdir
chef generate recipe cookbooks/awesome_customers_windows lcm

# Rezept anlegen
$lcmRecipe = @'
powershell_script 'Configure the LCM' do
  code <<-EOH
    Configuration ConfigLCM
    {
        Node "localhost"
        {
            LocalConfigurationManager
            {
                ConfigurationMode = "ApplyOnly"
                RebootNodeIfNeeded = $false
            }
        }
    }
    ConfigLCM -OutputPath "#{Chef::Config[:file_cache_path]}\\DSC_LCM"
    Set-DscLocalConfigurationManager -Path "#{Chef::Config[:file_cache_path]}\\DSC_LCM"
  EOH
  not_if '(Get-DscLocalConfigurationManager | select -ExpandProperty "ConfigurationMode") -eq "ApplyOnly"'
end
'@

$lcmRecipe | out-file $cookbooksdir\awesome_customers_windows\recipes\lcm.rb -Encoding utf8 -Append
code $cookbooksdir\awesome_customers_windows\recipes\lcm.rb

# Das neue Rezept vom default runbook aufrufen
$defaultrb = @'
include_recipe 'awesome_customers_windows::lcm'
'@

$defaultrb | Out-File $cookbooksdir\awesome_customers_windows\recipes\default.rb -Encoding utf8 -Append

# Testen
Push-Location
Set-Location $cookbooksdir\awesome_customers_windows
kitchen converge
Pop-Location

chef generate recipe cookbooks/awesome_customers_windows web

$webrb = @'
# Enable the IIS role.
dsc_script 'Web-Server' do
  code <<-EOH
  WindowsFeature InstallWebServer
  {
    Name = "Web-Server"
    Ensure = "Present"
  }
  EOH
end

# Install ASP.NET 4.5.
dsc_script 'Web-Asp-Net45' do
  code <<-EOH
  WindowsFeature InstallDotNet45
  {
    Name = "Web-Asp-Net45"
    Ensure = "Present"
  }
  EOH
end

# Install the IIS Management Console.
dsc_script 'Web-Mgmt-Console' do
  code <<-EOH
  WindowsFeature InstallIISConsole
  {
    Name = "Web-Mgmt-Console"
    Ensure = "Present"
  }
  EOH
end
'@

$webrb | out-file $cookbooksdir\awesome_customers_windows\recipes\web.rb -Encoding UTF8 -Append
code $cookbooksdir\awesome_customers_windows\recipes\web.rb

$defaultrb = @'
include_recipe 'awesome_customers_windows::web'
'@

$defaultrb | Out-File $cookbooksdir\awesome_customers_windows\recipes\default.rb -Encoding utf8 -Append
code $cookbooksdir\awesome_customers_windows\recipes\default.rb

cd $cookbooksDir\awesome_customers_windows
kitchen converge


# Einen Passwort-Store erzeugen

$key = New-Object byte[](512)
$rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($key)
[Convert]::ToBase64String($key) | Out-File '$home\learn-chef\.chef\encrypted_data_bag_secret' -encoding 'UTF8'
[array]::Clear($key, 0, $key.Length)

Set-Location $startdir 
$dbpasswordDir = (mkdir data_bags\database_passwords).FullName

$databag = @{
    id = "sql_server_customers";
    sa_password = "Passw0rd"
}

$databag | ConvertTo-Json | Out-File $dbpasswordDir\sql_server_customers.json -Encoding UTF8 -Force

knife data bag from file database_passwords sql_server_customers.json --secret-file .chef/encrypted_data_bag_secret --local-mode
code $startdir/data_bags/database_passwords/sql_server_customers.json

knife data bag show database_passwords sql_server_customers --secret-file .chef/encrypted_data_bag_secret --local-mode


# SQL-Server installieren
# SQL-Server Cookbook muß als Abhängigkeit in cookbook in metadata.rb konfiguriert werden
# depends gibt das abhängige cookbook an, ~> die Versionnummer. 


"depends 'sql_server', '~> 2.5.0'" | out-file $cookbooksDir\awesome_customers_windows\metadata.rb -Encoding utf8 -Append
code $cookbooksDir\awesome_customers_windows\metadata.rb

knife cookbook site show

# neues Rezept für Datenbankinstallation
chef generate recipe cookbooks/awesome_customers_windows database


# neues Attribut-Fule anlegen 
chef generate attribute cookbooks/awesome_customers_windows default

# custom Attributes File generieren. Dies wird zum Überschreiben der vorgegebenen Attribute aus dem Kochbuch benötigt

$customAttributes = @"
default['sql_server']['accept_eula'] = true
default['sql_server']['version'] = '2012'
default['sql_server']['instance_name']  = 'MSSQLSERVER'
default['sql_server']['update_enabled'] = false
"@

$customAttributes | out-file -FilePath $startdir\cookbooks\awesome_customers_windows\attributes\default.rb -Append -Encoding utf8
code $startdir\cookbooks\awesome_customers_windows\attributes\default.rb

$databaserb = @'
# Load the secrets file and the encrypted data bag item that holds the sa password.
password_secret = Chef::EncryptedDataBagItem.load_secret(node['awesome_customers_windows']['secret_file'])
password_data_bag_item = Chef::EncryptedDataBagItem.load('database_passwords', 'sql_server_customers', password_secret)

# Set the node attribute that holds the sa password with the decrypted passoword.
node.default['sql_server']['server_sa_password'] = password_data_bag_item['sa_password']

# Install SQL Server.
include_recipe 'sql_server::server'
'@

$databaserb | Out-File -FilePath $cookbooksDir\awesome_customers_windows\recipes\database.rb -Encoding utf8 -Append
code $cookbooksDir\awesome_customers_windows\recipes\database.rb

"default['awesome_customers_windows']['secret_file'] = 'C:/chef/encrypted_data_bag_secret'" | 
    out-file $startdir\cookbooks\awesome_customers_windows\attributes\default.rb -Encoding UTF8 -Append 
code $startdir\cookbooks\awesome_customers_windows\attributes\default.rb

Copy-Item -Path 'C:\Users\hvoge\ChefTemplate\.kitchen_awesomeCustomers.yml' -Destination "$cookbooksDir\awesome_customers_windows\.kitchen.yml" -Force
code "$cookbooksDir\awesome_customers_windows\.kitchen.yml"

"include_recipe 'awesome_customers_windows::database'" |
    Out-File $cookbooksdir\awesome_customers_windows\recipes\default.rb -Encoding utf8 -Append




