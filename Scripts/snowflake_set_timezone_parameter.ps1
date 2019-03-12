# ScriptVersion:005 MinVersion:8310 MaxVersion:* TargetType:Snowflake ModelType:* ScriptType:Powershell64
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
