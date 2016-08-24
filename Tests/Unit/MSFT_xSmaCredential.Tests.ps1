<#
.Synopsis
   MSFT_xSmaCredential unit test.
#>

# Suppression of this PSSA rule allowed in tests.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
Param()

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
    #region SMA credentials not found
    Describe 'SMA credentials not found' {
        Mock -CommandName Get-SmaCredential -MockWith { "" } 
        Mock -CommandName Set-SmaCredential -MockWith { } -Verifiable

        $testParameters = @{
            Name = 'CredentialName'
            credential = $cred
            WebServiceEndpoint = 'https://localhost'
        }

        It 'Get method returns no user name or description' {

            $result = Get-TargetResource @testParameters 
            
            $result.name | Should Be $testParameters.Name
            $result.credential | should be $testParameters.credential
            $result.Description | should be ""
            $result.UserName | should be ""
            $result.WebServiceEndpoint | Should Be $testParameters.WebServiceEndpoint
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

    #region The SMA Credential exist but has the wrong user name
    Describe 'The SMA Credential exist but has the wrong user name' {
        $testParameters = @{
            Name = 'CredentialName'
            credential = $cred
            WebServiceEndpoint = 'https://localhost'
        }

        Mock -CommandName Get-SmaCredential -MockWith { @{ Name = $testParameters.Name; UserName = "$($cred.UserName)1"} } 
        Mock -CommandName Set-SmaCredential -MockWith {  } -Verifiable

        It 'Get method returns discovered user name' {
            $result = Get-TargetResource @testParameters 
            
            $result.name | Should Be $testParameters.Name
            $result.credential | should be $testParameters.credential
            $result.Description | should be ""
            $result.UserName | should be "$($cred.UserName)1"
            $result.WebServiceEndpoint | Should Be $testParameters.WebServiceEndpoint
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

        Mock -CommandName Get-SmaCredential -MockWith { @{ Name = $testParameters.Name; UserName = $cred.UserName; } } 
        Mock -CommandName Set-SmaCredential -MockWith {  } -Verifiable  

        It 'Get method returns blank description ' {
            $result = Get-TargetResource @testParameters 
            
            $result.name | Should Be $testParameters.Name
            $result.credential | should be $testParameters.credential
            $result.Description | should be ""
            $result.UserName | should be $testParameters.credential.UserName
            $result.WebServiceEndpoint | Should Be $testParameters.WebServiceEndpoint
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
            $result.credential | should be $testParameters.credential
            $result.Description | should be $testParameters.Description
            $result.UserName | should be $testParameters.credential.UserName
            $result.WebServiceEndpoint | Should Be $testParameters.WebServiceEndpoint
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

