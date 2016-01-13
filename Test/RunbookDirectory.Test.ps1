$Module = "$PSScriptRoot\..\DSCResources\xRunbookDirectory\xRunbookDirectory.psm1"

Remove-Module -Name xRunbookDirectory -Force -ErrorAction SilentlyContinue

Import-Module -Name $Module -Force -ErrorAction Stop
Import-Module -Name 'Pester'

InModuleScope 'xRunbookDirectory' {
     Describe 'RunbookDirectory' {
        Context 'Test-TargetResource' {
            It 'Returns true when Matches is true' {
                Mock -CommandName 'Get-TargetResource' -MockWith { @{ Matches = $true} }

                Test-TargetResource -RunbookPath 'path' -WebServiceEndpoint 'endpoint' | should be $True 
            }         

            It 'Returns false when Matches is false' {
                Mock -CommandName 'Get-TargetResource' -MockWith { @{ Matches = $false} }

                Test-TargetResource -RunbookPath 'path' -WebServiceEndpoint 'endpoint' | should be $false 
            }
        }

        Context 'Get-TargetResource' {     
            # Add functions to mock to InModuleScope scope
            function Get-SmaRunbookDefinition {}

            It 'Does not return a match when runbooks do not match' {
                Mock -CommandName 'Get-Item' -MockWith {@{ FullName = 'test'; BaseName = 'Test'} }
                Mock -CommandName 'Get-SmaRunbookDefinition' -MockWith { @{ Content = ''} }
                Mock -CommandName 'Get-Content' -MockWith { '' }
                Mock -CommandName 'Get-Content' -MockWith { 'Fail' } -ParameterFilter {$path -eq 'test'}

                $return = Get-TargetResource -RunbookPath 'path' -WebServiceEndpoint 'endpoint' 

                $return.Matches | should be $false
            }

            It 'Returns a match when runbooks match' {
                Mock -CommandName 'Get-Item' -MockWith {@{ FullName = 'test'; BaseName = 'Test'} }
                Mock -CommandName 'Get-SmaRunbookDefinition' -MockWith { @{ Content = ''} }
                Mock -CommandName 'Get-Content' -MockWith { 'Pass' }
                Mock -CommandName 'Get-Content' -MockWith { 'Pass' } -ParameterFilter {$path -eq 'test'}

                $return = Get-TargetResource -RunbookPath 'path' -WebServiceEndpoint 'endpoint' 

                $return.Matches | should be $true
            }
            
            It 'Returns a match despite new line differences' {
                Mock -CommandName 'Get-Item' -MockWith {@{ FullName = 'test'; BaseName = 'Test'} }
                Mock -CommandName 'Get-SmaRunbookDefinition' -MockWith { @{ Content = ''} }
                Mock -CommandName 'Get-Content' -MockWith { @('','Pass','') }
                Mock -CommandName 'Get-Content' -MockWith { 'Pass' } -ParameterFilter {$path -eq 'test'}

                $return = Get-TargetResource -RunbookPath 'path' -WebServiceEndpoint 'endpoint' 

                $return.Matches | should be $true
            }    
            
            It 'Returns true when runbook path contains nothing' {
                Mock -CommandName 'Get-Item' -MockWith {}

                $return = Get-TargetResource -RunbookPath 'path' -WebServiceEndpoint 'endpoint'

                $return.Matches | should be $true
            }    

            It 'Validate published is used if specified' {
                Mock -CommandName 'Get-Item' -MockWith {@{ FullName = 'test'; BaseName = 'Test'} }
                Mock -CommandName 'Get-SmaRunbookDefinition' -MockWith { @{ Content = ''} } -ParameterFilter {$Type -eq "Published"} -Verifiable 
                Mock -CommandName 'Get-Content' -MockWith { 'Pass' }
                Mock -CommandName 'Get-Content' -MockWith { 'Pass' } -ParameterFilter {$path -eq 'test'}

                Get-TargetResource -RunbookPath 'path'-WebServiceEndpoint 'endpoint'

                Assert-MockCalled -CommandName 'Get-SmaRunbookDefinition' -Exactly 1 -Scope It
            } 

            It 'Validate published is not used if not specified' {
                Mock -CommandName 'Get-Item' -MockWith {@{ FullName = 'test'; BaseName = 'Test'} }
                Mock -CommandName 'Get-SmaRunbookDefinition' -MockWith { @{ Content = ''} } -ParameterFilter {$Type -eq "Draft"} -Verifiable
                Mock -CommandName 'Get-Content' -MockWith { 'Pass' }
                Mock -CommandName 'Get-Content' -MockWith { 'Pass' } -ParameterFilter {$path -eq 'test'}

                Get-TargetResource -RunbookPath 'path' -Publish $false -WebServiceEndpoint 'endpoint'

                Assert-MockCalled -CommandName 'Get-SmaRunbookDefinition' -Exactly 1 -Scope It
            }
        }

        Context 'Set-TargetResource' {
            # Add functions to mock to InModuleScope scope
            function Edit-SmaRunbook {}
            function Import-SmaRunbook {}
            function Publish-SmaRunbook {}

            It 'Import/Edits each runbook 2 times' {
                Mock -CommandName 'Get-Item' -MockWith { @( @{ FullName = 'test'; BaseName = 'Test'},  @{ FullName = 'test1'; BaseName = 'Test1'}) }
                Mock -CommandName 'Edit-SmaRunbook' -MockWith {} 

                Set-TargetResource -RunbookPath 'path' -Publish $false -WebServiceEndpoint 'endpoint' 

                Assert-MockCalled -CommandName 'Edit-SmaRunbook' -Exactly 4 -Scope It
            }

            It 'Imports runbooks when EDit-SmaRunbook fails' {
                Mock -CommandName 'Get-Item' -MockWith { @( @{ FullName = 'test'; BaseName = 'Test'},  @{ FullName = 'test1'; BaseName = 'Test1'}) }
                Mock -CommandName 'Edit-SmaRunbook' -MockWith { throw "Wdit-SmaRunbook Failed" } 
                Mock -CommandName 'Import-SmaRunbook' -MockWith {}

                Set-TargetResource -RunbookPath 'path' -Publish $false -WebServiceEndpoint 'endpoint'

                Assert-MockCalled -CommandName 'Import-SmaRunbook' -Exactly 4 -Scope It
            }

            It 'Published runbooks when publish is true' {
                Mock -CommandName 'Get-Item' -MockWith { @( @{ FullName = 'test'; BaseName = 'Test'},  @{ FullName = 'test1'; BaseName = 'Test1'}) }
                Mock -CommandName 'Edit-SmaRunbook' -MockWith {} 
                Mock -CommandName 'Publish-SmaRunbook' -MockWith {}

                Set-TargetResource -RunbookPath 'path'-WebServiceEndpoint 'endpoint'

                Assert-MockCalled -CommandName 'Publish-SmaRunbook' -Exactly 2 -Scope It
            }
        }
     }
}