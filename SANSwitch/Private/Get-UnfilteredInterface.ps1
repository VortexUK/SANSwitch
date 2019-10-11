<#
	.SYNOPSIS
		Gets the interfaces from the switch.
	
	.DESCRIPTION
		The output of this function  is not really 'human' readable - it has the interfaces and then a UID called 'InterfaceOID'.
		This is used to pair it later with the WWNS + Aliases
	
	.PARAMETER SwitchName
		Name of the Switch
	
	.PARAMETER SwitchIP
		IP of the switch
	.EXAMPLE
				PS C:\> Get-UnfilteredInterface -SwitchName 'SANSW1-3A1-VGIS'
	
	.OUTPUTS
		System.Management.Automation.PSObject, System.Management.Automation.PSObject
	
	.NOTES
		None
#>
function Get-UnfilteredInterface
{
	[CmdletBinding(DefaultParameterSetName = 'FromName',
				   PositionalBinding = $true,
				   SupportsPaging = $true,
				   SupportsShouldProcess = $false)]
	[OutputType([System.Management.Automation.PSObject], ParameterSetName = 'FromName')]
	[OutputType([System.Management.Automation.PSObject], ParameterSetName = 'FromIP')]
	PARAM
	(
		[Parameter(ParameterSetName = 'FromName',
				   Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false,
				   Position = 0)]
		[ValidateScript({ $_ -match $SANSWitchFormat })]
		[Alias('n')]
		[System.String]$SwitchName,
		[Parameter(ParameterSetName = 'FromIP',
				   Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false,
				   Position = 1)]
		[Alias('ip')]
		[System.Net.IPAddress]$SwitchIP
	)
	
	BEGIN { }
	PROCESS
	{
		if ($SwitchName)
		{
			$NameOfSwitch = $SwitchName
			$SwitchIP = Get-SwitchIP -SwitchName $SwitchName
			if ($SwitchIP -eq $null)
			{
				return $null
			}
		}
		else
		{
			$NameOfSwitch = Get-SwitchName -SwitchIP $SwitchIP
			if ($NameOfSwitch -eq $null)
			{
				return $null
			}
		}
		$InterfacesUnfiltered = Get-SNMPData -IP $SwitchIP -OID $Oids.FlogiInterfaces -CommunityString $SNMPCommunityString
		$Interfaces = $InterfacesUnfiltered | Select-object -Property `
															@{ N = 'Switch'; E = { $NameOfSwitch } },
															@{ N = 'Interface'; E = { $_.Data.Trim() } },
															@{ N = 'InterfaceOID'; E = { ($_.OID -replace '(.*)\.(.*)$', '$2').Trim() } }
		return $Interfaces
	}
	END { }
}
