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
            RunbookPath = 'C:\Program Files\Microsoft System Center 2012 R2\Orchestrator\Web Service\SampleRunbooks\*'
            WebServiceEndpoint = 'https:\\localhost'
            Ensure = 'Absent'
        }
    }
}

RunbookDirectory -NodeName "localhost" -OutputPath .\SMA

Start-DscConfiguration -Path .\SMA -Wait -Force -Verbose
