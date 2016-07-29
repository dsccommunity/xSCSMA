function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $credential,

        [System.String]
        $Description,

        [parameter(Mandatory = $true)]
        [System.String]
        $WebServiceEndpoint,

        [System.UInt32]
        $Port
    )

    $Set = $true
    try
    {
        $null = $PSBoundParameters.Remove("credential")
        $null = $PSBoundParameters.Remove("Description")

        $SMACredential = Get-SmaCredential @PSBoundParameters -ErrorAction Stop

        # check variable value match
        if($SMACredential.UserName -ne $credential.UserName)
        {
            Write-Verbose "Credential $Name account $($SMACredential.UserName) expected $($credential.UserName)"
            $Set = $false
        }

        # check descption match
        if($SMACredential.Description -ne $Description )
        {
            # check description are not supposed to be empty
            if( !(($SMACredential.Description -eq $null) -and ($Description -eq ""))  )
            {
                Write-Verbose "variable $Name Description $($SMACredential.Description) expected $Description"
                $Set = $false
            }
        }
    }
    catch
    {
        Write-Verbose "Failed to find Credential $Name"
        $Set = $false
    }
    
    $returnValue = @{
        Name = [System.String]$Name
        credential = [System.Management.Automation.PSCredential]$credential
        Description = [System.String]$Description
        Set = [System.Boolean]$Set
        WebServiceEndpoint = [System.String]$WebServiceEndpoint
        Port = [System.UInt32]$Port
    }

    $returnValue
    
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $credential,

        [System.String]
        $Description,

        [parameter(Mandatory = $true)]
        [System.String]
        $WebServiceEndpoint,

        [System.UInt32]
        $Port
    )

    $PSBoundParameters.Add("value", $credential)
    $PSBoundParameters.Remove("credential")

    Set-SmaCredential @PSBoundParameters -ErrorAction Stop
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $credential,

        [System.String]
        $Description,

        [parameter(Mandatory = $true)]
        [System.String]
        $WebServiceEndpoint,

        [System.UInt32]
        $Port
    )

    return (Get-TargetResource @PSBoundParameters).Set -eq $true
}


Export-ModuleMember -Function Get-TargetResource, Set-TargetResource, Test-TargetResource
