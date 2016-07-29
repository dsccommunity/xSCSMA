<#
.Synopsis
   MSFT_xSmaCredential unit test.
#>

$script:DSCModuleName      = 'MSFT_xSmaCredential'
$script:DSCResourceName    = 'MSFT_xSmaCredential' 

#region HEADER

# Unit Test Template Version: 1.1.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit 

#endregion HEADER

$pass = ConvertTo-SecureString 'password' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("account", $pass)

function Get-SmaCredential {}
function Set-SmaCredential {}
# Begin Testing
try
{
    #region Error getting SMA Credential
    Describe 'Error getting SMA Credential' {
        $errorValue = 'Error getting SMA Credential'        

        Mock -CommandName Get-SmaCredential -MockWith { Throw $errorValue } 
        Mock -CommandName Set-SmaCredential -MockWith { Throw $errorValue } -Verifiable

        $testParameters = @{
            Name = 'CredentialName'
            credential = $cred
            WebServiceEndpoint = 'https://localhost'
        }

        It 'Get method returns set equal to false' {
            $result = Get-TargetResource @testParameters 
            
            $result.name | Should Be $testParameters.Name
            $result.WebServiceEndpoint | Should Be $testParameters.WebServiceEndpoint
            $result.Set | Should Be 'False'
        }

        It 'Test method returns false' {
            Test-TargetResource @testParameters | Should be $false
        }

        It 'Set method calls Set-SmaCredential' {
            { Set-TargetResource @testParameters } | should throw $errorValue

            Assert-MockCalled Set-SmaCredential 
        }
    }
    #endregion

    #region The SMA Credential exist but has the wrong user name
    Describe 'The SMA Credential exist but has the wrong user name' {
        $testParameters = @{
            Name = 'CredentialName'
            credential = $cred
            WebServiceEndpoint = 'https://localhost'
        }

        Mock -CommandName Get-SmaCredential -MockWith { @{ Name = $testParameters.Name; UserName = "$($cred.UserName)1"} } 
        Mock -CommandName Set-SmaCredential -MockWith {  } -Verifiable

        It 'Get method returns set equal to false' {
            $result = Get-TargetResource @testParameters 
            
            $result.name | Should Be $testParameters.Name
            $result.WebServiceEndpoint | Should Be $testParameters.WebServiceEndpoint
            $result.Set | Should Be 'False'
        }

        It 'Test method returns false' {
            Test-TargetResource @testParameters | Should be $false
        }

        It 'Set method calls Set-SmaCredential' {
            Set-TargetResource @testParameters

            Assert-MockCalled Set-SmaCredential 
        }
    }
    #endregion

    #region The SMA Credential exist but has the wrong description
    Describe 'The SMA Credential exist but has the wrong description' {
        $testParameters = @{
            Name = 'CredentialName'
            credential = $cred
            WebServiceEndpoint = 'https://localhost'
            Description = 'Description'
        }

        Mock -CommandName Get-SmaCredential -MockWith { @{ Name = $testParameters.Name; UserName = $($cred.UserName)} } 
        Mock -CommandName Set-SmaCredential -MockWith {  } -Verifiable  

        It 'Get method returns set equal to false' {
            $result = Get-TargetResource @testParameters 
            
            $result.name | Should Be $testParameters.Name
            $result.WebServiceEndpoint | Should Be $testParameters.WebServiceEndpoint
            $result.Description | Should Be $testParameters.Description
            $result.Set | Should Be 'False'
        }

        It 'Test method returns false' {
            Test-TargetResource @testParameters | Should be $false
        }

        It 'Set method calls Set-SmaCredential' {
            Set-TargetResource @testParameters

            Assert-MockCalled Set-SmaCredential 
        }
    }
    #endregion

    #region The system is in the desired state
    Describe 'The system is in the desired state' {
        $testParameters = @{
            Name = 'CredentialName'
            credential = $cred
            WebServiceEndpoint = 'https://localhost'
            Description = 'Description'
        }
        
        Mock -CommandName Get-SmaCredential -MockWith { @{ Name = $testParameters.Name; UserName = $($cred.UserName); Description = $testParameters.Description} } 

        It 'Get method returns true' {
            $result = Get-TargetResource @testParameters 
            
            $result.name | Should Be $testParameters.Name
            $result.WebServiceEndpoint | Should Be $testParameters.WebServiceEndpoint
            $result.Description | Should Be $testParameters.Description
            $result.Set | Should Be 'True'
        }

        It 'Test method returns true' {
            Test-TargetResource @testParameters | Should be $true
        }
    }
    #endregion
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion

    Remove-Item Function:\Get-SmaCredential
    Remove-Item Function:\Set-SmaCredential
}

