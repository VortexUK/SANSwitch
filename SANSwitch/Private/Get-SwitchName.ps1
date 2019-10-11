<#
	.SYNOPSIS
		Converts an IP to a DNS Name
	
	.DESCRIPTION
		Converts a Switch IP to a NAME in DNS using reverse lookup. Errors if this fails, warns if it can but there are multiple. In this case it will select the first one
	
	.PARAMETER SwitchIP
		IP of the switch
	
	.EXAMPLE
				PS C:\> Get-SwitchName -SwitchIP '10.0.0.1'
	
	.NOTES
		None
#>
function Get-SwitchName
{
	[CmdletBinding(PositionalBinding = $true,
				   SupportsPaging = $true,
				SupportsShouldProcess = $false)]
	[OutputType([System.String])]
	PARAM
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false,
				   Position = 1)]
		[System.Net.IPAddress]$SwitchIP
	)
	BEGIN { }
	PROCESS
	{
		try
		{
			$SwitchName = ([System.Net.Dns]::GetHostEntry($SwitchIP.IPAddressToString)).HostName
		}
		catch
		{
			Write-Error "IP does not resolve to a dns Name. Please check and try again"
			return $null
		}
		if (($SwitchName | Measure-Object).Count -ne 1)
		{
			Write-Warning -Message "Multiple hostnames detected for this IP. Selecting the first one and continuing"
			$SwitchName = $SwitchName | Select-Object -First 1
		}
		if ($SwitchName -notmatch $SANSwitchFormat)
		{
			Write-Error -Message "Hostname does not match the format ($SANSwitchFormat) for san switches: $SwitchName"
			return $null
		}
		return $SwitchName
	}
	END { }
}
