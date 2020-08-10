param (
  $unmatchedParameter,
  [switch]$help=$false,
  [string]$metaDsn,
  [string]$metaDsnArch='64',
  [string]$metaUser='',
  [string]$metaPwd='',
  [string]$metaBase,
  [string]$snowflakeDB,
  [string]$tgtLoadSchema,
  [string]$tgtStageSchema,
  [string]$tgtEdwSchema,
  [string]$tgtDvSchema,
  [string]$snowflakeDsn,
  [string]$snowflakeUser='',
  [string]$snowflakePwd='',
  [string]$sfSnowsqlAcc,
  [string]$snowflakeDataWarehouse,
  [int]$startAtStep=1
)

#--==============================================================================
#-- Script Name      :    setup_red_for_snowflake.ps1
#-- Description      :    Installs the Red Repository and Snowflake Enablement Pack
#-- Author           :    WhereScape, Inc
#--==============================================================================
#-- Notes / History
#-- MME v 1.0.0 2020-07-21 First Version

# Print script help msg
Function Print-Help {
  $helpMsg = @"

This WhereScape Enablement Pack install script must be run as administrator.

Prerequisites before running this script: 
  1. Valid install of WhereScape RED with License key entered and accepted
  2. An empty SQL Server Database with a DSN to connect to it
  3. An empty Snowflake Database with a DSN to connect to it
   - Your Snowflake DB should have at least one dedicated schema available for use in creating RED Data Warehouse Targets
   - Both Snowflake ODBC Driver and SnowSQL are required

Any required parameters will be prompted for at run-time, otherwise enter each named paramter as arguments:  

Example:.\setup_red_for_snowflake.ps1 -metaDsn "REDMetaRepoDSN" -metaUser "REDMetaRepoUser" -metaPwd "REDMetaRepoPwd" -metaBase "REDMetaRepoDB" -snowflakeDB "SnowflakeDB" -tgtLoadSchema "dev_load" -tgtStageSchema "dev_stage" -tgtEdwSchema "dev_edw" -tgtDvSchema "dev_dv" -snowflakeDsn "SnowflakeDSN" -snowflakeUser "SnowflakeUser" -snowflakePwd "SnowflakePwd" -snowflakeDataWarehouse "SnowflakeDataWarehouse"

Available Parameters:
  -help                   "Displays this help message"
  -metaDsn                "RED MetaRepo DSN"                [REQUIRED]
  -metaDsnArch            "64 or 32"                        [DEFAULT = 64]
  -metaUser               "RED MetaRepo User"               [OMITTED FOR WINDOWS AUTH]
  -metaPwd                "RED MetaRepo PW"                 [OMITTED FOR WINDOWS AUTH]
  -metaBase               "RED MetaRepo DB"                 [REQUIRED]
  -snowflakeDB            "Snowflake DB"                    [REQUIRED]
  -tgtLoadSchema          "Snowflake Load Target Schema"    [REQUIRED]
  -tgtStageSchema         "Snowflake Stage Target Schema"   [REQUIRED]
  -tgtEdwSchema           "Snowflake Load Target Schema"    [REQUIRED]
  -tgtDvSchema            "Snowflake Load Target Schema"    [REQUIRED]
  -snowflakeDsn           "Snowflake DSN"                   [REQUIRED]
  -snowflakeUser          "Snowflake User"                  [OMITTED FOR WINDOWS AUTH]
  -snowflakePwd           "Snowflake Password"              [OMITTED FOR WINDOWS AUTH] 
  -sfSnowsqlAcc           "Snowflake Account, usually your server name with '.snowflakecomputing.com' removed" [REQUIRED]
  -snowflakeDataWarehouse "Snowflake Data Warehouse"        [REQUIRED]
  -startAtStep            "Defaults to first step, used to resume script from a certain step" [DEFAULT = 1]
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
  if([string]::IsNullOrEmpty($metaDsn))                 {$metaDsn = Read-Host -Prompt "Enter RED MetaRepo DSN"}
  if($PSBoundParameters.count -eq 0)                    {$metaUser = Read-Host -Prompt "Enter RED MetaRepo User or 'enter' for none"}
  if(![string]::IsNullOrEmpty($metaUser) -and [string]::IsNullOrEmpty($metaPwd)) {
    $metaPwdSecureString = Read-Host -Prompt "Enter RED MetaRepo Pwd" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($metaPwdSecureString)
    $metaPwd = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  }
  if([string]::IsNullOrEmpty($metaBase))                {$metaBase = Read-Host -Prompt "Enter RED MetaRepo DB"}
  if([string]::IsNullOrEmpty($snowflakeDB))             {$snowflakeDB = Read-Host -Prompt "Enter Snowflake DB"}
  if([string]::IsNullOrEmpty($tgtLoadSchema))           {$tgtLoadSchema = Read-Host -Prompt "Enter Snowflake 'Load' Target Schema (the vaule entered will be the default for following schemas)" | %{if([string]::IsNullOrEmpty($_)){'DEV_LOAD'}else{$_.ToUpper()}} }
  if([string]::IsNullOrEmpty($tgtStageSchema))          {$tgtStageSchema = Read-Host -Prompt "Enter Snowflake 'Stage' Target Schema, default: '$tgtLoadSchema'" | %{if([string]::IsNullOrEmpty($_)){$tgtLoadSchema}else{$_.ToUpper()}} }
  if([string]::IsNullOrEmpty($tgtEdwSchema))            {$tgtEdwSchema = Read-Host -Prompt "Enter Snowflake 'EDW' Target Schema, default: '$tgtLoadSchema'" | %{if([string]::IsNullOrEmpty($_)){$tgtLoadSchema}else{$_.ToUpper()}} }
  if([string]::IsNullOrEmpty($tgtDvSchema))             {$tgtDvSchema = Read-Host -Prompt "Enter Snowflake 'Data Vault' Target Schema, default: '$tgtLoadSchema'" | %{if([string]::IsNullOrEmpty($_)){$tgtLoadSchema}else{$_.ToUpper()}} }
  if([string]::IsNullOrEmpty($snowflakeDsn))            {$snowflakeDsn = Read-Host -Prompt "Enter Snowflake DSN"}
  if($PSBoundParameters.count -eq 0)                    {$snowflakeUser = Read-Host -Prompt "Enter Snowflake User or 'enter' for none"}
  if(![string]::IsNullOrEmpty($snowflakeUser) -and [string]::IsNullOrEmpty($snowflakePwd) ) {
    $snowflakePwdSecureString = Read-Host -Prompt "Enter Snowflake Pwd" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($snowflakePwdSecureString)
    $snowflakePwd = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  }
  if([string]::IsNullOrEmpty($snowflakeDataWarehouse))  {$snowflakeDataWarehouse = Read-Host -Prompt "Enter Snowflake DataWarehouse"}
  if([string]::IsNullOrEmpty($sfSnowsqlAcc))            {$sfSnowsqlAcc = Read-Host -Prompt "Enter Snowflake Account, usually your server name with '.snowflakecomputing.com' removed"}
  
  # Output the command line used to the host (passwords removed)
  $cmdLineArgs = @"
"$PSScriptRoot\install_New_RED_Repository_for_Snowflake.ps1" -metaDsn "$metaDsn" -metaDsnArch "$metaDsnArch" $( if(![string]::IsNullOrEmpty($metaUser)){"-metaUser ""$metaUser"" "})-metaBase "$metaBase" -snowflakeDB "$snowflakeDB" -tgtLoadSchema "$tgtLoadSchema" -tgtStageSchema "$tgtStageSchema" -tgtEdwSchema "$tgtEdwSchema" -tgtDvSchema "$tgtDvSchema" -snowflakeDsn "$snowflakeDsn" $( if(![string]::IsNullOrEmpty($snowflakeUser)){"-snowflakeUser ""$snowflakeUser"" "})-snowflakeDataWarehouse "$SnowflakeDataWarehouse" -sfSnowsqlAcc "$sfSnowsqlAcc" -startAtStep $startAtStep
"@
  Write-Host "`nINFO: Script command line executed (passwords removed): $cmdLineArgs`n"
}

