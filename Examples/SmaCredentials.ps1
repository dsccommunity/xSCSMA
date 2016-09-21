param(
    [parameter(mandatory = $true)]
    [PSCredential]
    $cred 
)

Configuration SmaCredential 
{ 
    Import-DscResource -ModuleName 'xSCSMA' 

    Node "localhost" 
    { 
        xSmaCredential Example 
        { 
            Name = $cred.UserName
            credential = $cred 
            WebServiceEndpoint = 'https:\\localhost'
        }
    } 
} 

$ConfigData = @{ 
    AllNodes = @(  
        @{ 
            NodeName = "localhost"
            PSDscAllowPlainTextPassword = $true
        }
    ) 
} 

SmaCredential -ConfigurationData $ConfigData -OutputPath .\SMA 

Start-DscConfiguration -Path .\SMA -Wait -Force -Verbose 
