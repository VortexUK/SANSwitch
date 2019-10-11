<#
	.SYNOPSIS
	   Ties together the various 'unfiltered' information and returns a list of aliases on a single switch
	.DESCRIPTION
	   Invisible to the user, this generates a list of current FCAliases and their PWWNs
	.PARAMETER SwitchName
		Name of the Switch. Function will convert this to IP for use in SNMP
	
	.PARAMETER SwitchIP
		IP of the switch
	.EXAMPLE
	
		PS C:\>Get-SANFCAlias -SwitchName "sanag1-3a2-vgis.uberit.net"
	.OUTPUTS
	   Array of FC Aliases from the switch
	.NOTES
	   General
	#>
function Get-SANFCAlias
{
	[CmdletBinding(DefaultParameterSetName = 'FromName',
				   PositionalBinding = $true,
				   SupportsPaging = $true,
				   SupportsShouldProcess = $false)]
	[OutputType([SANFCAlias], ParameterSetName = 'FromName')]
	[OutputType([SANFCAlias], ParameterSetName = 'FromIP')]
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
				return
			}
		}
		else
		{
			$SwitchName = Get-SwitchName -SwitchIP $SwitchIP
			if ($SwitchName -eq $null)
			{
				return
			}
		}
		$Aliases = Get-UnfilteredAlias -SwitchIP $SwitchIP
		$Flogis = Get-SANFlogiDB -SwitchIP $SwitchIP
		$VSANS = Get-SANVSAN -SwitchIP $SwitchIP
		Foreach ($Flogi in $Flogis)
		{
			New-Object -TypeName SANFCAlias -Property ([ordered]@{
					'Switch' = $SwitchName.ToUpper()
					'Interface' = $Flogi.Interface
					'Alias' = $Aliases | Where-Object -Property PWWN -EQ -Value $Flogi.PWWN | Select-Object -ExpandProperty Alias
					'VSAN' = $VSANS | Where-Object -Property ID -EQ -Value $Flogi.VSAN.ID
					'PWWN' = $Flogi.PWWN
				}) | Write-Output
		}
	}
	END { }
}