$logLevel=5
$outputMode="json"
$dstDir="C:\temp\"
$schedulerName="WIN0001"
$wslSchedLog="C:\ProgramData\WhereScape\Scheduler\WslSched_${metaDsn}_${schedulerName}.log"
$defBrowserSchema="dbo"
$dtmSFFile="$PSScriptRoot\Data Type Mappings\SNOWFLAKE from File.xml"
$dtmSFFWF="$PSScriptRoot\Data Type Mappings\SNOWFLAKE from FIXED WIDTH FILE.xml"
$dtmSFXmlJson="$PSScriptRoot\Data Type Mappings\SNOWFLAKE from XML and JSON.xml"
$dtmSFSF="$PSScriptRoot\Data Type Mappings\SNOWFLAKE from SNOWFLAKE.xml"
$dtmSFSql="$PSScriptRoot\Data Type Mappings\SNOWFLAKE from SQL Server.xml"
$dtmSFDb2="$PSScriptRoot\Data Type Mappings\SNOWFLAKE from DB2.xml"
$dtmSFOra="$PSScriptRoot\Data Type Mappings\SNOWFLAKE from Oracle.xml"
$dtmSFO="$PSScriptRoot\Data Type Mappings\SNOWFLAKE from Other.xml"
$dtmSFPsql="$PSScriptRoot\Data Type Mappings\SNOWFLAKE from PostgreSQL.xml"
$dtmSFRedShift="$PSScriptRoot\Data Type Mappings\SNOWFLAKE from Redshift.xml"
$dtmSFTD="$PSScriptRoot\Data Type Mappings\SNOWFLAKE from Teradata.xml"
$dfsSF="$PSScriptRoot\Database Function Sets\Snowflake Function Set.xml"
$extProFile="$PSScriptRoot\Extended Properties\Snowflake.extprop"
$templatesFile="$PSScriptRoot\import_powershell_templates.ps1"
$optionsFile="$PSScriptRoot\Options\Options.xml"
$wsLoc="C:\ProgramData\WhereScape\"

# Print the starting step
if ($startAtStep -ne 1) { Write-Host "Starting from Step = $startAtStep" }

# Check for a correct RED Version
$redLoc="C:\Program Files\WhereScape\RED\"
$getRedVersion = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  Select-Object DisplayName, DisplayVersion, InstallLocation | where DisplayName -eq "WhereScape RED" | where DisplayVersion -like "8.5.*"
if ($getRedVersion -isnot [array] -and $getRedVersion -ne $null) { 
  $redLoc = $getRedVersion.InstallLocation 
} elseif ($getRedVersion.count -gt 1) {
  Write-Warning "Multiple RED Versions available, please select one from:"
  $getRedVersion | %{ write-host $_.InstallLocation }
  $redLoc = Read-Host -Prompt "Please Enter a RED Install Directory from the above list"
} else {
  Write-Warning "Could not find a compatible RED Version Installed - Please install WhereScape RED 8.5.1.0 or greater to continue."
  Exit
}

# Build required file and folder paths
$redCliPath=Join-Path -Path $redLoc -ChildPath "RedCli.exe"
$defDtmDir=Join-Path -Path $redLoc -ChildPath "Administrator\Data Type Mappings"
$defDfsDir=Join-Path -Path $redLoc -ChildPath "Administrator\Function Sets"
$wslSched=Join-Path -Path $redLoc -ChildPath "WslSched.exe"
$wsFSLoc=Join-Path -Path $wsLoc -ChildPath "FieldSolutions"

