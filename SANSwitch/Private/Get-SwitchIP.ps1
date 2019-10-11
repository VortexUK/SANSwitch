<#
	.SYNOPSIS
		Converts a Name to an IP
	
	.DESCRIPTION
		Converts a Switch NAME in DNS to an IP. Errors if this fails, warns if it can but there are multiple
	
	.PARAMETER SwitchName
		Name of the switch
	
	.EXAMPLE
				PS C:\> Get-SwitchIP -SwitchName 'SANSW1-3A1-VGIS'
	
	.NOTES
		None
#>
function Get-SwitchIP
{
	[CmdletBinding(PositionalBinding = $true,
				   SupportsPaging = $true,
				   SupportsShouldProcess = $false)]
	[OutputType([System.Net.IPAddress])]
	PARAM
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false,
				   Position = 1)]
		[ValidateScript({ $_ -match $SANSwitchFormat })]
		[System.String]$SwitchName
	)
	
	BEGIN { }
	PROCESS
	{
		try
		{
			$SwitchIP = ([System.Net.Dns]::GetHostAddresses($SwitchName) | Where-Object -FilterScript { $_.AddressFamily -ne 'InterNetworkV6' })
		}
		catch
		{
			Write-Error "DNS name does not resolve to an IP. Please check and try again"
			return $null
		}
		if (($SwitchIP | Measure-Object).Count -ne 1)
		{
			Write-Warning -Message "Multiple IPs detected for this hostname. Selecting the first one and continuing"
			$SwitchName = $SwitchName | Select-Object -First 1
		}
		return $SwitchIP
	}
	END { }
}
