<#
    This example will install the PSScriptAnalyzer module and ensure only version 1.17.1 is present.
#>

Configuration Example
{
    Import-DscResource -ModuleName PSModulesDsc

    Node localhost
    {
        PowershellModule PSScriptAnalyzer
        {
            Name            = "PSScriptAnalyzer"
            RequiredVersion = "1.17.1"
            Ensure          = "Present"
        }
    }
}
