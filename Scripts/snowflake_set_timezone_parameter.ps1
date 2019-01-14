# ScriptVersion:003 MinVersion:8210 MaxVersion:* TargetType:Snowflake ModelType:* ScriptType:Powershell (32-bit)
#--==============================================================================
#-- DBMS Name        :    SNOWFLAKE Custom*
#-- Block Name       :    snowflake_set_timezone_parameter
#-- Description      :    Set the timezone to be used when interacting with timestamps
#-- Author           :    Tom Kelly
#--==============================================================================
#-- Notes / History
#-- TK v 1.0.0 2018-09-20 First Version
#--
Import-Module WslPowershellCommon -DisableNameChecking

try {
    $tz = Get-ExtendedProperty -PropertyName "SF_TIMEZONE" -TableName "DIM_DATE_SF"
    if([string]::IsNullOrWhiteSpace($tz)) {
        $pValue = ""
    }
    else {
        $pValue = "ALTER SESSION SET TIMEZONE = '$tz';"
    }
    $null = WsParameterWrite -ParameterName "TIMEZONE" -ParameterValue "$pValue" -ParameterComment "Used to specify the timezone in DAILY_DATE_ROLL_SF"
}
catch {
    Write-Output -2
    Write-Output "Failed to update timezone parameter"
}

Write-Output 1
Write-Output "Timezone parameter updated to '$tz'"
