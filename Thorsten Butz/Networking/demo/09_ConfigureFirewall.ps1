#region FIRWALLRULES

    New-NetFirewallRule -DisplayName '_ICMPv4Echo' -Protocol "ICMPv4" -IcmpType 8 -Enabled True -Action Allow  -CimSession $cimsession
    New-NetFirewallRule -DisplayName '_ICMPv6Echo' -Protocol "ICMPv4" -IcmpType 8 -Enabled True -Action Allow  -CimSession $cimsession

    Get-NetFirewallRule -DisplayName '_ICMPv*Echo' -CimSession $cimsession | Select-Object -Property DisplayName, Enabled
    Get-NetFirewallRule -DisplayName '_ICMPv*Echo' -CimSession $cimsession | Remove-NetFirewallRule -Confirm:$false

    # Enable existing rules
    $smbrules = Get-NetFirewallRule -DisplayName 'File and Printer Sharing*' -CimSession $cimsession
    $smbrules | Select-Object -Property DisplayName, Profile, Enabled
    $smbrules | Set-NetFirewallRule -Enabled True

 #endregion