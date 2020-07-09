#Run this Script as Administrator
# Set these vars to suit your environment
#.\setup_red_for_snowflake.ps1 EDW_SF_RCLI 64 " " " " EDW_SF_RCLI TEST_DRIVE_DB100 RG_DEV_LOAD RG_DEV_STAGE RG_DEV_EDW RG_DEV_DATA_VAULT Snowflake TEST_DRIVE100 wsl WHERESCAPE TEST_DRIVE_WH
$dsnName=$args[0]
If ($dsnName -eq $Null) { $dsnName = Read-Host -Prompt "Please Enter Vaild DSN"  }
$dsnArch=$args[1]
If ($dsnArch -eq $Null) { $dsnArch = Read-Host -Prompt "Please Enter Vaild DSN Arch"  }
$metaUser=$args[2]
If ($metaUser -eq $Null) { $metaUser = Read-Host -Prompt "Please Enter Vaild Meta User"  }
$metaPwd=$args[3]
If ($metaPwd -eq $Null) { $metaPwd = Read-Host -Prompt "Please Enter Vaild Meta Password"  }
$metaBase=$args[4]
If ($metaBase -eq $Null) { $metaBase = Read-Host -Prompt "Please Enter Vaild Meta DB"  }
$sfDatabase=$args[5]
If ($sfDatabase -eq $Null) { $sfDatabase = Read-Host -Prompt "Please Enter Vaild SF DB"  }
$schemaLoad =$args[6]
If ($schemaLoad -eq $Null) { $schemaLoad = Read-Host -Prompt "Please Enter Vaild Schema Load"  }
$schemaStage=$args[7]
If ($schemaStage -eq $Null) { $schemaStage = Read-Host -Prompt "Please Enter Vaild Schema Stage"  }
$schemaEdw=$args[8]
If ($schemaEdw -eq $Null) { $schemaEdw = Read-Host -Prompt "Please Enter Vaild Schema EDW"  }
$schemaDV=$args[9]
If ($schemaDV -eq $Null) { $schemaDV = Read-Host -Prompt "Please Enter Vaild Schema DV"  }
$sfDsn=$args[10]
If ($sfDsn -eq $Null) { $sfDsn = Read-Host -Prompt "Please Enter Vaild SF Dsn"  }
$sfUser=$args[11]
If ($sfUser -eq $Null) { $sfUser = Read-Host -Prompt "Please Enter Vaild SF User"  }
$sfPwd=$args[12]
If ($sfPwd -eq $Null) { $sfPwd = Read-Host -Prompt "Please Enter Vaild SF PWD"  }
$sfSnowsqlAcc=$args[13]
If ($sfSnowsqlAcc -eq $Null) { $sfSnowsqlAcc = Read-Host -Prompt "Please Enter Vaild SF SnowSql Account"  }
$sfSnowsqlWH=$args[14]
If ($sfSnowsqlWH -eq $Null) { $sfSnowsqlWH = Read-Host -Prompt "Please Enter Vaild SF WH"  }
$logLevel=9
$outputMode="json"
$redCliDir="C:\Program Files\WhereScape\RED\RedCli.exe"
$defDtmDir="C:\Program Files\WhereScape\RED\Administrator\Data Type Mappings"
$defDfsDir="C:\Program Files\WhereScape\RED\Administrator\Function Sets"
$dstDir="c:\temp\"
$schedulerName="WIN0001"
$wslSched="C:\Program Files\WhereScape\RED\WslSched.exe"
$wslSchedLog="C:\ProgramData\WhereScape\Scheduler\WslSched_redcli.log"
$defBrowserSchema="dbo"
$dtmSFFile=".\Data Type Mappings\SNOWFLAKE from File.xml"
$dtmSFFWF=".\Data Type Mappings\SNOWFLAKE from FIXED WIDTH FILE.xml"
$dtmSFXmlJson=".\Data Type Mappings\SNOWFLAKE from XML and JSON.xml"
$dtmSFSF=".\Data Type Mappings\SNOWFLAKE from SNOWFLAKE.xml"
$dtmSFSql=".\Data Type Mappings\SNOWFLAKE from SQL Server.xml"
$dtmSFDb2=".\Data Type Mappings\SNOWFLAKE from DB2.xml"
$dtmSFOra=".\Data Type Mappings\SNOWFLAKE from Oracle.xml"
$dtmSFO=".\Data Type Mappings\SNOWFLAKE from Other.xml"
$dtmSFPsql=".\Data Type Mappings\SNOWFLAKE from PostgreSQL.xml"
$dtmSFRedShift=".\Data Type Mappings\SNOWFLAKE from Redshift.xml"
$dtmSFTD=".\Data Type Mappings\SNOWFLAKE from Teradata.xml"
$dfsSF=".\Database Function Sets\Snowflake Function Set.xml"
$extProFile=".\Extended Properties\Snowflake.extprop"
$templatesFile=".\install_templates.ps1"
$optionsFile=".\Options.xml"
$sfDsn="Snowflake"
$red="WhereScape RED"
$redVersion="8.5.100"
$redLoc="C:\Program Files\WhereScape\RED\"
#Check RED Version
$getRedVersion = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  Select-Object DisplayName, DisplayVersion, InstallLocation | where DisplayName -eq $red | where DisplayVersion -eq $redVersion
$loc = $getRedVersion.InstallLocation
if ($loc -ne $redLoc) {
  Write-Warning "Please Select RED Version $redVersion"
  Exit
}
#Checking Redcli Files exist or not.
if (!(Test-Path $dtmSFFile)) {
  Write-Warning "Please Check DTM SNOWFLAKE from File does not exist"
  Exit
}
if (!(Test-Path $dtmSFFWF)) {
  Write-Warning "Please Check DTM SNOWFLAKE from FIXED WIDTH FILE does not exist"
  Exit
}
if (!(Test-Path $dtmSFXmlJson)) {
  Write-Warning "Please Check DTM SNOWFLAKE from XML and JSON File does not exist"
  Exit
}
if (!(Test-Path $dtmSFSF)) {
  Write-Warning "Please Check DTM SNOWFLAKE from SNOWFLAKE File does not exist"
  Exit
}
if (!(Test-Path $dtmSFSql)) {
  Write-Warning "Please Check DTM SNOWFLAKE from SQL Server File does not exist"
  Exit
}
if (!(Test-Path $dtmSFDb2)) {
  Write-Warning "Please Check DTM SNOWFLAKE from DB2 File does not exist"
  Exit
}
if (!(Test-Path $dtmSFOra)) {
  Write-Warning "Please Check DTM SNOWFLAKE from Oracle File does not exist"
  Exit
}
if (!(Test-Path $dtmSFO)) {
  Write-Warning "Please Check DTM SNOWFLAKE from Other File does not exist"
  Exit
}
if (!(Test-Path $dtmSFPsql)) {
  Write-Warning "Please Check DTM SNOWFLAKE from PostgreSQL File does not exist"
  Exit
}
if (!(Test-Path $dtmSFRedShift)) {
  Write-Warning "Please Check DTM SNOWFLAKE from Redshift File does not exist"
  Exit
}
if (!(Test-Path $dtmSFTD)) {
  Write-Warning "Please Check DTM SNOWFLAKE from Teradata File does not exist"
  Exit
}
if (!(Test-Path $dfsSF)) {
  Write-Warning "Please Check Function Set Snowflake File does not exist"
  Exit
}
if (!(Test-Path $extProFile)) {
  Write-Warning "Please Check Extended Properties File does not exist"
  Exit
}
if (!(Test-Path $templatesFile)) {
  Write-Warning "Please Check Templates Script File does not exist"
  Exit
}
if (!(Test-Path $optionsFile)) {
  Write-Warning "Please Check Options Xml File does not exist"
  Exit
}
#Check Snowflake Connectivity
$conn = New-Object Data.Odbc.OdbcConnection
$conn.ConnectionString= "dsn=$sfDsn;uid=$sfUser;pwd=$sfPwd;"
try { 
	if (($conn.open()) -eq $true) { 
		$conn.Close() 
		$true 
	}
} catch { 
	Write-Host $_.Exception.Message
	Write-Warning "Please Check Snowflake ODBC Connection"
	Exit
}
$cmds=@"
repository create
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
    $cmdReturn = Execute-Command "RedCli CMD" $redCliDir "$cmd $commonArgs"
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

