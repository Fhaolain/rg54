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

#Connect to MetaData Repository
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString = "DSN=$metaDsn"
if( ! [string]::IsNullOrEmpty($metaUser)) { $conn.ConnectionString += ";UID=$metaUser" }
if( ! [string]::IsNullOrEmpty($metaPwd)) { $conn.ConnectionString += ";PWD=$metaPwd" }

#Update the Script Launcher Menu items
$sql = @"
MERGE INTO ws_table_attributes AS ta
USING (select 0 as ta_obj_key) as new_ta
  ON ta.ta_obj_key = new_ta.ta_obj_key and ta.ta_type = 'R'
WHEN MATCHED THEN
UPDATE SET ta_obj_key = 0,
  ta_type = 'R',
  ta_text_1 = 'Add Transforms to a Fixed Width Stage Table',
  ta_text_2 = 'Create New Range Tables',
  ta_text_3 = 'Pause a Ranged Table',
  ta_text_4 = 'Restart a Ranged Table',
  ta_text_5 = 'Retrofit Fivetran Tables',
  ta_text_6 = 'Parse JSON  load->stage',
  ta_text_7 = 'Job Versioning',
  ta_text_8 = 'Job Maintenance',
  ta_val_1 = (select oo_obj_key from dbo.ws_obj_object where oo_name = 'snowflake_fixed_width_setup' and oo_type_key = 3),
  ta_val_2 = (select oo_obj_key from dbo.ws_obj_object where oo_name = 'snowflake_create_range_table' and oo_type_key = 3),
  ta_val_3 = (select oo_obj_key from dbo.ws_obj_object where oo_name = 'snowflake_ranged_table_pause' and oo_type_key = 3),
  ta_val_4 = (select oo_obj_key from dbo.ws_obj_object where oo_name = 'snowflake_ranged_table_restart' and oo_type_key = 3),
  ta_val_5 = (select oo_obj_key from dbo.ws_obj_object where oo_name = 'snowflake_retrofit_tables' and oo_type_key = 3),
  ta_val_6 = (select oo_obj_key from dbo.ws_obj_object where oo_name = 'snowflake_parse_json_load_tables' and oo_type_key = 3),
  ta_val_7 = (select oo_obj_key from dbo.ws_obj_object where oo_name = 'snowflake_job_versioning_extensions' and oo_type_key = 3),
  ta_val_8 = (select oo_obj_key from dbo.ws_obj_object where oo_name = 'snowflake_job_maintenance_extensions' and oo_type_key = 3)
WHEN NOT MATCHED THEN
INSERT (ta_obj_key,ta_type,ta_text_1,ta_text_2,ta_text_3,ta_text_4,ta_text_5,ta_text_6,ta_text_7,ta_text_8,ta_val_1,ta_val_2,ta_val_3,ta_val_4,ta_val_5,ta_val_6,ta_val_7,ta_val_8) 
  VALUES (0,'R','Add Transforms to a Fixed Width Stage Table','Create New Range Tables','Pause a Ranged Table','Restart a Ranged Table','Retrofit Fivetran Tables','Parse JSON  load->stage','Job Versioning','Job Maintenance',(select oo_obj_key from dbo.ws_obj_object where oo_name = 'snowflake_fixed_width_setup' and oo_type_key = 3),(select oo_obj_key from dbo.ws_obj_object where oo_name = 'snowflake_create_range_table' and oo_type_key = 3),(select oo_obj_key from dbo.ws_obj_object where oo_name = 'snowflake_ranged_table_pause' and oo_type_key = 3),(select oo_obj_key from dbo.ws_obj_object where oo_name = 'snowflake_ranged_table_restart' and oo_type_key = 3),(select oo_obj_key from dbo.ws_obj_object where oo_name = 'snowflake_retrofit_tables' and oo_type_key = 3),(select oo_obj_key from dbo.ws_obj_object where oo_name = 'snowflake_parse_json_load_tables' and oo_type_key = 3),(select oo_obj_key from dbo.ws_obj_object where oo_name = 'snowflake_job_versioning_extensions' and oo_type_key = 3),(select oo_obj_key from dbo.ws_obj_object where oo_name = 'snowflake_job_maintenance_extensions' and oo_type_key = 3))
;
"@

$command = New-Object System.Data.Odbc.OdbcCommand($sql,$conn)
$command.CommandTimeout = 0
$command.CommandType = "StoredProcedure"
$conn.Open()
[void]$command.ExecuteNonQuery()
$conn.Close()

if ($error.count -gt 0) {
  Exit 1
} else {
  Exit $LASTEXITCODE
}