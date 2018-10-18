<#
    Due to limitations in Powershell 5, testing classes requires launching Pester using:

    "powershell.exe -Command { Invoke-Pester -Script .\Tests\Unit\PowershellModule.tests.ps1 }"

    or use version 6.1+ if one-off tests are necessary.
#>

#Requires -Version 5.0
#Requires -Modules Pester

# this decoration ensures that tests occur within a container. this solves the Pester-class scope issue.
[Microsoft.DscResourceKit.UnitTest(ContainerName = 'PowershellModule', ContainerImage = 'microsoft/windowsservercore')]

#region HEADER
$script:DSCModuleName = 'PSModulesDsc'
$script:DSCResourceName = 'PowershellModule'

# Unit Test Template Version: 1.2.4

$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -ResourceType 'Class' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# begin test
try
{
    Invoke-TestSetup

    InModuleScope $Script:DscResourceName {
        Describe "PowershellModule" -Tag Unit {

            $ModuleExists = New-MockObject -Type psmoduleinfo
            $ModuleExists | Add-Member -Name Name -Value ModuleExists -MemberType NoteProperty -Force
            $ModuleExists | Add-Member -Name RepositorySourceLocation -Value "https://module.exists" -MemberType NoteProperty -Force
            $ModuleExists | Add-Member -Name Version -Value ([system.version]::New(1, 0, 0, 0)) -MemberType NoteProperty -Force

            BeforeEach {
                $PowershellModule = [PowershellModule]::new()
                $PowershellModule.Name = $ModuleExists.Name
                $PowershellModule.RequiredVersion = $ModuleExists.Version
            }

            Context 'When the GetPSBoundParameters method is called' {

                It 'Should not throw' {
                    { $PowershellModule.GetPSBoundParameters() } | Should not throw
                }

                It 'Should be a hashtable' {
                    $PowershellModule.GetPSBoundParameters() | Should -BeOfType hashtable
                }

                It 'Should return the expected properties' {
                    $PSBoundParameters = $PowershellModule.GetPSBoundParameters()
                    $PSBoundParameters.Name | Should -Be $ModuleExists.Name
                    $PSBoundParameters.RequiredVersion | Should -Be $ModuleExists.Version
                    $PSBoundParameters.Repository | Should -Be "PSGallery"
                }
            }

            Context 'When the Get method is called' {
                It 'Should not throw' {
                    { $PowershellModule.Get() } | Should not throw
                }

                It 'Should return a type of PowershellModule' {
                    $PowershellModule.Get().GetType() | Should -Be "PowershellModule"
                }

                It 'Should call Get-Module one time' {
                    Mock Get-Module {}

                    $PowershellModule.Get() | Should -Be $true

                    Assert-MockCalled -CommandName Get-Module -Scope It -Times 1
                }

                It 'Should return null if module does not exist' {
                    Mock Get-Module {}

                    $PowershellModule = $PowershellModule.Get()
                    $PowershellModule.Name | Should -BeNullOrEmpty
                    $PowershellModule.RequiredVersion | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Get-Module -Scope It -Times 1
                }

                It 'Should return name and version if module does exist' {
                    Mock Get-Module { $ModuleExists }

                    $PowershellModule = $PowershellModule.Get()
                    $PowershellModule.Name | Should -be $ModuleExists.Name
                    $PowershellModule.RequiredVersion | Should -be $ModuleExists.Version

                    Assert-MockCalled -CommandName Get-Module -Scope It -Times 1
                }
            }

            Context 'When the Test method is called' {
                It 'Should not throw' {
                    { $PowershellModule.Test() } | Should not throw
                }

                It 'Should return a type of "boolean"' {
                    $PowershellModule.Test() | Should -BeOfType boolean
                }

                Context 'Ensure = Present' {
                    It 'Should return $false when module does not exist' {
                        $PowershellModule.Ensure = "Present"

                        Mock Get-Module {}

                        $PowershellModule.Test() | Should -Be $false

                        Assert-MockCalled -CommandName Get-Module -Scope It -Times 1
                    }

                    It 'Should return $false when module version is incorrect' {
                        $PowershellModule.Ensure = "Present"
                        $PowershellModule.RequiredVersion = [system.version]::New((1 + $ModuleExists.Version.Major), 0, 0, 0)

                        Mock Get-Module { $ModuleExists }

                        $PowershellModule.Test() | Should -Be $false

                        Assert-MockCalled -CommandName Get-Module -Scope It -Times 1
                    }

                    It 'Should return $false when module count is incorrect' {
                        $PowershellModule.Ensure = "Present"
                        $ModuleCountIncorrect = @()
                        $ModuleCountIncorrect += $ModuleExists
                        $ModuleCountIncorrect += $ModuleExists

                        Mock Get-Module { $ModuleCountIncorrect }

                        $PowershellModule.Test() | Should -Be $false

                        Assert-MockCalled -CommandName Get-Module -Scope It -Times 1
                    }

                    It 'Should return $true when module does exist' {
                        $PowershellModule.Ensure = "Present"

                        Mock Get-Module { $ModuleExists }

                        $PowershellModule.Test() | Should -Be $true

                        Assert-MockCalled -CommandName Get-Module -Scope It -Times 1
                    }
                }

                Context 'Ensure = Absent' {
                    It 'Should return $false when module does exist' {
                        $PowershellModule.Ensure = "Absent"

                        Mock Get-Module { $ModuleExists }

                        $PowershellModule.Test() | Should -Be $false

                        Assert-MockCalled -CommandName Get-Module -Scope It -Times 1
                    }

                    It 'Should return $true when module does not exist' {
                        $PowershellModule.Ensure = "Absent"

                        Mock Get-Module {}

                        $PowershellModule.Test() | Should -Be $true

                        Assert-MockCalled -CommandName Get-Module -Scope It -Times 1
                    }
                }
            }

            Context 'When the Set method is called' {

                # resolve issue with Pester intermittently failing to find Install-Module
                BeforeEach {
                    Import-Module PowerShellGet
                }

                It 'Should not throw' {
                    Mock Get-Module {}
                    Mock Install-Module {}

                    { $PowershellModule.Set() } | Should not throw

                    Assert-MockCalled -CommandName Get-Module -Scope It -Times 1
                    Assert-MockCalled -CommandName Install-Module -Scope It -Times 1
                }

                It 'Should call Install-Module if Ensure is Present' {
                    $PowershellModule.Ensure = "Present"

                    Mock Get-Module {}
                    Mock Install-Module {}

                    $PowershellModule.Set() | Should -Be $null

                    Assert-MockCalled -CommandName Get-Module -Scope It -Times 1
                    Assert-MockCalled -CommandName Install-Module -Scope It -Times 1
                }

                It 'Should call Install-PackageProvider if Ensure is Present and NuGet provider is missing' {
                    $PowershellModule.Ensure = "Present"

                    Mock Get-PackageProvider {}
                    Mock Install-PackageProvider {}
                    Mock Get-Module {}
                    Mock Install-Module {}

                    $PowershellModule.Set() | Should -Be $null

                    Assert-MockCalled -CommandName Get-PackageProvider -Scope It -Times 1
                    Assert-MockCalled -CommandName Install-PackageProvider -Scope It -Times 1
                    Assert-MockCalled -CommandName Get-Module -Scope It -Times 1
                    Assert-MockCalled -CommandName Install-Module -Scope It -Times 1
                }

                It 'Should call Uninstall-Module and Install-Module if Ensure is Present and Version -lt desired' {
                    $PowershellModule.Ensure = "Present"
                    $PowershellModule.RequiredVersion = [system.version]::New((1 + $ModuleExists.Version.Major), 0, 0, 0)

                    Mock Get-Module { $ModuleExists }
                    Mock Get-InstalledModule { $ModuleExists }
                    Mock Uninstall-Module {}
                    Mock Install-Module {}

                    $PowershellModule.Set() | Should -Be $null

                    Assert-MockCalled -CommandName Get-Module -Scope It -Times 1
                    Assert-MockCalled -CommandName Get-InstalledModule -Scope It -Times 1
                    Assert-MockCalled -CommandName Uninstall-Module -Scope It -Times 1
                    Assert-MockCalled -CommandName Install-Module -Scope It -Times 1
                }

                It 'Should call Uninstall-Module and Install-Module if Ensure is Present and Version -gt desired' {
                    $PowershellModule.Ensure = "Present"
                    $PowershellModule.RequiredVersion = [system.version]::New(($ModuleExists.Version.Major - 1), 0, 0, 0)

                    Mock Get-Module { $ModuleExists }
                    Mock Get-InstalledModule { $ModuleExists }
                    Mock Uninstall-Module {}
                    Mock Install-Module {}

                    $PowershellModule.Set() | Should -Be $null

                    Assert-MockCalled -CommandName Get-Module -Scope It -Times 1
                    Assert-MockCalled -CommandName Get-InstalledModule -Scope It -Times 1
                    Assert-MockCalled -CommandName Uninstall-Module -Scope It -Times 1
                    Assert-MockCalled -CommandName Install-Module -Scope It -Times 1
                }

                It 'Should call Uninstall-Module if Ensure is Absent' {
                    $PowershellModule.Ensure = "Absent"

                    Mock Get-Module { $ModuleExists }
                    Mock Uninstall-Module {}

                    $PowershellModule.Set() | Should -Be $null

                    Assert-MockCalled -CommandName Get-Module -Scope It -Times 1
                    Assert-MockCalled -CommandName Uninstall-Module -Scope It -Times 1
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
