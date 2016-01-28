Configuration RunbookDirectory 
{ 
    Param 
    ( 
        $NodeName 
    ) 


    Import-DscResource -ModuleName 'xSCSMA' 

    Node $NodeName 
    { 
        SmaVariable Example 
        { 
            Name = "Variable"
            Value = 'Value' 
            WebServiceEndpoint = 'https:\\localhost' 
        } 
    } 
} 


RunbookDirectory -NodeName "localhost" -OutputPath .\SMA 

Start-DscConfiguration -Path .\SMA -Wait -Force -Verbose 