# Check Snowflake Connectivity
$installStep=1
if ($installStep -ge $startAtStep) {
  $conn = New-Object Data.Odbc.OdbcConnection
  $conn.ConnectionString= "dsn=$snowflakeDsn;uid=$snowflakeUser;pwd=$snowflakePwd;"
  try { 
    if (($conn.open()) -eq $true) { 
      $conn.Close() 
      $true 
    }
  } catch { 
    Write-Host $_.Exception.Message
    Write-Warning "Failed to establish a connection to Snowflake, please check your Snowflake DSN and credentials"
    Write-Output "Failed at step = $installStep"
    Exit
  }
}
#Check or Copy the folder FieldSolutions to WhereScape
if (!(Test-Path $wsFSLoc)) {
  Copy-Item -Path '$PSScriptRoot\FieldSolutions\' -Destination $wsLoc
}

# common RedCli arguments
$commonRedCliArgs = @" 
--meta-dsn "$metaDsn" --meta-dsn-arch "$metaDsnArch" --meta-user-name "$metaUser" --meta-password "$metaPwd" --meta-database "$metaBase" --log-level "$logLevel" --output-mode "$outputMode"
"@

$generalSetupCmds=@"
dtm import --default-dtm-path "$defDtmDir" --file-name "$dtmSFFile"
dtm import --default-dtm-path "$defDtmDir" --file-name "$dtmSFFWF"
dtm import --default-dtm-path "$defDtmDir" --file-name "$dtmSFXmlJson"
dtm import --default-dtm-path "$defDtmDir" --file-name "$dtmSFSF"
dtm import --default-dtm-path "$defDtmDir" --file-name "$dtmSFSql"
dtm import --default-dtm-path "$defDtmDir" --file-name "$dtmSFDb2"
dtm import --default-dtm-path "$defDtmDir" --file-name "$dtmSFOra"
dtm import --default-dtm-path "$defDtmDir" --file-name "$dtmSFO"
dtm import --default-dtm-path "$defDtmDir" --file-name "$dtmSFPsql"
dtm import --default-dtm-path "$defDtmDir" --file-name "$dtmSFRedShift"
dtm import --default-dtm-path "$defDtmDir" --file-name "$dtmSFTD"
dfs import --default-dfs-path "$defDfsDir" --file-name "$dfsSF"
ext-prop-definition import --file-name "$extProFile"
parameter add --name JSON_NUMBER_PLUS_FACTOR --value 2 --comments "When setting precision of decimals, this formula is used:   round up to nearest A of (( X + B ) * C )  where this parameter is B and X is the max precision found"
parameter add --name JSON_NUMBER_ROUNDING --value 1 --comments "When setting precision of decimals, this formula is used:   round up to nearest A of (( X + B ) * C )  where this parameter is A and X is the max precision found"
parameter add --name JSON_NUMBER_TIMES_FACTOR --value 1 --comments "When setting precision of decimals, this formula is used:   round up to nearest A of (( X + B ) * C )  where this parameter is C and X is the max precision found"
parameter add --name JSON_VARCHAR_PLUS_FACTOR --value 10 --comments "When setting length of varchars, this formula is used:   round up to nearest A of (( X + B ) * C )  where this parameter is B and X is the max length found"
parameter add --name JSON_VARCHAR_ROUNDING --value 10 --comments "When setting length of varchars, this formula is used:   round up to nearest A of (( X + B ) * C )  where this parameter is A and X is the max length found"
parameter add --name RANGE_COMPRESSION_RATE --value 5 --comments "The expected compression rate of extract files"
parameter add --name RANGE_DEBUG_MODE --value FALSE --comments "Debug Mode for the range table create script.  Valid values are TRUE and FALSE."
parameter add --name RANGE_OPTIMAL_FILE_SIZE --value 100 --comments "The optimal file size in MB for a compressed extract file"
parameter add --name RANGE_WORK_CONNECTION --value "Range Table Location" --comments "RED Connection pointing to SQL Server range table location.  Ignored if using SNOWFLAKE range tables."
parameter add --name RANGE_WORK_TABLE_LOCATION --value "SQLSERVER" --comments "Database type for range tables, one of:  SQLSERVER  SNOWFLAKE"
parameter add --name RANGE_WORK_TARGET --value "rangeTables" --comments "RED Target pointing to SQL Server range table location.  Ignored if using SNOWFLAKE range tables."
parameter add --name RETRO_DEFAULT_TEMPLATE --value wsl_snowflake_create_table --comments "Text applied to all imported tables in various places"
parameter add --name RETRO_IMPORT_ACTION_NAME --value "Fivetran Import" --comments "Text applied to all imported tables in various places"
parameter add --name RETRO_IMPORT_USER_NAME --value "Fivetran Import User" --comments "User name used to check out all imported tables"
parameter add --name TIMEZONE --comments "Used to specify the timezone in DAILY_DATE_ROLL_SF.  Value is either empty, or an alter statment.  Eg:  ALTER SESSION SET TIMEZONE = 'Europe/Zurich';"
"@

