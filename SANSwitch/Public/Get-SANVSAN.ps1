<#
	.SYNOPSIS
		Returns a list of VSANs on the switch
	
	.DESCRIPTION
		VSANs are the same on both switches (that are paired) with one difference - the ID. Eg. Odd will be 105 Even will be 205 (MSB changes, rest stays the same)
	
	.PARAMETER SwitchName
		Name of the Switch. Function will convert this to IP for use in SNMP
	
	.PARAMETER SwitchIP
		IP of the switch
	
	.EXAMPLE
		PS C:\>Get-SANVSAN -SwitchName "sanag1-3a2-vgis.uberit.net"
	.OUTPUTS
		A array containing the VSANs the user chose
	
	.NOTES
		General
#>
function Get-SANVSAN
{
	[CmdletBinding(DefaultParameterSetName = 'FromName',
				   PositionalBinding = $true,
				   SupportsPaging = $true,
				   SupportsShouldProcess = $false)]
	[OutputType(ParameterSetName = 'FromName')]
	[OutputType(ParameterSetName = 'FromIP')]
	PARAM
	(
		[Parameter(ParameterSetName = 'FromName',
				   Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false,
				   Position = 0)]
		[ValidateScript({$_ -match $SANSWitchFormat })]
		[Alias('n')]
		[System.String]$SwitchName,
		[Parameter(ParameterSetName = 'FromIP',
				   Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false,
				   Position = 1)]
		[Alias('ip')]
		[System.String]$SwitchIP
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
		$VSANSUnformatted = Get-SNMPData -IP $SwitchIP -OID $Oids.VSANS -CommunityString $SNMPCommunityString
		Foreach ($UnformattedVSAN in $VSANSUnformatted)
		{
			New-Object -TypeName SANSVSAN -Property ([ordered]@{
					'Switch' = $SwitchName.ToUpper()
					'Name' = [System.String](($UnformattedVSAN.Data).Trim())
					'ID' = [System.Int32](($UnformattedVSAN.OID -replace "(\.)?$($OIDs.VSANs)\.").Trim())
				}) | Write-Output
		}
	}
	END { }
}
