[![Build status](https://ci.appveyor.com/api/projects/status/xihqaoojlad4nb43/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xscsma/branch/master)

# xSCSMA

The **xSCSMA** module contains DSC resources for installation of System Center Service Management Automation (SMA). 

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).


## Resources

* **xSCSMAPowerShellSetup** installs SMA PowerShell 
* **xSCSMAWebServiceServerSetup** installs an SMA Web Service server
* **xSCSMARunbookWorkerServerSetup** installs an SMA Runbook Worker server
* **xRunbookDirectory** imports Runbook(s) to an SMA instance
* **xSmaVariable** Imports SMA variable to an SMA instance

### xSCSMAPowerShellSetup

* **Ensure**: (Key) Ensures that the SMA PowerShell components are **Present** or **Absent** on the machine. 
* **SourcePath**: (Required) UNC path to the root of the source files for installation.
* **SourceFolder**: Folder within the source path containing the source files for installation.
* **SetupCredential**: (Required) Credential to be used to perform the installation.

###xSCSMAWebServiceServerSetup
is used for installation of the SMA Web Service server, and has the following properties:

* **Ensure**: (Key) Ensures that the SCSCMA Web Service server components are **Present** or **Absent** on the machine. 
* **SourcePath**: (Required) UNC path to the root of the source files for installation.
* **SourceFolder**: Folder within the source path containing the source files for installation.
* **SetupCredential**: (Required) Credential to be used to perform the installation.
* **FirstWebServiceServer**: (Required) Binary value defining if this the first Management Server
* **ApPool**: (Required) Service account of the web service application pool.
* **ApPoolUsername**: Output user name of the web service application pool.
* **AdminGroupMembers**: A comma-separated list of users to add to the IIS Administrators group.
* **SqlServer**: (Required) Name of the SQL Server for the SMA database.
* **SqlInstance**: (Required) Name of the SQL Instance for the SMA database.
* **SqlDatabase**: Name of the SMA database.
* **SiteName**: Name of the SMA website.
* **WebServicePort**: Port of the SMA website.
* **InstallFolder**: Installation folder for SMA.
* **UseSSL**: Binary value defining whether or not to use SSL.
* **SpecifyCertificate**: Specify an existing certificate for the SMA web site.
* **CertificateName**: Name of the existing certificate to use.
* **ETWManifest**: Log to ETW.
* **SendCEIPReports**: { 0 | 1 } 
0: Do not opt in to the Customer Experience Improvement Program (CEIP). 
1: Opt in to CEIP.
* **MSUpdate**: { 0 | 1 } 
0: Do not opt in to Microsoft Update. 
1: Opt in to Microsoft Update.
* **ProductKey**: Product key for licensed installations.
* **RunbookWorkerServers**: Array of Runbook Worker servers in this deployment.

### xSCSMARunbookWorkerServerSetup

* **Ensure**: (Key) Ensures that the SMA Runbook Worker server is **Present** or **Absent** on the machine.
* **SourcePath**: (Required) UNC path to the root of the source files for installation.
* **SourceFolder**: Folder within the source path containing the source files for installation.
* **SetupCredential**: (Required) Credential to be used to perform the installation.
* **Service**: (Required) Service account of the web service application pool.
* **ServiceUserName**: Output user name of the Service account of the web service application pool.
* **SqlServer**: (Required) Name of the SQL Server for the SMA database.
* **SqlInstance**: (Required) Name of the SQL Instance for the SMA database.
* **SqlDatabase**: Name of the SMA database.
* **InstallFolder**: Installation folder for SMA.
* **ETWManifest**: Log to ETW.
* **SendCEIPReports**: { 0 | 1 } 
0: Do not opt in to the Customer Experience Improvement Program (CEIP). 
1: Opt in to CEIP.
* **MSUpdate**: { 0 | 1 } 
0: Do not opt in to Microsoft Update. 
1: Opt in to Microsoft Update.
* **ProductKey**: Product key for licensed installations.

### xRunbookDirectory
Imports runbook(s) into an SMA instance. The Workflow name is expected to match the name of the ps1, and will become the name of the Runbooks.

* **RunbookPath**: (Key) Path to Runbook(s) to be imported. Accepts wildcards.
* **Ensure**: (Required) The import state of runbooks found at RunbookPath. This can be Published, Draft, or Absent.
* **WebServiceEndpoint**: (Key) The web service endpoint of the SMA instance to import the Runbook too.
* **Port**: Port to reach the web service endpoint. Defaults to the SMA default of 9090.
* **Port** Port to reach the web service endpoint. Defaults to the SMA default of 9090.

### xSmaVariable

* **Ensure** (Required) Ensures that the SMA variable is **Present** or **Absent** at the web service endpoint.
* **Name** (Key) Name of variable.
* **Value** (Required) Value of variable.
* **Description** Description of variable.
* **WebServiceEndpoint** (Key) Web service endpoint of SMA instance.
* **Port** Port to reach the web service endpoint. Defaults to the SMA default of 9090.

## Versions

### Unreleased
* Converted appveyor.yml to install Pester from PSGallery instead of from Chocolatey.

* Added new example to show how to use xRunbookDirectory to remove all SMA sample Runbooks

### 1.3.0.0

* Added new resource to manage a single or directory of Runbooks, xRunbookDirectory.
* Added xSmaVariable resource.

### 1.2.1.0

* Increased timeout for setup process to start to 60 seconds.
* xSCSMAWebServiceServerSetup
    - Fixed bug when using named SQL instance
    - Added SMA service account to admin group.
* xSCSMARunbookWorkerSetup
    - Fixed bug when using named SQL instance.

### 1.1.0.0

* Initial release with the following resources:
    * xSCSMAPowerShellSetup
    * xSCSMAWebServiceServerSetup
    * xSCSMARunbookWorkerServerSetup

## Examples

Three example configurations are included in the Examples folder. All three examples also use the xSQLServer module.

### Single Server Installation

SCSMA-SingleServer.ps1 installs all SMA roles including prerequisites and SQL on a single server.

### Separate SQL

SCSMA-SeperateSQL.ps1 installs all SMA roles on one server and SQL on a separate server.

### Multiple Instances

SCSMA-MultiInstance.ps1 installs all SMA roles including multiple instances of both Web Service and Runbook Worker servers and SQL on a separate server.

### Remove Sample Runbooks

RemoveSampleRunbooks.ps1 removes SMA's default sample Runbooks.

###  Runbook Directory

RunbookDirectory.ps1 imports all Runbooks found in a directory that start with the name "Start-" and publishes them.

### SMA Variable

SmaVariable.ps1 adds a variable named "Variable" with value "Value" 

Notes:

The Single Server Installation, Separate SQL, and Multiple Instances examples use the exact same Configuration and just modify the behavior based on input ConfigurationData.

In the Examples folder you will see a version of each file with "-TP" appended to the name. 
These are the equivalent examples for deployment of System Center Technical Preview on Windows Server Technical Preview.

The samples require the use of the [Windows Management Framework (WMF) 5.0 Preview.](http://go.microsoft.com/fwlink/?LinkId=398175)

System Center 2012 R2 Service Management Automation Web Service and Runbook Worker installers have a hard check for PowerShell 4.0. 
If you are using these resources to install on a system that has WMF 5.0 preview installed, you must copy the transform (MST) files from the Web Service and Runbook Worker DSC resource folders to the SMA installation folder.
