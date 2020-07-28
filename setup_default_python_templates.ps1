param (
  $unmatchedParameter,
  [switch]$help=$false,
  [string]$metaDsn,
  [string]$metaDsnArch='64',
  [string]$metaUser='',
  [string]$metaPwd='',
  [string]$metaBase,
  [string]$snowflakeDsn,
  [int]$startAtStep=1
)

#--==============================================================================
#-- Script Name      :    setup_default_python_templates.ps1
#-- Description      :    Update Default Templates To Python Templates
#-- Author           :    WhereScape Inc
#--==============================================================================
#-- Notes / History
#-- MME v 1.0.0 2020-07-21 First Version

# Print script help msg
Function Print-Help {
  $helpMsg = @"

This Update Default Python Templates script must be run as admininstrator.

Pre-requisites before running this script: 
  1. WhereScape Enablement Pack install script should be installed.

Any required paramters will be prompted for at run-time, otherwise enter each named paramter as arguments:  

Example:.\setup_default_python_templates.ps1 -metaDsn "REDMetaRepoDSN" -metaUser "REDMetaRepoUser" -metaPwd "REDMetaRepoPwd" -metaBase "REDMetaRepoDB" -snowflakeDsn "SnowflakeDSN"

Available Parameters:
  -help                   "Displays this help message"
  -metaDsn                "RED MetaRepo DSN"                [REQUIRED]
  -metaDsnArch            "64 or 32"                        [DEFAULT = 64]
  -metaUser               "RED MetaRepo User"               [OMITTED FOR WINDOWS AUTH]
  -metaPwd                "RED MetaRepo PW"                 [OMITTED FOR WINDOWS AUTH]
  -metaBase               "RED MetaRepo DB"                 [REQUIRED]
  -snowflakeDsn           "Snowflake DSN"                   [REQUIRED]
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
  if([string]::IsNullOrEmpty($snowflakeDsn))            {$snowflakeDsn = Read-Host -Prompt "Enter Snowflake Connection Name"}
  # Output the command line used to the host (passwords replced with '***')
  Write-Host "`nINFO: Run Parameters: -metaDsn '$metaDsn' -metaDsnArch '$metaDsnArch' $( if(![string]::IsNullOrEmpty($metaUser)){"-metaUser '$metaUser' -metaPwd '***' "})-metaBase '$metaBase' -snowflakeDsn '$snowflakeDsn' -startAtStep $startAtStep`n"
}


$logLevel=5
$outputMode="json"

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

# common RedCli arguments
$commonRedCliArgs = @" 
--meta-dsn "$metaDsn" --meta-dsn-arch "$metaDsnArch" --meta-user-name "$metaUser" --meta-password "$metaPwd" --meta-database "$metaBase" --log-level "$logLevel" --output-mode "$outputMode"
"@

$pyDefTempSetupCmds=@"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Stage" --obj-sub-type "Stage" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_stage"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Stage" --obj-sub-type "DataVaultStage" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_dv_stage"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Stage" --obj-sub-type "WorkTable" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_stage"
connection set-default-template --connection-name $snowflakeDsn --obj-type "ods" --obj-sub-type "DataStore" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
connection set-default-template --connection-name $snowflakeDsn --obj-type "ods" --obj-sub-type "History" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_hist"
connection set-default-template --connection-name $snowflakeDsn --obj-type "HUB" --obj-sub-type "Detail" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_dv_perm"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Link" --obj-sub-type "Detail" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_dv_perm"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Satellite" --obj-sub-type "History" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_dv_perm"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Normal" --obj-sub-type "Normalized" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Normal" --obj-sub-type "History" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_hist"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Dim" --obj-sub-type "ChangingDimension" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_hist"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Dim" --obj-sub-type "Dimension" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Dim" --obj-sub-type "PreviousDimension" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Dim" --obj-sub-type "RangedDimension" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Dim" --obj-sub-type "TimeDimension" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Dim" --obj-sub-type "MappingTable" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Dim" --obj-sub-type "WorkTable" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Fact" --obj-sub-type "Detail" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_dv_perm"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Agg" --obj-sub-type "Aggregate" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_dv_perm"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Agg" --obj-sub-type "Summary" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_dv_perm"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Agg" --obj-sub-type "WorkTable" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_dv_perm"
connection set-default-template --connection-name $snowflakeDsn --obj-type "Custom2" --obj-sub-type "Detail" --op-type "UpdateRoutine" --template-name "wsl_snowflake_pyscript_perm"
"@

Function Remove-Passwords ($stringWithPwds) { 
  $stringWithPwdsRemoved = $stringWithPwds
  if (![string]::IsNullOrEmpty($metaPwd)){ 
    $stringWithPwdsRemoved = $stringWithPwdsRemoved -replace "(`"|`'| ){1}$metaPwd(`"|`'| |$){1}",'$1***$2'
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
#             MAIN SETUP BEGINS
#
# ---------------------------------------------------------------------------------------------------

# Run Python setup commands
$installStep=100
$cmdArray = $pyDefTempSetupCmds.replace("`r`n", "`n").split("`n")  
for($i=0; $i -lt $cmdArray.Count; $i++) {
  $global:installStep++
  if ($installStep -ge $startAtStep) {
    Execute-RedCli-Command $cmdArray[$i] $commonRedCliArgs
  }
}

#Update with SQL Commands
$installStep=200
if ($installStep -ge $startAtStep) {
  $sql = @"
UPDATE ws_dbc_default_template
SET ddt_template_key = (select oo_obj_key from dbo.ws_obj_object where oo_name = 'wsl_snowflake_pyscript_export' and oo_type_key = 4)
WHERE  ddt_table_type_key = (select ot_type_key from dbo.ws_obj_type where ot_description = 'Export')
;
UPDATE dbo.ws_table_attributes 
SET ta_ind_1 = 4, 
    ta_val_1 = (select oo_obj_key from dbo.ws_obj_object where oo_name = 'wsl_snowflake_pyscript_load' and oo_type_key = 4)
WHERE ta_obj_key IN (
    select oo_obj_key from dbo.ws_obj_object where oo_name in ('Database Source System','Runtime Connection for Scripts','Windows Comma Sep Files','Windows Fixed Width','Windows JSON Files','Windows Pipe Sep Files','Windows XML Files') 
  )
AND ta_type = 'L'
;
UPDATE dbo.ws_table_attributes 
SET ta_val_2 = (select oo_obj_key from dbo.ws_obj_object where oo_name = 'wsl_snowflake_pyscript_load' and oo_type_key = 4)
WHERE ta_obj_key = (select oo_obj_key from dbo.ws_obj_object where oo_name = '$snowflakeDsn')
AND ta_type = 'L'
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
