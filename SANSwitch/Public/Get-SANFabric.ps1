<#
	.SYNOPSIS
	   Returns the fabrics from a switch
	.DESCRIPTION
	   Fabrics maintain a 1-1 relationship with VSANs 95% of the time. This will return the fabrics from a given switch - the ID of each is closely tied to VSAN ID
	.PARAMETER SwitchName
		Name of the Switch. Function will convert this to IP for use in SNMP
	
	.PARAMETER SwitchIP
		IP of the switch
	.EXAMPLE
		PS C:\>Get-SANFabric -SwitchName "sanag1-3a2-vgis.uberit.net"
	.OUTPUTS
	   A array containing the Fabrics the User chose
	.NOTES
	   General
	#>
function Get-SANFabric
{
	[CmdletBinding(DefaultParameterSetName = 'FromName',
				   PositionalBinding = $true,
				   SupportsPaging = $true,
				   SupportsShouldProcess = $false)]
	[OutputType([SANFabric], ParameterSetName = 'FromName')]
	[OutputType([SANFabric], ParameterSetName = 'FromIP')]
	PARAM
	(
		[Parameter(ParameterSetName = 'FromName',
				   Mandatory = $true,
				   Position = 0)]
		[Alias('n')]
		[ValidateScript({ $_ -match $SANSWitchFormat })]
		[System.String]$SwitchName,
		[Parameter(ParameterSetName = 'FromIP',
				   Mandatory = $true,
			 	   Position = 0)]
		[Alias('ip')]
		[System.Net.IPAddress]$SwitchIP
	)
	BEGIN { }
	PROCESS
	{
		if ($SwitchName)
		{
			$NameOfSwitch = $SwitchName # Why you ask? Because pester is stupid and won't mock Get-SwitchName correctly.
			$SwitchIP = Get-SwitchIP -SwitchName $SwitchName -ErrorAction Stop
			if ($SwitchIP -eq $null)
			{
				return $null
			}
		}
		else
		{
			$NameOfSwitch = Get-SwitchName -SwitchIP $SwitchIP -ErrorAction Stop
			if ($NameOfSwitch -eq $null)
			{
				return $null
			}
		}
		$FabricsUnformatted = Get-SNMPData -IP $SwitchIP -OID $Oids.Fabrics -CommunityString $SNMPCommunityString
		Foreach ($UnformattedFabric in $FabricsUnformatted)
		{
			New-Object -TypeName SANFabric -Property ([ordered]@{
					'Switch' = $NameOfSwitch.ToUpper()
					'Name' = "$(($UnformattedFabric.Data).Trim())"
					'ID' = [int](($UnformattedFabric.OID -replace "(\.)?$($OIDs.Fabrics)\.").Trim() -replace '\.[0-9]$')
					'Active' = [bool][int](($UnformattedFabric.OID -replace "(\.)?$($OIDs.Fabrics)\.[0-9]{1,4}\.").Trim())
				}) | Write-Output
		}
	}
	END { }	
}
