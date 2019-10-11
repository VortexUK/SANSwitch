<#
	.SYNOPSIS
	InvokeBuild Script to Build, Analyze & Test Module
	.DESCRIPTION
	This script is used as parto of the InvokeBuild module to automate the following steps:
		* Clean - ensuring we have a fresh space
		* Build - Create PSModule by combining classes, public & private into one psm1. This is also versioned based on your CI Engine
		* Analyze - Invoke PSScriptAnalyzer and throw if issues are raised
		* Test - Invoke pester tests and upload to your CI Engine
	.NOTES
	This is designed to be used in multiple projects. 
	It can be customized depending on requirments but should largely be left alone and kept generic. 
#>

Param (
	[Int]$BuildNumber,
	
	[ValidateSet('Local','Bamboo')]
	[String]$CIEngine = 'Local',

	[String]$NugetUrl

	[String]$ApiKey = $env:PSRepoApiKey
)
$VersionMajor = 3
$VersionMinor = 0
$Organization = 'PSModules'
$Repository = 'PSSANSwitch'
$ModuleName = 'SANSwitch'
$RequiredModules = @('Pester', 'PSScriptAnalyzer','platyps')
$RootPath = $PSScriptRoot
$SourcePath = "$RootPath\$ModuleName"
$OutputPath = "$env:ProgramFiles\WindowsPowerShell\Modules"
$ScriptAnalyzerSettings = "$RootPath\ScriptAnalyzerSettings.psd1"
$GitApi = 'https://github.com/api/v3/'
$GitStatus = @{
	'Pending' = 'Pending'
	'Success' = 'Success'
	'Failure' = 'Failure'
	'Error' = 'Error'
}
Task .


