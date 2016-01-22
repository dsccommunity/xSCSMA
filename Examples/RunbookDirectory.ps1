Configuration RunbookDirectory
{
    Param
    (
        $NodeName
    )

    Import-DscResource -ModuleName 'xSCSMA'

    Node $NodeName
    {
        RunbookDirectory Example
        {
            RunbookPath = 'C:\Source\Runbooks\Start-*'
            WebServiceEndpoint = 'https:\\localhost'
        }
    }
}

RunbookDirectory -NodeName "localhost" -OutputPath .\SMA

Start-DscConfiguration -Path .\SMA -Wait -Force -Verbose
