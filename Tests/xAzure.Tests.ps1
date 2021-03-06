Import-Module "$(Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))\xAzure.psm1"

##############################
# Script Analyzer tests
##############################
$here = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$scriptsModules = Get-ChildItem $here -Include *.psd1, *.psm1, *.ps1 -Exclude *MSFT_*.psm1,.tests.ps1,*uild.ps1 -Recurse | Where-Object {$_.FullName -notlike "*Examples*"}

Describe 'General - Testing all scripts and modules against the Script Analyzer Rules' {
	Context "Checking files to test exist and Invoke-ScriptAnalyzer cmdLet is available" {
		It "Checking files exist to test." {
			$scriptsModules.count | Should Not Be 0
		}
		It "Checking Invoke-ScriptAnalyzer exists." {
			{ Get-Command Invoke-ScriptAnalyzer -ErrorAction Stop } | Should Not Throw
		}
	}

	$scriptAnalyzerRules = Get-ScriptAnalyzerRule

	forEach ($scriptModule in $scriptsModules) {
		switch -wildCard ($scriptModule) { 
			'*.psm1' { $typeTesting = 'Module' } 
			'*.ps1'  { $typeTesting = 'Script' } 
			'*.psd1' { $typeTesting = 'Manifest' } 
		}

		Context "Checking [$($typeTesting)]:[$($scriptModule)] - conforms to Script Analyzer Rules" {
			forEach ($scriptAnalyzerRule in $scriptAnalyzerRules) {
                if($scriptAnalyzerRule.RuleName -ne "PSUseDeclaredVarsMoreThanAssignments") {
    				It "Script Analyzer Rule $($scriptAnalyzerRule.RuleName)" {
	    				(Invoke-ScriptAnalyzer -Path $scriptModule -IncludeRule $scriptAnalyzerRule).count | Should Be 0
                    }
				}
			}
		}
	}
}

##############################
# Help check test
##############################
Foreach ($resource in (Get-DscResource -Module xAzure | Select-Object -ExpandProperty Name)) {
        Describe "Checking Help file on $resource" {
            $help = Get-Help *$resource*
            It "Should have help" {
                $help | should not benullorempty
            }
        }
    }