& "$templatesFile"

#Connections commands
$conCmds=@"
connection rename --force --new-name "Runtime Connection for Scripts" --old-name "windows"
connection modify --name "Runtime Connection for Scripts" --con-type "Windows" --odbc-source-arch 32  --work-dir $dstDir --default-load-type "Script based load" --def-odbc-user Extract --admin-user-id $sfUser --admin-pwd $sfPwd
connection add --name $sfDsn --con-type "Database" --db-id $sfDatabase --odbc-source $sfDsn --odbc-source-arch $dsnArch --dtm-set-name "SNOWFLAKE from SNOWFLAKE" --db-type Custom --default-load-type "Database link" --default-load-script-con "Runtime Connection for Scripts" --def-update-script-con "Runtime Connection for Scripts" --def-pre-load-action "Truncate" --display-data-sql "SELECT * FROM `$OBJECT`$ SAMPLE (`$MAXDISPLAYDATA`$ ROWS)" --row-count-sql "SELECT COUNT(*) FROM `$OBJECT`$" --drop-table-sql "DROP TABLE `$OBJECT`$" --drop-view-sql "DROP VIEW `$OBJECT`$" --truncate-sql "TRUNCATE TABLE `$OBJECT`$" --def-browser-schema "$schemaLoad,$schemaStage,$schemaEdw,$schemaDV" --def-odbc-user Extract --def-table-alter-ddl-tem "wsl_snowflake_alter_ddl" --def-table-create-ddl-tem "wsl_snowflake_create_table" --def-view-create-ddl-tem "wsl_snowflake_create_view" --default-load-script-template "wsl_snowflake_pscript_load" --con-info-proc "wsl_snowflake_table_information" --extract-user-id $sfUser --extract-pwd $sfPwd
target add --connection-name $sfDsn --name load --database $sfDatabase --schema $schemaLoad --tree-colour #ff0000
target add --connection-name $sfDsn --name stage --database $sfDatabase --schema $schemaStage --tree-colour #4e00c0
target add --connection-name $sfDsn --name edw --database $sfDatabase --schema $schemaEdw --tree-colour #008054
target add --connection-name $sfDsn --name data_vault --database $sfDatabase --schema $schemaDV --tree-colour #c08000
connection add --name "Database Source System" --con-type ODBC --odbc-source "SET THIS VALUE" --odbc-source-arch $dsnArch --work-dir $dstDir --db-type "SQL Server" --dtm-set-name "SNOWFLAKE from SQL Server" --default-load-type "Script based load" --default-load-script-con "Runtime Connection for Scripts" --def-pre-load-action "Truncate" --def-browser-schema "SET THIS VALUE" --def-odbc-user Extract --default-load-script-template "wsl_snowflake_pscript_load"
ext-prop-value modify --object-name "Database Source System" --value-data "+" --value-name "RANGE_CONCATWORD"
connection add --name "Range Table Location" --con-type ODBC --db-id RANGE_WORK_DB --odbc-source RANGE_WORK_DB --odbc-source-arch $dsnArch --work-dir $dstDir --db-type "SQL Server" --default-load-type "ODBC load" --def-pre-load-action Truncate --def-browser-schema $defBrowserSchema --def-odbc-user Extract
target add --connection-name "Range Table Location" --name RangeTables --database RANGE_WORK_DB --schema $defBrowserSchema --tree-colour #ff57ff
connection rename --force --new-name Repository --old-name "DataWarehouse"
connection modify --name "Repository" --con-type Database --db-id $metaBase --odbc-source $metaBase --odbc-source-arch $dsnArch --work-dir $dstDir --db-type "SQL Server" --meta-repo true --notes "This connection points back to the data warehouse and is used during drag and drop operations." --default-load-type "Database link load" --function-set SNOWFLAKE --def-browser-schema $defBrowserSchema --def-odbc-user Extract
connection add --name "Windows Comma Sep Files" --con-type Windows --odbc-source-arch 32 --work-dir $dstDir --dtm-set-name "SNOWFLAKE from File" --default-load-type "Script based load" --def-odbc-user Extract --default-load-script-template "wsl_snowflake_pscript_load"
ext-prop-value modify --object-name "Windows Comma Sep Files" --value-data "FMT_RED_CSV_SKIP_GZIP_COMMA" --value-name "SF_FILE_FORMAT"
connection add --name "Windows Fixed Width" --con-type Windows --odbc-source-arch 32  --work-dir $dstDir --dtm-set-name "SNOWFLAKE from FIXED WIDTH FILE" --db-type None --default-load-type "Script based load" --def-odbc-user Extract --default-load-script-template "wsl_snowflake_pscript_load"
ext-prop-value modify --object-name "Windows Fixed Width" --value-data "FMT_RED_FIX_NOSKIP_GZIP" --value-name "SF_FILE_FORMAT"
connection add --name "Windows JSON Files" --con-type Windows --odbc-source-arch 32  --work-dir $dstDir --dtm-set-name "SNOWFLAKE from XML and JSON " --db-type None --default-load-type "Script based load" --def-odbc-user Extract --default-load-script-template "wsl_snowflake_pscript_load"
ext-prop-value modify --object-name "Windows JSON Files" --value-data "FMT_RED_JSON_GZIP" --value-name "SF_FILE_FORMAT"
connection add --name "Windows Pipe Sep Files" --con-type Windows --odbc-source-arch 32  --work-dir $dstDir --dtm-set-name "SNOWFLAKE from File" --default-load-type "Script based load" --def-odbc-user Extract --default-load-script-template "wsl_snowflake_pscript_load"
ext-prop-value modify --object-name "Windows Pipe Sep Files" --value-data "FMT_RED_CSV_SKIP_GZIP_PIPE" --value-name "SF_FILE_FORMAT"
connection add --name "Windows XML Files" --con-type Windows --odbc-source-arch 32  --work-dir $dstDir --dtm-set-name "SNOWFLAKE from XML and JSON" --default-load-type "Script based load" --def-odbc-user Extract --default-load-script-template "wsl_snowflake_pscript_load"
ext-prop-value modify --object-name "Windows XML Files" --value-data "FMT_RED_XML_GZIP" --value-name "SF_FILE_FORMAT"
ext-prop-value modify --object-name $sfDsn --value-data "+" --value-name "RANGE_CONCATWORD"
ext-prop-value modify --object-name $sfDsn --value-data False --value-name "SF_DEBUG_MODE"
ext-prop-value modify --object-name $sfDsn --value-data $sfSnowsqlAcc --value-name "SF_SNOWSQL_ACCOUNT"
ext-prop-value modify --object-name $sfDsn --value-data $sfDatabase --value-name "SF_SNOWSQL_DATABASE"
ext-prop-value modify --object-name $sfDsn --value-data $sfSnowsqlWH --value-name "SF_SNOWSQL_WAREHOUSE"
ext-prop-value modify --object-name $sfDsn --value-data "FMT_RED_CSV_NOSKIP_GZIP_PIPE" --value-name "SF_FILE_FORMAT"
ext-prop-value modify --object-name $sfDsn --value-data "TRUE" --value-name "SF_SEND_FILES_ZIPPED"
ext-prop-value modify --object-name $sfDsn --value-data 1000000 --value-name "SF_SPLIT_THRESHOLD"
ext-prop-value modify --object-name $sfDsn --value-data 1 --value-name "SF_SPLIT_COUNT"
ext-prop-value modify --object-name $sfDsn --value-data FALSE --value-name "SF_UNICODE_SUPPORT"
ext-prop-value modify --object-name $sfDsn --value-data | --value-name SF_UNLOAD_DELIMITER
ext-prop-value modify --object-name $sfDsn --value-data "''" --value-name "SF_UNLOAD_ENCLOSED_BY"
ext-prop-value modify --object-name $sfDsn --value-data # --value-name SF_UNLOAD_ESCAPE_CHAR
ext-prop-value modify --object-name $sfDsn --value-data ASCII --value-name RANGE_EXTRACT_CHARSET
ext-prop-value modify --object-name $sfDsn --value-data FALSE --value-name RANGE_FAIL_ON_THREAD_FAILURE
ext-prop-value modify --object-name $sfDsn --value-data 10 --value-name RANGE_MAX_THREAD_FAILURES
ext-prop-value modify --object-name $sfDsn --value-data 4 --value-name RANGE_THREAD_COUNT
ext-prop-value modify --object-name $sfDsn --value-data TRUE --value-name RANGE_UNLOAD_GZIP
ext-prop-value modify --object-name $sfDsn --value-data 3 --value-name RANGE_UPLOAD_MAX_RETRIES
connection set-default-template --connection-name $sfDsn --obj-type "Stage" --obj-sub-type "Stage" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_stage"
connection set-default-template --connection-name $sfDsn --obj-type "Stage" --obj-sub-type "DataVaultStage" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_dv_stage"
connection set-default-template --connection-name $sfDsn --obj-type "Stage" --obj-sub-type "WorkTable" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_stage"
connection set-default-template --connection-name $sfDsn --obj-type "ods" --obj-sub-type "DataStore" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name $sfDsn --obj-type "ods" --obj-sub-type "History" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_hist"
connection set-default-template --connection-name $sfDsn --obj-type "HUB" --obj-sub-type "Detail" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Link" --obj-sub-type "Detail" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Satellite" --obj-sub-type "History" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Normal" --obj-sub-type "Normalized" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Normal" --obj-sub-type "History" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_hist"
connection set-default-template --connection-name $sfDsn --obj-type "Dim" --obj-sub-type "ChangingDimension" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_hist"
connection set-default-template --connection-name $sfDsn --obj-type "Dim" --obj-sub-type "Dimension" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Dim" --obj-sub-type "PreviousDimension" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Dim" --obj-sub-type "RangedDimension" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Dim" --obj-sub-type "TimeDimension" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Dim" --obj-sub-type "MappingTable" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Dim" --obj-sub-type "WorkTable" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Fact" --obj-sub-type "Detail" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Agg" --obj-sub-type "Aggregate" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Agg" --obj-sub-type "Summary" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Agg" --obj-sub-type "WorkTable" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_dv_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Custom2" --obj-sub-type "Detail" --op-type "UpdateRoutine" --tem-name "wsl_snowflake_pscript_perm"
options import -f ".\Options.xml"
deployment deploy --app-number SFDATEDIM --app-version 0001 --app-directory ".\Deployment Applications\Date Dimension" --continue-ver-mismatch
deployment deploy --app-number SFFILEFMT --app-version 0001 --app-directory ".\Deployment Applications\File Formats" --continue-ver-mismatch
deployment deploy --app-number SFEXTENSIONS --app-version 0001 --app-directory ".\Deployment Applications\Extensions" --continue-ver-mismatch
deployment deploy --app-number SFJOBS --app-version 0001 --app-directory ".\Deployment Applications\Jobs" --continue-ver-mismatch
"@

