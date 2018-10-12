<#
    This example will ensure the PSGallery repository is present and trusted.
#>

Configuration Example
{
    Import-DscResource -ModuleName PSModulesDsc

    Node localhost
    {
        PowershellRepository PSGallery
        {
            Name                = "PSGallery"
            InstallationPolicy  = "Trusted"
            Ensure              = "Present"
        }
    }
}
