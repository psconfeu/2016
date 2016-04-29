# PREQUISITES
$password = ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('contoso\administrator',$password)
$vmDC1 = 'sea-dc1'

# Check VM status
Get-VM -Name $vmDC1

# PowerShell direct
Invoke-Command -VMName $vmDC1 -Credential $cred -ScriptBlock {
    Get-NetAdapter | Get-NetIPAddress 
} 

Invoke-Command -VMName $vmDC1 -Credential $cred -ScriptBlock {        
    Get-ADDomain 
} |  Select-Object DNSRoot,PDCEmulator

# Create Harvest
Invoke-Command -VMName $vmDC1 -Credential $cred -ScriptBlock {
  # New-Item -Path C:\depot -ItemType Directory
  # New-SmbShare -Path C:\depot -Name depot -FullAccess:Administrators
  if (Test-Path -Path C:\depot) {
    foreach ($i in 4..10) {
        djoin.exe /Provision /Domain contoso /Machine "sea-nano$i" /SaveFile "c:\depot\sea-nano$i.djoin"
    }
  }
  (Get-ChildItem -Path C:\depot -Filter *.djoin).Fullname
}

# Interactive session through VMBus
Enter-PSSession -VMName $vmDC1 -Credential $cred

# One more thing: you can copy filse INTO VMs with COPY-VMFILE
# But only in one direction ...
Copy-VMFile $vmDC1 -SourcePath 'C:\depot\somefile.txt' -DestinationPath 'C:\depot\somefile.txt' -FileSource Host -Force
Invoke-Command -VMName $vmDC1 -Credential $cred -ScriptBlock {
    Get-Content -Path 'C:\depot\somefile.txt'
}

<#  COPY FILES
    New-PSDrive -Name Remote -PSProvider FileSystem -Root '\\192.168.0.1\depot' -Credential $cred
    Copy-Item 'remote:\*.djoin' 'C:\NanoServer_TP4'
    Remove-PSDrive -Name Remote 
#>
