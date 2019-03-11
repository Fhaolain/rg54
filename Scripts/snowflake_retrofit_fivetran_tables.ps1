#--==============================================================================
#-- Script Name      :    snowflake_retrofit_fivetran_tables
#-- Description      :    Retrofit in any number of fivetran tables
#-- Author           :    Jason Laws
#--==============================================================================
#-- Notes / History
#-- JML v 1.0.0 2019-02-25 First Version
#--
try {
		$logFile = "${env:ProgramData}\WhereScape\RetroLoadTables\RetroLoadTables-${env:WSL_SEQUENCE}.log"
    $parserCommand = "${env:ProgramData}\WhereScape\FieldSolutions\RetroLoadTables\RetroLoadTables.exe"
    $parserArgs = "${env:WSL_SEQUENCE} ${env:WSL_META_DSN}"
    if( ! [string]::IsNullOrEmpty(${env:WSL_META_USER})) { $parserArgs += " ${env:WSL_META_USER}" }
    if( ! [string]::IsNullOrEmpty(${env:WSL_META_PWD})) { $parserArgs += " ${env:WSL_META_PWD}" }
    start-Process -Wait -FilePath $parserCommand -ArgumentList $parserArgs
    $host.ui.WriteLine("1")
    $host.ui.WriteLine("Fivetran Retrofit completed.")
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
    $host.ui.WriteLine("Fivetran Retrofit failed.")
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
