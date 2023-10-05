<#
.SYNOPSIS
    Use PSScriptAnalyzer and Pester to test if the module are ready for publishing.
.DESCRIPTION
    Use PSScriptAnalyzer and Pester to test if the module are ready for publishing.
    It is assumed that the module structure resembles this (for the module Prefix.ModuleName):

    [RootPath]
    ├───Prefix.ModuleName
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

    The following values needs to be known:
    - $ModuleName (GitHub environment variable: $env:MODULENAME)
        - Formattet as [Prefix.ModuleName]
    - $RootPath = (GitHub environment variable: $env:GITHUB_WORKSPACE)
.EXAMPLE
    Local execution, including fixing.
    
    .\Prefix.ModuleName\_Test\Prefix.ModuleName.Test.ps1 -ModuleName Prefix.ModuleName -RootPath ".\" -Fix
#>
[CmdletBinding(DefaultParameterSetName='default')]
param (
    # What is the module name, when running locally
    [parameter(Mandatory=$true, ParameterSetName='local')]
    [string]$ModuleName,

    # What is the root path, when run locally
    [parameter(Mandatory=$true, ParameterSetName='local')]
    [string]$RootPath,

    # Should we fix errors, when run locally
    [parameter(Mandatory=$false, ParameterSetName='local')]
    [switch]$Fix
)
# Lists the RuleNames to exclude
$ExcludedRuleNames = @(
    "PSUseShouldProcessForStateChangingFunctions"
)

# Determine where we run
switch ($PSCmdlet.ParameterSetName) {
    'default' {
        # Retrieve the environment variables needed
        $ModuleName = $env:MODULENAME
        $RootPath = $env:GITHUB_WORKSPACE
    }
}

# Build the required paths and filenames
$ModulePath = Join-Path -Path $RootPath -ChildPath "$ModuleName\$ModuleName"
$ModuleFile = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psm1"
$PublicFolder = Join-Path -Path $ModulePath -ChildPath "Public"
$PrivateFolder = Join-Path -Path $ModulePath -ChildPath "Private"

# Prepare the test result
$Success = $true

# Do some testing only if we are not local
if ($PSCmdlet.ParameterSetName -ne "local") {
    # Import the module
    Write-Output "Importing Module: $ModuleName"
    Import-Module -Name $ModuleFile -Force -ErrorVariable ErrorMessage -ErrorAction SilentlyContinue
    if ($ErrorMessage) {
        Write-Output "Module import error: $ErrorMessage"
        $Success = $false
    }

    # Verify that all public functions are exported
    Write-Output "Counting Exported Commands"
    $Found = (Get-Module -Name $ModuleName).ExportedCommands.Keys.Count
    $Expected = @(Get-ChildItem -Path @($PublicFolder, $PrivateFolder)).Count
    if ($Found -ne $Expected) {
        Write-Output "Exported Commands Found: $Found"
        Write-Output "Exported Commands Expected: $Expected"
        $Success = $false
    }
}

# Now do the general testing
Write-Output "Running ScriptAnalyzer testing on Public functions"
$ScriptFiles = Get-ChildItem -Path $PublicFolder -File
foreach ($ScriptFile in $ScriptFiles) {
    Write-Output "Processing file $($ScriptFile.Name)"
    if ($Fix) {
        $Result = Invoke-ScriptAnalyzer -Path $ScriptFile.FullName -Fix
    }
    else {
        $Result = Invoke-ScriptAnalyzer -Path $ScriptFile.FullName | Where-Object {$_.RuleName -notin $ExcludedRuleNames}
    }
    if ($Result) {
        Write-Output $Result
        $Success = $false
    }
}

Write-Output "Running ScriptAnalyzer testing on Private functions"
$ScriptFiles = Get-ChildItem -Path $PrivateFolder -File
foreach ($ScriptFile in $ScriptFiles) {
    Write-Output "Processing file $($ScriptFile.Name)"
    if ($Fix) {
        $Result = Invoke-ScriptAnalyzer -Path $ScriptFile.FullName -Fix
    }
    else {
        $Result = Invoke-ScriptAnalyzer -Path $ScriptFile.FullName | Where-Object {$_.RuleName -notin $ExcludedRuleNames}
    }
    if ($Result) {
        Write-Output $Result
        $Success = $false
    }
}

if (-not $Success) {
    Write-Error "Testing not successfull" -ErrorAction Stop
}