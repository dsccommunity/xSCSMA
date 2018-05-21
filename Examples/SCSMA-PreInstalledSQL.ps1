#requires -Version 5
# Installs SMA 2016

$SecurePassword = ConvertTo-SecureString -String "********" -AsPlainText -Force
$InstallerServiceAccount = New-Object System.Management.Automation.PSCredential ("domain\!Installer", $SecurePassword)
$SecurePassword = ConvertTo-SecureString -String "Pass@word1" -AsPlainText -Force
$SMAWorkerServiceAccount = New-Object System.Management.Automation.PSCredential ("domain\!sma", $SecurePassword)
$SecurePassword = ConvertTo-SecureString -String "Pass@word1" -AsPlainText -Force
$SMAAppPoolAccount = New-Object System.Management.Automation.PSCredential ("domain\!sma", $SecurePassword)

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
            # Default path in module is \SystemCenter2012R2\Orchestrator
            SourcePath = "\\SQL01\Software"
            SourceFolder = "\SystemCenter2016\Orchestrator"
            InstallerServiceAccount = $InstallerServiceAccount
            ServiceAccount = $SMAWorkerServiceAccount
            ApPool = $SMAAppPoolAccount
            AdminGroupMembers = "domain\ladmin,domain\smaAdmin"
            SystemCenterProductKey = ""
            UseSSL = "Yes"
            # Certificate must be present in the Personal store on the machine
            SpecifyCertificate = "Yes"
            # Must be the subject name of the certificate in the computer store
            CertificateName = "SMA"
            SqlServer = "SQL01.domain.info"
            SqlInstance = "MSSQLSERVER"
            SqlDatabase = "SMA"
            WebServicePort = "443"

        }
        @{
            NodeName = "Node02.domain.info"
            Roles = @(
                "System Center 2016 Service Management Automation Web Service Server",
                "System Center 2016 Service Management Automation Runbook Worker Server"
            )
        }
    )
}