foreach ($cmd in $conCmds.replace("`r`n", "`n").split("`n")) {
    $cmdReturn = Execute-Command "RedCli CMD" $redCliDir "$cmd $commonArgs"
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

#Scheduler
& $redcliDir scheduler add --service-name $dsnName --scheduler-name $schedulerName --exe-path-name "$wslSched" --sched-log-level 2 --log-file-name "$wslSchedLog" --sched-meta-dsn-arch $dsnArch --sched-meta-dsn $dsnName --sched-meta-user-name $metaUser --sched-meta-password $metaPwd --login-mode LocalSystemAccount --ip-service tcp --host-name ${env:COMPUTERNAME}

#Update Options Tool with Sql commands
$sql = @"
UPDATE ws_obj_type 
SET ot_options = SUBSTRING(CAST(ot_options AS VARCHAR(4000)),1,CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000)))-1)+'OBJTGTKEY='+(SELECT CAST(dt_target_key AS VARCHAR(10)) FROM ws_dbc_target WHERE dt_name = 'load')+';'+SUBSTRING(CAST(ot_options AS VARCHAR(4000)),CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000)))+CHARINDEX(';',SUBSTRING(CAST(ot_options AS VARCHAR(4000)),CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000))),100)),1000) 
WHERE ot_type_key IN (8,31,32)
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
     , mn_postfix   = '' 
