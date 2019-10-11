<#
	.SYNOPSIS
		Returns the flogi DB from a given Switch.
	
	.DESCRIPTION
		Combines various unfiltered streams into a single unified (readable) list.
	
	.PARAMETER SwitchName
		Name of the switch
	
	.PARAMETER SwitchIP
		IP of the switch
	
	.EXAMPLE
		PS C:\>Get-SANFlogiDB -SwitchName "sanag1-3a2-vgis.uberit.net"
	.NOTES
		General
#>
function Get-SANFlogiDB
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
		$PWWNs = Get-UnfilteredPWWN -SwitchIP $SwitchIP
		$Interfaces = Get-UnfilteredInterface -SwitchIP $SwitchIP
		$VSANS = Get-SANVSAN -SwitchIP $SwitchIP
		Foreach ($PWWN in $PWWNs)
		{
			New-Object -TypeName SANFlogiDB -Property ([ordered]@{
					'Switch' = $SwitchName.ToUpper()
					'Interface' = $Interfaces | Where-Object -Property InterfaceOID -EQ -Value $PWWN.InterfaceOID | Select-Object -ExpandProperty Interface
					'VSAN' = $VSANS | Where-Object -Property ID -EQ -Value $PWWN.VSAN
					'PWWN' = $PWWN.PWWN
				}) | Write-Output
		}
	}
	END { }
}
