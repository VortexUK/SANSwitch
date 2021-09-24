Import-Module -Name SNMP
$ModuleName = 'SANSwitch'
$null = Get-ChildItem -Path "$PSScriptRoot\$ModuleName" -Filter *.ps1 -recurse |
ForEach-Object -Process { . $_.FullName }
#region Unit Testing
#region Required Variables for testing
[System.String]$SANSWitchFormat = '^SAN(SW|AG)'
[System.String]$IPFormat = '\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b'
[System.String]$SNMPCommunityString = ''
#endregion
#region Internal Variables
[System.Management.Automation.PSObject]$Oids = New-Object -TypeName System.Management.Automation.PSObject -Property @{
	'FlogiPWWNs'	   = '1.3.6.1.4.1.9.9.289.1.1.5.1.3'
	'FlogiInterfaces'  = '1.3.6.1.2.1.2.2.1.2'
	'VSANs'		       = '.1.3.6.1.4.1.9.9.282.1.1.3.1.2'
	'Fabrics'		   = '1.3.6.1.4.1.9.9.294.1.1.4.1.2'
	'Aliases'		   = '1.3.6.1.4.1.9.9.430.1.1.2.1.3.1'
}
#endregion
Describe -Tags 'UNIT' -Name "Get-SwitchIP Unit Tests" {
	Context -Name 'Call with valid switchname' {
		$Result = Get-SwitchIP -SwitchName 'sanag1-3a2-vgis.uberit.net'
		It 'should return a type of System.Net.IPAddress' {
			$Result | Should BeOfType 'System.Net.IPAddress'
		}
	}
	Context -Name 'Call with invalid switchname' {
		Mock -CommandName Write-Error -MockWith { } -Verifiable
		$Result = Get-SwitchIP -SwitchName 'SANSWsomething.bad'
		It 'should return $null' {
			$Result | Should Be $null
		}
		It 'should call Write-Error 1 time' {
			Assert-MockCalled -CommandName Write-Error -Times 1 -Exactly
		}
	}
	Context -Name 'Multiple IPs found' {
		Mock -CommandName Measure-Object -MockWith { @{ Count = 2 } }
		Mock -CommandName Write-Warning -MockWith { }
		$Result = Get-SwitchIP -SwitchName 'sanag1-3a2-vgis.uberit.net' -ErrorAction SilentlyContinue
		It 'should return a type of System.Net.IPAddress' {
			$Result | Should BeOfType 'System.Net.IPAddress'
		}
		It 'should call Write-Warning 1 time' {
			Assert-MockCalled -CommandName Write-Warning -Times 1 -Exactly
		}
	}
}
Describe -Tags 'UNIT' -Name "Get-SwitchName Unit Tests" {
	Context -Name 'Call with valid switchIP' {
		$Result = Get-SwitchName -SwitchIP "172.19.33.2"
		It 'should return a type of System.String' {
			$Result | Should BeOfType 'System.String'
		}
	}
	Context -Name 'Call with ip that does not resolve' {
		Mock -CommandName Write-Error -MockWith { } -Verifiable
		$Result = Get-SwitchName -SwitchIP "172.19.33.0"
		It 'should return $null' {
			$Result | Should Be $null
		}
		It 'should call Write-Error 1 time' {
			Assert-MockCalled -CommandName Write-Error -Times 1 -Exactly
		}
	}
	Context -Name 'Multiple Names found' {
		Mock -CommandName Measure-Object -MockWith { @{ Count = 2 } }
		Mock -CommandName Write-Warning -MockWith { }
		$Result = Get-SwitchName -SwitchIP "172.19.33.2"
		It 'should return a type of System.String' {
			$Result | Should BeOfType 'System.String'
		}
		It 'should call Write-Warning 1 time' {
			Assert-MockCalled -CommandName Write-Warning -Times 1 -Exactly
		}
	}
	Context -Name 'Call with ip that resolves to something that is not a SANSwitch' {
		Mock -CommandName Write-Error -MockWith { } -Verifiable
		$Result = Get-SwitchName -SwitchIP "172.18.0.100"
		It 'should return $null' {
			$Result | Should Be $null
		}
		It 'should call Write-Error 1 time' {
			Assert-MockCalled -CommandName Write-Error -Times 1 -Exactly
		}
	}
}
Describe -Tags 'UNIT' -Name "Get-UnfilteredAlias Unit Tests" {
	Mock -CommandName Get-SNMPData -MockWith { @{ Data = "SomeAlias"; OID = "AA:BB:CC:DD:EE:FF:GG:HH:II"; } }
	Context -Name 'Get unfiltered aliases using switch name' {
		Mock -CommandName Get-SwitchIP -MockWith { [System.Net.IPAddress]"172.19.33.2" }
		$Result = Get-UnfilteredAlias -SwitchName "sanag1-3a2-vgis.uberit.net"
		It 'should return a type of System.Management.Automation.PSObject' {
			$Result | Should BeOfType 'System.Management.Automation.PSObject'
		}
		It 'Should call Get-SwitchIP 1 time'{
			Assert-MockCalled -CommandName Get-SwitchIP -Times 1 -Exactly
		}
		It 'Should call Get-SNMPData 1 time'{
			Assert-MockCalled -CommandName Get-SNMPData -Times 1 -Exactly
		}
	}
	Context -Name 'Bad switch name' {
		Mock -CommandName Get-SwitchIP -MockWith { }
		$Result = Get-UnfilteredAlias -SwitchName "sanagbadname.uberit.net"
		It 'should return $null' {
			$Result | Should Be $null
		}
		It 'Should call Get-SwitchIP 1 time'{
			Assert-MockCalled -CommandName Get-SwitchIP -Times 1 -Exactly
		}
		It 'Should call Get-SNMPData 0 time'{
			Assert-MockCalled -CommandName Get-SNMPData -Times 0 -Exactly
		}
	}
	Context -Name 'Get unfiltered aliases using switch ip' {
		Mock -CommandName Get-SwitchName -MockWith { "sanag1-3a2-vgis.uberit.net" }
		$Result = Get-UnfilteredAlias -SwitchIP "172.19.33.2"
		It 'should return a type of System.Management.Automation.PSObject' {
			$Result | Should BeOfType 'System.Management.Automation.PSObject'
		}
		It 'Should call Get-SwitchName 1 time'{
			Assert-MockCalled -CommandName Get-SwitchName -Times 1 -Exactly
		}
		It 'Should call Get-SNMPData 1 time'{
			Assert-MockCalled -CommandName Get-SNMPData -Times 1 -Exactly
		}
	}
	Context -Name 'Bad switch ip' {
		Mock -CommandName Get-SwitchName -MockWith { $null }
		$Result = Get-UnfilteredAlias -SwitchIP "172.19.33.2"
		It 'should return $null' {
			$Result | Should Be $null
		}
		It 'Should call Get-SwitchName 1 time'{
			Assert-MockCalled -CommandName Get-SwitchName -Times 1 -Exactly
		}
		It 'Should call Get-SNMPData 0 time'{
			Assert-MockCalled -CommandName Get-SNMPData -Times 0 -Exactly
		}
	}
}
Describe -Tags 'UNIT' -Name "Get-UnfilteredInterface Unit Tests" {
	Mock -CommandName Get-SNMPData -MockWith { @{ Data = "SomeAlias"; OID = "AA:BB:CC:DD:EE:FF:GG:HH:II"; } }
	Context -Name 'Get unfiltered aliases using switch name' {
		Mock -CommandName Get-SwitchIP -MockWith { [System.Net.IPAddress]"172.19.33.2" }
		$Result = Get-UnfilteredInterface -SwitchName "sanag1-3a2-vgis.uberit.net"
		It 'should return a type of System.Management.Automation.PSObject' {
			$Result | Should BeOfType 'System.Management.Automation.PSObject'
		}
		It 'Should call Get-SwitchIP 1 time'{
			Assert-MockCalled -CommandName Get-SwitchIP -Times 1 -Exactly
		}
		It 'Should call Get-SNMPData 1 time'{
			Assert-MockCalled -CommandName Get-SNMPData -Times 1 -Exactly
		}
	}
	Context -Name 'Bad switch name' {
		Mock -CommandName Get-SwitchIP -MockWith { }
		$Result = Get-UnfilteredInterface -SwitchName "sanagbadname.uberit.net"
		It 'should return $null' {
			$Result | Should Be $null
		}
		It 'Should call Get-SwitchIP 1 time'{
			Assert-MockCalled -CommandName Get-SwitchIP -Times 1 -Exactly
		}
		It 'Should call Get-SNMPData 0 time'{
			Assert-MockCalled -CommandName Get-SNMPData -Times 0 -Exactly
		}
	}
	Context -Name 'Get unfiltered aliases using switch ip' {
		Mock -CommandName Get-SwitchName -MockWith { "sanag1-3a2-vgis.uberit.net" }
		$Result = Get-UnfilteredInterface -SwitchIP "172.19.33.2"
		It 'should return a type of System.Management.Automation.PSObject' {
			$Result | Should BeOfType 'System.Management.Automation.PSObject'
		}
		It 'Should call Get-SwitchName 1 time'{
			Assert-MockCalled -CommandName Get-SwitchName -Times 1 -Exactly
		}
		It 'Should call Get-SNMPData 1 time'{
			Assert-MockCalled -CommandName Get-SNMPData -Times 1 -Exactly
		}
	}
	Context -Name 'Bad switch ip' {
		Mock -CommandName Get-SwitchName -MockWith { $null }
		$Result = Get-UnfilteredInterface -SwitchIP "172.19.33.2"
		It 'should return $null' {
			$Result | Should Be $null
		}
		It 'Should call Get-SwitchName 1 time'{
			Assert-MockCalled -CommandName Get-SwitchName -Times 1 -Exactly
		}
		It 'Should call Get-SNMPData 0 time'{
			Assert-MockCalled -CommandName Get-SNMPData -Times 0 -Exactly
		}
	}
}
Describe -Tags 'UNIT' -Name "Get-UnfilteredPWWN Unit Tests" {
	Mock -CommandName Get-SNMPData -MockWith { @{ Data = "SomeAlias"; OID = "AA:BB:CC:DD:EE:FF:GG:HH:II"; } }
	Context -Name 'Get unfiltered aliases using switch name' {
		Mock -CommandName Get-SwitchIP -MockWith { [System.Net.IPAddress]"172.19.33.2" }
		$Result = Get-UnfilteredPWWN -SwitchName "sanag1-3a2-vgis.uberit.net"
		It 'should return a type of System.Management.Automation.PSObject' {
			$Result | Should BeOfType 'System.Management.Automation.PSObject'
		}
		It 'Should call Get-SwitchIP 1 time'{
			Assert-MockCalled -CommandName Get-SwitchIP -Times 1 -Exactly
		}
		It 'Should call Get-SNMPData 1 time'{
			Assert-MockCalled -CommandName Get-SNMPData -Times 1 -Exactly
		}
	}
	Context -Name 'Bad switch name' {
		Mock -CommandName Get-SwitchIP -MockWith { }
		$Result = Get-UnfilteredPWWN -SwitchName "sanagbadname.uberit.net"
		It 'should return $null' {
			$Result | Should Be $null
		}
		It 'Should call Get-SwitchIP 1 time'{
			Assert-MockCalled -CommandName Get-SwitchIP -Times 1 -Exactly
		}
		It 'Should call Get-SNMPData 0 time'{
			Assert-MockCalled -CommandName Get-SNMPData -Times 0 -Exactly
		}
	}
	Context -Name 'Get unfiltered aliases using switch ip' {
		Mock -CommandName Get-SwitchName -MockWith { "sanag1-3a2-vgis.uberit.net" }
		$Result = Get-UnfilteredPWWN -SwitchIP "172.19.33.2"
		It 'should return a type of System.Management.Automation.PSObject' {
			$Result | Should BeOfType 'System.Management.Automation.PSObject'
		}
		It 'Should call Get-SwitchName 1 time'{
			Assert-MockCalled -CommandName Get-SwitchName -Times 1 -Exactly
		}
		It 'Should call Get-SNMPData 1 time'{
			Assert-MockCalled -CommandName Get-SNMPData -Times 1 -Exactly
		}
	}
	Context -Name 'Bad switch ip' {
		Mock -CommandName Get-SwitchName -MockWith { $null }
		$Result = Get-UnfilteredPWWN -SwitchIP "172.19.33.2"
		It 'should return $null' {
			$Result | Should Be $null
		}
		It 'Should call Get-SwitchName 1 time'{
			Assert-MockCalled -CommandName Get-SwitchName -Times 1 -Exactly
		}
		It 'Should call Get-SNMPData 0 time'{
			Assert-MockCalled -CommandName Get-SNMPData -Times 0 -Exactly
		}
	}
}
Describe -Tags 'UNIT' -Name "Get-SANFabric Unit Tests" {
	Mock -CommandName Get-SNMPData -MockWith { @{ Data = "SomeAlias"; OID = 1; } } -Verifiable
	Mock -CommandName Get-SwitchIP -MockWith { '10.0.0.1' } -ParameterFilter { $SwitchName -eq 'SANSW3' }
	Mock -CommandName Get-SwitchIP -MockWith { throw } -ParameterFilter { $SwitchName -eq 'BadSW3' }
	Mock -CommandName Get-SwitchName -MockWith { 'SANSW3' } -ParameterFilter { $SwitchIP -eq '10.0.0.1' }
	Mock -CommandName Get-SwitchName -MockWith { throw } -ParameterFilter { $SwitchIP -eq '00.0.0t' }
	Context -Name 'Call with valid switchname' {
		$Result = Get-SANFabric -SwitchName 'SANSW3'
		It 'should call Get-SwitchIP 1 time' {
			Assert-MockCalled -CommandName Get-SwitchIP -Times 1 -Exactly
		}
		It 'should call It should collect data from the unfiltered functions' {
			Assert-VerifiableMock
		}
	}
	Context -Name 'Call with invalid switchname' {
		It 'should throw an error' {
			{ Get-SANFabric -SwitchName 'BadSW3' } | Should Throw
		}
	}
	Context -Name 'Call with invalid switchname 2' {
		Mock -CommandName Get-SwitchIP -MockWith { }
		$Result = Get-SANFabric -SwitchName 'Sanag1-a1a-vgis' 
		It 'should return null' {
			 $Result | Should Be $null
		}
		It 'should call Get-SwitchIP 1 time' {
			Assert-MockCalled -CommandName Get-SwitchIP -Times 1 -Exactly
		}
	}
	Context -Name 'Call with valid IP' {
		$Result = Get-SANFabric -SwitchIP '10.0.0.1'
		It 'should call Get-SwitchName 1 time' {
			Assert-MockCalled -CommandName Get-SNMPData -Times 1 -Exactly
			Assert-MockCalled -CommandName Get-SwitchName -Times 1 -Exactly
		}
		It 'should call It should collect data from the unfiltered functions' {
			Assert-VerifiableMock
		}
	}
	Context -Name 'Call with invalid Switch IP' {
		It 'should throw an error' {
			{ Get-SANFabric -SwitchIP '00.0.0t' } | Should Throw
		}
	}
	Context -Name 'Call with invalid Switch IP 2' {
		Mock -CommandName Get-SwitchName -MockWith { }
		$Result = Get-SANFabric -SwitchIP '172.19.33.2'
		It 'should return null' {
			$Result | Should Be $null
		}
		It 'should call Get-SwitchIP 1 time' {
			Assert-MockCalled -CommandName Get-SwitchName -Times 1 -Exactly
		}
	}
}
Describe -Tags 'UNIT' -Name "Get-SANFCAlias Unit Tests" {
	Mock -CommandName Get-UnfilteredAlias -MockWith { } -Verifiable
	Mock -CommandName Get-SANFlogiDB -MockWith { } -Verifiable
	Mock -CommandName Get-SANVSAN -MockWith { } -Verifiable
	Mock -CommandName Get-SwitchIP -MockWith { '10.0.0.1' } -ParameterFilter { $SwitchName -eq 'SANSW3' }
	Mock -CommandName Get-SwitchIP -MockWith { throw } -ParameterFilter { $SwitchName -eq 'BadSW3' }
	Mock -CommandName Get-SwitchName -MockWith { 'SANSW3' } -ParameterFilter { $SwitchIP -eq '10.0.0.1' }
	Mock -CommandName Get-SwitchName -MockWith { throw } -ParameterFilter { $SwitchIP -eq '00.0.0t' }
	Context -Name 'Call with valid switchname' {
		$Result = Get-SANFCAlias -SwitchName 'SANSW3'
		It 'should call Get-SwitchIP 1 time' {
			Assert-MockCalled -CommandName Get-SwitchIP -Times 1 -Exactly
		}
		It 'should call It should collect data from the unfiltered functions' {
			Assert-VerifiableMock
		}
	}
	Context -Name 'Call with invalid switchname' {
		It 'should throw an error' {
			{ Get-SANFCAlias -SwitchName 'BadSW3' } | Should Throw
		}
	}
	Context -Name 'Call with valid IP' {
		$Result = Get-SANFCAlias -SwitchIP '10.0.0.1'
		It 'should call Get-SwitchName 1 time' {
			Assert-MockCalled -CommandName Get-SwitchName -Times 1 -Exactly
		}
		It 'should call It should collect data from the unfiltered functions' {
			Assert-VerifiableMock
		}
	}
	Context -Name 'Call with invalid Switch IP' {
		It 'should throw an error' {
			{ Get-SANFCAlias -SwitchIP '00.0.0tt' } | Should Throw
		}
	}
}
Describe -Tags 'UNIT' -Name "Get-SanFlogiDB Unit Tests" {
	Mock -CommandName Get-UnfilteredPWWN -MockWith { } -Verifiable
	Mock -CommandName Get-UnfilteredInterface -MockWith { } -Verifiable
	Mock -CommandName Get-SANVSAN -MockWith { } -Verifiable
	Mock -CommandName Get-SwitchIP -MockWith { '10.0.0.1' } -ParameterFilter { $SwitchName -eq 'SANSW3' }
	Mock -CommandName Get-SwitchIP -MockWith { throw } -ParameterFilter { $SwitchName -eq 'BadSW3' }
	Mock -CommandName Get-SwitchName -MockWith { 'SANSW3' } -ParameterFilter { $SwitchIP -eq '10.0.0.1' }
	Mock -CommandName Get-SwitchName -MockWith { throw } -ParameterFilter { $SwitchIP -eq '00.0.0t' }
	Context -Name 'Call with valid switchname' {
		$Result = Get-SanFlogiDB -SwitchName 'SANSW3'
		It 'should call Get-SwitchIP 1 time' {
			Assert-MockCalled -CommandName Get-SwitchIP -Times 1 -Exactly
		}
		It 'should call It should collect data from the unfiltered functions' {
			Assert-VerifiableMock
		}
	}
	Context -Name 'Call with invalid switchname' {
		It 'should throw an error' {
			{ Get-SanFlogiDB -SwitchName 'BadSW3' } | Should Throw
		}
	}
	Context -Name 'Call with valid IP' {
		$Result = Get-SanFlogiDB -SwitchIP '10.0.0.1'
		It 'should call Get-SwitchName 1 time' {
			Assert-MockCalled -CommandName Get-SwitchName -Times 1 -Exactly
		}
		It 'should call It should collect data from the unfiltered functions' {
			Assert-VerifiableMock
		}
	}
	Context -Name 'Call with invalid Switch IP' {
		It 'should throw an error' {
			{ Get-SanFlogiDB -SwitchIP '00.0.0t' } | Should Throw
		}
	}
}
Describe -Tags 'UNIT' -Name "Get-SANVSAN Unit Tests" {
	Mock -CommandName Get-SNMPData -MockWith { } -Verifiable
	Mock -CommandName Get-SwitchIP -MockWith { '10.0.0.1' } -ParameterFilter { $SwitchName -eq 'SANSW3' }
	Mock -CommandName Get-SwitchIP -MockWith { throw } -ParameterFilter { $SwitchName -eq 'BadSW3' }
	Mock -CommandName Get-SwitchName -MockWith { 'SANSW3' } -ParameterFilter { $SwitchIP -eq '10.0.0.1' }
	Mock -CommandName Get-SwitchName -MockWith { throw } -ParameterFilter { $SwitchIP -eq '00.0.0t' }
	Context -Name 'Call with valid switchname' {
		$Result = Get-SANVSAN -SwitchName 'SANSW3'
		It 'should call Get-SwitchIP 1 time' {
			Assert-MockCalled -CommandName Get-SwitchIP -Times 1 -Exactly
		}
		It 'should call It should collect data from the unfiltered functions' {
			Assert-VerifiableMock
		}
	}
	Context -Name 'Call with invalid switchname' {
		It 'should throw an error' {
			{ Get-SANVSAN -SwitchName 'BadSW3' } | Should Throw
		}
	}
	Context -Name 'Call with valid IP' {
		$Result = Get-SANVSAN -SwitchIP '10.0.0.1'
		It 'should call Get-SwitchName 1 time' {
			Assert-MockCalled -CommandName Get-SwitchName -Times 1 -Exactly
		}
		It 'should call It should collect data from the unfiltered functions' {
			Assert-VerifiableMock
		}
	}
	Context -Name 'Call with invalid Switch IP' {
		It 'should throw an error' {
			{ Get-SANVSAN -SwitchIP '00.0.0t' } | Should Throw
		}
	}
}
#endregion
#region Structural Tests
Describe -Tags 'STRUCT' -Name 'Structure Tests' {
	$FunctionFiles = "Private", "Public" | ForEach-Object -Process { if (Test-Path -Path "$PSScriptRoot\$ModuleName\$_\") { Get-ChildItem -Path "$PSScriptRoot\$ModuleName\$_\" -File } }
	Write-Host "There are $(($FunctionFiles | measure).Count)"
	[System.Collections.ArrayList]$Tests = Get-Content -Path "$PSScriptRoot\$ModuleName.tests.ps1"
	foreach ($Function in $FunctionFiles)
	{
		$FunctionName = $Function.Name -replace '\.ps1'
		$FunctionBody = Get-Content -Path $Function.FullName
		Context "$FunctionName Structure Tests"	{
			It 'Should have an associated Unit Test' {
				($Tests | Where-Object -FilterScript { $_ -match "Describe -Tags 'UNIT' -Name `"$FunctionName Unit Tests`" {" } | Measure-Object).Count | Should be 1
			}
			It 'Function Name should match file name' {
				($FunctionBody | Where-Object -FilterScript { $_ -match "function $FunctionName" } | Measure-Object).Count | Should be  1
			}
			It 'Should have a comment help block' {
				($FunctionBody | Where-Object -FilterScript { $_ -match "\.(SYNOPSIS|DESCRIPTION|EXAMPLE)" } | Measure-Object).Count | Should be  3
			}
			It 'Should have A CmdletBinding' {
				($FunctionBody | Where-Object -FilterScript { $_ -match "\[CmdletBinding\(.+" } | Measure-Object).Count | Should be  1
			}
			if ($Function.FullName -match '\\Public\\' -and $Function.Name -notmatch "^Get-")
			{
				It 'Should have support for -whatif and -verbose if not a get function' {
					($FunctionBody | Where-Object -FilterScript { $_ -match 'SupportsShouldProcess[^\r\n]+true' } | Measure-Object).Count | Should be  1
				}
			}
			foreach ($Block in '\tPARAM(?![eE])', '\tBEGIN', '\tPROCESS', '\tEND')
			{
				It "Should have  $Block block" {
					($FunctionBody | Where-Object -FilterScript { $_ -cmatch $Block } | Measure-Object).Count | Should be  1
				}
			}
		}
	}
}
#endregion
#region PSSA Testing
Describe -Tags 'PSSA' -Name 'Testing against PSScriptAnalyzer rules' {
	Context 'PSSA Standard Rules' {
		$ScriptAnalyzerSettings = Get-Content -Path "$PSScriptRoot\ScriptAnalyzerSettings.psd1" | Out-String | Invoke-Expression
		$ModulePath = Get-Module -Name $ModuleName | Select-Object -ExpandProperty ModuleBase
		Invoke-ScriptAnalyzer -Path "$PSScriptRoot\$ModuleName" -Settings $ScriptAnalyzerSettings
		# Test all the functions. I use PowerShell studio that puts 'temppoints' everywhere, so need to exclude them
		$ScriptAnalyzerRuleNames = Get-ScriptAnalyzerRule | Select-Object -ExpandProperty RuleName
		forEach ($Rule in $ScriptAnalyzerRuleNames)
		{
			if ($ScriptAnalyzerSettings.excluderules -notcontains $Rule)
			{
				It "Should pass $Rule" {
					$Failures = $AnalyzerIssues | Where-Object -Property RuleName -EQ -Value $rule
					($Failures | Measure-Object).Count | Should Be 0
				}
			}
			else
			{
				# We still want it in the tests, but since it doesn't actually get tested we will skip
				It "Should pass $Rule" -Skip {
					$Failures = $AnalyzerIssues | Where-Object -Property RuleName -EQ -Value $rule
					($Failures | Measure-Object).Count | Should Be 0
				}
			}
			
		}
		
	}
	
}
#endregion
#region Integration Testing
Describe -Tags 'INTEG' -Name 'Testing full module functions' {
	Context -Name 'Search-AD and return results' {
		It "should return more than one result" {
			$Results = Get-SANFabric -SwitchName 'SANSW1-3A1-VGIS'
			($Results | Measure-Object).Count | Should BeGreaterThan 1
		}
	}
}
#endregion