#Create Connections commands
$connectionSetupCmds=@"
connection rename --force --new-name "Runtime Connection for Scripts" --old-name "windows"
connection modify --name "Runtime Connection for Scripts" --con-type "Windows" --odbc-source-arch 32  --work-dir $dstDir --default-load-type "Script based load" 
connection add --name "$snowflakeDsn" --con-type "Database" --db-id $snowflakeDB --odbc-source "$snowflakeDsn" --odbc-source-arch $metaDsnArch --dtm-set-name "SNOWFLAKE from SNOWFLAKE" --db-type Custom --def-update-script-con "Runtime Connection for Scripts" --def-pre-load-action "Truncate" --display-data-sql "SELECT * FROM `$OBJECT`$ SAMPLE (`$MAXDISPLAYDATA`$ ROWS)" --row-count-sql "SELECT COUNT(*) FROM `$OBJECT`$" --drop-table-sql "DROP TABLE `$OBJECT`$" --drop-view-sql "DROP VIEW `$OBJECT`$" --truncate-sql "TRUNCATE TABLE `$OBJECT`$" --def-browser-schema "$($(@($tgtLoadSchema,$tgtStageSchema,$tgtEdwSchema,$tgtDvSchema) | Sort-Object | Get-Unique) -join ',')" --def-odbc-user Extract --def-table-alter-ddl-tem "wsl_snowflake_alter_ddl" --def-table-create-ddl-tem "wsl_snowflake_create_table" --def-view-create-ddl-tem "wsl_snowflake_create_view" --con-info-proc "wsl_snowflake_table_information" --extract-user-id $snowflakeUser --extract-pwd $snowflakePwd
target add --connection-name "$snowflakeDsn" --name load --database $snowflakeDB --schema $tgtLoadSchema --tree-colour #ff0000
target add --connection-name "$snowflakeDsn" --name stage --database $snowflakeDB --schema $tgtStageSchema --tree-colour #4e00c0
target add --connection-name "$snowflakeDsn" --name edw --database $snowflakeDB --schema $tgtEdwSchema --tree-colour #008054
target add --connection-name "$snowflakeDsn" --name data_vault --database $snowflakeDB --schema $tgtDvSchema --tree-colour #c08000
connection add --name "Database Source System" --con-type ODBC --odbc-source "SET THIS VALUE" --odbc-source-arch $metaDsnArch --work-dir $dstDir --db-type "SQL Server" --dtm-set-name "SNOWFLAKE from SQL Server" --def-pre-load-action "Truncate" --def-browser-schema "SET THIS VALUE" --def-odbc-user Extract
ext-prop-value modify --object-name "Database Source System" --value-data "+" --value-name "RANGE_CONCATWORD"
connection add --name "Range Table Location" --con-type ODBC --db-id RANGE_WORK_DB --odbc-source RANGE_WORK_DB --odbc-source-arch $metaDsnArch --work-dir $dstDir --db-type "SQL Server" --def-pre-load-action Truncate --def-browser-schema $defBrowserSchema --def-odbc-user Extract
target add --connection-name "Range Table Location" --name RangeTables --database RANGE_WORK_DB --schema $defBrowserSchema --tree-colour #ff57ff
connection rename --force --new-name Repository --old-name "DataWarehouse"
connection modify --name "Repository" --con-type Database --db-id $metaBase --odbc-source $metaDsn --odbc-source-arch $metaDsnArch --work-dir $dstDir --db-type "SQL Server" --meta-repo true --function-set SNOWFLAKE --def-browser-schema $defBrowserSchema --def-odbc-user Extract --extract-user-id "$metaUser" --extract-pwd "$metaPwd"
connection add --name "Windows Comma Sep Files" --con-type Windows --work-dir $dstDir --dtm-set-name "SNOWFLAKE from File"
ext-prop-value modify --object-name "Windows Comma Sep Files" --value-data "FMT_RED_CSV_SKIP_GZIP_COMMA" --value-name "SF_FILE_FORMAT"
connection add --name "Windows Fixed Width" --con-type Windows  --work-dir $dstDir --dtm-set-name "SNOWFLAKE from FIXED WIDTH FILE"
ext-prop-value modify --object-name "Windows Fixed Width" --value-data "FMT_RED_FIX_NOSKIP_GZIP" --value-name "SF_FILE_FORMAT"
connection add --name "Windows JSON Files" --con-type Windows --work-dir $dstDir --dtm-set-name "SNOWFLAKE from XML and JSON "
ext-prop-value modify --object-name "Windows JSON Files" --value-data "FMT_RED_JSON_GZIP" --value-name "SF_FILE_FORMAT"
connection add --name "Windows Pipe Sep Files" --con-type Windows --work-dir $dstDir --dtm-set-name "SNOWFLAKE from File"
ext-prop-value modify --object-name "Windows Pipe Sep Files" --value-data "FMT_RED_CSV_SKIP_GZIP_PIPE" --value-name "SF_FILE_FORMAT"
connection add --name "Windows XML Files" --con-type Windows --work-dir $dstDir --dtm-set-name "SNOWFLAKE from XML and JSON"
ext-prop-value modify --object-name "Windows XML Files" --value-data "FMT_RED_XML_GZIP" --value-name "SF_FILE_FORMAT"
ext-prop-value modify --object-name "$snowflakeDsn" --value-data "+" --value-name "RANGE_CONCATWORD"
ext-prop-value modify --object-name "$snowflakeDsn" --value-data False --value-name "SF_DEBUG_MODE"
ext-prop-value modify --object-name "$snowflakeDsn" --value-data $sfSnowsqlAcc --value-name "SF_SNOWSQL_ACCOUNT"
ext-prop-value modify --object-name "$snowflakeDsn" --value-data $snowflakeDB --value-name "SF_SNOWSQL_DATABASE"
ext-prop-value modify --object-name "$snowflakeDsn" --value-data $snowflakeDataWarehouse --value-name "SF_SNOWSQL_WAREHOUSE"
ext-prop-value modify --object-name "$snowflakeDsn" --value-data "FMT_RED_CSV_NOSKIP_GZIP_PIPE" --value-name "SF_FILE_FORMAT"
ext-prop-value modify --object-name "$snowflakeDsn" --value-data "TRUE" --value-name "SF_SEND_FILES_ZIPPED"
ext-prop-value modify --object-name "$snowflakeDsn" --value-data 1000000 --value-name "SF_SPLIT_THRESHOLD"
ext-prop-value modify --object-name "$snowflakeDsn" --value-data 1 --value-name "SF_SPLIT_COUNT"
ext-prop-value modify --object-name "$snowflakeDsn" --value-data FALSE --value-name "SF_UNICODE_SUPPORT"
ext-prop-value modify --object-name "$snowflakeDsn" --value-data | --value-name SF_UNLOAD_DELIMITER
ext-prop-value modify --object-name "$snowflakeDsn" --value-data \" --value-name "SF_UNLOAD_ENCLOSED_BY"
ext-prop-value modify --object-name "$snowflakeDsn" --value-data # --value-name SF_UNLOAD_ESCAPE_CHAR
ext-prop-value modify --object-name "$snowflakeDsn" --value-data ASCII --value-name RANGE_EXTRACT_CHARSET
ext-prop-value modify --object-name "$snowflakeDsn" --value-data FALSE --value-name RANGE_FAIL_ON_THREAD_FAILURE
ext-prop-value modify --object-name "$snowflakeDsn" --value-data 10 --value-name RANGE_MAX_THREAD_FAILURES
ext-prop-value modify --object-name "$snowflakeDsn" --value-data 4 --value-name RANGE_THREAD_COUNT
ext-prop-value modify --object-name "$snowflakeDsn" --value-data TRUE --value-name RANGE_UNLOAD_GZIP
ext-prop-value modify --object-name "$snowflakeDsn" --value-data 3 --value-name RANGE_UPLOAD_MAX_RETRIES
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Stage" --obj-sub-type "Stage" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_stage"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Stage" --obj-sub-type "DataVaultStage" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_dv_stage"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Stage" --obj-sub-type "WorkTable" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_stage"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "ods" --obj-sub-type "DataStore" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "ods" --obj-sub-type "History" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_hist"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "HUB" --obj-sub-type "Detail" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Link" --obj-sub-type "Detail" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Satellite" --obj-sub-type "History" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Normal" --obj-sub-type "Normalized" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Normal" --obj-sub-type "History" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_hist"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Dim" --obj-sub-type "ChangingDimension" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_hist"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Dim" --obj-sub-type "Dimension" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Dim" --obj-sub-type "PreviousDimension" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Dim" --obj-sub-type "RangedDimension" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Dim" --obj-sub-type "TimeDimension" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Dim" --obj-sub-type "MappingTable" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Dim" --obj-sub-type "WorkTable" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Fact" --obj-sub-type "Detail" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Agg" --obj-sub-type "Aggregate" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Agg" --obj-sub-type "Summary" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Agg" --obj-sub-type "WorkTable" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name "$snowflakeDsn" --obj-type "Custom2" --obj-sub-type "Detail" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pscript_perm"
"@

