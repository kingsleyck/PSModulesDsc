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
        This configuration will ensure that the PSGallery is set to trusted.
#>
Configuration PowershellRepository_SetRepository_Config
{
    Import-DscResource -ModuleName 'PSModulesDsc'

    node $AllNodes.NodeName
    {
        PowershellRepository SetRepository
        {
            Name                = "PSGallery"
            InstallationPolicy  = "Trusted"
            SourceLocation      = "https://www.powershellgallery.com/api/v2"
            Ensure              = "Present"
        }
    }
}

<#
    .SYNOPSIS
        This configuration will ensure that a test respository is added.
#>
Configuration PowershellRepository_AddRepository_Config
{
    Import-DscResource -ModuleName 'PSModulesDsc'

    node $AllNodes.NodeName
    {
        PowershellRepository AddRepository
        {
            Name            = "myNuGetSource"
            SourceLocation  = "https://www.myget.org/F/powershellgetdemo/api/v2"
            Ensure          = "Present"
        }
    }
}


<#
    .SYNOPSIS
        This configuration will ensure that a test respository is removed.
#>
Configuration PowershellRepository_RemoveRepository_Config
{
    Import-DscResource -ModuleName 'PSModulesDsc'

    node $AllNodes.NodeName
    {
        PowershellRepository RemoveRepository
        {
            Name            = "myNuGetSource"
            Ensure          = "Absent"
        }
    }
}

