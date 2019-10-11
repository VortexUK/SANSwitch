<#
	.SYNOPSIS
		The 'SAN FC Alias' class. Holds information on the Fabrics returned in Get-SANFCAlias
	
	.DESCRIPTION
		By default, the 'Switch' is hidden and so the output of 'Get-SANFabric' will only show the 'Interface' (Which interface the alias is on), Alias (the Alias name of the PWWN) and PWWN.
		'VSAN' is special in that it is an object (of type SANVSAN), however formatting changes the veiw so that it returns as a more easily viewed item.
	
	.NOTES
		None
#>
class SANFCAlias
{
	[System.String]$Switch
	[System.String]$Interface
	[System.String]$Alias
	[SANAVSAN]$VSAN
	[System.String]$PWWN
}
