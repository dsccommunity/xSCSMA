[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification='PesterTest')]
param()

$script:dscModuleName = (Split-Path -Path (Split-Path -Path $PSScriptRoot)).Split('\')[-1]
$script:dscResourceName = (Split-Path -Path $PSCommandPath -Leaf).Split('.')[0]
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'), '-q')
}

#region helper
Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit 
#endregion

try
{
    InModuleScope $script:DSCResourceName {

        $script:dscModuleName = (Split-Path -Path (Split-Path -Path $PSScriptRoot)).Split('\')[-1]
        $script:dscResourceName = (Split-Path -Path $PSCommandPath -Leaf).Split('.')[0]

        $credential = (New-Object System.Management.Automation.PSCredential ("administrator", (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force)))
        
        $2016Version = @{
            VersionInfo = @{
                ProductVersion = "7.3.345.0"
            }
            ID = "{4B76B636-AE9A-47D5-A246-E02909D97CF2}"
        }

        $2012Version = @{
            VersionInfo = @{
                ProductVersion = "7.2.1563.0"
            }
            ID = "{4B76B636-AE9A-47D5-A246-E02909D97CF2}" #SAME NUMBER????
        }

        $unknownVersion = @{
            VersionInfo = @{
                ProductVersion = "7.2.1563.2"
            }
        }

        $defaultDesiredState = @{
            Case = 'True when 2016 Product ID is found & Ensure is Present'
            Params = @{
                Ensure = "Present"
                SourcePath = "$TestDrive\SCSMA"
                SourceFolder = 'SystemCenter2016'
                SetupCredential = $credential
                FirstWebServiceServer = $true
                InstallFolder = 'C:\Program Files\Microsoft System Center 2016\Orchestrator\WebService'
                ApPool = $credential
                SiteName = 'SMA'
                AdminGroupMembers = $credential
                SqlServer = 'SQL'
                SqlDatabase = 'SMA'
                SqlInstance = 'SMA'
                RunbookWorkerServers = 'SQL'
                SendTelemetryReports = 'No'
            }
            SetupExeReturn = $2016Version
        }

        Describe "$($script:dscResourceName)\Get&Test-TargetResource" -Tag 'Get' {

            $testCases = @(
                $defaultDesiredState
                @{
                    Case = 'False when 2016 Product ID is not found & Ensure is Present'
                    Params = @{
                        Ensure = 'Present'
                    }
                    SetupExeReturn = $2016Version
                    TestDefaultInstance = $true #Test for using the default SQL Instance name, which returns $null for default instance name
                }
                @{
                    Case = 'False when 2016 Product ID is found & Ensure is Absent'
                    Params = @{
                        Ensure = 'Absent'
                    }
                    SetupExeReturn = $2016Version
                }
                @{
                    Case = 'True when 2016 Product ID is not found & Ensure is Absent'
                    Params = @{
                        Ensure = 'Absent'
                    }
                    SetupExeReturn = $2016Version
                }
                @{
                    Case = 'True when 2012 R2 Product ID is found & Ensure is Present'
                    Params = @{
                        Ensure = 'Present'
                    }
                    SetupExeReturn = $2012Version
                }
                @{
                    Case = 'True when unknown Product ID is found'
                    Params = @{
                        Ensure = 'Present'
                    }
                    SetupExeReturn = $unknownVersion
                }
            )

            It 'Returns <case>' -TestCases $testCases {
                param ( $Case, $Params, $SetupExeReturn, $TestDefaultInstance )

                $testParams = $defaultDesiredState.Params.Clone()
                
                if ($TestDefaultInstance)
                {
                    $testParams.SqlInstance = 'MSSQLServer' #Test for using the default SQL Instance name, which returns $null for default instance name
                }

                function Get-SmaRunbookWorkerDeployment {}

                Mock -CommandName Get-Item -MockWith { $SetupExeReturn } -ParameterFilter { $Path -eq $pathToSetupExe }
                Mock -CommandName Get-WmiObject -MockWith { 
                    if ($Params.Ensure -eq 'Present')
                    {
                        return $true
                    }
                    else
                    {
                        return $false
                    }
                } -ParameterFilter { $Class -eq 'win32_product' -and $Filter -eq "IdentifyingNumber='$($2016Version.ID)'" }
                Mock -CommandName Get-ItemProperty -MockWith { @{ DatabaseServerName = $testParams.SqlServer } } -ParameterFilter { $Name -eq 'DatabaseServerName' }
                Mock -CommandName Get-ItemProperty -MockWith {
                    if ($testParams.SqlInstance -eq 'MSSQLServer') # tests for default instance name, which returns $Null in the key for default instance name
                    {
                        $null
                    }
                    else
                    {
                        @{ DatabaseServerInstance = $testParams.SqlInstance } 
                    }
                } -ParameterFilter { $Name -eq 'DatabaseServerInstance' }
                Mock -CommandName Get-ItemProperty -MockWith { @{ DatabaseName = $testParams.SqlDatabase } } -ParameterFilter { $Name -eq 'DatabaseName' }
                Mock -CommandName Get-ItemProperty -MockWith { @{ InstallationFolder = $testParams.InstallFolder } } -ParameterFilter { $Name -eq 'InstallationFolder' }
                Mock -CommandName Get-ItemProperty -MockWith { @{ IisSiteName = $testParams.SiteName } } -ParameterFilter { $Name -eq 'IisSiteName' }
                Mock -CommandName Get-ItemProperty -MockWith { @{ IisAppPoolAccount = $testParams.ApPool.UserName } } -ParameterFilter { $Name -eq 'IisAppPoolAccount' }
                Mock -CommandName Get-ItemProperty -MockWith { @{ IisAuthorizationAdminGroupMembers = $testParams.AdminGroupMembers.UserName } } -ParameterFilter { $Name -eq 'IisAuthorizationAdminGroupMembers' }
                
                Mock -CommandName Import-Module -ParameterFilter { $Name -eq 'Microsoft.SystemCenter.ServiceManagementAutomation' }
                Mock -CommandName Get-SmaRunbookWorkerDeployment -MockWith { @{ ComputerName = $defaultDesiredState.Params.SqlServer } }
                
                $testParams.Ensure = $Params.Ensure
                
                #Create the exe file
                $pathToSetupExe = (Join-Path -Path (Join-Path -Path $testParams.SourcePath -ChildPath $testParams.SourceFolder) -ChildPath "\SMA\WebServiceSetup.exe")
                New-Item -Path $pathToSetupExe -ItemType File -Value 'foo' -Force
                
                # $unknownVersion won't return a product ID
                if ($SetupExeReturn.ID)
                {
                    $result = Get-TargetResource @testParams

                    # Test-TargetResource simply compares the passed in Ensure 
                    # against the return from Get, so we also test that here
                    $testResult = Test-TargetResource @testParams
                    
                    if ($testParams.Ensure -eq 'Absent')
                    {
                        # Remove properties for Ensure = 'Absent'
                        $testParams.Remove('ApPool')
                        $testParams.Remove('ServiceUsername')
                        $testParams.Remove('SqlServer')
                        $testParams.Remove('SqlInstance')
                        $testParams.Remove('SqlDatabase')
                        $testParams.Remove('InstallFolder')
                        $testParams.Remove('SendTelemetryReports')
                        $testParams.Remove('RunbookWorkerServers')

                        $testResult | Should -Be ('Absent' -eq $Params.Ensure)
                    }
                    else
                    {
                        $testResult | Should -Be ('Present' -eq $Params.Ensure)
                    }

                    foreach ($property in $result.GetEnumerator())
                    {
                        if ($testParams[$property.Name] -is [pscredential])
                        {
                            $property.Value | Should -Be $testParams[$property.Name].UserName
                        }
                        else
                        {
                            $property.Value | Should -Be $testParams[$property.Name]
                        }
                    }
                }
                else
                {
                    { Get-TargetResource @testParams } | Should -Throw 'Unknown version of Service Management Automation!'
                }
            }
        }

        Describe "$($script:dscResourceName)\Set-TargetResource" {
            It 'ToDo' {
                
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $testEnvironment
}

