<#
	.SYNOPSIS
		Get's the active WWNs from the switch. 
	
	.DESCRIPTION
		This function does not contain what interface these wwns are on in a readable format. The output from this function is tied together with 'Get-UnfilteredInterface'
	
	.PARAMETER SwitchName
		Name of the Switch
	
	.PARAMETER SwitchIP
		IP of the switch
	.EXAMPLE
				PS C:\> Get-UnfilteredPWWN -SwitchName 'SANSW1-3A1-VGIS'
	
	.OUTPUTS
		System.Management.Automation.PSObject, System.Management.Automation.PSObject
	
	.NOTES
		Additional information about the function.
#>
function Get-UnfilteredPWWN
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
			$NameofSwitch = $SwitchName
			$SwitchIP = Get-SwitchIP -SwitchName $SwitchName
			if ($SwitchIP -eq $null)
			{
				return $null
			}
		}
		else
		{
			$NameofSwitch = Get-SwitchName -SwitchIP $SwitchIP
			if ($NameofSwitch -eq $null)
			{
				return $null
			}
		}
		# Note the Additional Paremeter here to specify it is Hex output!! Without this you get random ASCII strings back.
		$PWWNsUnfiltered = Get-SNMPData -IP $SwitchIP -OID $Oids.FlogiPWWNs -CommunityString $SNMPCommunityString -HexOutput
		$PWWNs = $PWWNsUnfiltered | Select-object -Property `
												  @{ N = 'Switch'; E = { $NameofSwitch } },
												  @{ N = 'PWWN'; E = { ($_.Data -replace '(..)(?=.)', '$1:').Trim() } },
												  @{ N = 'VSAN'; E = { ($_.OID -replace '(.*\.)(.*)(\..*)$', '$2').Trim() } },
												  @{ N = 'InterfaceOID'; E = { ($_.OID -replace '(.*)\.(.*)(\..*)\.(.*)$', '$2').Trim() } }
		return $PWWNs
	}
	END { }
}
