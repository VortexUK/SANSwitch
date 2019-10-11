<#
	.SYNOPSIS
		The 'SAN Fabric' class. Holds information on the Fabrics returned in Get-SANFabric
	
	.DESCRIPTION
		By default, the 'Switch' and 'Active' properties are hidden and so the output of 'Get-SANFabric' will only show the 'Name' (Name of the fabric) and 'ID' (closely tied to VSAN ID)
	.NOTES
		None
#>
class SANFabric
{
	[System.String]$Switch
	[System.String]$Name
	[System.Int32]$ID
	[System.Boolean]$Active	
}
