param (
  $unmatchedParameter,
  [switch]$help=$false,
  [string]$metaDsn,
  [string]$metaUser='',
  [string]$metaPwd=''
)

#--==============================================================================
#-- Script Name      :    import_fieldsolutions.ps1
#-- Description      :    The folder FieldSolutions in the Snowflake Enablement pack needs to be copied to C:\ProgramData\WhereScape\FieldSolutions
#-- Author           :    WhereScape Inc
#--==============================================================================
#-- Notes / History
#-- MME v 1.0.0 2020-08-13 First Version

# Print script help msg
Function Print-Help {
  $helpMsg = @"
  
This script Copy FieldSolutions Folder and its Contents.

Any required parameters will be prompted for at run-time, otherwise enter each named parameter as arguments: 

Example:.\import_fieldsolutions.ps1 -metaDsn "REDMetaRepoDSN" -metaUser "REDMetaRepoUser" -metaPwd "REDMetaRepoPwd"

Available Parameters:
  -help                       "Displays this help message"
  -metaDsn                    "RED MetaRepo DSN"                  [REQUIRED]
  -metaUser                   "RED MetaRepo User"                 [OMITTED FOR WINDOWS AUTH]
  -metaPwd                    "RED MetaRepo PW"                   [OMITTED FOR WINDOWS AUTH]
"@
  Write-Host $helpMsg
}

# Validate Script Parameters
if ( $help -or $unmatchedParameter -or ( $Args.Count -gt 0 )) {
  Print-Help 
  Exit
} 
else {
  # Prompt for any required paramaters
  if([string]::IsNullOrEmpty($metaDsn)) {  $metaDsn = Read-Host -Prompt "Enter RED MetaRepo DSN"}
  if($PSBoundParameters.count -eq 0) {  $metaUser = Read-Host -Prompt "Enter RED MetaRepo User or 'enter' for none"}
  if(![string]::IsNullOrEmpty($metaUser) -and [string]::IsNullOrEmpty($metaPwd)) {
    $metaPwdSecureString = Read-Host -Prompt "Enter RED MetaRepo Pwd" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($metaPwdSecureString)
    $metaPwd = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  }
  # Output the command line used to the host (passwords replced with '***')
  Write-Host "`nINFO: Run Parameters: -metaDsn '$metaDsn' $( if(![string]::IsNullOrEmpty($metaUser)){"-metaUser '$metaUser' -metaPwd '***' "})"
}

$logLevel=5
$outputMode='json'
$currentDir = $PSScriptRoot
$installDir = "${env:PROGRAMDATA}\WhereScape\"
$wsFSDir=Join-Path -Path $installDir -ChildPath "FieldSolutions"

#Copy the folder FieldSolutions to WhereScape
$excludes = "import_fieldsolutions.ps1"
if (!(Test-Path $wsFSDir)) {
  md -Path "$installDir\FieldSolutions" | Out-Null
  Get-ChildItem -path $currentDir -Recurse | Where-Object{$_.Name -notin $excludes} | Copy-Item -Destination {Join-Path $wsFSDir $_.FullName.Substring($currentDir.length)}
  Write-Output "FieldSolutions Folder Copied Successfuly"
} else {
  Get-ChildItem -path $currentDir -Recurse | Where-Object{$_.Name -notin $excludes} | Copy-Item -Destination {Join-Path $wsFSDir $_.FullName.Substring($currentDir.length)} -Force
  Write-Output "Overwriting FieldSolutions Folder where the Folder Already Exists"
}

if ($error.count -gt 0) {
  Exit 1
} else {
  Exit $LASTEXITCODE
}