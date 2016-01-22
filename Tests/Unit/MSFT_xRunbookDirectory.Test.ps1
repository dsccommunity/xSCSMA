<#
.Synopsis
   Unit test for xRunbookDirectory DSC Resource
#>

$Global:DSCModuleName      = 'xRunbookDirectory' 
$Global:DSCResourceName    = 'MSFT_xRunbookDirectory' 

#region HEADER
if ( (-not (Test-Path -Path '.\DSCResource.Tests\')) -or `
     (-not (Test-Path -Path '.\DSCResource.Tests\TestHelper.psm1')) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git')
}
else
{
    & git @('-C',(Join-Path -Path (Get-Location) -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module .\DSCResource.Tests\TestHelper.psm1 -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit 
#endregion

# Begin Testing
try
{
    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $Global:DSCResourceName {

        #region Pester Test Initialization
        # Add functions to mock to InModuleScope scope
        function Get-SmaRunbookDefinition {}
        function Edit-SmaRunbook {}
        function Import-SmaRunbook {}
        function Publish-SmaRunbook {}
        #endregion

        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
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
        #endregion

        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            It 'Returns true when Matches is true' {
                Mock -CommandName 'Get-TargetResource' -MockWith { @{ Matches = $true} }

                Test-TargetResource -RunbookPath 'path' -WebServiceEndpoint 'endpoint' | should be $True 
            }         

            It 'Returns false when Matches is false' {
                Mock -CommandName 'Get-TargetResource' -MockWith { @{ Matches = $false} }

                Test-TargetResource -RunbookPath 'path' -WebServiceEndpoint 'endpoint' | should be $false 
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            It 'Import/Edits each runbook 2 times' {
                Mock -CommandName 'Get-Item' -MockWith { @( @{ FullName = 'test'; BaseName = 'Test'},  @{ FullName = 'test1'; BaseName = 'Test1'}) }
                Mock -CommandName 'Edit-SmaRunbook' -MockWith {} 

                Set-TargetResource -RunbookPath 'path' -Publish $false -WebServiceEndpoint 'endpoint' 

                Assert-MockCalled -CommandName 'Edit-SmaRunbook' -Exactly 4 -Scope It
            }

            It 'Imports runbooks when Edit-SmaRunbook fails' {
                Mock -CommandName 'Get-Item' -MockWith { @( @{ FullName = 'test'; BaseName = 'Test'},  @{ FullName = 'test1'; BaseName = 'Test1'}) }
                Mock -CommandName 'Edit-SmaRunbook' -MockWith { throw "Edit-SmaRunbook Failed" } 
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
        #endregion
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}