WHERE  mn_object   = 'dim_get' 
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
     , mn_postfix   = '' 
WHERE  mn_object   = 'fact_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_KEY' 
WHERE  mn_object   = 'fact_key' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'fact_kpi_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'hub_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'HK_' 
     , mn_name   = 'Full table name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'hub_key' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'link_get' 
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
     , mn_postfix   = '' 
WHERE  mn_object   = 'normal_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'ods_get' 
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
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'satellite_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'custom1_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_key' 
WHERE  mn_object   = 'custom1_key' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'file_format_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_key' 
WHERE  mn_object   = 'file_format_key' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'custom2_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_key' 
WHERE  mn_object   = 'custom2_key' 
;
UPDATE ws_table_attributes
SET    ta_text_1   = 'Version=08010;sbtype=Set;sansijoin=TRUE;Select_Hint:~;Update~;Minus_Update:;Update_Hint:TABLOCK~;Insert~;Minus_Insert:;Insert_Hint:TABLOCK~;HISNullSupport=TRUE;'
WHERE ta_obj_key IN (-6,-5,-26,-27,-31,-32)
AND    ta_type      = 'M' 
;
UPDATE ws_table_attributes
SET    ta_text_1   = 'Version=08010;sbtype=Set;sansijoin=TRUE;Select_Hint:~;Update~;Minus_Update:;Update_Hint:TABLOCK~;Insert~;Minus_Insert:;Insert_Hint:TABLOCK~;HISNullSupport=TRUE;'
WHERE ta_obj_key IN (-28,-29,-30)
AND    ta_type      = 'M' 
;
INSERT INTO ws_dbc_default_template (ddt_connect_key, ddt_table_type_key,ddt_template_key,ddt_operation_type) VALUES (60,13,37,5)
;
UPDATE ws_dbc_connect
SET dc_attributes = 'DefLoad~=0013;Database link;DefLoadScriptCon~=0030;Runtime Connection for Scripts;DefUpdateScriptCon~=0030;Runtime Connection for Scripts;DefPreLoadAct~=0008;Truncate;DisplayDataSQL~=0053;SELECT * FROM `$OBJECT`$ SAMPLE (`$MAXDISPLAYDATA`$ ROWS);RowCountSQL~=0030;SELECT COUNT(*) FROM `$OBJECT`$ ;DropTableSQL~=0019;DROP TABLE `$OBJECT`$;DropViewSQL~=0018;DROP VIEW `$OBJECT`$;TruncateSQL~=0023;TRUNCATE TABLE `$OBJECT`$;OdbcDsnArch~=2;64;DefSch~=053;$schemaLoad,$schemaStage,$schemaEdw,$schemaDV;'
WHERE  dc_name = 'Snowflake' 
;
UPDATE ws_dbc_connect
SET dc_attributes = 'DefLoad~=0017;Script based load;DefLoadScriptCon~=0030;Runtime Connection for Scripts;OdbcDsnArch~=2;64;DefSch~=053;SET THIS VALUE'
WHERE  dc_name = 'Database Source System'
;
UPDATE ws_dbc_connect
SET dc_attributes = 'DefLoad~=0009;ODBC load;OdbcDsnArch~=2;64;'
WHERE  dc_name = 'Range Table Location' 
;
UPDATE ws_dbc_connect
SET dc_attributes = 'DefLoad~=0017;Script based load;'
WHERE  dc_name = 'Runtime Connection for Scripts' 
;
UPDATE ws_dbc_connect
SET dc_attributes = 'DefLoad~=0017;Script based load;'
WHERE  dc_name = 'Windows Comma Sep Files' 
;
UPDATE ws_dbc_connect
SET dc_attributes = 'DefLoad~=0017;Script based load;'
WHERE  dc_name = 'Windows Fixed Width' 
;
UPDATE ws_dbc_connect
SET dc_attributes = 'DefLoad~=0017;Script based load;'
WHERE  dc_name = 'Windows JSON Files' 
;
UPDATE ws_dbc_connect
SET dc_attributes = 'DefLoad~=0017;Script based load;'
WHERE  dc_name = 'Windows Pipe Sep Files' 
;
UPDATE ws_dbc_connect
SET dc_attributes = 'DefLoad~=0017;Script based load;'
WHERE  dc_name = 'Windows XML Files' 
;
"@

$redOdbc = New-Object System.Data.Odbc.OdbcConnection
$redOdbc.ConnectionString = "DSN=$dsnName"
if( ! [string]::IsNullOrEmpty($metaUser)) { $redOdbc.ConnectionString += ";UID=$metaUser" }
if( ! [string]::IsNullOrEmpty($metaPwd))  { $redOdbc.ConnectionString += ";PWD=$metaPwd" }

$command = New-Object System.Data.Odbc.OdbcCommand($sql,$redOdbc)
$command.CommandTimeout = 0
$command.CommandType = "StoredProcedure"
$redOdbc.Open()
[void]$command.ExecuteNonQuery()
$redOdbc.Close()
