<#
.SYNOPSIS
    Publish script, to publish a NuGet PowerShell module to GitHub Packages.
.DESCRIPTION
    Publish script, to publish a NuGet PowerShell module to GitHub Packages.
    It is assumed that the module structure resembles this (for the module Prefix.ModuleName):
    
    Prefix.ModuleName
    ├───Prefix.ModuleName
    │   │   Prefix.ModuleName.psd1
    │   │   Prefix.ModuleName.psm1
    │   │
    │   ├───Private
    │   │       Get-PrivateFunction.ps1
    │   │
    │   └───Public
    │           Get-PublicFunction.ps1
    │
    ├───_Build
    │       Prefix.ModuleName.Build.ps1
    |       Prefix.ModuleName.Release.ps1
    │
    └───_Test
            Prefix.ModuleName.Test.ps1
            
    General rules are:
    1. One function, one file
    2. Function and file names follows the verb-noun conventions
    3. Functions to be exported goes into the Public folder
    4. Functions not to be exported goes into the Private folder
#>
# Retrieve the environment variables needed
$ModuleName = $env:MODULENAME
$ModuleVersion = $env:VERSION
$RootPath = $env:GITHUB_WORKSPACE
$APIKey = $env:GITHUB_TOKEN
$RepositorySource = "$env:GITHUB_SERVER_URL/$env:GITHUB_REPOSITORY"

# Build the required paths and filenames
$ModulePath = Join-Path -Path $RootPath -ChildPath "$ModuleName\$ModuleName"
$ReleasePath = Join-Path -Path $RootPath -ChildPath "Release"


# Publish module locally first
$null = New-Item -Path $ReleasePath -ItemType Directory -Force
Register-PSRepository -Name "LocalBuild" -SourceLocation $ModulePath -PublishLocation $ReleasePath -InstallationPolicy Trusted
Publish-Module -Path $ModulePath -Repository "LocalBuild"

dotnet tool install --global gpr --version 0.1.281
gpr push -k $APIKey "$ReleasePath/$ModuleName.$ModuleVersion.nupkg" -r $RepositorySource