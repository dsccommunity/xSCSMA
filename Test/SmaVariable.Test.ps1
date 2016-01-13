$Module = "$PSScriptRoot\..\DSCResources\xSmaVariable\xSmaVariable.psm1"

Remove-Module -Name xSmaVariable -Force -ErrorAction SilentlyContinue

Import-Module -Name $Module -Force -ErrorAction Stop
Import-Module -Name 'Pester'

InModuleScope 'xSmaVariable' {
     Describe 'SmaVariable' {
        Context 'Test-TargetResource' {
            It 'Returns true when set is true' {
                Mock -CommandName 'Get-TargetResource' -MockWith { @{ Set = $true} }

                Test-TargetResource -Name 'name' -Value 'value' -Description 'description' -WebServiceEndpoint 'endpoint' -port 0 | should be $true 
            }         

            It 'Returns false when set is false' {
                Mock -CommandName 'Get-TargetResource' -MockWith { @{ Set = $false} }

                Test-TargetResource -Name 'name' -Value 'value' -Description 'description' -WebServiceEndpoint 'endpoint' -port 0 | should be $false 
            }
        }

        Context 'Get-TargetResource' { 
            # Add functions to mock to InModuleScope scope
            function Get-SmaVariable {}

            It 'Returns set equal to true when name/value matches and no description' {
                Mock -CommandName Get-SmaVariable -MockWith { @{Name = 'name'; Value = 'value'; Description = ''} }
                
                $result = Get-TargetResource -Name 'name' -Value 'value' -WebServiceEndpoint 'endpoint' -port 0

                $result.set | should be $true
            }

            It 'Returns set equal to true when name matches and description matches' {
                Mock -CommandName Get-SmaVariable -MockWith { @{Name = 'name'; Value = 'value'; Description = 'description'} }
                
                $result = Get-TargetResource -Name 'name' -Value 'value' -Description 'description' -WebServiceEndpoint 'endpoint' -port 0

                $result.set | should be $true
            }

            It 'Returns set equal to false when SMA variable cannot be found' {
                Mock -CommandName Get-SmaVariable -MockWith { throw 'SMA Variable not found' }

                $result = Get-TargetResource -Name 'name' -Value 'value' -Description 'description' -WebServiceEndpoint 'endpoint' -port 0

                $result.set | should be $false
            }    

            It 'Returns set equal to false when name/value matches and description does not match' {
                Mock -CommandName Get-SmaVariable -MockWith { @{Name = 'name'; Value = 'value'; Description = ''} }
                
                $result = Get-TargetResource -Name 'name' -Value 'value' -Description 'description' -WebServiceEndpoint 'endpoint' -port 0

                $result.set | should be $false
            }

            It 'Returns set equal to false when name/description matches and value does not match' {
                Mock -CommandName Get-SmaVariable -MockWith { @{Name = 'name'; Value = 'value1'; Description = ''} }
                
                $result = Get-TargetResource -Name 'name' -Value 'value' -Description 'description' -WebServiceEndpoint 'endpoint' -port 0

                $result.set | should be $false
            }
        }
    }
}