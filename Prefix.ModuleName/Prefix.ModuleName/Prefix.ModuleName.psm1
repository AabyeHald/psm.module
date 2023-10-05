<#
.SYNOPSIS
    Dot source the private and public functions included in the module.
.DESCRIPTION
    Dot source the private and public functions included in the module.
    It is assumed that the module structure resembles this (for the module Prefix.ModuleName):
    
    Prefix.ModuleName
    ├───Prefix.ModuleName
    │   │   Prefix.ModuleName.psd1
    │   │   Prefix.ModuleName.psm1
    │   │
    │   ├───Private
    │   │       Get-PrivateFunctions.ps1
    │   │
    │   └───Public
    │           Get-PublicFunctions.ps1
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
$PSDefaultParameterValues.Clear()

# Build the private and public function paths
$PrivatePath = Join-Path -Path $PSScriptRoot -ChildPath "Private"
$PublicPath = Join-Path -Path $PSScriptRoot -ChildPath "Public"

# Dot source the private functions
$PrivateFunctions = Get-ChildItem $PrivatePath -ErrorAction SilentlyContinue
foreach ($Function in $PrivateFunctions) {
    . $Function.FullName
}

# Dot source the public functions
$PublicFunctions = Get-ChildItem $PublicPath -ErrorAction SilentlyContinue
foreach ($Function in $PublicFunctions) {
    . $Function.FullName
}