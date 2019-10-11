<#
	.SYNOPSIS
		The 'SAN VSAN' class. Holds information on the VSANs returned in Get-SANVSAN
	
	.DESCRIPTION
		By default, the 'Switch' is hidden and so the output of 'Get-SANFabric' will only show the 'Name' (Name VSAN) and 'ID' (closely tied to Fabric ID)
    Why sanAvsan? because ordering. Thats why
	.NOTES
		None
#>
class SANAVSAN
{
	[System.String]$Switch
	[System.String]$Name
	[System.Int32]$ID
}