# Local + Bamboo (internal use)
Task UnitTest StartUnitTests, PesterUnitTest, CompleteUnitTests
Task PesterTest StartUnitTests, AnalyzeFunctions, PesterUnitTest, PesterStructureTest, CompleteUnitTests
Task IntegrationTest StartIntegrationTests, PesterIntegrationTest, CompleteIntegrationTests
# Local + Bamboo (Public use)
Task Build Init, { Clean }, Compile, GenerateDocs, GenerateReadMe
Task BuildAndTest Init, { Clean }, Compile, PesterTest, IntegrationTest
Task BuildAndDeploy Init, { Clean }, Compile, PesterTest, IntegrationTest, Deploy, { Clean }
#region Function: set Git Hub Status
function Set-GitHubStatus
{
	[CmdletBinding(PositionalBinding = $true,
				   SupportsPaging = $false,
				   SupportsShouldProcess = $false)]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $false,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false,
				   Position = 1)]
		[String]$Revision,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $false,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false,
				   Position = 2)]
		[ValidateSet('Success', 'Pending', 'Failure', 'Error')]
		[String]$State,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $false,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false,
				   Position = 3)]
		[String]$Context,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $false,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false,
				   Position = 4)]
		[String]$Description,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false,
				   Position = 0)]
		[Alias('Repo')]
		[String]$Repository
	)
	
	BEGIN
	{
		$Headers = @{ Authorization = "token $OAuthToken" }
	}
	PROCESS
	{
		$Body = @{
			state   = $State.ToLower()
			context = $Context.ToLower()
			description = $Description
			target_url = $ResultsURL
		} | ConvertTo-Json
		Try
		{
			$RestParams = @{
				Method   = 'POST'
				Uri	     = "$($GitApi)repos/$Organization/$Repository/statuses/$($Revision)"
				Body	 = $Body
				Headers  = $Headers
			}
			$null = Invoke-RestMethod @RestParams
		}
		Catch
		{
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
	END { }
}
#endregion
#region Function: Clean Environment
Function Clean
{
	#Remove any previously loaded module versions from subsequent runs
	Get-Module -Name $ModuleName | Remove-Module -Force
	
	#Remove any files previously compiled but leave other versions intact
	$Path = Join-Path -Path $OutputPath -ChildPath $ModuleName
	If ($PSVersionTable.PSVersion.Major -ge 5)
	{
		$Path = Join-Path -Path $Path -ChildPath $Script:Version.ToString()
	}
	Write-Output "Cleaning: $Path"
	$Path | Get-Item -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
}
#endregion
#region Tasks
Task Init {
	$Seperator
	$Context = "PSModule_Testing"
	#Determine the new version. Major & Minor are set in the source psd1 file, BuildNumer is fed in as a parameter
	If ($BuildNumber)
	{
		$Script:Version = [Version]::New($VersionMajor, $VersionMinor, $BuildNumber)
	}
	Else
	{
		$Script:Version = [Version]::New($VersionMajor, $VersionMinor, 0)
	}
	Write-Output -InputObject $Description
	#Import required modules
	foreach ($Module in $RequiredModules)
	{
		If (-not (Get-Module -Name $Module -ListAvailable))
		{
			Try
			{
				Write-Output "Installing Module: $Module"
				Install-Module -Name $Module -Force
			}
			Catch
			{
				$Description = "Unable to install missing module - $($_.Exception.Message)"
				Set-GitHubStatus -Repository $Repository -State $GitStatus.Error -Revision $Revision -Context $Context -Description $Description
				Throw "Unable to install missing module - $($_.Exception.Message)"
			}
		}
		if ($null -eq (Get-module $Module -ErrorAction SilentlyContinue))
		{
			Write-Output -InputObject "Importing Module: $Module"
			Import-Module -Name $Module -Force
		}
	}
}
Task Compile {
	$Seperator
	$Context = "PSModule_Compile"
	$Description = "Compiling: $ModuleName ($Version)"
	if ($CIEngine -eq 'Bamboo')
	{
		Set-GitHubStatus -Repository $Repository -State $GitStatus.Pending -Revision $Revision -Context $Context -Description $Description
	}
	Write-Output -InputObject $Description
	#Depending on powershell version the module folder may or may not already exists after subsequent runs
	If (Test-Path -Path "$OutputPath\$ModuleName")
	{
		$Script:ModuleFolder = Get-Item -Path "$OutputPath\$ModuleName"
	}
	Else
	{
		$Script:ModuleFolder = New-Item -Path $OutputPath -Name $ModuleName -ItemType Directory
	}
	
	#Make a subfolder for the version if module is for powershell 5
	If ($PSVersionTable.PSVersion.Major -ge 5)
	{
		$Script:ModuleFolder = New-Item -Path $Script:ModuleFolder -Name $Version.ToString() -ItemType Directory
	}
	# Get PSM1 file core:
	$ModuleContent = Get-Content -Path "$SourcePath\$ModuleName.psm1" -Verbose
	#Create module psm1 file
	$Parts = 'Classes', 'Private', 'Public'
	ForEach ($Part in $parts)
	{
		if (Test-Path -Path (Join-Path -Path $SourcePath -ChildPath $Part))
		{
			$ModuleContent += "#region $Part"
			$Files = Join-Path -Path $SourcePath -ChildPath $Part | Get-ChildItem -Recurse -Depth 2 -Include '*.ps1', '*.psm1'
			foreach ($File in $files)
			{
				$ModuleContent += "#region $($File.BaseName)"
				$ModuleContent += Get-Content -Path $File.FullName
				$ModuleContent += "#endregion"
			}
			$ModuleContent += "#endregion"
		}
	}
	$RootModule = New-Item -Path $ModuleFolder.FullName -Name "$ModuleName.psm1" -ItemType File -Value ($ModuleContent -join "`r`n")
	
	#Copy module manifest and any other source files
	Write-Output -InputObject "Copying other source files..."
	Get-ChildItem -Path $SourcePath -File | Where-Object { $_.Name -notin $RootModule.Name } | Copy-Item -Destination $ModuleFolder.FullName
	Get-ChildItem -Path $SourcePath -Directory | Where-Object { $_.Name -notin 'Classes', 'Public', 'Private' } | Copy-Item -Destination $ModuleFolder.FullName -Recurse
	
	
	#Update module copied manifest
	$NewManifestPath = Join-Path -Path $ModuleFolder.FullName -ChildPath "$ModuleName.psd1"
	Write-Host "Updating Manifest ModuleVersion to $Script:Version"
	#Stupidly Update-ModuleManifest fails to correct the version when it doesnt match the folder its in. wtf?
	(Get-Content -Path $NewManifestPath) -replace "ModuleVersion = .+", "ModuleVersion = '$Script:Version'" | Set-Content -Path $NewManifestPath
	
	$FunctionstoExport = Get-ChildItem -Path "$SourcePath\Public" -Filter '*.ps1' | Select-Object -ExpandProperty BaseName
	Write-Output "Updating Manifest FunctionsToExport to $FunctionstoExport"
	Update-ModuleManifest -Path $NewManifestPath -FunctionsToExport $FunctionstoExport
	
	#Update nuspec
	$NuspecPath = Join-Path -Path $ModuleFolder.FullName -ChildPath "$ModuleName.nuspec"
	(Get-Content -Path $NuspecPath) -replace "<version>__VERSION__</version>", "<version>$Script:Version</version>" | Set-Content -Path $NuspecPath
	$Description = "Compiling: $ModuleName ($Version) Success"
	if ($CIEngine -eq 'Bamboo')
	{
		Set-GitHubStatus -Repository $Repository -State $GitStatus.Success -Revision $Revision -Context $Context -Description $Description
	}
	Write-Output -InputObject $Description
}
#region Unit Testing Tasks
Task StartUnitTests {
	$Seperator
	$Context = "PSModule_UnitTesting"
	$Description = "Beginning $CIEngine UNIT TESTS for: $Name ($Version)"
	if ($CIEngine -eq 'Bamboo')
	{
		Set-GitHubStatus -Repository $Repository -State $GitStatus.Pending -Revision $Revision -Context $Context -Description $Description
	}
}
Task AnalyzeFunctions {
	$Context = "Script_Analyzer"
	Write-Output "Invoking PSScriptAnalyzer..."
	if ($CIEngine -eq 'Local')
	{
		$NUnitXml = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "${ModuleName}-PSSA-PesterOutput.xml"
		$TestResults = Invoke-Pester -Path $PSScriptRoot -Tag 'PSSA' -PassThru -OutputFormat NUnitXml -OutputFile $NUnitXml
		If ($TestResults.FailedCount -gt 0)
		{
			$Description = "$($TestResults.FailedCount) out of $($TestResults.TotalCount) Tests failed"
		}
		else
		{
			$Description = "$($TestResults.PassedCount) out of $($TestResults.TotalCount) Tests succeeded"
		}
	}
	else
	{
		$NUnitXml = Join-Path -Path $PSScriptRoot -ChildPath "${ModuleName}-PSSA-PesterOutput.xml"
		Set-GitHubStatus -Repository $Repository -State $GitStatus.Pending -Revision $Revision -Context $Context -Description "Using PSScriptAnalyzer..."
		$TestResults = Invoke-Pester -Path $PSScriptRoot -Tag 'PSSA' -PassThru -OutputFormat NUnitXml -OutputFile $NUnitXml
		If ($TestResults.FailedCount -gt 0)
		{
			$Description = "$($TestResults.FailedCount) out of $($TestResults.TotalCount) Tests failed"
			Set-GitHubStatus -Repository $Repository -State $GitStatus.Failure -Revision $Revision -Context $Context -Description $Description
		}
		else
		{
			$Description = "$($TestResults.PassedCount) out of $($TestResults.TotalCount) Tests succeeded"
			Set-GitHubStatus -Repository $Repository -State $GitStatus.Success -Revision $Revision -Context $Context -Description $Description
		}
	}
	Write-Output -InputObject $Description
}
Task PesterUnitTest {
	Write-Output "Invoking Pester Unit tests..."
	$Context = "Pester_Tests"
	$Functions = Get-ChildItem -Path "$PSScriptRoot\$ModuleName" -Filter *.ps1 -Recurse
	if ($CIEngine -eq 'Local')
	{
		$NUnitXml = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "${ModuleName}-UNIT-PesterOutput.xml"
		$NUnitCCXml = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "${ModuleName}-CC-PesterOutput.xml"
		$TestResults = Invoke-Pester -Path $PSScriptRoot -Tag 'UNIT' -PassThru -OutputFormat NUnitXml -OutputFile $NUnitXml -CodeCoverage "$PSScriptRoot\$ModuleName\*\*.ps1" -CodeCoverageOutputFile $NUnitCCXml
		If ($TestResults.FailedCount -gt 0)
		{
			$Description = "$($TestResults.FailedCount) out of $($TestResults.TotalCount) Tests failed"
		}
		else
		{
			$Description = "$($TestResults.PassedCount) out of $($TestResults.TotalCount) Tests succeeded"
		}
	}
	else
	{
		$NUnitXml = Join-Path -Path $PSScriptRoot -ChildPath "${ModuleName}-UNIT-PesterOutput.xml"
		$NUnitCCXml = Join-Path -Path $PSScriptRoot -ChildPath "${ModuleName}-CC-PesterOutput.xml"
		Set-GitHubStatus -Repository $Repository -State $GitStatus.Pending -Revision $Revision -Context $Context -Description "Invoking Pester..."
		$TestResults = Invoke-Pester -Path $PSScriptRoot -Tag 'UNIT' -PassThru -OutputFormat NUnitXml -OutputFile $NUnitXml -CodeCoverage "$PSScriptRoot\$ModuleName\*\*.ps1" -CodeCoverageOutputFile $NUnitCCXml
		If ($TestResults.FailedCount -gt 0)
		{
			$Description = "$($TestResults.FailedCount) out of $($TestResults.TotalCount) Tests failed"
			Set-GitHubStatus -Repository $Repository -State $GitStatus.Failure -Revision $Revision -Context $Context -Description $Description
		}
		else
		{
			$Description = "$($TestResults.PassedCount) out of $($TestResults.TotalCount) Tests succeeded"
			Set-GitHubStatus -Repository $Repository -State $GitStatus.Success -Revision $Revision -Context $Context -Description $Description
		}
	}
	Write-Output -InputObject $Description
}
Task PesterStructureTest {
	Write-Output "Invoking Pester Unit tests..."
	$Context = "Pester_Tests"
	if ($CIEngine -eq 'Local')
	{
		$NUnitXml = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "${ModuleName}-STRUCT-PesterOutput.xml"
		$TestResults = Invoke-Pester -Path $PSScriptRoot -Tag 'STRUCT' -PassThru -OutputFormat NUnitXml -OutputFile $NUnitXml
		If ($TestResults.FailedCount -gt 0)
		{
			$Description = "$($TestResults.FailedCount) out of $($TestResults.TotalCount) Tests failed"
		}
		else
		{
			$Description = "$($TestResults.PassedCount) out of $($TestResults.TotalCount) Tests succeeded"
		}
	}
	else
	{
		$NUnitXml = Join-Path -Path $PSScriptRoot -ChildPath "${ModuleName}-STRUCT-PesterOutput.xml"
		Set-GitHubStatus -Repository $Repository -State $GitStatus.Pending -Revision $Revision -Context $Context -Description "Invoking Pester..."
		$TestResults = Invoke-Pester -Path $PSScriptRoot -Tag 'STRUCT' -PassThru -OutputFormat NUnitXml -OutputFile $NUnitXml
		If ($TestResults.FailedCount -gt 0)
		{
			$Description = "$($TestResults.FailedCount) out of $($TestResults.TotalCount) Tests failed"
			Set-GitHubStatus -Repository $Repository -State $GitStatus.Failure -Revision $Revision -Context $Context -Description $Description
		}
		else
		{
			$Description = "$($TestResults.PassedCount) out of $($TestResults.TotalCount) Tests succeeded"
			Set-GitHubStatus -Repository $Repository -State $GitStatus.Success -Revision $Revision -Context $Context -Description $Description
		}
	}
	Write-Output -InputObject $Description
}
Task NEWPesterTest {
	$Seperator
	Write-Output "Invoking NEW PEster test (local only)..."
	$Context = "NEW_Pester_Tests"
	if ($CIEngine -eq 'Local')
	{
		$NUnitXml = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath 'NEW-UNIT-PesterOutput.xml'
		$TestResults = Invoke-Pester -Path $PSScriptRoot -Tag 'NEW' -PassThru -OutputFormat NUnitXml -OutputFile $NUnitXml
		If ($TestResults.FailedCount -gt 0)
		{
			$Description = "$($TestResults.FailedCount) out of $($TestResults.TotalCount) Tests failed"
		}
		else
		{
			$Description = "$($TestResults.PassedCount) out of $($TestResults.TotalCount) Tests succeeded"
		}
	}
	else
	{
		# New Pester tests are a local thing only
		throw
	}
	Write-Output -InputObject $Description
}
Task CompleteUnitTests {
	$Description = "Unit Tests complete"
	if ($CIEngine -eq 'Bamboo')
	{
		$Context = "PSModule_UnitTesting"
		Set-GitHubStatus -Repository $Repository -State $GitStatus.Success -Revision $Revision -Context $Context -Description $Description
	}
	Write-Output -InputObject $Description
}
#endregion
#region Integration Testing Tasks
Task StartIntegrationTests {
	$Seperator
	$Description = "Beginning $CIEngine INTEGRATION TESTS for: $Name ($Version)"
	if ($CIEngine -eq 'Bamboo')
	{
		$Context = "PSModule_IntegrationTesting"
		Set-GitHubStatus -Repository $Repository -State $GitStatus.Pending -Revision $Revision -Context $Context -Description $Description
	}
	Write-Output -InputObject $Description
}
Task PesterIntegrationTest {
	$Seperator
	Write-Output "Invoking Pester Unit tests..."
	$Context = "PSModule_IntegrationTesting"
	#$Script:ModuleFolder
	if ($CIEngine -eq 'Local')
	{
		$NUnitXml = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath 'INTEG-PesterOutput.xml'
		$TestResults = Invoke-Pester -Path $PSScriptRoot -Tag 'INTEG' -PassThru -OutputFormat NUnitXml -OutputFile $NUnitXml
		If ($TestResults.FailedCount -gt 0)
		{
			$Description = "$($TestResults.FailedCount) out of $($TestResults.TotalCount) Tests failed"
		}
		else
		{
			$Description = "$($TestResults.PassedCount) out of $($TestResults.TotalCount) Tests succeeded"
		}
	}
	else
	{
		$NUnitXml = Join-Path -Path $PSScriptRoot -ChildPath 'INTEG-PesterOutput.xml'
		Set-GitHubStatus -Repository $Repository -State $GitStatus.Pending -Revision $Revision -Context $Context -Description "Invoking Pester..."
		$TestResults = Invoke-Pester -Path $PSScriptRoot -Tag 'INTEG' -PassThru -OutputFormat NUnitXml -OutputFile $NUnitXml
		If ($TestResults.FailedCount -gt 0)
		{
			$Description = "$($TestResults.FailedCount) out of $($TestResults.TotalCount) Tests failed"
			Set-GitHubStatus -Repository $Repository -State $GitStatus.Failure -Revision $Revision -Context $Context -Description $Description
		}
		else
		{
			$Description = "$($TestResults.PassedCount) out of $($TestResults.TotalCount) Tests succeeded"
			Set-GitHubStatus -Repository $Repository -State $GitStatus.Success -Revision $Revision -Context $Context -Description $Description
		}
	}
	Write-Output -InputObject $Description
}
Task CompleteIntegrationTests {
	$Seperator
	$Description = "All steps complete"
	if ($CIEngine -eq 'Bamboo')
	{
		$Context = "PSModule_IntegrationTesting"
		Set-GitHubStatus -Repository $Repository -State $GitStatus.Success -Revision $Revision -Context $Context -Description $Description
	}
	$Context = "Bamboo_BuildingEXE"
	Write-Output -InputObject $Description
}
#endregion
#region Generate Documentation
Task GenerateDocs {
	Import-Module -Name $ModuleName -Force
	Join-Path -Path $PSScriptRoot -ChildPath "docs" | Get-ChildItem | Remove-Item -Force
	New-MarkdownHelp -Module $ModuleName -OutputFolder "$PSScriptRoot\docs" -Force -NoMetadata -WithModulePage
	Join-Path -Path $PSScriptRoot -ChildPath "docs\$ModuleName.md" | Rename-Item -NewName "index.md"
}
#endregion
#region Generate ReadMe
Task GenerateReadMe {
	$PesterOutputs = Get-childitem -Path $ENV:Temp -filter *.xml | Where-Object -Property Name -match "${ModuleName}-.+-PesterOutput.xml"
	[System.Int32]$TotalTestCount = 0
	[System.Double]$CodeCoveragePct = 0
	[System.Collections.ArrayList]$ReadMeOutput = @()
	[System.Collections.Hashtable]$Results = @{ }
	$Descriptions = @{
		PSSA	  = "PowerShell Script Analyzer"
		UNIT	  = "Unit Tests"
		STRUCT    = "Function Structure Tests"
		CC	      = "Code Coverage"
	}
	foreach ($XMLFile in $PesterOutputs)
	{
		$XML = [xml](Get-Content -Path $XMLFile.FullName)
		switch -regex ($XMLFile.Name)
		{
			'-(PSSA|STRUCT|UNIT)-'
			{
				$Name = $XMLFile.Name -replace "${ModuleName}-(PSSA|STRUCT|UNIT)-PesterOutput.xml", '$1'
				$Results.$Name = @{
					"Test Set"   = $Descriptions.$Name
				}
				foreach ($State in "Total", "Errors", "Failures", "Not-run", "Inconclusive", "Ignored", "Skipped", "Invalid")
				{
					if ($State -eq "total")
					{
						$TotalTestCount += $XML.'test-results'.$State
					}
					$Results.$Name.$State = $XML.'test-results'.$State
				}
			}
			'-(CC)-'
			{
				$CCResults = $XML.report.counter | Where-Object -Property 'Type' -EQ -Value 'INSTRUCTION'
				$CodeCoveragePct = (([System.Int32]$CCResults.Covered) / ([System.Int32]$CCResults.Missed + [System.Int32]$CCResults.Covered)) * 100
			}
		}
	}
	$null = $ReadMeOutput.Add("# $ModuleName")
	$null = $ReadMeOutput.Add("## Testing Status ($TotalTestCount tests providing $("{0:N1}" -f $CodeCoveragePct)% Code Coverage)")
	$TableHeaders = @("Test Set", "Total", "Errors", "Failures", "Not-run", "Inconclusive", "Ignored", "Skipped", "Invalid")
	$null = $ReadMeOutput.Add("| $($TableHeaders -join ' | ')|")
	$null = $ReadMeOutput.Add("|$(($TableHeaders -replace '.', '-') -join '|')|")
	foreach ($TestSet in ("PSSA", "STRUCT", "UNIT"))
	{
		$Line = "| "
		foreach ($Header in $TableHeaders)
		{
			$Line += $Results.$TestSet.$Header
			$Line += " | "
		}
		$Line += " |"
		$null = $ReadMeOutput.Add($Line)
	}
	$ReadMeOutput -join "`r`n" | Out-File -FilePath "$PSScriptRoot\README.md" -Encoding ascii
}
#endregion
#region Deploy to Nuget
Task Deploy {
	$Nuspec = Join-Path -Path $Script:ModuleFolder -ChildPath "$ModuleName.nuspec" | Get-Item
	& NuGet.exe Pack $Nuspec.FullName
	$Nupkg = Join-Path -Path $PSScriptRoot -ChildPath "$ModuleName.$Script:Version.nupkg" | Get-Item
	& NuGet.exe Push $Nupkg.FullName -Source $NugetUrl -apikey $ApiKey
}
#endregion
#endregion
