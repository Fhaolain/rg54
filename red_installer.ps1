#Run this Script as Administrator
# Set these vars to suit your environment
$dsnName="EDW_SF_RCLI"
$dsnArch="64"
$metaUser=""
$metaPwd=""
$metaBase="EDW_SF_RCLI"
$logLevel=9
$outputMode="json"
$redInstallDir="C:\Program Files\WhereScape\RED\"
$redCliPath = Join-Path -Path $redInstallDir -ChildPath "RedCli.exe"
$sfDatabase="TEST_DRIVE_DB02"
$schemaLoad ="DEV_LOAD"
$schemaStage="DEV_STAGE"
$schemaEdw="DEV_EDW"
$schemaDV="DEV_DATA_VAULT"
$sfUser="TEST_DRIVE02"
$sfPwd="Wherescape123"
$sfSnowsqlWH="TEST_DRIVE_WH"
$defDtmDir="C:\Program Files\WhereScape\RED\Administrator\Data Type Mappings"
$defDfsDir="C:\Program Files\WhereScape\RED\Administrator\Function Sets"
$dstDir="c:\temp\"
$schedulerName="WIN0001"
$cmds=@"
repository create
dtm import --default-dtm-path "$defDtmDir" --file-name ".\Data Type Mappings\SNOWFLAKE from File.xml"
dtm import --default-dtm-path "$defDtmDir" --file-name ".\Data Type Mappings\SNOWFLAKE from FIXED WIDTH FILE.xml"
dtm import --default-dtm-path "$defDtmDir" --file-name ".\Data Type Mappings\SNOWFLAKE from XML and JSON.xml"
dtm import --default-dtm-path "$defDtmDir" --file-name ".\Data Type Mappings\SNOWFLAKE from SNOWFLAKE.xml"
dtm import --default-dtm-path "$defDtmDir" --file-name ".\Data Type Mappings\SNOWFLAKE from SQL Server.xml"
dtm import --default-dtm-path "$defDtmDir" --file-name ".\Data Type Mappings\SNOWFLAKE from DB2.xml"
dtm import --default-dtm-path "$defDtmDir" --file-name ".\Data Type Mappings\SNOWFLAKE from Oracle.xml"
dtm import --default-dtm-path "$defDtmDir" --file-name ".\Data Type Mappings\SNOWFLAKE from Other.xml"
dtm import --default-dtm-path "$defDtmDir" --file-name ".\Data Type Mappings\SNOWFLAKE from PostgreSQL.xml"
dtm import --default-dtm-path "$defDtmDir" --file-name ".\Data Type Mappings\SNOWFLAKE from Redshift.xml"
dtm import --default-dtm-path "$defDtmDir" --file-name ".\Data Type Mappings\SNOWFLAKE from Teradata.xml"
dfs import --default-dfs-path "$defDfsDir" --file-name ".\Database Function Sets\Snowflake Function Set.xml"
ext-prop-definition import --file-name ".\Extended Properties\Snowflake.extprop"
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
# common RedCli arguments
$commonArgs = @" 
--meta-dsn "$dsnName" --meta-dsn-arch "$dsnArch" --meta-user-name "$metaUser" --meta-password "$metaPwd" --meta-database "$metaBase" --log-level "$logLevel" --output-mode "$outputMode"
"@
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
# main
foreach ($cmd in $cmds.replace("`r`n", "`n").split("`n")) {
    $cmdReturn = Execute-Command "RedCli CMD" $redCliPath "$cmd $commonArgs"
    $progressEnd = ($cmdReturn.stdout -split "`n" | Select-String -Pattern ',"Progress End":.+"}').Line
    if ($cmdReturn.stderr.Trim() -ne '' -or $progressEnd -notmatch 'Error Message":"","Progress End"') {
        Write-Output "Failure executing cmd: $cmd"
        Write-Output $( $progressEnd -replace '.+?"Progress End":".+?\}(.+?)','$1' )
        Exit
    }
    else {
        $batchJson = ($cmdReturn.stdout -split "`n" | Select-String -Pattern '^{"Batch":\[').Line.Trim().TrimEnd("Content-Type: application/json; charset=utf-8")
        $cmdResult = ($batchJson | ConvertFrom-Json).Batch[0].Result
        Write-Output "Result: $cmdResult Cmd: $cmd"
    }
}
& ".\install_templates.ps1"

