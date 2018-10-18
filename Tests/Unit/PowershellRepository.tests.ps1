<#
    Due to limitations in Powershell 5, testing classes requires launching Pester in its own scope using:

    "powershell.exe -Command { Invoke-Pester -Script .\Tests\Unit\PowershellRepository.tests.ps1 }"

    or use version 6.1+ if one-off tests are necessary.
#>

#Requires -Version 5.0
#Requires -Modules Pester

# this decoration ensures that tests occur within a container. this solves the Pester-class scope issue.
[Microsoft.DscResourceKit.UnitTest(ContainerName = 'PowershellRepository', ContainerImage = 'microsoft/windowsservercore')]

#region HEADER
$script:DSCModuleName = 'PSModulesDsc'
$script:DSCResourceName = 'PowershellRepository'

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
        Describe "PowershellRepository" -Tag Unit {

            $RepositoryExists = [pscustomobject]@{
                Name = "PSGalleryUnderTest";
                InstallationPolicy = "Trusted"
                SourceLocation = "https://www.powershellgallery.com/api/v2"
            }

            BeforeEach {
                $PowershellRepository = [PowershellRepository]::new()
                $PowershellRepository.Name = $RepositoryExists.Name
            }

            Context 'When the GetPSBoundParameters method is called' {

                It 'Should not throw' {
                    { $PowershellRepository.GetPSBoundParameters() } | Should not throw
                }

                It 'Should be a hashtable' {
                    $PowershellRepository.GetPSBoundParameters() | Should -BeOfType hashtable
                }

                It 'Should return the expected properties' {
                    $PowershellRepository.InstallationPolicy = $RepositoryExists.InstallationPolicy
                    $PowershellRepository.SourceLocation = $RepositoryExists.SourceLocation

                    $PSBoundParameters = $PowershellRepository.GetPSBoundParameters()
                    $PSBoundParameters.Name | Should -Be $RepositoryExists.Name
                    $PSBoundParameters.InstallationPolicy | Should -Be $RepositoryExists.InstallationPolicy
                    $PSBoundParameters.SourceLocation | Should -Be $RepositoryExists.SourceLocation
                }
            }

            Context 'When the Get method is called' {
                It 'Should not throw' {
                    { $PowershellRepository.Get() } | Should not throw
                }

                It 'Should return a type of PowershellRepository' {
                    $PowershellRepository.Get().GetType() | Should -Be "PowershellRepository"
                }

                It 'Should call Get-PSRepository one time' {
                    Mock Get-PSRepository {}

                    $PowershellRepository.Get() | Should -Be $true

                    Assert-MockCalled -CommandName Get-PSRepository -Scope It -Times 1
                }

                It 'Should return null if PSRepository does not exist' {
                    Mock Get-PSRepository {}

                    $PowershellRepository = $PowershellRepository.Get()
                    $PowershellRepository.Name | Should -BeNullOrEmpty
                    $PowershellRepository.RequiredVersion | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Get-PSRepository -Scope It -Times 1
                }

                It 'Should return name and version if PSRepository does exist' {
                    Mock Get-PSRepository { $RepositoryExists }

                    $PowershellRepository = $PowershellRepository.Get()
                    $PowershellRepository.Name | Should -be $RepositoryExists.Name
                    $PowershellRepository.RequiredVersion | Should -be $RepositoryExists.Version

                    Assert-MockCalled -CommandName Get-PSRepository -Scope It -Times 1
                }
            }

            Context 'When the Test method is called' {
                It 'Should not throw' {
                    $PowershellRepository.SourceLocation = "https://pester.me"
                    { $PowershellRepository.Test() } | Should not throw
                }

                It 'Should return a type of "boolean"' {
                    $PowershellRepository.SourceLocation = "https://pester.me"
                    $PowershellRepository.Test() | Should -BeOfType boolean
                }

                Context 'Ensure = Present' {
                    It 'Should return $false when PSRepository does not exist' {
                        $PowershellRepository.SourceLocation = "https://pester.me"
                        $PowershellRepository.Ensure = "Present"

                        Mock Get-PSRepository {}

                        $PowershellRepository.Test() | Should -Be $false

                        Assert-MockCalled -CommandName Get-PSRepository -Scope It -Times 1
                    }

                    It 'Should throw when PSRepository does not exist and SourceLocation unspecified' {
                        Mock Get-PSRepository {}

                        { $PowershellRepository.Test() } | Should throw

                        Assert-MockCalled -CommandName Get-PSRepository -Scope It -Times 1
                    }

                    It 'Should not throw when PSGallery does not exist and SourceLocation unspecified' {
                        $PowershellRepository.Name = "PSGallery"

                        Mock Get-PSRepository {}

                        { $PowershellRepository.Test() } | Should not throw

                        Assert-MockCalled -CommandName Get-PSRepository -Scope It -Times 1
                    }

                    It 'Should return $false when InstallationPolicy is incorrect' {
                        $PowershellRepository.Ensure = "Present"
                        $PowershellRepository.InstallationPolicy = "Untrusted"

                        Mock Get-PSRepository { $RepositoryExists }

                        $PowershellRepository.Test() | Should -Be $false

                        Assert-MockCalled -CommandName Get-PSRepository -Scope It -Times 1
                    }

                    It 'Should return $false when SourceLocation is incorrect' {
                        $PowershellRepository.Ensure = "Present"
                        $PowershellRepository.SourceLocation = "https://pester.me"

                        Mock Get-PSRepository { $RepositoryExists }

                        $PowershellRepository.Test() | Should -Be $false

                        Assert-MockCalled -CommandName Get-PSRepository -Scope It -Times 1
                    }

                    It 'Should return $true when PSRepository does exist' {
                        $PowershellRepository.InstallationPolicy = $RepositoryExists.InstallationPolicy
                        $PowershellRepository.SourceLocation = $RepositoryExists.SourceLocation
                        $PowershellRepository.Ensure = "Present"

                        Mock Get-PSRepository { $RepositoryExists }

                        $PowershellRepository.Test() | Should -Be $true

                        Assert-MockCalled -CommandName Get-PSRepository -Scope It -Times 1
                    }
                }

                Context 'Ensure = Absent' {
                    It 'Should return $false when PSRepository does exist' {
                        $PowershellRepository.Ensure = "Absent"

                        Mock Get-PSRepository { $RepositoryExists }

                        $PowershellRepository.Test() | Should -Be $false

                        Assert-MockCalled -CommandName Get-PSRepository -Scope It -Times 1
                    }

                    It 'Should return $true when PSRepository does not exist' {
                        $PowershellRepository.Ensure = "Absent"

                        Mock Get-PSRepository {}

                        $PowershellRepository.Test() | Should -Be $true

                        Assert-MockCalled -CommandName Get-PSRepository -Scope It -Times 1
                    }
                }
            }

            Context 'When the Set method is called' {

                It 'Should not throw' {
                    $PowershellRepository.SourceLocation = $RepositoryExists.SourceLocation
                    $PowershellRepository.Ensure = "Present"

                    Mock Get-PSRepository -Verifiable {}
                    Mock Register-PSRepository {}

                    { $PowershellRepository.Set() } | Should not throw

                    Assert-MockCalled -CommandName Get-PSRepository -Scope It -Times 1
                    Assert-MockCalled -CommandName Register-PSRepository -Scope It -Times 1
                }

                It 'Should call Install-PackageProvider if Ensure is Present and NuGet provider is missing' {
                    $PowershellRepository.SourceLocation = $RepositoryExists.SourceLocation
                    $PowershellRepository.Ensure = "Present"

                    Mock Get-PackageProvider {}
                    Mock Install-PackageProvider {}
                    Mock Get-PSRepository {}
                    Mock Register-PSRepository {}

                    $PowershellRepository.Set() | Should -Be $null

                    Assert-MockCalled -CommandName Get-PackageProvider -Scope It -Times 1
                    Assert-MockCalled -CommandName Install-PackageProvider -Scope It -Times 1
                    Assert-MockCalled -CommandName Get-PSRepository -Scope It -Times 1
                    Assert-MockCalled -CommandName Register-PSRepository -Scope It -Times 1
                }

                It 'Should call Register-PSRepository if Ensure is Present and repository is absent' {
                    $PowershellRepository.SourceLocation = $RepositoryExists.SourceLocation
                    $PowershellRepository.Ensure = "Present"

                    Mock Get-PSRepository {}
                    Mock Register-PSRepository {}

                    $PowershellRepository.Set() | Should -Be $null

                    Assert-MockCalled -CommandName Get-PSRepository -Scope It -Times 1
                    Assert-MockCalled -CommandName Register-PSRepository -Scope It -Times 1
                }

                It 'Should call Set-PSRepository if InstallationPolicy is incorrect' {
                    $PowershellRepository.Ensure = "Present"
                    $PowershellRepository.SourceLocation = $RepositoryExists.SourceLocation
                    $PowershellRepository.InstallationPolicy = "Untrusted"

                    Mock Get-PSRepository { $RepositoryExists }
                    Mock Set-PSRepository {}

                    $PowershellRepository.Set() | Should -Be $null

                    Assert-MockCalled -CommandName Get-PSRepository -Scope It -Times 1
                    Assert-MockCalled -CommandName Set-PSRepository -Scope It -Times 1
                }

                It 'Should call Unregister then Set-PSRepository if SourceLocation is incorrect' {
                    $PowershellRepository.Ensure = "Present"
                    $PowershellRepository.SourceLocation = "https://pester.me"
                    $PowershellRepository.InstallationPolicy = "Untrusted"

                    Mock Get-PSRepository { $RepositoryExists }
                    Mock Unregister-PSRepository {}
                    Mock Register-PSRepository {}

                    $PowershellRepository.Set() | Should -Be $null

                    Assert-MockCalled -CommandName Get-PSRepository -Scope It -Times 1
                    Assert-MockCalled -CommandName Unregister-PSRepository -Scope It -Times 1
                    Assert-MockCalled -CommandName Register-PSRepository -Scope It -Times 1
                }

                It 'Should call Unregister-PSRepository if Ensure is Absent' {
                    $PowershellRepository.SourceLocation = $RepositoryExists.SourceLocation
                    $PowershellRepository.Ensure = "Absent"

                    Mock Get-PSRepository { $RepositoryExists }
                    Mock Unregister-PSRepository {}

                    $PowershellRepository.Set() | Should -Be $null

                    Assert-MockCalled -CommandName Get-PSRepository -Scope It -Times 1
                    Assert-MockCalled -CommandName Unregister-PSRepository -Scope It -Times 1
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
