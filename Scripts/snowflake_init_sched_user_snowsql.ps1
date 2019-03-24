# ScriptVersion:005 MinVersion:8310 MaxVersion:* TargetType:Snowflake ModelType:* ScriptType:Powershell64
#--==============================================================================
#-- Script Name      :    snowflake_init_sched_user_snowsql
#-- Description      :    Run a "ls @~;" via snowsql to ensure snowsql has its python libraries compiled 
#-- Author           :    WhereScape
#--==============================================================================
#-- Notes / History
#-- JML v 1.0.0 2019-03-13 First Version
#--
Import-module -Name WslPowershellCommon -DisableNameChecking
Hide-Window

function Print-Log {
    try {
        $logStream.Dispose()
        $logReader = New-Object IO.StreamReader($fileAud)
        while( ! $logReader.EndOfStream) {
            [Console]::WriteLine($logReader.ReadLine())
        }
        $logReader.Dispose()
        $null = Remove-Item $fileAud
    }
    catch {}
    try {
        $errStream.Dispose()
        $errReader = New-Object IO.StreamReader($fileErr)
        while( ! $errReader.EndOfStream) {
            $host.ui.WriteErrorLine($errReader.ReadLine())
        }
        $errReader.Dispose()
        $null = Remove-Item $fileErr
    }
    catch {}
}

try {
    $fileAud = Join-Path -Path ${env:WSL_WORKDIR} -ChildPath "${env:WSL_TASK_NAME}_${env:WSL_SEQUENCE}.aud"
		$fileErr = Join-Path -Path ${env:WSL_WORKDIR} -ChildPath "${env:WSL_TASK_NAME}_${env:WSL_SEQUENCE}.err"
    $logStream = New-Object IO.StreamWriter($FileAud,$false)
    $logStream.AutoFlush = $true

		Add-Type -Path $(Join-Path -Path ${env:WSL_BINDIR} -ChildPath 'WslMetadataServiceClient.dll')
    $metaDbType = [WslMetadataServiceClient.MetaDatabaseType]::SqlServer

    ${env:SNOWSQL_ACCOUNT}    = Get-ExtendedProperty -PropertyName "SF_SNOWSQL_ACCOUNT" -TableName ${env:WSL_DATABASE}
    ${env:SNOWSQL_DATABASE}   = Get-ExtendedProperty -PropertyName "SF_SNOWSQL_DATABASE" -TableName ${env:WSL_DATABASE}
    ${env:SNOWSQL_SCHEMA}     = Get-ExtendedProperty -PropertyName "SF_SNOWSQL_SCHEMA" -TableName ${env:WSL_DATABASE}
    ${env:SNOWSQL_WAREHOUSE}  = Get-ExtendedProperty -PropertyName "SF_SNOWSQL_WAREHOUSE" -TableName ${env:WSL_DATABASE}
    ${env:SNOWSQL_USER}       = ${env:WSL_TGT_USER}
    ${env:SNOWSQL_PWD}        = ${env:WSL_TGT_PWD}
    
    $logStream.WriteLine("=================== SNOWSQL ENVIRONMENT VARIABLES ===================")
    $logStream.WriteLine("SF_SNOWSQL_ACCOUNT:       " + ${env:SNOWSQL_ACCOUNT})
    $logStream.WriteLine("SF_SNOWSQL_WAREHOUSE:     " + ${env:SNOWSQL_WAREHOUSE})
    $logStream.WriteLine("SF_SNOWSQL_DATABASE:      " + ${env:SNOWSQL_DATABASE})
    $logStream.WriteLine("SF_SNOWSQL_SCHEMA:        " + ${env:SNOWSQL_SCHEMA})
    $logStream.WriteLine("SF_SNOWSQL_USER:          " + ${env:SNOWSQL_USER})
    $logStream.WriteLine("SF_SNOWSQL_PASSWORD:      " + (New-Object string ('*', ${env:SNOWSQL_PWD}.Length)))

    $snowSqlAction = "ls @~;"
    $snowSqlCmd = "snowsql -q ""$snowSqlAction"" -o friendly=false  -o remove_comments=true -o output_format=csv -o timing=false > ""$fileErr"""
    $snowSqlRes = & $([ScriptBlock]::Create($snowSqlCmd))
    $errStream = New-Object IO.StreamWriter($FileErr,$true)

    [Console]::WriteLine("1")
    [Console]::WriteLine("Snowsql initialized successfully for the scheduler account.")
    Print-Log
}
catch {
    $logStream.WriteLine($_.Exception.Message)
    $logStream.WriteLine($_.InvocationInfo.PositionMessage)
    [Console]::WriteLine("-2")
    [Console]::WriteLine("Snowsql initialization failed")
    Print-Log
}
