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
            Ensure = "Present"
            Result = $true
            Present = $true
            SetupExeReturn = $2016Version
        }

        Describe "$($script:dscResourceName)\Get&Test-TargetResource" -Tag 'Get', 'Test' {

            $testCases = @(
                $defaultDesiredState
                @{
                    Case = 'False when 2016 Product ID is not found & Ensure is Present'
                    Ensure = 'Present'
                    Result = $false
                    Present = $false
                    SetupExeReturn = $2016Version
                }
                @{
                    Case = 'False when 2016 Product ID is found & Ensure is Absent'
                    Ensure = 'Absent'
                    SqlInstance = 'MSSQLSERVER'
                    Result = $false
                    Present = $true
                    SetupExeReturn = $2016Version
                }
                @{
                    Case = 'True when 2016 Product ID is not found & Ensure is Absent'
                    Ensure = 'Absent'
                    Result = $true
                    Present = $false
                    SetupExeReturn = $2016Version
                }
                @{
                    Case = 'True when 2012 R2 Product ID is found & Ensure is Present'
                    Ensure = 'Present'
                    Result = $true
                    Present = $true
                    SetupExeReturn = $2012Version
                }
                @{
                    Case = 'Throw when unknown Product ID is found'
                    Ensure = 'Present'
                    Result = $false
                    Present = $false
                    SetupExeReturn = $unknownVersion
                }
            )

            BeforeEach {

                <#
                    Clone the default params, because we're only testing
                    against $SQLInstance and $Ensure in the Get/Test functions
                #>
                $testParams = $defaultDesiredState.Params.Clone()

                # Populate SourcePath here for scoping reasons
                $testParams.SourcePath = "$TestDrive\SCSMA"

                function Get-SmaRunbookWorkerDeployment {
                    param ($WebServiceEndpoint)
                }
            }

            It '<Result> when resource is <Present> and Ensure is <Ensure>' -TestCases $testCases {
                param ( $Case, $Ensure, $Present, $Result, $SetupExeReturn, $SqlInstance )

                # Populate the default paramset with the passed in Ensure key
                $testParams.Ensure = $Ensure

                # Case for installing the default instance name
                if ($SqlInstance)
                {
                    $testParams.SqlInstance = 'MSSQLSERVER'
                }

                #region Mocks
                # Get does a path check for the exe, but we never use it, so mock that it's there
                Mock -CommandName Get-Item -MockWith { $SetupExeReturn } -ParameterFilter { $Path -eq $pathToSetupExe }

                # Setup tests for present and absent resource state
                if ($present -eq $true)
                {
                    Mock -CommandName Get-ItemProperty -MockWith { return $Present }
                }
                if ($present -eq $false)
                {
                    Mock -CommandName Get-ItemProperty -MockWith { }
                }

                # Return the SQL Server hostname from the reg key
                Mock -CommandName Get-ItemProperty -MockWith { @{ DatabaseServerName = $testParams.SqlServer } } `
                    -ParameterFilter { $Name -eq 'DatabaseServerName' }

                # Tests for default instance name, which returns $Null in the reg key instead of the default instance name
                Mock -CommandName Get-ItemProperty -MockWith {
                    if ($testParams.SqlInstance -eq 'MSSQLServer')
                    {
                       $null
                    }
                    else
                    {
                        @{ DatabaseServerInstance = $testParams.SqlInstance }
                    }
                } -ParameterFilter { $Name -eq 'DatabaseServerInstance' }

                Mock -CommandName Get-ItemProperty -MockWith { @{ DatabaseName = $testParams.SqlDatabase } } `
                    -ParameterFilter { $Name -eq 'DatabaseName' }

                Mock -CommandName Get-ItemProperty -MockWith { @{ InstallationFolder = $testParams.InstallFolder } } -ParameterFilter { $Name -eq 'InstallationFolder' }
                Mock -CommandName Get-ItemProperty -MockWith { @{ IisSiteName = $testParams.SiteName } } -ParameterFilter { $Name -eq 'IisSiteName' }
                Mock -CommandName Get-ItemProperty -MockWith { @{ IisAppPoolAccount = $testParams.ApPool.UserName } } -ParameterFilter { $Name -eq 'IisAppPoolAccount' }
                Mock -CommandName Get-ItemProperty -MockWith { @{ IisAuthorizationAdminGroupMembers = $testParams.AdminGroupMembers.UserName } } -ParameterFilter { $Name -eq 'IisAuthorizationAdminGroupMembers' }

                Mock -CommandName Import-Module -ParameterFilter { $Name -eq 'Microsoft.SystemCenter.ServiceManagementAutomation' }

                if ($testParams.SqlInstance -eq 'MSSQLServer')
                {
                    Mock -CommandName Get-SmaRunbookWorkerDeployment -ParameterFilter {$WebServiceEndpoint -eq "https://localhost"} -MockWith { New-Object -TypeName PSCustomObject -Property @{ComputerName = $defaultDesiredState.Params.SqlServer} }
                    Mock -CommandName Get-SmaRunbookWorkerDeployment -ParameterFilter {$WebServiceEndpoint.ToString() -ne "https://localhost"} -MockWith { throw 'test' }
                }
                else
                {
                    Mock -CommandName Get-SmaRunbookWorkerDeployment -MockWith { New-Object -TypeName PSCustomObject -Property @{ComputerName = $defaultDesiredState.Params.SqlServer} }
                }

                # Create the exe file
                $pathToSetupExe = (Join-Path -Path (Join-Path -Path $testParams.SourcePath -ChildPath $testParams.SourceFolder) -ChildPath "\SMA\WebServiceSetup.exe")
                New-Item -Path $pathToSetupExe -ItemType File -Value 'foo' -Force

                # $unknownVersion won't return a product ID
                if ($SetupExeReturn.ID)
                {
                    $getResult = Get-TargetResource @testParams

                    <#
                        Test-TargetResource simply compares the passed in Ensure
                        against the return from Get, so we also test that here
                    #>
                    $testResult = Test-TargetResource @testParams

                    # Remove properties not returned by Get/Test
                    $testParams.Remove('FirstWebServiceServer')
                    $testParams.Remove('SetupCredential')

                    <#
                        Since Get alters the utility of the Ensure param to return
                        state, we have to adjust the expected value here
                    #>
                    $testParams.Ensure = $getResult.Ensure

                    if ($getResult.Ensure -eq 'Absent')
                    {
                        # Remove properties with no values for Ensure = 'Absent'
                        $testParams.Remove('AdminGroupMembers')
                        $testParams.Remove('ApPool')
                        $testParams.Remove('ServiceUsername')
                        $testParams.Remove('SiteName')
                        $testParams.Remove('SqlServer')
                        $testParams.Remove('SqlInstance')
                        $testParams.Remove('SqlDatabase')
                        $testParams.Remove('InstallFolder')
                        $testParams.Remove('SendTelemetryReports')
                        $testParams.Remove('RunbookWorkerServers')

                        $testResult | Should -Be $Result
                    }
                    else
                    {
                        $testResult | Should -Be $Result
                    }

                    foreach ($property in $testParams.GetEnumerator())
                    {
                        Write-Verbose "Evaluating $($Property.Name)"
                        if ($property.Value -is [pscredential])
                        {
                            $property.Value.UserName | Should -Be $getResult[$property.Name]
                        }
                        else
                        {
                            $property.Value | Should -Be $getResult[$property.Name]
                        }
                    }
                }
                else
                {
                    { Get-TargetResource @testParams } | Should -Throw 'Unknown version of Service Management Automation!'
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $testEnvironment
}

