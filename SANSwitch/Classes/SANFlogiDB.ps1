<#
	.SYNOPSIS
		The 'SAN Flogi Database' class. Holds information on the Flogi Database entries returned in Get-SANFlogiDB
	
	.DESCRIPTION
		By default, the 'Switch' is hidden and so the output of 'Get-SANFlogiDB' will only show the 'Interface' (Which interface the PWWN is on) and 'PWWN' (World wide name for the san target/host)
		'VSAN' is special in that it is an object (of type SANVSAN), however formatting changes the veiw so that it returns as a more easily viewed item.
	
	.NOTES
		None
#>
class SANFlogiDB
{
	[System.String]$Switch
	[System.String]$Interface
	[SANAVSAN]$VSAN
	[System.String]$PWWN
}