#Connections commands
$conCmds=@"
connection add --name "Database Source System" --con-type ODBC --odbc-source "SET THIS VALUE" --odbc-source-arch 64 --work-dir $dstDir --db-type "SQL Server" --dtm-set-name "SNOWFLAKE from SQL Server" --def-load-type "Script based load" --def-load-script-con "Runtime Connection for Scripts" --def-pre-load-action "Truncate" --load-port-start 0 --load-port-end 0 --def-browser-schema "SET THIS VALUE" --create-indexes true --def-odbc-user Extract --ext-user-sec-mode Unencrypted --ext-pwd-sec-mode Unencrypted --admin-user-sec-mode Unencrypted --admin-pwd-sec-mode Unencrypted --td-wallet-user-sec-mode Unencrypted --td-wallet-string-sec-mode Unencrypted --jdbc-user-sec-mode Unencrypted --jdbc-pwd-sec-mode Unencrypted --def-load-script-tem "wsl_snowflake_pscript_load"
ext-prop-value modify --object-name "Database Source System" --value-data "+" --value-name "RANGE_CONCATWORD"
connection add --name "Range Table Location" --con-type ODBC --db-id RANGE_WORK_DB --odbc-source RANGE_WORK_DB --odbc-source-arch 64 --work-dir $dstDir --db-type "SQL Server" --def-load-type "ODBC load" --def-pre-load-action Truncate --def-browser-schema dbo --create-indexes true --def-odbc-user Extract --ext-user-sec-mode Unencrypted --ext-pwd-sec-mode Unencrypted --admin-user-sec-mode Unencrypted --admin-pwd-sec-mode Unencrypted --td-wallet-user-sec-mode Unencrypted --td-wallet-string-sec-mode Unencrypted --jdbc-user-sec-mode Unencrypted --jdbc-pwd-sec-mode Unencrypted
target add --connection-name "Range Table Location" --name RangeTables --database RANGE_WORK_DB --schema dbo --tree-colour #ff57ff
connection rename --force --new-name Repository --old-name "DataWarehouse"
connection modify --name "Repository" --con-type Database --db-id $metaBase --odbc-source $metaBase --odbc-source-arch 64 --work-dir $dstDir --db-type "SQL Server" --meta-repo true --notes "This connection points back to the data warehouse and is used during drag and drop operations." --def-load-type "Database link load" --function-set SNOWFLAKE --load-port-start 0 --load-port-end 0 --def-browser-schema dbo --create-indexes true --def-odbc-user Extract --ext-user-sec-mode Unencrypted --ext-pwd-sec-mode Unencrypted --admin-user-sec-mode Unencrypted --admin-pwd-sec-mode Unencrypted --td-wallet-user-sec-mode Unencrypted --td-wallet-string-sec-mode Unencrypted --jdbc-user-sec-mode Unencrypted --jdbc-pwd-sec-mode Unencrypted
connection rename --force --new-name "Runtime Connection for Scripts" --old-name "windows"
connection modify --name "Runtime Connection for Scripts" --con-type "Windows" --odbc-source-arch 32  --work-dir $dstDir --def-load-type "Script based load" --load-port-start 0 --load-port-end 0 --create-indexes true --def-odbc-user Extract --ext-user-sec-mode Unencrypted --ext-pwd-sec-mode Unencrypted --admin-user-sec-mode Unencrypted --admin-pwd-sec-mode Unencrypted --td-wallet-user-sec-mode Unencrypted --td-wallet-string-sec-mode Unencrypted --jdbc-user-sec-mode Unencrypted --jdbc-pwd-sec-mode Unencrypted --admin-user-id $sfUser --admin-pwd $sfPwd
connection add --name "Windows Comma Sep Files" --con-type Windows --odbc-source-arch 32 --work-dir $dstDir --dtm-set-name "SNOWFLAKE from File" --db-type None --def-load-type "Script based load" --load-port-start 0 --load-port-end 0 --create-indexes true --def-odbc-user Extract --ext-user-sec-mode Unencrypted --ext-pwd-sec-mode Unencrypted --admin-user-sec-mode Unencrypted --admin-pwd-sec-mode Unencrypted --td-wallet-user-sec-mode Unencrypted --td-wallet-string-sec-mode Unencrypted --jdbc-user-sec-mode Unencrypted --jdbc-pwd-sec-mode Unencrypted --def-load-script-tem "wsl_snowflake_pscript_load"
ext-prop-value modify --object-name "Windows Comma Sep Files" --value-data "FMT_RED_CSV_SKIP_GZIP_COMMA" --value-name "SF_FILE_FORMAT"
connection add --name "Windows Fixed Width" --con-type Windows --odbc-source-arch 32  --work-dir $dstDir --dtm-set-name "SNOWFLAKE from FIXED WIDTH FILE" --db-type None --def-load-type "Script based load" --load-port-start 0 --load-port-end 0 --create-indexes true --def-odbc-user Extract --ext-user-sec-mode Unencrypted --ext-pwd-sec-mode Unencrypted --admin-user-sec-mode Unencrypted --admin-pwd-sec-mode Unencrypted --td-wallet-user-sec-mode Unencrypted --td-wallet-string-sec-mode Unencrypted --jdbc-user-sec-mode Unencrypted --jdbc-pwd-sec-mode Unencrypted --def-load-script-tem "wsl_snowflake_pscript_load"
ext-prop-value modify --object-name "Windows Fixed Width" --value-data "FMT_RED_FIX_NOSKIP_GZIP" --value-name "SF_FILE_FORMAT"
connection add --name "Windows JSON Files" --con-type Windows --odbc-source-arch 32  --work-dir $dstDir --dtm-set-name "SNOWFLAKE from XML and JSON " --db-type None --def-load-type "Script based load" --load-port-start 0 --load-port-end 0  --create-indexes true --def-odbc-user Extract --ext-user-sec-mode Unencrypted --ext-pwd-sec-mode Unencrypted --admin-user-sec-mode Unencrypted --admin-pwd-sec-mode Unencrypted --td-wallet-user-sec-mode Unencrypted --td-wallet-string-sec-mode Unencrypted --jdbc-user-sec-mode Unencrypted --jdbc-pwd-sec-mode Unencrypted --def-load-script-tem "wsl_snowflake_pscript_load"
ext-prop-value modify --object-name "Windows JSON Files" --value-data "FMT_RED_JSON_GZIP" --value-name "SF_FILE_FORMAT"
connection add --name "Windows Pipe Sep Files" --con-type Windows --odbc-source-arch 32  --work-dir $dstDir --dtm-set-name "SNOWFLAKE from File" --db-type None --def-load-type "Script based load" --load-port-start 0 --load-port-end 0 --create-indexes true --def-odbc-user Extract --ext-user-sec-mode Unencrypted --ext-pwd-sec-mode Unencrypted --admin-user-sec-mode Unencrypted --admin-pwd-sec-mode Unencrypted --td-wallet-user-sec-mode Unencrypted --td-wallet-string-sec-mode Unencrypted --jdbc-user-sec-mode Unencrypted --jdbc-pwd-sec-mode Unencrypted --def-load-script-tem "wsl_snowflake_pscript_load"
ext-prop-value modify --object-name "Windows Pipe Sep Files" --value-data "FMT_RED_CSV_SKIP_GZIP_PIPE" --value-name "SF_FILE_FORMAT"
connection add --name "Windows XML Files" --con-type Windows --odbc-source-arch 32  --work-dir $dstDir --dtm-set-name "SNOWFLAKE from XML and JSON" --db-type None --def-load-type "Script based load" --load-port-start 0 --load-port-end 0  --create-indexes true --def-odbc-user Extract --ext-user-sec-mode Unencrypted --ext-pwd-sec-mode Unencrypted --admin-user-sec-mode Unencrypted --admin-pwd-sec-mode Unencrypted --td-wallet-user-sec-mode Unencrypted --td-wallet-string-sec-mode Unencrypted --jdbc-user-sec-mode Unencrypted --jdbc-pwd-sec-mode Unencrypted --def-load-script-tem "wsl_snowflake_pscript_load"
ext-prop-value modify --object-name "Windows XML Files" --value-data "FMT_RED_XML_GZIP" --value-name "SF_FILE_FORMAT"
connection add --name Snowflake --con-type "Database" --db-id $sfDatabase --odbc-source Snowflake --odbc-source-arch 64 --dtm-set-name "SNOWFLAKE from SNOWFLAKE" --db-type Custom --def-load-type "Database link" --def-load-script-con "Runtime Connection for Scripts" --def-update-script-con "Runtime Connection for Scripts" --def-pre-load-action "Truncate" --display-data-sql "SELECT * FROM $OBJECT$ SAMPLE ($MAXDISPLAYDATA$ ROWS)" --row-count-sql "SELECT COUNT(*) FROM $OBJECT$" --drop-table-sql "DROP TABLE $OBJECT$" --drop-view-sql "DROP VIEW $OBJECT$" --truncate-sql "TRUNCATE TABLE $OBJECT$" --def-browser-schema "RG_DEV_LOAD,RG_DEV_STAGE,RG_DEV_EDW,RG_DEV_DATA_VAULT" --def-odbc-user Extract --ext-user-sec-mode Unencrypted --ext-pwd-sec-mode Unencrypted --admin-user-sec-mode Unencrypted --admin-pwd-sec-mode Unencrypted --td-wallet-user-sec-mode Unencrypted --td-wallet-string-sec-mode Unencrypted --jdbc-user-sec-mode Unencrypted --jdbc-pwd-sec-mode Unencrypted --def-table-alter-ddl-tem "wsl_snowflake_alter_ddl" --def-table-create-ddl-tem "wsl_snowflake_create_table" --def-view-create-ddl-tem "wsl_snowflake_create_view" --def-load-script-tem "wsl_snowflake_pscript_load" --con-info-proc "wsl_snowflake_table_information" --extract-user-id $sfUser --extract-pwd $sfPwd
target add --connection-name Snowflake --name load --database $sfDatabase --schema $schemaLoad --tree-colour #ff0000
target add --connection-name Snowflake --name stage --database $sfDatabase --schema $schemaStage --tree-colour #4e00c0
target add --connection-name Snowflake --name edw --database $sfDatabase --schema $schemaEdw --tree-colour #008054
target add --connection-name Snowflake --name data_vault --database $sfDatabase --schema $schemaDV --tree-colour #c08000
ext-prop-value modify --object-name Snowflake --value-data "+" --value-name "RANGE_CONCATWORD"
ext-prop-value modify --object-name Snowflake --value-data False --value-name "SF_DEBUG_MODE"
ext-prop-value modify --object-name Snowflake --value-data "WHERESCAPE" --value-name "SF_SNOWSQL_ACCOUNT"
ext-prop-value modify --object-name Snowflake --value-data $sfDatabase --value-name "SF_SNOWSQL_DATABASE"
ext-prop-value modify --object-name Snowflake --value-data $sfSnowsqlWH --value-name "SF_SNOWSQL_WAREHOUSE"
ext-prop-value modify --object-name Snowflake --value-data "FMT_RED_CSV_NOSKIP_GZIP_PIPE" --value-name "SF_FILE_FORMAT"
ext-prop-value modify --object-name Snowflake --value-data "TRUE" --value-name "SF_SEND_FILES_ZIPPED"
ext-prop-value modify --object-name Snowflake --value-data 1000000 --value-name "SF_SPLIT_THRESHOLD"
ext-prop-value modify --object-name Snowflake --value-data 1 --value-name "SF_SPLIT_COUNT"
ext-prop-value modify --object-name Snowflake --value-data FALSE --value-name "SF_UNICODE_SUPPORT"
ext-prop-value modify --object-name Snowflake --value-data | --value-name SF_UNLOAD_DELIMITER
ext-prop-value modify --object-name Snowflake --value-data "''" --value-name "SF_UNLOAD_ENCLOSED_BY"
ext-prop-value modify --object-name Snowflake --value-data # --value-name SF_UNLOAD_ESCAPE_CHAR
ext-prop-value modify --object-name Snowflake --value-data ASCII --value-name RANGE_EXTRACT_CHARSET
ext-prop-value modify --object-name Snowflake --value-data FALSE --value-name RANGE_FAIL_ON_THREAD_FAILURE
ext-prop-value modify --object-name Snowflake --value-data 10 --value-name RANGE_MAX_THREAD_FAILURES
ext-prop-value modify --object-name Snowflake --value-data 4 --value-name RANGE_THREAD_COUNT
ext-prop-value modify --object-name Snowflake --value-data TRUE --value-name RANGE_UNLOAD_GZIP
ext-prop-value modify --object-name Snowflake --value-data 3 --value-name RANGE_UPLOAD_MAX_RETRIES
options import -f ".\REDCLI_Options.xml"
deployment deploy --app-number Objects --app-version 1 --app-directory ".\Deployment Applications\Objects" --continue-ver-mismatch
connection set-default-template --connection-name "Snowflake" --obj-type "Stage" --obj-sub-type "Stage" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_stage"
connection set-default-template --connection-name "Snowflake" --obj-type "Stage" --obj-sub-type "DataVaultStage" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_dv_stage"
connection set-default-template --connection-name "Snowflake" --obj-type "Stage" --obj-sub-type "WorkTable" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_stage"
connection set-default-template --connection-name "Snowflake" --obj-type "ods" --obj-sub-type "DataStore" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name "Snowflake" --obj-type "ods" --obj-sub-type "History" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_hist"
connection set-default-template --connection-name "Snowflake" --obj-type "HUB" --obj-sub-type "Detail" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name "Snowflake" --obj-type "Link" --obj-sub-type "Detail" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name "Snowflake" --obj-type "Satellite" --obj-sub-type "History" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name "Snowflake" --obj-type "Normal" --obj-sub-type "Normalized" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name "Snowflake" --obj-type "Normal" --obj-sub-type "History" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_hist"
connection set-default-template --connection-name "Snowflake" --obj-type "Dim" --obj-sub-type "ChangingDimension" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_hist"
connection set-default-template --connection-name "Snowflake" --obj-type "Dim" --obj-sub-type "Dimension" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name "Snowflake" --obj-type "Dim" --obj-sub-type "PreviousDimension" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name "Snowflake" --obj-type "Dim" --obj-sub-type "RangedDimension" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name "Snowflake" --obj-type "Dim" --obj-sub-type "TimeDimension" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name "Snowflake" --obj-type "Dim" --obj-sub-type "MappingTable" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name "Snowflake" --obj-type "Dim" --obj-sub-type "WorkTable" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name "Snowflake" --obj-type "Fact" --obj-sub-type "Detail" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name "Snowflake" --obj-type "Agg" --obj-sub-type "Aggregate" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name "Snowflake" --obj-type "Agg" --obj-sub-type "Summary" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name "Snowflake" --obj-type "Agg" --obj-sub-type "WorkTable" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name "Snowflake" --obj-type "Custom2" --obj-sub-type "Detail" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
"@

