#region ORIGINS

    $result1 = Get-CimInstance -Namespace 'root/StandardCimv2' -ClassName 'MSFT_NetAdapter' 
    $result2 = Get-NetAdapter 												# MODULE NetAdapter

    $result1 = Get-CimInstance -Namespace 'root/StandardCimv2' -ClassName 'MSFT_NetAdapterHardwareInfoSettingData'
    $result2 = Get-NetAdapterHardwareInfo 									# MODULE NetAdapter

    $result1 = Get-CimInstance -Namespace 'root/StandardCimv2' -ClassName 'MSFT_NetAdapterBindingSettingData'
    $result2 = Get-NetAdapterBinding 										# MODULE NetAdapter

    $result1 = Get-CimInstance -Namespace 'root/StandardCimv2' -ClassName  'MSFT_NetAdapterStatisticsSettingData'
    $result2 = Get-NetAdapterStatistics 		                            # MODULE NetAdapter

    $result1 = Get-CimInstance -Namespace 'root/StandardCimv2' -ClassName 'MSFT_NetIPAddress'
    $result2 = Get-NetIPAddress 			   							  	# MODULE NetTCPIP

    $result1 = Get-CimInstance -Namespace 'root/StandardCimv2' -ClassName 'MSFT_NetIPInterface'
    $result2 = Get-NetIPInterface 			                                # MODULE NetTCPIP

    # Equal results? 
    Compare-Object -ReferenceObject $result1 -DifferenceObject $result2 

    # Useful things from the module "NetAdapter"
    Get-NetAdapter -IncludeHidden 
    Get-NetAdapter -Physical 
    Get-NetAdapter -Name Ethernet | Get-NetIPAddress
    Get-NetAdapterBinding 
    Get-NetAdapterStatistics

#endregion

#region IPCONIG

    # What is "Get-NetIPConfiguration" ? 

    # Function:
    # $pshome\Modules\NetTCPIP\NetIPConfiguration.psm1

    # .. staggering some "usual suspects":
    (Get-WmiObject win32_ComputerSystem).Name
    Get-CimInstance -Namespace 'ROOT/StandardCimv2' -ClassName 'MSFT_NetAdapter'
    Get-CimInstance -Namespace 'ROOT/StandardCimv2' -ClassName 'MSFT_NetIPInterface'
    # etc. 

    Get-NetIPConfiguration 	# quick overview, limited information
    gip  					# Alias

    gip -all 				# a bit more

    gip -Detailed 	        # close to "ipconfig.exe -all", but still limited
                            # e.g. missing: DNS suffix, NetBT status, IAID, DUID

#endregion