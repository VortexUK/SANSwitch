<#
	.SYNOPSIS
	   When using converged san switching, all aliases exist on all switches. Which is a bit annoying! There maybe a better OID, if I find it I will update. This returns all aliases from a switch
	.DESCRIPTION
	   Returns all valid aliases from a given switch. Not all aliases are live on the switch though if in a converged architecture
	.PARAMETER SwitchName
		Name of the Switch. Function will convert this to IP for use in SNMP
	
	.PARAMETER SwitchIP
		IP of the switch
	.EXAMPLE
				PS C:\> Get-UnfilteredAlias -SwitchName 'SANSW1-3A1-VGIS'
	.OUTPUTS
	   Array of FC Aliases from the chosen pair of switches
	.NOTES
	   General
	.FUNCTIONALITY
	   Output is used later when determining Target/Storage hosts on a specified switch
	#>
function Get-UnfilteredAlias
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
			$SwitchIP = Get-SwitchIP -SwitchName $SwitchName
			if ($SwitchIP -eq $null)
			{
				return $null
			}
		}
		else
		{
			$TestSwitchName = Get-SwitchName -SwitchIP $SwitchIP
			if ($TestSwitchName -eq $null)
			{
				return $null
			}
		}
		$AliasesUnformatted = Get-SNMPData -IP $SwitchIP -OID $Oids.Aliases -CommunityString $SNMPCommunityString
		$Aliases = $AliasesUnformatted | Select-Object -property `
													   @{ N = 'Alias'; E = { $_.Data } },
													   @{ N = "PWWN"; E = { (($_.OID -replace "(\.)?$($OIDS.Aliases)\.") -split '\.' | ForEach-Object -Process { "{0:X2}" -f [int]$_ }) -join ':' } }
		
		return $Aliases
	}
	END { }
}