# RED Application deployments
$applicationDeploymentCmds = @"
deployment deploy --app-number SFDATEDIM --app-version 0001 --app-directory "$PSScriptRoot\Deployment Applications\Date Dimension" --continue-ver-mismatch --default-load-script-connection "Runtime Connection for Scripts" --dest-connection-name "$snowflakeDsn" --dest-target-name "load"
deployment deploy --app-number SFFILEFMT --app-version 0001 --app-directory "$PSScriptRoot\Deployment Applications\File Formats" --continue-ver-mismatch --default-load-script-connection "Runtime Connection for Scripts" --dest-connection-name "$snowflakeDsn" --dest-target-name "load" 
deployment deploy --app-number SFEXTENSIONS --app-version 0001 --app-directory "$PSScriptRoot\Deployment Applications\Extensions" --continue-ver-mismatch --default-load-script-connection "Runtime Connection for Scripts" --dest-connection-name "Repository"
deployment deploy --app-number SFJOBS --app-version 0001 --app-directory "$PSScriptRoot\Deployment Applications\Jobs" --continue-ver-mismatch --default-load-script-connection "Runtime Connection for Scripts" --dest-connection-name "$snowflakeDsn" --dest-target-name "load"
"@

Function Remove-Passwords ($stringWithPwds) { 
  $stringWithPwdsRemoved = $stringWithPwds
  if (![string]::IsNullOrEmpty($metaPwd)){ 
    $stringWithPwdsRemoved = $stringWithPwdsRemoved -replace "(`"|`'| ){1}$metaPwd(`"|`'| |$){1}",'$1***$2'
  } 
  if (![string]::IsNullOrEmpty($snowflakePwd)){ 
    $stringWithPwdsRemoved = $stringWithPwdsRemoved -replace "(`"|`'| ){1}$snowflakePwd(`"|`'| |$){1}",'$1***$2' 
  } 
  $stringWithPwdsRemoved 
}

Function Execute-Command ($commandTitle, $commandPath, $commandArguments)
{
    Try {
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $commandPath
        $pinfo.RedirectStandardError = $true
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false
        $pinfo.WindowStyle = 'Hidden'
        $pinfo.CreateNoWindow = $True
        $pinfo.Arguments = $commandArguments
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $p.Start() | Out-Null
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()
        $p.WaitForExit()
        $p | Add-Member "commandTitle" $commandTitle
        $p | Add-Member "stdout" $stdout
        $p | Add-Member "stderr" $stderr
    }
    Catch {
    }
    $p
}

Function Execute-RedCli-Command ( $commandArguments, $commonArguments="" ) {
  $cmdReturn = Execute-Command "RedCli CMD" $redCliPath "$commandArguments $commonArguments"
  $progressEnd = ($cmdReturn.stdout -split "`n" | Select-String -Pattern ',"Progress End":.+"}').Line
  if ($cmdReturn.stderr.Trim() -ne '' -or $progressEnd -notmatch 'Error Message":"","Progress End"') {
      Write-Output "Failure executing cmd: $(Remove-Passwords $commandArguments)"
      Write-Output "Failed at step = $installStep"
      if ($cmdReturn.stderr.Trim() -ne '') { Write-Output $cmdReturn.stderr }
      Write-Output $( $progressEnd -replace '.+?"Progress End":".+?\}(.+?)','$1' )
      Exit
  }
  else {
      $batchJson = ($cmdReturn.stdout -split "`n" | Select-String -Pattern '^{"Batch":\[').Line.Trim().TrimEnd("Content-Type: application/json; charset=utf-8")
      $cmdResult = ($batchJson | ConvertFrom-Json).Batch[0].Result
      Write-Output "Result: $cmdResult Cmd: $(Remove-Passwords $commandArguments)"
  }
}

# ---------------------------------------------------------------------------------------------------
# 
#             MAIN INSTALLER PROGRAM BEGINS
#
# ---------------------------------------------------------------------------------------------------

