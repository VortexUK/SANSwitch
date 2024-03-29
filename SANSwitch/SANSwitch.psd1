@{
	
	# Script module or binary module file associated with this manifest.
	RootModule = 'SANSwitch'
	
	# Version number of this module.
	ModuleVersion = '3.0.0.1'
	
	# ID used to uniquely identify this module
	GUID = '4c4f8b72-b322-40f0-8e04-639c07e173e8'
	
	# Author of this module
	Author = 'Ben McElroy'
	
	# Company or vendor of this module
	CompanyName = 'G-Research'
	
	# Copyright statement for this module
	Copyright = '(c) 2017 InfraEng. All rights reserved.'
	
	# Description of the functionality provided by this module
	 Description = 'Allows polling of SAN Switches for useful Port/SAN Info'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '5.0'
	
	# Name of the Windows PowerShell host required by this module
	# PowerShellHostName = ''
	
	# Minimum version of the Windows PowerShell host required by this module
	# PowerShellHostVersion = ''
	
	# Minimum version of Microsoft .NET Framework required by this module
	# DotNetFrameworkVersion = ''
	
	# Minimum version of the common language runtime (CLR) required by this module
	# CLRVersion = ''
	
	# Processor architecture (None, X86, Amd64) required by this module
	# ProcessorArchitecture = ''
	
	# Modules that must be imported into the global environment prior to importing this module
	RequiredModules = @(
		'SNMP',
		'ActiveDirectory'
	)
	
	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @()
	
	# Script files (.ps1) that are run in the caller's environment prior to importing this module.
	# ScriptsToProcess = @()
	
	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @()
	
	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess = @(
		'SANSwitch.format.ps1xml'
	)
	
	# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
	# NestedModules = @()
	
	# Functions to export from this module
	#FunctionsToExport = '*'
	
	# Cmdlets to export from this module
	CmdletsToExport = '*'
	
	# Variables to export from this module
	VariablesToExport = '*'
	
	# Aliases to export from this module
	AliasesToExport = '*'
	
	# List of all modules packaged with this module
	# ModuleList = @()
	
	# List of all files packaged with this module
	# FileList = @()
	
	# Private data to pass to the module specified in RootModule/ModuleToProcess
	# PrivateData = ''
	
	# HelpInfo URI of this module
	# HelpInfoURI = ''
	
	# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
	# DefaultCommandPrefix = ''
	
}