Configuration SMA
{
    #Import-DscResource -Module xSQLServer
    Import-DscResource -Module xSCSMA
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    # Set role and instance variables
    # This code creates variables for each role to install with the names of the nodes in the,
    # the var SystemCenter2016ServiceManagementAutomationWebServiceServers will have every server that has this role defined in it
    $Roles = $AllNodes.Roles | Sort-Object -Unique
    foreach($Role in $Roles)
    {
        $Servers = @($AllNodes.Where{$_.Roles | Where-Object {$_ -eq $Role}}.NodeName)
        Set-Variable -Name ($Role.Replace(" ","").Replace(".","") + "s") -Value $Servers
        if($Servers.Count -eq 1)
        {
            Set-Variable -Name ($Role.Replace(" ","").Replace(".","")) -Value $Servers[0]
            if(
                $Role.Contains("Database") -or
                $Role.Contains("Datawarehouse") -or
                $Role.Contains("Reporting") -or
                $Role.Contains("Analysis") -or
                $Role.Contains("Integration")
            )
            {
                $Instance = $AllNodes.Where{$_.NodeName -eq $Servers[0]}.SQLServers.Where{$_.Roles | Where-Object {$_ -eq $Role}}.InstanceName
                Set-Variable -Name ($Role.Replace(" ","").Replace(".","").Replace("Server","Instance")) -Value $Instance
            }
        }
    }

    Node $AllNodes.NodeName
    {

        # Install .NET Framework 3.5 on SQL nodes
        if(
            ($SystemCenter2016ServiceManagementAutomationDatabaseServer -eq $Node.NodeName) -or
            ($SQLServer2012ManagementTools | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            WindowsFeature "NET-Framework-Core"
            {
                Ensure = "Present"
                Name = "NET-Framework-Core"
                Source = $Node.SourcePath + "\WindowsServer2012R2\sources\sxs"
            }
        }

        # Install IIS on Web Service servers
        if(
            ($SystemCenter2016ServiceManagementAutomationWebServiceServers  | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            WindowsFeature "Web-WebServer"
            {
                Ensure = "Present"
                Name = "Web-WebServer"
            }

            WindowsFeature "Web-Basic-Auth"
            {
                Ensure = "Present"
                Name = "Web-Basic-Auth"
            }

            WindowsFeature "Web-Url-Auth"
            {
                Ensure = "Present"
                Name = "Web-Url-Auth"
            }

            WindowsFeature "Web-Windows-Auth"
            {
                Ensure = "Present"
                Name = "Web-Windows-Auth"
            }

            WindowsFeature "Web-Asp-Net45"
            {
                Ensure = "Present"
                Name = "Web-Asp-Net45"
            }

            WindowsFeature "NET-WCF-HTTP-Activation45"
            {
                Ensure = "Present"
                Name = "NET-WCF-HTTP-Activation45"
            }
            WindowsFeature IISCOnsole
            {
                Ensure = "Present"
                Name = "Web-Mgmt-Console"
                DependsOn = "[WindowsFeature]Web-WebServer"
            }
        }
        <#
        # Install SQL Instances
        if(
            ($SystemCenter2016ServiceManagementAutomationDatabaseServer -eq $Node.NodeName)
        )
        {
            foreach($SQLServer in $Node.SQLServers)
            {
                $SQLInstanceName = $SQLServer.InstanceName

                $Features = ""
                if(
                    (
                        ($SystemCenter2016ServiceManagementAutomationDatabaseServer -eq $Node.NodeName) -and
                        ($SystemCenter2016ServiceManagementAutomationDatabaseInstance -eq $SQLInstanceName)
                    )
                )
                {
                    $Features += "SQLENGINE"
                }
                $Features = $Features.Trim(",")

                if($Features -ne "")
                {
                    xSqlServerSetup ($Node.NodeName + $SQLInstanceName)
                    {
                        DependsOn = "[WindowsFeature]NET-Framework-Core"
                        SourcePath = $Node.SourcePath
                        SourceFolder = $Node.SQLSourceFolder
                        SetupCredential = $Node.InstallerServiceAccount
                        InstanceName = $SQLInstanceName
                        Features = $Features
                        SQLSysAdminAccounts = $Node.SQLSysAdminAccounts
                    }

                    xSqlServerFirewall ($Node.NodeName + $SQLInstanceName)
                    {
                        DependsOn = ("[xSqlServerSetup]" + $Node.NodeName + $SQLInstanceName)
                        SourcePath = $Node.SourcePath
                        InstanceName = $SQLInstanceName
                        Features = $Features
                    }
                }
            }
        }
        #>
        # Install SQL Management Tools
        if($SQLServer2012ManagementTools | Where-Object {$_ -eq $Node.NodeName})
        {
            xSqlServerSetup "SQLMT"
            {
                DependsOn = "[WindowsFeature]NET-Framework-Core"
                SourcePath = $Node.SourcePath
                SetupCredential = $Node.InstallerServiceAccount
                InstanceName = "NULL"
                Features = "SSMS,ADV_SSMS"
            }
        }

        # Install SMA PowerShell on all SMA roles
        if(
            ($SystemCenter2016ServiceManagementAutomationWebServiceServers  | Where-Object {$_ -eq $Node.NodeName}) -or
            ($SystemCenter2016ServiceManagementAutomationRunbookWorkerServers  | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            xSCSMAPowerShellSetup "SMAPS"
            {
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = $Node.SourceFolder
                SetupCredential = $Node.InstallerServiceAccount
            }
        }

        # Install first Web Service Server
        if ($SystemCenter2016ServiceManagementAutomationWebServiceServers[0] -eq $Node.NodeName)
        {
            # Create DependsOn for first Web Service Server
            $DependsOn = @()
            <#
            # Wait for Operations SQL Server
            if ($SystemCenter2016ServiceManagementAutomationWebServiceServers[0] -eq $SystemCenter2016ServiceManagementAutomationDatabaseServer)
            {
                $DependsOn += @(("[xSqlServerFirewall]" + $SystemCenter2016ServiceManagementAutomationDatabaseServer + $SystemCenter2016ServiceManagementAutomationDatabaseInstance))
            }
            else
            {
                WaitForAll "SMADB"
                {
                    NodeName = $SystemCenter2016ServiceManagementAutomationDatabaseServer
                    ResourceName = ("[xSqlServerFirewall]" + $SystemCenter2016ServiceManagementAutomationDatabaseServer + $SystemCenter2016ServiceManagementAutomationDatabaseInstance)
                    PsDscRunAsCredential = $Node.InstallerServiceAccount
                    RetryCount = 720
                    RetryIntervalSec = 5
                }
                $DependsOn += @("[WaitForAll]SMADB")
            }
            #>
            # Install first Web Service Server
            xSCSMAWebServiceServerSetup "SMAWS"
            {
                DependsOn = $DependsOn
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = $Node.SourceFolder
                SetupCredential = $Node.InstallerServiceAccount
                FirstWebServiceServer = $true
                ApPool = $Node.ApPool
                AdminGroupMembers = $Node.AdminGroupMembers
                SqlServer = "SQL01.domain.info"
                SqlInstance = "MSSQLSERVER"
                SqlDatabase = $Node.SqlDatabase
                RunbookWorkerServers = $SystemCenter2016ServiceManagementAutomationRunbookWorkerServers
                WebServicePort = $Node.WebServicePort
                SiteName = $Node.SiteName
                UseSSL = $Node.UseSSL
                SpecifyCertificate = $Node.SpecifyCertificate
                CertificateName = $Node.CertificateName
                ProductKey = $Node.SystemCenterProductKey
				LogMSIinstall = $false
            }
        }

        # Wait for first Web Service server on other Web Service servers and Runbook Worker server
        if(
            (
                ($SystemCenter2016ServiceManagementAutomationWebServiceServers | Where-Object {$_ -eq $Node.NodeName}) -or
                ($SystemCenter2016ServiceManagementAutomationRunbookWorkerServers | Where-Object {$_ -eq $Node.NodeName})
            ) -and
            (!($SystemCenter2016ServiceManagementAutomationWebServiceServers[0] -eq $Node.NodeName))
        )
        {
            WaitForAll "SMAWS"
            {
                NodeName = $SystemCenter2016ServiceManagementAutomationWebServiceServers[0]
                ResourceName = "[xSCSMAWebServiceServerSetup]SMAWS"
                RetryIntervalSec = 5
                RetryCount = 720
                PsDscRunAsCredential = $Node.InstallerServiceAccount
            }
        }

        # Install additional Web Service servers
        if(
            ($SystemCenter2016ServiceManagementAutomationWebServiceServers | Where-Object {$_ -eq $Node.NodeName}) -and
            (!($SystemCenter2016ServiceManagementAutomationWebServiceServers[0] -eq $Node.NodeName))
        )
        {
            xSCSMAWebServiceServerSetup "SMAWS"
            {
                DependsOn = "[WaitForAll]SMAWS"
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = $Node.SourceFolder
                SetupCredential = $Node.InstallerServiceAccount
                FirstWebServiceServer = $false
                ApPool = $Node.ApPool
                AdminGroupMembers = $Node.AdminGroupMembers
                SqlServer = $Node.SqlServer
                SqlInstance = $Node.SqlInstance
                SqlDatabase = $Node.SqlDatabase
                WebServicePort = $Node.WebServicePort
                SiteName = $Node.SiteName
                UseSSL = $Node.UseSSL
                SpecifyCertificate = $Node.SpecifyCertificate
                CertificateName = $Node.CertificateName
                ProductKey = $Node.SystemCenterProductKey
                LogMSIinstall = $true
            }
        }

        # Install Runbook Worker servers
        if($SystemCenter2016ServiceManagementAutomationRunbookWorkerServers | Where-Object {$_ -eq $Node.NodeName})
        {
            # If this is the first worker server, depend on that
            # otherwise wait for that
            if($SystemCenter2016ServiceManagementAutomationWebServiceServers[0] -eq $Node.NodeName)
            {
                $DependsOn = "[xSCSMAWebServiceServerSetup]SMAWS"
            }
            else
            {
                $DependsOn = "[WaitForAll]SMAWS"
            }

            xSCSMARunbookWorkerServerSetup "SMARW"
            {
                DependsOn = $DependsOn
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = $Node.SourceFolder
                SetupCredential = $Node.InstallerServiceAccount
                Service = $Node.ServiceAccount
                SqlServer = "SQL01.domain.info"
                SqlInstance = "MSSQLSERVER"
                SqlDatabase = $Node.SqlDatabase
                LogMSIinstall = $true
            }
        }
    }
}

foreach($Node in $ConfigurationData.AllNodes)
{
    if($Node.NodeName -ne "*")
    {
        Start-Process -FilePath "robocopy.exe" -ArgumentList ("`"C:\Program Files\WindowsPowerShell\Modules`" `"\\" + $Node.NodeName + "\c$\Program Files\WindowsPowerShell\Modules`" /e /purge /xf") -NoNewWindow -Wait
    }
}

Write-Host "Creating MOFs" -ForegroundColor Yellow
SMA -ConfigurationData $ConfigurationData
Write-Host "Running Config" -ForegroundColor Yellow
Start-DscConfiguration -Path .\SMA -Verbose -Wait -Force
