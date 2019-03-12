# ScriptVersion:005 MinVersion:8310 MaxVersion:* TargetType:Snowflake ModelType:* ScriptType:Powershell64
#--==============================================================================
#-- Script Name      :    snowflake_parse_json_load_tables
#-- Description      :    Parse a JSON load table into one or more stage tables
#-- Author           :    Jason Laws
#--==============================================================================
#-- Notes / History
#-- JML v 1.0.0 2019-02-19 First Version
#--
try {
    $logFile = "${env:ProgramData}\WhereScape\JsonParser\JsonParser-${env:WSL_SEQUENCE}.log"
    $parserCommand = "${env:ProgramData}\WhereScape\FieldSolutions\JsonParser\JsonParser.exe"
    $parserArgs = "${env:WSL_SEQUENCE} ${env:WSL_META_DSN}"
    if( ! [string]::IsNullOrEmpty(${env:WSL_META_USER})) { $parserArgs += " ${env:WSL_META_USER}" }
    if( ! [string]::IsNullOrEmpty(${env:WSL_META_PWD})) { $parserArgs += " ${env:WSL_META_PWD}" }
    start-Process -Wait -FilePath $parserCommand -ArgumentList $parserArgs
    $host.ui.WriteLine("1")
    $host.ui.WriteLine("Json Parser completed.")
    try {
        $host.ui.WriteLine("Loading log file: $logFile")
        $logReader = New-Object IO.StreamReader($logFile)
        while( ! $logReader.EndOfStream) {
            $host.ui.WriteLine($logReader.ReadLine())
        }
        $logReader.Dispose()
        $null = Remove-Item $fileAud
    }
    catch {}
}
catch {
    $host.ui.WriteLine("-3")
    $host.ui.WriteLine("Json Parser failed.")
    $host.ui.WriteLine("An unhandled exception occurred.")
    $host.ui.WriteLine($_.Exception.Message)
    $host.ui.WriteLine($_.InvocationInfo.PositionMessage)
    try {
        $host.ui.WriteLine("Loading log file: $logFile")
        $logReader = New-Object IO.StreamReader($logFile)
        while( ! $logReader.EndOfStream) {
            $host.ui.WriteLine($logReader.ReadLine())
        }
        $logReader.Dispose()
    }
    catch {}
}
