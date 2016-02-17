<#
.Synopsis
   Unit test for xSmaVariable DSC Resource
#>

$Global:DSCModuleName      = 'xSmaVariable' 
$Global:DSCResourceName    = 'MSFT_xSmaVariable' 

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
        function Get-SmaVariable {}
        function Set-SmaVariable {}
        function Remove-SmaVariable {}
        #endregion


        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" { 
            It 'Returns set equal to true when name/value matches and no description' {
                Mock -CommandName Get-SmaVariable -MockWith { @{Name = 'name'; Value = 'value'; Description = ''} }
                
                $result = Get-TargetResource -Name 'name' -Value 'value' -Ensure "Present" -WebServiceEndpoint 'endpoint' -port 0

                $result.set | should be $true
            }

            It 'Returns set equal to true when name matches and description matches' {
                Mock -CommandName Get-SmaVariable -MockWith { @{Name = 'name'; Value = 'value'; Description = 'description'} }
                
                $result = Get-TargetResource -Name 'name' -Value 'value' -Description 'description' -Ensure "Present" -WebServiceEndpoint 'endpoint' -port 0

                $result.set | should be $true
            }

            It 'Returns Ensure equal to Absent when SMA variable cannot be found' {
                Mock -CommandName Get-SmaVariable -MockWith { throw 'SMA Variable not found' }

                $result = Get-TargetResource -Name 'name' -Value 'value' -Description 'description' -Ensure "Present" -WebServiceEndpoint 'endpoint' -port 0

                $result.Ensure | should be 'Absent'
            }    

            It 'Returns set equal to false when name/value matches and description does not match' {
                Mock -CommandName Get-SmaVariable -MockWith { @{Name = 'name'; Value = 'value'; Description = ''} }
                
                $result = Get-TargetResource -Name 'name' -Value 'value' -Description 'description' -Ensure "Present" -WebServiceEndpoint 'endpoint' -port 0

                $result.set | should be $false
            }

            It 'Returns set equal to false when name/description matches and value does not match' {
                Mock -CommandName Get-SmaVariable -MockWith { @{Name = 'name'; Value = 'value1'; Description = ''} }
                
                $result = Get-TargetResource -Name 'name' -Value 'value' -Description 'description' -Ensure "Present" -WebServiceEndpoint 'endpoint' -port 0

                $result.set | should be $false
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            It 'Returns true when DS is present, and the variable is found and is correct' {
                Mock -CommandName 'Get-TargetResource' -MockWith { @{ Set = $true; Ensure = 'Present'} }

                Test-TargetResource -Name 'name' -Value 'value' -Description 'description' -Ensure "Present" -WebServiceEndpoint 'endpoint' -port 0 | should be $true 
            }         

            It 'Returns true when DS is absent no matter returned status of set' {
                Mock -CommandName 'Get-TargetResource' -MockWith { @{ Set = $true; Ensure = 'Absent'} }

                Test-TargetResource -Name 'name' -Value 'value' -Description 'description' -Ensure "Absent" -WebServiceEndpoint 'endpoint' -port 0 | should be $true 
            }

            It 'Returns false when DS is present, and the variable is found and is incorrect' {
                Mock -CommandName 'Get-TargetResource' -MockWith { @{ Set = $false; Ensure = 'Present'} }

                Test-TargetResource -Name 'name' -Value 'value' -Description 'description' -Ensure "Present" -WebServiceEndpoint 'endpoint' -port 0 | should be $false 
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            It 'Attemps to set the variable when Ensure is Present' {
                Mock -CommandName Set-SmaVariable -Verifiable

                Set-TargetResource -Name 'name' -Value 'value' -Description 'description' -Ensure "Present" -WebServiceEndpoint 'endpoint' -port 0

                Assert-MockCalled -CommandName Set-SmaVariable -Exactly 1 -Scope It
            }

            It 'Attemps to remove the variable when Ensure is Absent' {
                Mock -CommandName Remove-SmaVariable -Verifiable

                Set-TargetResource -Name 'name' -Value 'value' -Description 'description' -Ensure "Absent" -WebServiceEndpoint 'endpoint' -port 0

                Assert-MockCalled -CommandName Remove-SmaVariable -Exactly 1 -Scope It
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

