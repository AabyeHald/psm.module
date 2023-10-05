<#
.SYNOPSIS
    Customize the PowerShell Module template, to fit the needed purpose.
.DESCRIPTION
    Customize the PowerShell Module template, to fit the needed purpose.
    The customizations include:
    1. Rename the folders, to match the module name and prefix.
    2. Rename the Build and Test files to match the module name and prefix.
    3. Rename the PSD and PSM files to match the module name and prefix.
    4. Update the content of the workflow files to match the module name and prefix.
    5. Update the PSD file content, with new GUID, Author, CompanyName, Copyright and Description.
    6. Clear the README file, leaving a header.
#>
param (
    # The prefix value, used for filenames and workflows
    [parameter(Mandatory=$true)]
    [string]$Prefix,

    # The module name value, used for filenames and workflows
    [parameter(Mandatory=$true)]
    [string]$ModuleName,

    # The author value, used in the PSD file and as part of the copyright
    [parameter(Mandatory=$true)]
    [string]$Author,

    # The company name value, used in the PSD file and as part of the copyright
    [parameter(Mandatory=$true)]
    [string]$CompanyName,

    # A short onliner description of the module
    [parameter(Mandatory=$true)]
    [string]$Description,

    # GitHub handle, used to build repo URL for badges
    [parameter(Mandatory=$true)]
    [string]$GitHubHandle,

    # GitHub repository name, used to build repo URL for badges (psm.Prefix.ModuleName)
    [parameter(Mandatory=$true)]
    [string]$RepositoryName
)

# Find the root of the module folder structure
Write-Verbose -Message "$((Get-Date -Format o -AsUTC).Replace(":", ".")) - Find the root of the module folder structure"
$ModuleRootFolder = $(Get-Item $PSScriptRoot).Parent
Write-Verbose -Message "$((Get-Date -Format o -AsUTC).Replace(":", ".")) - Root folder: $($ModuleRootFolder)"
$NewName = $Prefix + "." + $ModuleName


# Rename folders, according to prefix and module name
Write-Verbose -Message "$((Get-Date -Format o -AsUTC).Replace(":", ".")) - Renaming folders, according to prefix and module name"
$ModuleFolders = Get-ChildItem -Path $ModuleRootFolder.FullName -Recurse -Filter "Prefix.ModuleName*" -Directory | Sort-Object -Descending -Property FullName
Write-Verbose -Message "$((Get-Date -Format o -AsUTC).Replace(":", ".")) - Folders found: $($ModuleFolders.Count)"

foreach ($ModuleFolder in $ModuleFolders) {
    Write-Verbose -Message "$((Get-Date -Format o -AsUTC).Replace(":", ".")) - Renaming: $($ModuleFolder)"
    Rename-Item -Path $ModuleFolder -NewName $NewName
}

# Rename files, according to prefix and module name
Write-Verbose -Message "$((Get-Date -Format o -AsUTC).Replace(":", ".")) - Renaming files, according to prefix and module name"
$ModuleFiles = Get-ChildItem -Path $ModuleRootFolder.FullName -Recurse -Filter "Prefix.ModuleName*" -File
Write-Verbose -Message "$((Get-Date -Format o -AsUTC).Replace(":", ".")) - Files found: $($ModuleFiles.Count)"

foreach ($ModuleFile in $ModuleFiles) {
    Write-Verbose -Message "$((Get-Date -Format o -AsUTC).Replace(":", ".")) - Renaming: $($ModuleFile)"
    Rename-Item -Path $ModuleFile -NewName $($ModuleFile.FullName).Replace("Prefix.ModuleName.", $NewName + ".")
}

# Update the content of the workflow files to match the module name and prefix
Write-Verbose -Message "$((Get-Date -Format o -AsUTC).Replace(":", ".")) - Updating the content of the workflow files to match the module name and prefix"
$WorkflowFiles = Get-ChildItem -Path $(Join-Path -Path $ModuleRootFolder.FullName -ChildPath ".github\workflows") -Filter "$NewName*.yml"
Write-Verbose -Message "$((Get-Date -Format o -AsUTC).Replace(":", ".")) - Files found: $($WorkflowFiles.Count)"

foreach ($WorkflowFile in $WorkflowFiles) {
    Write-Verbose -Message "$((Get-Date -Format o -AsUTC).Replace(":", ".")) - Updating file: $WorkflowFile"
    $WorkflowFileContent = Get-Content -Path $WorkflowFile -Raw
    $WorkflowFileContent = $WorkflowFileContent -replace 'Prefix.ModuleName', $NewName
    $WorkflowFileContent | Set-Content -Path $WorkflowFile
}

# Update the PSD file content, with new GUID, Author, CompanyName, Copyright and Description
Write-Verbose -Message "$((Get-Date -Format o -AsUTC).Replace(":", ".")) - Updating the PSD file content, with new GUID, Author, CompanyName, Copyright and Description"
$PSDFile = Get-Item -Path $(Join-Path $ModuleRootFolder.FullName -ChildPath "$NewName\$NewName\$NewName.psd1")
Write-Verbose -Message "$((Get-Date -Format o -AsUTC).Replace(":", ".")) - Updating file: $($PSDFile.FullName)"

$PSDFileContent = Get-Content -Path $PSDFile.FullName -Raw
$PSDFileContent = $PSDFileContent -replace '<RootModule>', "$NewName.psm1"
$PSDFileContent = $PSDFileContent -replace '<GUID>', $(New-Guid).Guid
$PSDFileContent = $PSDFileContent -replace '<Author>', $Author
$PSDFileContent = $PSDFileContent -replace '<CompanyName>', $CompanyName
$PSDFileContent = $PSDFileContent -replace '<Copyright>', $("(c) $CompanyName - All rights reserved.")
$PSDFileContent = $PSDFileContent -replace '<Decription>', $Description
$PSDFileContent | Set-Content -Path $PSDFile.FullName

# Clear the README file, leaving a header
Write-Verbose -Message "$((Get-Date -Format o -AsUTC).Replace(":", ".")) - Clearing the README file, leaving a header"
$ReadmeFile = Get-Item -Path $(Join-Path -Path $ModuleRootFolder.FullName -ChildPath "README")
$ReadmeFileContent = "# $NewName - PowerShell Module`n"
$ReadmeFileContent += "![Commit to Main](https://github.com/$GitHubHandle/$RepositoryName/actions/workflows/$NewName.Commit.yml/badge.svg)`n"
$ReadmeFileContent += "![Release](https://github.com/$GitHubHandle/$RepositoryName/actions/workflows/$NewName.Release.yml/badge.svg)`n"
$ReadmeFileContent | Set-Content -Path $ReadmeFile.FullName