foreach ($cmd in $conCmds.replace("`r`n", "`n").split("`n")) {
    $cmdReturn = Execute-Command "RedCli CMD" $redCliPath "$cmd $commonArgs"
    $progressEnd = ($cmdReturn.stdout -split "`n" | Select-String -Pattern ',"Progress End":.+"}').Line
    if ($cmdReturn.stderr.Trim() -ne '' -or $progressEnd -notmatch 'Error Message":"","Progress End"') {
        Write-Output "Failure executing cmd: $cmd"
        Write-Output $( $progressEnd -replace '.+?"Progress End":".+?\}(.+?)','$1' )
        Exit
    }
    else {
        $batchJson = ($cmdReturn.stdout -split "`n" | Select-String -Pattern '^{"Batch":\[').Line.Trim().TrimEnd("Content-Type: application/json; charset=utf-8")
        $cmdResult = ($batchJson | ConvertFrom-Json).Batch[0].Result
        Write-Output "Result: $cmdResult Cmd: $cmd"
    }
}

& "C:\Program Files\WhereScape\RED\RedCli.exe" scheduler add --service-name $dsnName --scheduler-name $schedulerName --exe-path-name "C:\Program Files\WhereScape\RED\WslSched.exe" --sched-log-level 2 --log-file-name "C:\ProgramData\WhereScape\Scheduler\WslSched_redcli.log" --sched-meta-dsn-arch $dsnArch --sched-meta-dsn $dsnName --sched-meta-user-name $metaUser --sched-meta-password $metaPwd --login-mode LocalSystemAccount --ip-service tcp --host-name ${env:COMPUTERNAME}

