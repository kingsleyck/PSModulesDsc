#region HEADER
# Integration Test Config Template Version: 1.2.0
#endregion

$configFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, 'json')
if (Test-Path -Path $configFile)
{
    $ConfigurationData = Get-Content -Path $configFile | ConvertFrom-Json
}
else
{
    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName        = 'localhost'
                CertificateFile = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        This configuration will ensure that the xActiveDirectory module version 2.21.0.0 is installed.
#>
Configuration PowershellModule_InstallModule_Config
{
    Import-DscResource -ModuleName 'PSModulesDsc'

    node $AllNodes.NodeName
    {
        PowershellModule InstallModule
        {
            Name            = "xActiveDirectory"
            RequiredVersion = "2.21.0.0"
            Ensure          = "Present"
        }
    }
}

<#
    .SYNOPSIS
        This configuration will ensure that the xActiveDirectory module is not installed.
#>
Configuration PowershellModule_RemoveModule_Config
{
    Import-DscResource -ModuleName 'PSModulesDsc'

    node $AllNodes.NodeName
    {
        PowershellModule RemoveModule
        {
            Name            = "xActiveDirectory"
            RequiredVersion = "2.21.0.0"
            Ensure          = "Absent"
        }
    }
}