# Create RED Metadata Repository
$installStep=100
if ($installStep -ge $startAtStep) {
  Execute-RedCli-Command "repository create" $commonRedCliArgs
}
# Run initial setup commands
$installStep=200
$cmdArray = $generalSetupCmds.replace("`r`n", "`n").split("`n")  
for($i=0; $i -lt $cmdArray.Count; $i++) {
  $global:installStep++
  if ($installStep -ge $startAtStep) {
    Execute-RedCli-Command $cmdArray[$i] $commonRedCliArgs
  }
}

# Install Templates, Scripts and Procedures
$installStep=300
if ($installStep -ge $startAtStep) { 

  if( ([string]::IsNullOrEmpty($metaUser) -and [string]::IsNullOrEmpty($metaPwd)) -or ([string]::IsNullorWhitespace($metaUser) -and [string]::IsNullorWhitespace($metaPwd))) {
   & powershell -ExecutionPolicy RemoteSigned -file "$templatesFile" -metaDsn "$metaDsn"
  }else{
  & powershell -ExecutionPolicy RemoteSigned -file "$templatesFile" -metaDsn "$metaDsn" -metaUser "$metaUser" -metaPwd "$metaPwd"
  }
  if( $LASTEXITCODE -eq 0 ) {
    Write-Output "Templates, Scripts and Procedures updated successfully"
  } else {
    Write-Output "Failures during Template/Script/Procedure import"
    Write-Output "Failed at step = $installStep"
    Exit $LASTEXITCODE
  }
}

# Setup Connection Configurations
$installStep=400
$cmdArray = $connectionSetupCmds.replace("`r`n", "`n").split("`n")  
for($i=0; $i -lt $cmdArray.Count; $i++) {
  $global:installStep++
  if ($installStep -ge $startAtStep) {
    Execute-RedCli-Command $cmdArray[$i] $commonRedCliArgs
  }
}

# Setup RED Options
$installStep=500
if ($installStep -ge $startAtStep) {
  $importOptionsCmd =  @"
options import -f "$optionsFile"
"@
  Execute-RedCli-Command $importOptionsCmd $commonRedCliArgs
}

# Deploy RED Applications
$installStep=600
$cmdArray = $applicationDeploymentCmds.replace("`r`n", "`n").split("`n")  
for($i=0; $i -lt $cmdArray.Count; $i++) {
  $global:installStep++
  if ($installStep -ge $startAtStep) {
    Write-Host "Deploying Application for Step $installStep, please wait..."
    Execute-RedCli-Command $cmdArray[$i] $commonRedCliArgs
  }
}

#Update Options Tool with Sql commands
$installStep=700
if ($installStep -ge $startAtStep) {
  $sql = @"
UPDATE ws_obj_type 
SET ot_options = SUBSTRING(CAST(ot_options AS VARCHAR(4000)),1,CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000)))-1)+'OBJTGTKEY='+(SELECT CAST(dt_target_key AS VARCHAR(10)) FROM ws_dbc_target WHERE dt_name = 'load')+';'+SUBSTRING(CAST(ot_options AS VARCHAR(4000)),CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000)))+CHARINDEX(';',SUBSTRING(CAST(ot_options AS VARCHAR(4000)),CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000))),100)),1000) 
WHERE ot_type_key IN (select ot_type_key from dbo.ws_obj_type where ot_description in ('Load Table','File Format','Extensions'))
;
UPDATE ws_obj_type
SET  ot_pre_fix   = 'DIM_' 
WHERE  ot_type_key   = 6
;
UPDATE ws_meta_names
SET    mn_name   = 'DSS_CHANGE_HASH' 
WHERE  mn_object   = 'dss_change_hash' 
;
UPDATE ws_meta_names
SET    mn_name   = 'DSS_CREATE_TIME' 
WHERE  mn_object   = 'dss_create_time' 
;
UPDATE ws_meta_names
SET    mn_name   = 'DSS_CURRENT_FLAG'
WHERE  mn_object   = 'dss_current_flag' 
;
UPDATE ws_meta_names
SET    mn_name   = 'DSS_END_DATE' 
WHERE  mn_object   = 'dss_end_date' 
;
UPDATE ws_meta_names
SET    mn_name   = 'DSS_LOAD_DATE' 
WHERE  mn_object   = 'dss_load_date' 
;
UPDATE ws_meta_names
SET    mn_name   = 'DSS_RECORD_SOURCE' 
WHERE  mn_object   = 'dss_record_source' 
;
UPDATE ws_meta_names
SET    mn_name   = 'DSS_START_DATE' 
WHERE  mn_object   = 'dss_start_date' 
;
UPDATE ws_meta_names
SET    mn_name   = 'DSS_UPDATE_TIME' 
WHERE  mn_object   = 'dss_update_time' 
;
UPDATE ws_meta_names
SET    mn_name   = 'DSS_VERSION'
WHERE  mn_object   = 'dss_version' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_KEY' 
WHERE  mn_object   = 'dim_key' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_KEY' 
WHERE  mn_object   = 'fact_key' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'HK_' 
     , mn_name   = 'Full table name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'hub_key' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'HK_' 
     , mn_name   = 'Full table name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'lnk_key' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_KEY' 
WHERE  mn_object   = 'ods_key' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'HK_' 
     , mn_name   = 'Full table name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'sat_key'
;
UPDATE ws_table_attributes
SET    ta_text_1   = 'Version=08010;sbtype=Set;sansijoin=TRUE;Select_Hint:~;Update~;Minus_Update:;Update_Hint:TABLOCK~;Insert~;Minus_Insert:;Insert_Hint:TABLOCK~;HISNullSupport=TRUE;'
WHERE ta_obj_key IN (select -1 * ot_type_key from dbo.ws_obj_type where ot_description in ('Dimension','Fact Table','Data Store','EDW 3NF','Hub','Satellite','Link','File Format','Extensions'))
AND    ta_type      = 'M' 
;
-- set default Export template 
MERGE INTO ws_dbc_default_template AS dt
USING (select oo_obj_key from dbo.ws_obj_object where oo_name = '$snowflakeDsn') AS new_dt
      ON dt.ddt_connect_key = new_dt.oo_obj_key AND dt.ddt_table_type_key = 13  
