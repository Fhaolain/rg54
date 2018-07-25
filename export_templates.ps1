$gitProj = $PSScriptRoot

if([string]::IsNullOrEmpty($gitProj)) {
    Write-Output "Execute this script directly either from the console or with F5 from the ISE"
    Pause
}

$objectConfig = "$gitProj\objects_to_export.txt"
$connectConfig = "$gitProj\connect_info.txt"

if( ! (Test-Path $connectConfig) ) {
    $dsn = Read-Host -Prompt "DSN"
    $dsn | Set-Content $connectConfig
    
    $uid = Read-Host -Prompt "Username"
    if( ! [string]::IsNullOrWhiteSpace($uid)) {
        $uid | Add-Content $connectConfig

        $secPwd = Read-Host -Prompt "Password" -AsSecureString
        ConvertFrom-SecureString -SecureString $secPwd | Add-Content $connectConfig

    }

    Write-Output  "Connect information has been saved to '$connectConfig'"
    Write-Warning "You will not be prompted again"
    Write-Output  "Delete '$connectConfig' if you wish to be prompted for connection information"
}

$connInfo = @(Get-Content $connectConfig | Where { ! [String]::IsNullOrWhiteSpace($_) })

$dsn = $connInfo[0]
if($connInfo.Length -gt 1) {
    $uid = $connInfo[1]
    $secPwd = ConvertTo-SecureString $connInfo[2]
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secPwd)
    $pwd = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
}

$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString = "DSN=$Dsn"
if( ! [string]::IsNullOrWhiteSpace($uid)) { $conn.ConnectionString += ";UID=$uid" }
if( ! [string]::IsNullOrWhiteSpace($pwd)) { $conn.ConnectionString += ";UID=$pwd" }

if( ! (Test-Path $objectConfig) ) {
    Write-Output "Enter full or partial names of templates, procedures and scripts you wish to export to file"
    Write-Output "wsl_%"
    Write-Output "other_*"
    Write-Output "another_template"
    $input = Read-Host -Prompt "Template Name"
    $input | Set-Content $objectConfig
    
    while ( ! [string]::IsNullOrWhiteSpace($input) ) {
        $input = Read-Host -Prompt "Template Name"
        if( ! [string]::IsNullOrWhiteSpace($input) ) {
            $input | Add-Content $objectConfig
        }
    }

    Write-Output  "Choices have been saved to '$objectConfig'"
    Write-Warning "You will not be prompted again"
    Write-Output  "Delete '$objectConfig' if you wish to be prompted for template names"
}

$sql = "SELECT th_name
        FROM ws_tem_header"

$objectsToCommit = @(Get-Content $objectConfig | Where { ! [String]::IsNullOrWhiteSpace($_) })

foreach($string in $objectsToCommit) {
    if($string -eq $objectsToCommit[0]) {
        $sql += "`r`nWHERE "
    }
    else {
        $sql += "`r`nOR "
    }
    $sql += "th_name LIKE '$string'"
}

$conn.Open()
$dt = New-Object System.Data.DataTable
$null = (New-Object System.Data.Odbc.OdbcDataAdapter($sql,$conn)).Fill($dt)
$conn.Close()

if( ! (Test-Path "${gitProj}\Templates")) {
    New-Item -ItemType Directory -Path "${gitProj}\Templates"
}

foreach ($object in $dt) {
    
    Write-Output "Exporting template: $($object.th_name)"

    try {

        $sw = New-Object System.IO.StreamWriter("${gitProj}\Templates\$($object.th_name).txt",$false,(New-Object System.Text.UTF8Encoding($False)))
        $sw.AutoFlush = $true

        $query = "select replace(replace(tl_line,char(10),''),char(13),'') 
                  from ws_tem_line 
                  join ws_tem_header 
                  on tl_obj_key = th_obj_key 
                  where th_name = '$($object.th_name)'
                  order by tl_line_no"

        $conn.open()

        $reader = (New-Object System.Data.Odbc.OdbcCommand($query,$conn)).ExecuteReader()

        while ( $reader.Read() ) {
            $sw.WriteLine($reader.GetValue(0))
        }
    
    }
    catch {

        $host.ui.WriteErrorLine("Export of template '$($object.th_name)' failed.")
        $host.ui.WriteErrorLine($_.Exception.Message)

    }
    finally {

        try { $sw.close() } catch {}
        try { $reader.close() } catch {}
        try { $conn.close() } catch {}

    }

}

pause