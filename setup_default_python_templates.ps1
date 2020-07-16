#Run this Script as Administrator
# Set these vars to suit your environment
#.\setup_default_python_templates.ps1 EDW_SF_RCLI 64 " " " " EDW_SF_RCLI Snowflake
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
$sfDsn=$args[5]
If ($sfDsn -eq $Null) { $sfDsn = Read-Host -Prompt "Please Enter Vaild SF Dsn"  }
$logLevel=9
$outputMode="json"
$redCliDir="C:\Program Files\WhereScape\RED\RedCli.exe"
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

$cmds=@"
connection set-default-template --connection-name $sfDsn --obj-type "Stage" --obj-sub-type "Stage" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_stage"
connection set-default-template --connection-name $sfDsn --obj-type "Stage" --obj-sub-type "DataVaultStage" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_dv_stage"
connection set-default-template --connection-name $sfDsn --obj-type "Stage" --obj-sub-type "WorkTable" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_stage"
connection set-default-template --connection-name $sfDsn --obj-type "ods" --obj-sub-type "DataStore" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
connection set-default-template --connection-name $sfDsn --obj-type "ods" --obj-sub-type "History" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_hist"
connection set-default-template --connection-name $sfDsn --obj-type "HUB" --obj-sub-type "Detail" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_dv_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Link" --obj-sub-type "Detail" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_dv_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Satellite" --obj-sub-type "History" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_dv_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Normal" --obj-sub-type "Normalized" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Normal" --obj-sub-type "History" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_hist"
connection set-default-template --connection-name $sfDsn --obj-type "Dim" --obj-sub-type "ChangingDimension" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_hist"
connection set-default-template --connection-name $sfDsn --obj-type "Dim" --obj-sub-type "Dimension" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Dim" --obj-sub-type "PreviousDimension" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Dim" --obj-sub-type "RangedDimension" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Dim" --obj-sub-type "TimeDimension" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Dim" --obj-sub-type "MappingTable" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Dim" --obj-sub-type "WorkTable" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Fact" --obj-sub-type "Detail" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_dv_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Agg" --obj-sub-type "Aggregate" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_dv_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Agg" --obj-sub-type "Summary" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_dv_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Agg" --obj-sub-type "WorkTable" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_dv_perm"
connection set-default-template --connection-name $sfDsn --obj-type "Custom2" --obj-sub-type "Detail" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
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

$sql = @"
UPDATE ws_dbc_default_template
SET ddt_template_key = 108
WHERE  ddt_table_type_key = 13
;
UPDATE dbo.ws_table_attributes 
SET ta_ind_1 = 4, 
      ta_val_1 = 110
WHERE ta_obj_key IN (60,3,62,63,64,65,66)
AND ta_type = 'L'
;
UPDATE dbo.ws_table_attributes 
SET ta_val_2 = 110
WHERE ta_obj_key = 59
AND ta_type = 'L'
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