WHEN MATCHED THEN 
UPDATE SET dt.ddt_connect_key = (select oo_obj_key from dbo.ws_obj_object where oo_name = '$snowflakeDsn'),
           dt.ddt_table_type_key = 13,
           dt.ddt_template_key = (select oo_obj_key from dbo.ws_obj_object where oo_name = 'wsl_snowflake_pscript_export' and oo_type_key = 4),
           ddt_operation_type = 5
WHEN NOT MATCHED THEN
INSERT (ddt_connect_key, ddt_table_type_key,ddt_template_key,ddt_operation_type) 
VALUES ((select oo_obj_key from dbo.ws_obj_object where oo_name = '$snowflakeDsn'),13,(select oo_obj_key from dbo.ws_obj_object where oo_name = 'wsl_snowflake_pscript_export' and oo_type_key = 4),5)
;
-- set DefLoadScriptCon on Snowflake 
UPDATE ws_dbc_connect
SET dc_attributes = (CASE 
                      WHEN CHARINDEX('DefLoadScriptCon~=', CAST(dc_attributes AS VARCHAR(4000))) > 0 THEN 
                        SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), 1, CHARINDEX('DefLoadScriptCon~=', CAST(dc_attributes AS VARCHAR(4000))) - 1) 
                        + 'DefLoadScriptCon~=0030;Runtime Connection for Scripts;' 
                        + SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoadScriptCon~=',CAST(dc_attributes AS VARCHAR(4000))) + LEN('DefLoadScriptCon~=') + ( (CHARINDEX(';', CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoadScriptCon~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoadScriptCon~='))) - (CHARINDEX('DefLoadScriptCon~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoadScriptCon~=')) ) + 1 + CAST(SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoadScriptCon~=', CAST(dc_attributes AS VARCHAR(4000))) + LEN('DefLoadScriptCon~='), ( (CHARINDEX(';', CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoadScriptCon~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoadScriptCon~='))) - (CHARINDEX('DefLoadScriptCon~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoadScriptCon~=')) )) AS int) + 1, LEN(CAST(dc_attributes AS VARCHAR(4000)))) 
                      ELSE 
                        CAST(dc_attributes AS VARCHAR(4000)) + 'DefLoadScriptCon~=0030;Runtime Connection for Scripts;' 
                    END)
WHERE  dc_name = '$snowflakeDsn' 
;
-- set DefLoad on Snowflake   
UPDATE ws_dbc_connect
SET dc_attributes = (CASE 
                      WHEN CHARINDEX('DefLoad~=', CAST(dc_attributes AS VARCHAR(4000))) > 0 THEN 
                        SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), 1, CHARINDEX('DefLoad~=', CAST(dc_attributes AS VARCHAR(4000))) - 1) 
                        + 'DefLoad~=0013;Database link;' 
                        + SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000))) + LEN('DefLoad~=') + ( (CHARINDEX(';', CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoad~='))) - (CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoad~=')) ) + 1 + CAST(SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoad~=', CAST(dc_attributes AS VARCHAR(4000))) + LEN('DefLoad~='), ( (CHARINDEX(';', CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoad~='))) - (CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoad~=')) )) AS int) + 1, LEN(CAST(dc_attributes AS VARCHAR(4000)))) 
                      ELSE 
                        CAST(dc_attributes AS VARCHAR(4000)) + 'DefLoad~=0013;Database link;' 
                    END)
WHERE  dc_name = '$snowflakeDsn' 
;
-- set DefLoadScriptCon on 'Database Source System' 
UPDATE ws_dbc_connect
SET dc_attributes = (CASE 
                      WHEN CHARINDEX('DefLoadScriptCon~=', CAST(dc_attributes AS VARCHAR(4000))) > 0 THEN 
                        SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), 1, CHARINDEX('DefLoadScriptCon~=', CAST(dc_attributes AS VARCHAR(4000))) - 1) 
                        + 'DefLoadScriptCon~=0030;Runtime Connection for Scripts;' 
                        + SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoadScriptCon~=',CAST(dc_attributes AS VARCHAR(4000))) + LEN('DefLoadScriptCon~=') + ( (CHARINDEX(';', CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoadScriptCon~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoadScriptCon~='))) - (CHARINDEX('DefLoadScriptCon~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoadScriptCon~=')) ) + 1 + CAST(SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoadScriptCon~=', CAST(dc_attributes AS VARCHAR(4000))) + LEN('DefLoadScriptCon~='), ( (CHARINDEX(';', CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoadScriptCon~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoadScriptCon~='))) - (CHARINDEX('DefLoadScriptCon~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoadScriptCon~=')) )) AS int) + 1, LEN(CAST(dc_attributes AS VARCHAR(4000)))) 
                      ELSE 
                        CAST(dc_attributes AS VARCHAR(4000)) + 'DefLoadScriptCon~=0030;Runtime Connection for Scripts;' 
                    END)
WHERE  dc_name = 'Database Source System'
;
-- set DefLoad on 'Database Source System'   
UPDATE ws_dbc_connect
SET dc_attributes = (CASE 
                      WHEN CHARINDEX('DefLoad~=', CAST(dc_attributes AS VARCHAR(4000))) > 0 THEN 
                        SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), 1, CHARINDEX('DefLoad~=', CAST(dc_attributes AS VARCHAR(4000))) - 1) 
                        + 'DefLoad~=0017;Script based load;' 
                        + SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000))) + LEN('DefLoad~=') + ( (CHARINDEX(';', CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoad~='))) - (CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoad~=')) ) + 1 + CAST(SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoad~=', CAST(dc_attributes AS VARCHAR(4000))) + LEN('DefLoad~='), ( (CHARINDEX(';', CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoad~='))) - (CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoad~=')) )) AS int) + 1, LEN(CAST(dc_attributes AS VARCHAR(4000)))) 
                      ELSE 
                        CAST(dc_attributes AS VARCHAR(4000)) + 'DefLoad~=0017;Script based load;' 
                    END)
