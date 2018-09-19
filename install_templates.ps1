$gitProj = $PSScriptRoot

if([string]::IsNullOrEmpty($gitProj)) {
    Write-Output "Execute this script directly either from the console or with F5 from the ISE"
    Pause
}

$objectConfig = "$gitProj\objects_to_install.txt"
$connectConfig = "$gitProj\connect_info.txt"

if( ! (Test-Path $connectConfig) ) {
    $dsn = Read-Host -Prompt "DSN"
    $dsn | Set-Content $connectConfig
    
    $uid = Read-Host -Prompt "Username"
    if( ! [string]::IsNullOrEmpty($uid)) {
        $uid | Add-Content $connectConfig

        $secPwd = Read-Host -Prompt "Password" -AsSecureString
        $outFmt = ConvertFrom-SecureString -SecureString $secPwd
        $outFmt | Add-Content $connectConfig

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
if( ! [string]::IsNullOrWhiteSpace($pwd)) { $conn.ConnectionString += ";PWD=$pwd" }

if( ! (Test-Path $objectConfig) ) {
    Write-Output "Enter full or partial names of templates you wish to install"
    Write-Output "wsl_%"
    Write-Output "other_*"
    Write-Output "another_template"
    Write-Output "Templates must exist in '$gitProj\Templates'"
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

$objectsToInstall = @(Get-Content $objectConfig | Where { ! [String]::IsNullOrWhiteSpace($_) })

$conn.Open()

foreach($objectMatch in $objectsToInstall) {
    $objectMatch = $objectMatch.Replace('%','*')
    $objects = Get-ChildItem "$gitProj\Templates\$objectMatch"

    foreach($object in $objects) {

        try {

            $trans = $conn.BeginTransaction()

            $command = New-Object System.Data.Odbc.OdbcCommand
            $command.Connection = $conn
            $command.Transaction = $trans

            $objectName = $object.Name.Replace(".txt","")
            $objectPath = $object.FullName

            $ws_obj_object_ss1 = "SELECT count(oo_name) FROM dbo.ws_obj_object WHERE oo_name = '$objectName'"
            $command.CommandText = $ws_obj_object_ss1
            $ws_obj_object_sr1 = $command.ExecuteScalar()

            $exists = $false

            if($ws_obj_object_sr1 -gt 0) {
                $ws_obj_object_ss2 = "SELECT count(oo_name) FROM dbo.ws_obj_object WHERE oo_name = '$objectName' AND oo_type_key = 4"
                $command.CommandText = $ws_obj_object_ss2
                $ws_obj_object_sr2 = $command.ExecuteScalar()

                if($ws_obj_object_sr2 -gt 0) {
                    $exists = $true
                }
                else {
                    Write-Warning "Object with name '$objectName' already exists but is not a template. Skipping"
                    $trans.Rollback()
                    Continue
                }
            }

            if($exists) {
                Write-Output "Template with name '$objectName' already exists and will be versioned"

                $ws_obj_object_ss4 = "SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = '$objectName'"
                $command.CommandText = $ws_obj_object_ss4
                $ws_obj_object_sr4 = $command.ExecuteScalar()
                $objectKey = $ws_obj_object_sr4

                $ws_tem_header_v_ss1 = "SELECT coalesce(max(th_version_no),0) + 1 FROM ws_tem_header_v"
                $command.CommandText = $ws_tem_header_v_ss1
                $ws_tem_header_v_sr1 = $command.ExecuteScalar()

                $versionKey = $ws_tem_header_v_sr1

                $ws_tem_header_v_is1 = @"
                  INSERT INTO ws_tem_header_v (
                      th_version_no
                    , th_obj_key
                    , th_name
                    , th_purpose
                    , th_type
                    , th_created
                    , th_updated
                    , th_author
                    , th_user_key
                    , th_status
                  )
                  SELECT
                      $versionKey
                    , th_obj_key
                    , th_name
                    , th_purpose
                    , th_type
                    , th_created
                    , th_updated
                    , th_author
                    , th_user_key
                    , th_status
                  FROM ws_tem_header
                  WHERE th_name = '$objectName'
"@
                $command.CommandText = $ws_tem_header_v_is1
                $ws_tem_header_v_ir1 = $command.ExecuteNonQuery()

                $ws_tem_line_v_is1 = @"
                  INSERT INTO ws_tem_line_v ( 
                      tl_version_no
                    , tl_obj_key
                    , tl_line_no
                    , tl_line
                  )
                  SELECT
                      $versionKey
                    , tl_obj_key
                    , tl_line_no
                    , tl_line
                  FROM ws_tem_line
                  JOIN ws_tem_header
                  ON tl_obj_key = th_obj_key
                  WHERE th_name = '$objectName'
"@
                $command.CommandText = $ws_tem_line_v_is1
                $ws_tem_line_v_ir1 = $command.ExecuteNonQuery()

                $ws_obj_versions_is1 = @"
                  INSERT INTO ws_obj_versions (
                      ov_version_no
                    , ov_obj_key
                    , ov_obj_name
                    , ov_obj_type_key
                    , ov_version_description
                    , ov_creation_date
                    , ov_retain_till_date
                    , ov_target_key
                  )
                  VALUES (
                      $versionKey
                    , $objectKey
                    , '$objectName'
                    , 4
                    , 'Auto version on replace by template installer script'
                    , CURRENT_TIMESTAMP
                    , CAST(CAST(DATEADD(YEAR, 10, CURRENT_TIMESTAMP) AS DATE) AS DATETIME)
                    , 0
                  )
"@
                $command.CommandText = $ws_obj_versions_is1
                $ws_obj_versions_ir1 = $command.ExecuteNonQuery()

                $ws_tem_line_ds1 = "DELETE FROM ws_tem_line WHERE tl_obj_key = ( SELECT th_obj_key FROM ws_tem_header WHERE th_name = '$objectName' )"
                $command.CommandText = $ws_tem_line_ds1
                $ws_tem_line_dr1 = $command.ExecuteNonQuery()

            }
            else {
                Write-Output "Installing '$objectName'"

                $sw = [System.IO.File]::OpenText($objectPath)
                $header = $sw.ReadLine()
                $sw.Close()

                $header = $header.Replace("{# --","").Replace("-- #}","").Trim()
                $headConf = $header.Split(" ")
                try { $targetType = $headConf | Where { $_.IndexOf("TargetType:") -ne -1 } | ForEach-Object { $_.Replace("TargetType:","") } } catch {}
                try { $templateType = $headConf | Where { $_.IndexOf("TemplateType:") -ne -1 } | ForEach-Object { $_.Replace("TemplateType:","") } } catch {}

                if($targetType -eq "SQLServer") {
                    $ta_val_1 = 2
                }
                else {
                    $ta_val_1 = 13
                }

                if($templateType -eq "Alter") {
                    $th_type = "a"
                }
                elseif($templateType -eq "DDL") {
                    $th_type = "6"
                }
                elseif($templateType -eq "Powershell") {
                    $th_type = "5"
                }
                elseif($templateType -eq "Utility") {
                    $th_type = "7"
                }
                elseif($templateType -eq "Unix") {
                    $th_type = "1"
                }
                elseif($templateType -eq "Linux") {
                    $th_type = "1"
                }
                elseif($templateType -eq "Windows") {
                    $th_type = "3"
                }
                elseif($templateType -eq "OLAP") {
                    $th_type = "2"
                }
                elseif($templateType -eq "Block") {
                    $th_type = "8"
                }
                elseif($templateType -eq "Procedure") {
                    $th_type = "9"
                }
                else {
                    Write-Warning "Failed to extract template type from template header. Falling back to Powershell"
                    $th_type = "5"
                }

                $ws_obj_object_is1 = @"
                  INSERT INTO ws_obj_object (
                      oo_name
                    , oo_type_key
                    , oo_group_key
                    , oo_project_key
                    , oo_active
                    , oo_target_key
                  )
                  VALUES (
                      '$objectName'
                    , 4
                    , 0
                    , 0
                    , 'Y'
                    , 0
                  )
"@
                $command.CommandText = $ws_obj_object_is1
                $ws_obj_object_ir1 = $command.ExecuteNonQuery()

                $ws_obj_object_ss3 = "SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = '$objectName'"
                $command.CommandText = $ws_obj_object_ss3
                $ws_obj_object_sr3 = $command.ExecuteScalar()
                $objectKey = $ws_obj_object_sr3

                $ws_tem_header_is1 = @"
                  INSERT INTO ws_tem_header (
                      th_obj_key
                    , th_name
                    , th_type
                    , th_created
                    , th_updated
                    , th_author
                  )
                  VALUES (
                      $objectKey
                    , '$objectName'
                    , '$th_type'
                    , CURRENT_TIMESTAMP
                    , CURRENT_TIMESTAMP
                    , 'WhereScape Ltd'
                  )
"@
                $command.CommandText = $ws_tem_header_is1
                $ws_tem_header_ir1 = $command.ExecuteNonQuery()

                $ws_table_attributes_is1 = @"
                  INSERT INTO ws_table_attributes (
                      ta_obj_key
                    , ta_type
                    , ta_ind_1
                    , ta_val_1
                  )
                  VALUES (
                      $objectKey
                    , 'F'
                    , 'W'
                    , $ta_val_1
                  )
"@

                $command.CommandText = $ws_table_attributes_is1
                $ws_table_attributes_ir1 = $command.ExecuteNonQuery()

            }

            $sr = New-Object System.IO.StreamReader($objectPath)

            $lineNo = 0

            while( ! $sr.EndOfStream ) {
                $lineNo ++
                $objectLine = $sr.ReadLine()
                $dbCompatible = "'" + $objectLine.Replace("'","''") + "'"

                $ws_tem_line_is1 = @"
                  INSERT INTO ws_tem_line (
                      tl_obj_key
                    , tl_line_no
                    , tl_line
                  )
                  VALUES (
                      $objectKey
                    , $lineNo
                    , $dbCompatible + CHAR(13)
                  )
"@
                $command.CommandText = $ws_tem_line_is1
                $ws_tem_line_ir1 = $command.ExecuteNonQuery()

            }

            $sr.Close()

            $ws_tem_header_us1 = "UPDATE ws_tem_header SET th_updated = CURRENT_TIMESTAMP WHERE th_name = '$objectName'"
            $command.CommandText = $ws_tem_header_us1
            $ws_tem_header_ur1 = $command.ExecuteScalar()

            $trans.Commit()
        }
        catch {
            try { $trans.Rollback() } catch {}
            try { $sr.Dispose() } catch {}
            $host.ui.WriteErrorLine("Failed to install template '$objectName'")
            $host.ui.WriteErrorLine($_.Exception.Message)
            $host.ui.WriteErrorLine($_.InvocationInfo.PositionMessage)
        }
    }
}

$conn.Close()

pause