$sql = "{ call Ws_Job_Release (?, ?, ?, ?, ?, ?, ?, ?, ?) }"
   
$redOdbc = New-Object System.Data.Odbc.OdbcConnection
$redOdbc.ConnectionString = "DSN=$dsnName"
if( ! [string]::IsNullOrEmpty($metaUser)) { $redOdbc.ConnectionString += ";UID=$metaUser" }
if( ! [string]::IsNullOrEmpty($metaPwd))  { $redOdbc.ConnectionString += ";PWD=$metaPwd" }

$command = New-Object System.Data.Odbc.OdbcCommand($sql,$redOdbc)
$command.CommandTimeout = 0
$command.CommandType = "StoredProcedure"
$param = [System.Data.Odbc.OdbcParameter]
[void]$command.Parameters.Add($(New-Object $param("@p_sequence","Int",0,"Input",$true,0,0,"","Current",1)))
[void]$command.Parameters.Add($(New-Object $param("@p_job_name","Varchar",64,"Input",$true,0,0,"","Current","Initialize Snowsql for Scheduler Account")))
[void]$command.Parameters.Add($(New-Object $param("@p_task_name","Varchar",64,"Input",$true,0,0,"","Current","snowflake_init_sched_user_snowsql")))
[void]$command.Parameters.Add($(New-Object $param("@p_job_id","Int",0,"Input",$true,0,0,"","Current",0)))
[void]$command.Parameters.Add($(New-Object $param("@p_task_id","Int",0,"Input",$true,0,0,"","Current",0)))
[void]$command.Parameters.Add($(New-Object $param("@p_release_job","Varchar",64,"Input",$true,0,0,"","Current","Daily Run")))
[void]$command.Parameters.Add($(New-Object $param("@p_return_code","Varchar",1,"Output",$true,0,0,"","Current",[DBNull]::Value)))
[void]$command.Parameters.Add($(New-Object $param("@p_return_msg","Varchar",256,"Output",$true,0,0,"","Current",[DBNull]::Value)))
[void]$command.Parameters.Add($(New-Object $param("@p_result","Int",0,"Output",$true,0,0,"","Current",[DBNull]::Value)))

$redOdbc.Open()
[void]$command.ExecuteNonQuery()
$redOdbc.Close()