WHERE  dc_name = 'Database Source System' 
;
-- set DefLoad on 'Range Table Location'   
UPDATE ws_dbc_connect
SET dc_attributes = (CASE 
                      WHEN CHARINDEX('DefLoad~=', CAST(dc_attributes AS VARCHAR(4000))) > 0 THEN 
                        SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), 1, CHARINDEX('DefLoad~=', CAST(dc_attributes AS VARCHAR(4000))) - 1) 
                        + 'DefLoad~=0009;ODBC load;' 
                        + SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000))) + LEN('DefLoad~=') + ( (CHARINDEX(';', CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoad~='))) - (CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoad~=')) ) + 1 + CAST(SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoad~=', CAST(dc_attributes AS VARCHAR(4000))) + LEN('DefLoad~='), ( (CHARINDEX(';', CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoad~='))) - (CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoad~=')) )) AS int) + 1, LEN(CAST(dc_attributes AS VARCHAR(4000)))) 
                      ELSE 
                        CAST(dc_attributes AS VARCHAR(4000)) + 'DefLoad~=0009;ODBC load;' 
                    END)
WHERE  dc_name = 'Range Table Location' 
;
-- set DefLoad on Windows Connections   
UPDATE ws_dbc_connect
SET dc_attributes = (CASE 
                      WHEN CHARINDEX('DefLoad~=', CAST(dc_attributes AS VARCHAR(4000))) > 0 THEN 
                        SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), 1, CHARINDEX('DefLoad~=', CAST(dc_attributes AS VARCHAR(4000))) - 1) 
                        + 'DefLoad~=0017;Script based load;' 
                        + SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000))) + LEN('DefLoad~=') + ( (CHARINDEX(';', CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoad~='))) - (CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoad~=')) ) + 1 + CAST(SUBSTRING(CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoad~=', CAST(dc_attributes AS VARCHAR(4000))) + LEN('DefLoad~='), ( (CHARINDEX(';', CAST(dc_attributes AS VARCHAR(4000)), CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoad~='))) - (CHARINDEX('DefLoad~=',CAST(dc_attributes AS VARCHAR(4000)))+LEN('DefLoad~=')) )) AS int) + 1, LEN(CAST(dc_attributes AS VARCHAR(4000)))) 
                      ELSE 
                        CAST(dc_attributes AS VARCHAR(4000)) + 'DefLoad~=0017;Script based load;' 
                    END)
WHERE  dc_name IN ('Runtime Connection for Scripts','Windows Comma Sep Files','Windows Fixed Width','Windows JSON Files','Windows Pipe Sep Files','Windows XML Files') 
;
-- set default load script templates
UPDATE dbo.ws_table_attributes 
SET ta_ind_1 = 4, 
    ta_val_1 = (select oo_obj_key from dbo.ws_obj_object where oo_name = 'wsl_snowflake_pscript_load' and oo_type_key = 4)
WHERE ta_obj_key IN (
    select oo_obj_key from dbo.ws_obj_object where oo_name in ('Database Source System','Runtime Connection for Scripts','Windows Comma Sep Files','Windows Fixed Width','Windows JSON Files','Windows Pipe Sep Files','Windows XML Files') 
  )
AND ta_type = 'L'
;
-- set Snowflake template defaults
UPDATE dbo.ws_table_attributes 
SET ta_ind_1 = 3,
  ta_ind_2 = 4,
	ta_ind_3 = 6,
	ta_ind_4 = 9,
	ta_val_1 = (select oo_obj_key from dbo.ws_obj_object where oo_name = 'wsl_snowflake_create_table' and oo_type_key = 4),
	ta_val_2 = (select oo_obj_key from dbo.ws_obj_object where oo_name = 'wsl_snowflake_pscript_load' and oo_type_key = 4),
  ta_val_3 = (select oo_obj_key from dbo.ws_obj_object where oo_name = 'wsl_snowflake_create_view' and oo_type_key = 4),
	ta_val_4 = (select oo_obj_key from dbo.ws_obj_object where oo_name = 'wsl_snowflake_alter_ddl' and oo_type_key = 4)
WHERE ta_obj_key = (select oo_obj_key from dbo.ws_obj_object where oo_name = '$snowflakeDsn')
AND ta_type = 'L'
;
-- set the Script Launcher Menu items
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

  $redOdbc = New-Object System.Data.Odbc.OdbcConnection
  $redOdbc.ConnectionString = "DSN=$metaDsn"
  if( ! [string]::IsNullOrEmpty($metaUser)) { $redOdbc.ConnectionString += ";UID=$metaUser" }
  if( ! [string]::IsNullOrEmpty($metaPwd))  { $redOdbc.ConnectionString += ";PWD=$metaPwd" }

  $command = New-Object System.Data.Odbc.OdbcCommand($sql,$redOdbc)
  $command.CommandTimeout = 0
  $command.CommandType = "StoredProcedure"
  $redOdbc.Open()
  [void]$command.ExecuteNonQuery()
  $redOdbc.Close()
}

# Create a RED Scheduler
$installStep=800
if ($installStep -ge $startAtStep) {
  Write-Output "`nFinal step: Installing the RED Scheduler, if this step fails you can manually install the RED Scheduler through RED Setup Administrator (ADM.exe)`n"
  $addSchedCmd =  @" 
scheduler add --service-name "$metaDsn" --scheduler-name "$schedulerName" --exe-path-name "$wslSched" --sched-log-level 2 --log-file-name "$wslSchedLog" --sched-meta-dsn-arch "$metaDsnArch" --sched-meta-dsn "$metaDsn" --sched-meta-user-name "$metaUser" --sched-meta-password "$metaPwd" --login-mode "LocalSystemAccount" --ip-service tcp --host-name "${env:COMPUTERNAME}" --output-mode json
"@
  Execute-RedCli-Command $addSchedCmd
}

Write-Output "`nINFO: Installation Complete, run RED to continue"