<#
.SYNOPSIS
    Build script, that builds a PowerShell module.
.DESCRIPTION
    Build script, that builds a PowerShell module.
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

# Build the required paths and filenames
$ModulePath = Join-Path -Path $RootPath -ChildPath "$ModuleName\$ModuleName"
$ManifestFile = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"
$PublicFolder = Join-Path -Path $ModulePath -ChildPath "Public"

# Update the Manifest header data
$ManifestContent = Get-Content -Path $ManifestFile -Raw
$ManifestContent = $ManifestContent -replace '<ModuleVersion>', $ModuleVersion

# Update the list of public funtions to export
if ((Test-Path -Path $PublicFolder) -and ($PublicFunctions = $(Get-ChildItem $PublicFolder |Select-Object -ExpandProperty BaseName))) {
    $FunctionList = ""
    $Count = 1
    foreach ($PublicFunction in $PublicFunctions) {
        if ($Count -eq $PublicFunctions.Count) {
            $FunctionList += "`r`n`t""$PublicFunction"""
        }
        else {
            $FunctionList += "`r`n`t""$PublicFunction"","
        }
        $Count++
    }
}
else {
    $FunctionList = $null
}
$ManifestContent = $ManifestContent -replace "'<FunctionsToExport>'", $FunctionList

# Save the updated Manifest
$ManifestContent | Set-Content -Path $ManifestFile
