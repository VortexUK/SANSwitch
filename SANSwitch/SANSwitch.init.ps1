#######################################################################################################################
# File:             SANSwitch.psm1		      			                        	                                  #
# Author:           Ben McElroy                                                                                       #
# Publisher:        Gloucester Research Ltd                                                                           #
# Copyright:        © 2017 Gloucester Research Ltd. All rights reserved.                                              #
# Documentation:    Inbuilt																							  #
#######################################################################################################################
#region Environment setup
[System.String]$DefaultNamingContext = Get-ADRootDSE | Select-Object -ExpandProperty defaultNamingContext
[System.String]$DNSDomainName = (Get-ADObject -Identity $DefaultNamingContext -Properties canonicalName).canonicalName.TrimEnd('/')
[System.String]$LocalSite = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite().Name
[System.String]$LocalDC = "dc.$LocalSite.sites.$DNSDomainName"
#endregion
#region Global Variables
[System.String]$SANSWitchFormat = '^SAN(SW|AG)' # Change this to whatever you want so that it will only accept SANSwitch names
[System.String]$IPFormat = '\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b'
[System.String]$SNMPCommunityString = 'Setme' # Set this to your public community string
#endregion
#region Internal Variables
[System.Management.Automation.PSObject]$Oids = New-Object -TypeName System.Management.Automation.PSObject -Property @{
	'FlogiPWWNs' = '1.3.6.1.4.1.9.9.289.1.1.5.1.3'
	'FlogiInterfaces' = '1.3.6.1.2.1.2.2.1.2'
	'VSANs' = '.1.3.6.1.4.1.9.9.282.1.1.3.1.2'
	'Fabrics' = '1.3.6.1.4.1.9.9.294.1.1.4.1.2'
	'Aliases' = '1.3.6.1.4.1.9.9.430.1.1.2.1.3.1'
}
#endregion

Write-Debug "LocalDC: $LocalDC"
Write-Debug "SANSWitchFormat: $SANSWitchFormat"
Write-Debug "IPFormat: $IPFormat"
Write-Debug "SNMPCommunityString: $SNMPCommunityString"
Write-Debug "Oids: $Oids"
