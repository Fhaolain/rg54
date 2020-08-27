# ScriptVersion:005 MinVersion:8310 MaxVersion:* TargetType:Snowflake ModelType:* ScriptType:Powershell64
#--==============================================================================
#-- Script Name      :    snowflake_create_range_table
#-- Description      :    Pick a load table and create a range table for it
#-- Author           :    WhereScape
#--==============================================================================
#-- Notes / History
#-- JML v 1.0.0 2018-10-16 First Version
#-- JML v 1.0.1 2018-10-26 Improved debug logging and encrypted password handling
#-- JML v 1.0.2 2018-10-29 Adding handling for ODBC timeouts
#-- JML v 1.0.3 2019-03-01 Added optional support for SQL Server range tables
#-- JML v 1.0.4 2019-03-13 Made parameter names consistent
#-- 

Import-module -Name WslPowershellCommon -DisableNameChecking

function Print-Log {
    Param (
        $exitStatus
    )

    try {
        $logStream.Dispose()
        $logReader = New-Object IO.StreamReader($fileAud)

        while( ! $logReader.EndOfStream) {
            $host.ui.WriteLine($logReader.ReadLine())
        }

        $logReader.Dispose()
        if(${env:DEBUG} -ne "TRUE" ) {
            $null = Remove-Item $fileAud
        }
    }
    catch {}

    if ( $exitStatus -ne 1 ) {
        try {
            $errStream.Dispose()
            $errReader = New-Object IO.StreamReader($fileErr)

            while( ! $errReader.EndOfStream) {
                $host.ui.WriteErrorLine($errReader.ReadLine())
            }

            $errReader.Dispose()
            if(${env:DEBUG} -ne "TRUE" ) {
                $null = Remove-Item $fileErr
            }
        }
        catch {}
    }
}

function GET-LOADTABLES {

    $query = @"
        SELECT lt_table_name
        FROM   ws_load_tab
        JOIN   ws_dbc_connect
        ON     lt_connect_key = dc_obj_key
        WHERE  dc_type IN ('D','O')
        AND    lt_table_name NOT IN (SELECT tab1.lt_table_name
                                     FROM   ws_load_tab tab1
                                     JOIN   ws_ext_prop_value
                                     ON     tab1.lt_obj_key = epv_obj_key
                                     JOIN   ws_ext_prop_def
                                     ON     epv_def_key = epd_key
                                     JOIN   ws_load_tab tab2
                                     ON     epv_value = tab2.lt_table_name
                                     WHERE  epd_display_name = 'RANGE_PILOT_TABLE')
        AND    lt_table_name NOT IN (SELECT epv_value
                                     FROM   ws_ext_prop_def
                                     JOIN   ws_ext_prop_value
                                     ON     epd_key = epv_def_key
                                     JOIN   ws_load_tab
                                     ON     epv_value = lt_table_name
                                     WHERE  epd_display_name = 'RANGE_PILOT_TABLE')
        ORDER BY 1
"@

    try {
        $command = New-Object System.Data.Odbc.OdbcCommand($query,$metaOdbc)
        $command.CommandTimeout = 0
        $adapter = New-Object System.Data.Odbc.OdbcDataAdapter($command)
        $loadTableList = New-Object System.Data.DataTable
        $null = $adapter.fill($loadTableList)
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Load Table List query failed")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Load Table List query failed")
        Print-Log -exitStatus -2
        exit
    }

    if($loadTableList.Rows.Count -eq 0) {
        if($loopcntr -gt 1) {
            $logStream.WriteLine("${debugWord}No load tables without range tables remain in metadata.")
            $host.ui.WriteLine("1")
            $host.ui.WriteLine("No load tables without range tables remain in metadata.")
            Print-Log -exitStatus 1
            exit
        }
        else {
            $logStream.WriteLine("${debugWord}No load tables in metadata.")
            $host.ui.WriteLine("-1")
            $host.ui.WriteLine("No load tables in metadata.")
            Print-Log -exitStatus -1
            exit
        }
    }

    return , $loadTableList

}

function GET-LOADCOLUMNS {
    Param(
        $loadTable
    )

    $query = @"
        SELECT lc_col_name
        FROM   ws_load_tab
        JOIN   ws_load_col
        ON     lt_obj_key = lc_obj_key
        WHERE  lt_table_name = '$loadTable'
        ORDER BY lc_order
"@

    try {
        $command = New-Object System.Data.Odbc.OdbcCommand($query,$metaOdbc)
        $command.CommandTimeout = 0
        $adapter = New-Object System.Data.Odbc.OdbcDataAdapter($command)
        $loadColumnList = New-Object System.Data.DataTable
        $null = $adapter.fill($loadColumnList)
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Load Column List query failed")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Load Column List query failed")
        Print-Log -exitStatus -2
        exit
    }

    return , $loadColumnList

}

function GUI {

    $loadTableList = GET-LOADTABLES

    Add-Type -AssemblyName System.Windows.Forms
    $MyForm = New-Object system.Windows.Forms.Form
    $MyForm.Text = "Create Range Table"
    $MyForm.AutoScroll = $True
    $MyForm.MinimizeBox = $False
    $MyForm.MaximizeBox = $False
    $MyForm.WindowState = "Normal"
    $MyForm.SizeGripStyle = "Hide"
    $MyForm.ShowInTaskbar = $False
    $MyForm.StartPosition = "CenterScreen"
    $MyForm.Width = 460
    $MyIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("${env:WSL_BINDIR}med.exe")
    $MyForm.Icon = $MyIcon

    $Location = New-Object System.Drawing.Point

    $TabColLabel = New-Object System.Windows.Forms.Label
    $Location.X = 20
    $Location.Y = 15
    $TabColLabel.Location = $Location
    $TabColLabel.Text = "Please select the load table and column that need a range table:"
    $TabColLabel.AutoSize = $True
    $MyForm.Controls.Add($TabColLabel)

    $ColumnBinding = New-Object System.Windows.Forms.BindingSource
    $ColumnCombo = New-Object System.Windows.Forms.ComboBox

    $TableCombo = New-Object System.Windows.Forms.ComboBox
    $Location.X = 25
    $Location.Y = $Location.Y + 20
    $TableCombo.Location = $Location
    $TableCombo.Width = 400
    $TableCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $TableCombo.Add_SelectedIndexChanged({$MyForm.ActiveControl = $MyForm.Controls.Item(1)})
    $TableCombo.DataSource = [array]($loadTableList.lt_table_name)
    $TableCombo.Add_SelectedIndexChanged( {
        $MyForm.ActiveControl = $MyForm.Controls.Item(1)
        $loadTable = $TableCombo.Items[$TableCombo.SelectedIndex]
        $RangeTableBox.Text = "RANGE_" + $loadTable
        $loadColumnList = GET-LOADCOLUMNS -loadTable $loadTable
        $ColumnBinding.DataSource = [array]($loadColumnList.lc_col_name)
        $ColumnCombo.ResetBindings()
    })
    $loadTable = $loadTableList.Rows[0].lt_table_name
    $MyForm.Controls.Add($TableCombo)

    $Location.X = 25
    $Location.Y = $Location.Y + 30
    $ColumnCombo.Location = $Location
    $ColumnCombo.Width = 400
    $ColumnCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $loadColumnList = GET-LOADCOLUMNS -loadTable $loadTable
    $ColumnBinding.DataSource = [array]($loadColumnList.lc_col_name)
    $ColumnBinding.ResetBindings($false)
    $ColumnCombo.DataSource = $ColumnBinding
    $ColumnCombo.Add_SelectedIndexChanged( {
        $MyForm.ActiveControl = $MyForm.Controls.Item(2)
    })
    $MyForm.Controls.Add($ColumnCombo)

    $RangeLabel = New-Object System.Windows.Forms.Label
    $Location.X = 20
    $Location.Y = $Location.Y + 40
    $RangeLabel.Location = $Location
    $RangeLabel.Text = "Enter the new range table name:"
    $RangeLabel.AutoSize = $True
    $MyForm.Controls.Add($RangeLabel)

    $RangeTableBox = New-Object System.Windows.Forms.TextBox
    $Location.X = 25
    $Location.Y = $Location.Y + 20
    $RangeTableBox.Location = $Location
    $RangeTableBox.Width = 400
    $RangeTableBox.Text = "RANGE_" + $loadTable
    $MyForm.Controls.Add($RangeTableBox)

    $ProfileCheckBox = New-Object System.Windows.Forms.CheckBox
    $CountLabel = New-Object System.Windows.Forms.Label
    $LengthLabel = New-Object System.Windows.Forms.Label
    $CardinalityLabel = New-Object System.Windows.Forms.Label
    $CountBox = New-Object System.Windows.Forms.TextBox
    $LengthBox = New-Object System.Windows.Forms.TextBox
    $CardinalityBox = New-Object System.Windows.Forms.TextBox

    $Location.X = 25
    $Location.Y = $Location.Y + 40
    $ProfileCheckBox.Location = $Location
    $ProfileCheckBox.Text = "Profile Source Table to fetch row count, row length and cardinality"
    $ProfileCheckBox.AutoSize = $True
    $ProfileCheckBox.Add_CheckStateChanged( {
        if($ProfileCheckBox.Checked -eq $false) {
            $CountLabel.Enabled = $true
            $LengthLabel.Enabled = $true
            $CardinalityLabel.Enabled = $true
            $CountBox.Enabled = $true
            $LengthBox.Enabled = $true
            $CardinalityBox.Enabled = $true
        }
        else {
            $CountLabel.Enabled = $false
            $LengthLabel.Enabled = $false
            $CardinalityLabel.Enabled = $false
            $CountBox.Enabled = $false
            $LengthBox.Enabled = $false
            $CardinalityBox.Enabled = $false
        }
    })
    $($ProfileCheckBox).Checked = $true
    $MyForm.Controls.Add($ProfileCheckBox)

    $Location.X = 20
    $Location.Y = $Location.Y + 25
    $CountLabel.Location = $Location
    $CountLabel.Text = "Row Count"
    $CountLabel.AutoSize = $True
    $CountLabel.Enabled = $false
    $MyForm.Controls.Add($CountLabel)

    $Location.X = 160
    $LengthLabel.Location = $Location
    $LengthLabel.Text = "Row Length"
    $LengthLabel.AutoSize = $True
    $LengthLabel.Enabled = $false
    $MyForm.Controls.Add($LengthLabel)

    $Location.X = 300
    $CardinalityLabel.Location = $Location
    $CardinalityLabel.Text = "Cardinality"
    $CardinalityLabel.AutoSize = $True
    $CardinalityLabel.Enabled = $false
    $MyForm.Controls.Add($CardinalityLabel)

    $Location.X = 25
    $Location.Y = $Location.Y + 20
    $CountBox.Location = $Location
    $CountBox.Width = 120
    $CountBox.Text = ""
    $CountBox.Enabled = $false
    $CountBox.add_TextChanged( {
        if($CountBox.Text -match '\D'){
            $CountBox.Text = $CountBox.Text -replace '\D'
            if($CountBox.Text.Length -gt 0){
                $CountBox.Focus()
                $CountBox.SelectionStart = $CountBox.Text.Length
            }
        }
    })
    $MyForm.Controls.Add($CountBox)

    $Location.X = 165
    $LengthBox.Location = $Location
    $LengthBox.Width = 120
    $LengthBox.Text = ""
    $LengthBox.Enabled = $false
    $LengthBox.add_TextChanged( {
        if($LengthBox.Text -match '\D'){
            $LengthBox.Text = $LengthBox.Text -replace '\D'
            if($LengthBox.Text.Length -gt 0){
                $LengthBox.Focus()
                $LengthBox.SelectionStart = $LengthBox.Text.Length
            }
        }
    })
    $MyForm.Controls.Add($LengthBox)

    $Location.X = 305
    $CardinalityBox.Location = $Location
    $CardinalityBox.Width = 120
    $CardinalityBox.Text = ""
    $CardinalityBox.Enabled = $false
    $CardinalityBox.add_TextChanged( {
        if($CardinalityBox.Text -match '\D'){
            $CardinalityBox.Text = $CardinalityBox.Text -replace '\D'
            if($CardinalityBox.Text.Length -gt 0){
                $CardinalityBox.Focus()
                $CardinalityBox.SelectionStart = $CardinalityBox.Text.Length
            }
        }
    })
    $MyForm.Controls.Add($CardinalityBox)

    $MyOKButton = New-Object System.Windows.Forms.Button
    $Location.X = ($MyForm.Width / 2) - 1.25*$MyOKButton.Width
    $Location.Y = $Location.Y + 50
    $MyOKButton.Location = $Location
    $MyOKButton.Text = "OK"
    $MyOKButton.Add_Click({$MyForm.DialogResult = "OK"})
    $MyForm.Controls.Add($MyOKButton)

    $MyCancelButton = New-Object System.Windows.Forms.Button
    $Location.X = ($MyForm.Width / 2) + 0.25*$MyCancelButton.Width
    $MyCancelButton.Location = $Location
    $MyCancelButton.Text = "Cancel"
    $MyCancelButton.Add_Click({$MyForm.DialogResult = "CANCEL"})
    $MyForm.Controls.Add($MyCancelButton)

    $MyForm.Height = $Location.Y + 75

    if ( $MyForm.ShowDialog() -eq "OK" ) {
        $loadTable = $TableCombo.Items[$TableCombo.SelectedIndex]
        $rangeTable = $RangeTableBox.Text
        $rangeColumn = $ColumnCombo.Items[$ColumnCombo.SelectedIndex]
        if($ProfileCheckBox.Checked -eq $false) {
            $rowCount = $CountBox.Text
            $avgRowLength = $LengthBox.Text
            $rangeCardinality = $CardinalityBox.Text
        }
        else {
            $rowCount = 1
            $avgRowLength = 1
            $rangeCardinality = 1
        }

        return $loadTable, $rangeTable, $rangeColumn, $ProfileCheckBox.Checked, $rowCount, $avgRowLength, $rangeCardinality
    }
    else {
        $host.ui.WriteLine("1")
        $host.ui.WriteLine("Script completed successfully")
        $logStream.WriteLine("${debugWord}GUI Cancelled")
        Print-Log -exitStatus 1
        exit
    }


}

function GET-SRC-PWD-ENC {

    # Generate query to see if passwords for source are encypted
    #
    $sSql = @"
      SELECT CASE WHEN ma_val_2 = '1' THEN 'Y' ELSE 'N' END AS encPwd
      FROM   ws_meta_admin
      WHERE  ma_type = 'E'
"@
    $encPwd = "N"
    try {
        $metaOdbc.Open()
        $command = New-Object System.Data.Odbc.OdbcCommand($sSql,$metaOdbc)
        $command.CommandTimeout = 0
        $encPwd = $command.ExecuteScalar()
        $metaOdbc.Close()
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Failed to check for password encryption.")
        $errStream.WriteLine("Passwords are encrypted: $encPwd")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Failed to check for password encryption.")
        Print-Log -exitStatus -2
        exit
    }

    return $encPwd
}

function GET-SRCPWD {

    Add-Type -Assembly 'System.Windows.Forms'

    $MyForm= New-Object Windows.Forms.Form
    $MyForm.MinimizeBox = $False
    $MyForm.MaximizeBox = $False
    $MyForm.WindowState = "Normal"
    $MyForm.SizeGripStyle = "Hide"
    $MyForm.ShowInTaskbar = $False
    $MyForm.StartPosition = "CenterScreen"
    $MyForm.Width = 360
    $MyForm.Text = "Enter Source System Password"
    $MyIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("${env:WSL_BINDIR}med.exe")
    $MyForm.Icon = $MyIcon
    
    $Location = New-Object System.Drawing.Point
    $Location.X = 20
    $Location.Y = 15

    $MyPasswordBox = New-Object Windows.Forms.MaskedTextBox
    $MyPasswordBox.PasswordChar = '*'
    $MyPasswordBox.Location = $Location
    $MyPasswordBox.Width = 300
    $MyForm.Controls.Add($MyPasswordBox)

    $MyOKButton = New-Object System.Windows.Forms.Button
    $Location.X = ($MyForm.Width / 2) - 1.25*$MyOKButton.Width
    $Location.Y = $Location.Y + 50
    $MyOKButton.Location = $Location
    $MyOKButton.Text = "OK"
    $MyOKButton.Add_Click({$MyForm.DialogResult = "OK"})
    $MyForm.Controls.Add($MyOKButton)

    $MyCancelButton = New-Object System.Windows.Forms.Button
    $Location.X = ($MyForm.Width / 2) + 0.25*$MyCancelButton.Width
    $MyCancelButton.Location = $Location
    $MyCancelButton.Text = "Cancel"
    $MyCancelButton.Add_Click({$MyForm.DialogResult = "CANCEL"})
    $MyForm.Controls.Add($MyCancelButton)

    $MyForm.Height = $Location.Y + 75

    if ( $MyForm.ShowDialog() -eq "OK" ) {
        $sourcePwd = $MyPasswordBox.Text
        return , $sourcePwd
    }
    else {
        $host.ui.WriteLine("1")
        $host.ui.WriteLine("Script completed successfully")
        $logStream.WriteLine("${debugWord}PWD Cancelled")
        Print-Log -exitStatus 1
        exit
    }
}

function GET-SOURCE-METADATA {

    # Generate Metadata select to get various connectivity information
    #
    $sMetaSql = @"
      SELECT CASE dbc1.dc_db_type_ind
                  WHEN 0 THEN 'local'
                  WHEN 1 THEN SUBSTRING(dbc1.dc_attributes,CHARINDEX('Notes~=',dbc1.dc_attributes)+12,CAST(SUBSTRING(dbc1.dc_attributes,CHARINDEX('Notes~=',dbc1.dc_attributes)+7,4) AS INTEGER))
                  WHEN 2 THEN 'SQL Server'
                  WHEN 3 THEN 'DB2'
                  WHEN 4 THEN 'Teradata'
                  WHEN 5 THEN 'Oracle'
                  WHEN 6 THEN 'Netezza'
                  WHEN 7 THEN 'Greenplum'
                  ELSE 'Unknown'
                  END AS source_db_type
           , lt_source_schema AS source_schema
           , lt_source_table AS source_table
           , dbc1.dc_odbc_source AS source_odbc
           , dbc1.dc_extract_userid AS source_user
           , dbc1.dc_extract_pwd AS source_pwd
           , lc_src_column AS source_column
           , dc_name AS source_connection
      FROM   ws_load_tab
      JOIN   ws_dbc_connect dbc1
      ON     lt_connect_key = dbc1.dc_obj_key
      JOIN   ws_obj_object
      ON     lt_obj_key = oo_obj_key
      JOIN   ws_load_col
      ON     lt_obj_key = lc_obj_key
      WHERE  lt_table_name = '$loadTable'
      AND    lc_col_name = '$rangeColumn'
      ORDER BY 1
"@

    try {
        $metaOdbc.Open()
        $command = New-Object System.Data.Odbc.OdbcCommand($sMetaSql,$metaOdbc)
        $command.CommandTimeout = 0
        $adapter = New-Object System.Data.Odbc.OdbcDataAdapter($command)
        $mdt = New-Object System.Data.DataTable
        $null = $adapter.fill($mdt)
        $metaOdbc.Close()
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Metadata query failed")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Metadata query failed")
        Print-Log -exitStatus -2
        exit
    }

    if($mdt.Rows.Count -eq 0) {
        $logStream.WriteLine("${debugWord}No compatible tables available")
        $host.ui.WriteLine("-1")
        $host.ui.WriteLine("No compatible tables available")
        Print-Log -exitStatus -1
        exit
    }

    $sourceDbType = $mdt.Rows[0].source_db_type
    $sourceSchema = $mdt.Rows[0].source_schema
    $sourceTable = $mdt.Rows[0].source_table
    $sourceOdbc = $mdt.Rows[0].source_odbc
    $sourceUser = $mdt.Rows[0].source_user
    $sourcePwd = $mdt.Rows[0].source_pwd
    $sourceColumn = $mdt.Rows[0].source_column
    $sourceConnection = $mdt.Rows[0].source_connection

    if($sourceDbType -eq "local") {
        $logStream.WriteLine("${debugWord}Source connection cannot be local, exiting.")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Source connection cannot be local, exiting.")
        Print-Log -exitStatus -2
        exit
    }

    $logStream.WriteLine("${debugWord}Source database type: $sourceDbType")

    return $sourceDbType, $sourceSchema, $sourceTable, $sourceOdbc, $sourceUser, $sourcePwd, $sourceColumn, $sourceConnection

}

function GET-ROWCOUNT {

    # Get source table row count
    #
    $sCountSql = "SELECT COUNT(*) AS row_count FROM $sourceSchema.$sourceTable"
    $rowCount = 1
    try {
        $srcOdbc.Open()
        $command = New-Object System.Data.Odbc.OdbcCommand($sCountSql,$srcOdbc)
        $command.CommandTimeout = 0
        $rowCount = $command.ExecuteScalar()
        $srcOdbc.Close()
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Failed to get source table row count ($sourceSchema.$sourceTable)")
        $errStream.WriteLine("Row count SQL: $sCountSql")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Failed to fetch row count from ($sourceSchema.$sourceTable)")
        Print-Log -exitStatus -2
        exit
    }
    $logStream.WriteLine("${debugWord}The source table has:  $rowCount rows")

    return $rowCount
}

function GET-ROWLENGTH {

    # Get the average row length of the first 200 rows of the source table
    #
    if($sourceDbType -eq "Teradata") {
        $sRowLengthSql = "SELECT TOP 250 * FROM $sourceSchema.$sourceTable"
    }
    elseif($sourceDbType -eq "Oracle") {
        $sRowLengthSql = "SELECT * FROM $sourceSchema.$sourceTable WHERE rownum<=250"
    }
    elseif($sourceDbType -eq "SQL Server") {
        $sRowLengthSql = "SELECT TOP 250 * FROM $sourceSchema.$sourceTable"
    }
    elseif($sourceDbType -eq "Redshift") {
        $sRowLengthSql = "SELECT TOP 250 * FROM $sourceSchema.$sourceTable"
    }
    elseif($sourceDbType -eq "Vertica") {
        $sRowLengthSql = "SELECT * FROM $sourceSchema.$sourceTable LIMIT 250"
    }
    elseif($sourceDbType -eq "Netezza") {
        $sRowLengthSql = "SELECT * FROM $sourceSchema.$sourceTable LIMIT 250"
    }
    elseif($sourceDbType -eq "Greenplum") {
        $sRowLengthSql = "SELECT * FROM $sourceSchema.$sourceTable LIMIT 250"
    }
    elseif($sourceDbType -eq "PostgreSQL") {
        $sRowLengthSql = "SELECT * FROM $sourceSchema.$sourceTable LIMIT 250"
    }
    elseif($sourceDbType -eq "DB2") {
        $sRowLengthSql = "SELECT * FROM $sourceSchema.$sourceTable WHERE FETCH FIRST 250 ROWS ONLY"
    }
    $avgRowLength = 1
    try {
        $srcOdbc.Open()
        $command = New-Object System.Data.Odbc.OdbcCommand($sRowLengthSql,$srcOdbc)
        $command.CommandTimeout = 0
        $reader = $command.ExecuteReader()
        $counter = 0
        $dataLength = 0
        $maxRowLength = 0
        while ($reader.Read() -And $counter -lt 200)
        {
            $counter++
            $rowLength = 0
            for ( $col = 0; $col -lt $reader.FieldCount; $col++ )
            {
                try {
                    $rowLength = $rowLength + [String]$reader.GetString($col).length + 1
                }
                catch {
                    $rowLength = $rowLength + 1
                }
            }
            $dataLength = $dataLength + $rowLength + 2
            if ( $rowLength -gt $maxRowLength ) {
                $maxRowLength = $rowLength
            }
        }
        if ( $counter -gt 0 )
        {
            $avgRowLength = $dataLength / $counter
        }
        $srcOdbc.Close()
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Failed to fetch data to calculate row length for $sourceSchema.$sourceTable")
        $errStream.WriteLine("Row Length SQL: $sRowLengthSql")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Failed to fetch data to calculate row length for $sourceSchema.$sourceTable")
        Print-Log -exitStatus -2
        exit
    }
    $maxRowLength = $maxRowLength * 3

    $logStream.WriteLine("${debugWord}The average row length is $([int]$avgRowLength) bytes.")
    if(${env:DEBUG} -eq "TRUE") {
        $logStream.WriteLine("DEBUG: The data length for the first $counter rows is: $dataLength bytes.")
        $logStream.WriteLine("DEBUG: The maximum row length is $maxRowLength bytes.")
        $logStream.WriteLine("DEBUG: The maximum row length including contingency is $maxRowLength bytes.")
    }
    return $avgRowLength, $maxRowLength
}

function GET-CARDINALITY {

    # Get cardinality of range column
    #
    $sCardinalitySql = "SELECT COUNT(DISTINCT($sourceColumn)) FROM $sourceSchema.$sourceTable"
    $rangeCardinality = 1
    try {
        $srcOdbc.Open()
        $command = New-Object System.Data.Odbc.OdbcCommand($sCardinalitySql,$srcOdbc)
        $command.CommandTimeout = 0
        $rangeCardinality = $command.ExecuteScalar()
        $srcOdbc.Close()
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Failed to get range column cardinality ($sourceSchema.$sourceTable.$sourceColumn)")
        $errStream.WriteLine("Cardinality SQL: $sCardinalitySql")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Failed to fetch cardinality from ($sourceSchema.$sourceTable.$sourceColumn)")
        Print-Log -exitStatus -2
        exit
    }
    $logStream.WriteLine("${debugWord}The source table range column has cardinality:  $rangeCardinality rows")

    return $rangeCardinality
}

function GET-OPTIMAL-FILESIZE {
    $metaOdbc.Open()
    $optimalFileSize = [decimal](((WsParameterRead "RANGE_OPTIMAL_FILE_SIZE")[0]) | out-string).Trim()
    if ( $optimalFileSize -eq 0 ) {
        $optimalFileSize = 100
        $logStream.WriteLine("${debugWord}Optimal File Size defaulted to:  $optimalFileSize Mb")
    }
    else {
        $logStream.WriteLine("${debugWord}Optimal File Size:  $optimalFileSize Mb")
    }
    $metaOdbc.Close()
    return $optimalFileSize
}

function GET-COMPRESSION-RATE {
    $metaOdbc.Open()
    $compressionRate = [decimal](((WsParameterRead "RANGE_COMPRESSION_RATE")[0]) | out-string).Trim()
    if ( $compressionRate -eq 0 ) {
        $compressionRate = 5
        $logStream.WriteLine("${debugWord}Expected File Compression Rate defaulted to:  $compressionRate X")
    }
    else {
        $logStream.WriteLine("${debugWord}Expected File Compression Rate:  $compressionRate X")
    }
    $metaOdbc.Close()
    return $compressionRate
}

function GET-RANGE-CONNECTION {
    $metaOdbc.Open()
    $rangeWorkConnection = (((WsParameterRead "RANGE_WORK_CONNECTION")[0]) | out-string).Trim()
    $logStream.WriteLine("${debugWord}Range Table Connection is:  $rangeWorkConnection")
    $metaOdbc.Close()
    return $rangeWorkConnection
}

function GET-RANGE-TARGET {
    $metaOdbc.Open()
    $rangeWorkTarget = (((WsParameterRead "RANGE_WORK_TARGET")[0]) | out-string).Trim()
    $logStream.WriteLine("${debugWord}Range Table Connection is:  $rangeWorkTarget")
    $metaOdbc.Close()
    return $rangeWorkTarget
}

function GET-RANGE-TABLE-LOCATION {
    $metaOdbc.Open()
    $rangeLocation = (((WsParameterRead "RANGE_WORK_TABLE_LOCATION")[0]) | out-string).Trim()
    $logStream.WriteLine("${debugWord}Range Table Location is:  $rangeLocation")
    $metaOdbc.Close()
    return $rangeLocation
}

function GET-TARGET-KEY
{

    # Generate Metadata select to get various connectivity information
    #
    $sMetaSql = @"
      SELECT dt_target_key
      FROM ws_dbc_target
      JOIN ws_dbc_connect
      ON dt_connect_key = dc_obj_key
      WHERE dc_name = '$rangeConnection'
      AND dt_name = '$rangeTarget'
"@

    try {
        $metaOdbc.Open()
        $command = New-Object System.Data.Odbc.OdbcCommand($sMetaSql,$metaOdbc)
        $command.CommandTimeout = 0
        $adapter = New-Object System.Data.Odbc.OdbcDataAdapter($command)
        $mdt = New-Object System.Data.DataTable
        $null = $adapter.fill($mdt)
        $metaOdbc.Close()
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Target key query failed")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Target key query failed")
        Print-Log -exitStatus -2
        exit
    }

    if($mdt.Rows.Count -eq 0) {
        $logStream.WriteLine("${debugWord}Connection and Target do not exist")
        $host.ui.WriteLine("-1")
        $host.ui.WriteLine("Connection and Target do not exist")
        Print-Log -exitStatus -1
        exit
    }

    $targetKey = $mdt.Rows[0].dt_target_key

    $logStream.WriteLine("${debugWord}Target key is: $targetKey")

    return $targetKey
}

function GET-SOURCE-DATATYPE {

    # Generate source database SELECT to get data type of incremental looping column
    #
    if($sourceDbType -eq "Teradata") {
        $sColTypeSql = @"
          SELECT CASE ColumnType
            WHEN 'DA' THEN 'date'
            WHEN 'TS' THEN 'timestamp'
            WHEN 'SZ' THEN 'timestamp'
            ELSE 'unknown'
            END AS DATATYPE
          FROM dbc.ColumnsV
          WHERE DatabaseName = '$sourceSchema'
          AND TableName = '$sourceTable'
          AND ColumnName = '$sourceColumn'
"@
    }
    elseif ($sourceDbType -eq "Oracle") {
        $sColTypeSql = @"
          SELECT data_type AS DATATYPE
          FROM all_tab_columns
          WHERE owner = UPPER('$sourceSchema')
          AND table_name = UPPER('$sourceTable')
          AND column_name = UPPER('$sourceColumn')
"@
    }
    elseif ($sourceDbType -eq "SQL Server") {
        $sColTypeSql = @"
          SELECT typ.name AS DATATYPE
          FROM sys.columns col
          JOIN sys.types typ
          ON col.system_type_id = typ.system_type_id
          AND col.user_type_id = typ.user_type_id
          WHERE OBJECT_SCHEMA_NAME(col.[object_id]) = '$sourceSchema'
          AND OBJECT_NAME(col.[object_id]) = '$sourceTable'
          AND col.name = '$sourceColumn'
"@
    }
    elseif ($sourceDbType -eq "Redshift") {
        $sColTypeSql = @"
          SELECT c.udt_name AS DATATYPE
          FROM information_schema.columns c
          WHERE c.table_schema = '$sourceSchema'
          AND c.table_name = '$sourceTable'
          AND c.column_name = '$sourceColumn'
"@
    }
    elseif ($sourceDbType -eq "Vertica") {
        $sColTypeSql = @"
          SELECT SUBSTR(c.data_type,1,(CASE WHEN INSTR(c.data_type,'(')=0 THEN 1000 ELSE INSTR(c.data_type,'(')-1 END)) AS DATATYPE
          FROM v_catalog.columns c
          WHERE c.table_schema = '$sourceSchema'
          AND c.table_name = '$sourceTable'
          AND c.column_name = '$sourceColumn'
"@
    }
    elseif ($sourceDbType -eq "Netezza") {
        $sColTypeSql = @"
          SELECT CASE SUBSTRING(C.DATA_TYPE,0,COALESCE(NULLIF(INSTR(C.DATA_TYPE,'('),0),LENGTH(C.DATA_TYPE) + 1))
            WHEN 'TIMESTAMP' THEN 'timestamp'
            WHEN 'DATE' THEN 'date'
            ELSE SUBSTRING(C.DATA_TYPE,0,COALESCE(NULLIF(INSTR(C.DATA_TYPE,'('),0),LENGTH(C.DATA_TYPE) + 1))
            END as DATATYPE
          FROM INFORMATION_SCHEMA.COLUMNS C
          WHERE C.table_schema = '$sourceSchema'
          AND C.table_name = '$sourceTable'
          AND C.column_name = '$sourceColumn'
"@
    }
    elseif ($sourceDbType -eq "Greenplum") {
        $sColTypeSql = @"
          SELECT CASE SUBSTRING(c.DATA_TYPE,0,COALESCE(NULLIF(POSITION('(' IN c.DATA_TYPE),0),LENGTH(c.DATA_TYPE) + 1))
            WHEN 'TIMESTAMP' THEN 'timestamp'
            WHEN 'DATE' THEN 'date'
            ELSE SUBSTRING(c.DATA_TYPE,0,COALESCE(NULLIF(POSITION('(' IN c.DATA_TYPE),0),LENGTH(c.DATA_TYPE) + 1))
            END as DATATYPE
          FROM INFORMATION_SCHEMA.COLUMNS c
          WHERE c.table_schema = '$sourceSchema'
          AND c.table_name = '$sourceTable'
          AND c.column_name = '$sourceColumn'
"@
    }
    elseif ($sourceDbType -eq "PostgreSQL") {
        $sColTypeSql = @"
          SELECT CASE SUBSTRING(C.DATA_TYPE,0,COALESCE(NULLIF(INSTR(C.DATA_TYPE,'('),0),LENGTH(C.DATA_TYPE) + 1))
            WHEN 'TIMESTAMP' THEN 'timestamp'
            WHEN 'DATE' THEN 'date'
            ELSE SUBSTRING(C.DATA_TYPE,0,COALESCE(NULLIF(INSTR(C.DATA_TYPE,'('),0),LENGTH(C.DATA_TYPE) + 1))
            END as DATATYPE
          FROM INFORMATION_SCHEMA.COLUMNS C
          WHERE C.table_schema = '$sourceSchema'
          AND C.table_name = '$sourceTable'
          AND C.column_name = '$sourceColumn'
"@
    }
    elseif ($sourceDbType -eq "DB2") {
        $sColTypeSql = @"
          SELECT TRIM(COLTYPE) AS DATATYPE
          FROM SYSIBM.SYSTABLES T
          INNER JOIN SYSIBM.SYSCOLUMNS C
          ON C.TBNAME = T.NAME
          AND C.TBCREATOR = T.CREATOR
          WHERE TRIM(T.CREATOR) = UPPER('$sourceSchema')
          AND TRIM(T.NAME) = UPPER('$sourceTable')
          AND TRIM(C.NAME) = UPPER('$sourceColumn')
"@
    }

    try {
        $srcOdbc.Open()
        $command = New-Object System.Data.Odbc.OdbcCommand($sColTypeSql,$srcOdbc)
        $command.CommandTimeout = 0
        $sourceDatatype = $command.ExecuteScalar()
        $srcOdbc.Close()
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Failed to fetch incremental override date type from $sourceOdbc")
        $errStream.WriteLine("Source datatype SQL: $sColTypeSql")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Failed to fetch incremental override date type from $sourceOdbc")
        Print-Log -exitStatus -2
        exit
    }
    $logStream.WriteLine("${debugWord}Source driving column datatype maps to:  $sourceDatatype")

    return , $sourceDatatype
}

function GET-TRANSFORMS
{

    # Construct source database minimum extract value transformation based on source database type and range column source database datatype
    #
    if($sourceDbType -eq "Teradata") {
        if($sourceDatatype -eq "date") {
            $minTransform = "'DATE ''' || CAST(CAST(MIN(sourceColumn) AS DATE FORMAT 'YYYY-MM-DD') AS VARCHAR(10)) || ''''"
        }
        elseif($sourceDatatype -eq "timestamp") {
            $minTransform = "'TIMESTAMP ''' || SUBSTR(CAST(CAST(MIN(sourceColumn) AS TIMESTAMP FORMAT 'YYYY-MM-DDBhh:mi:ss') AS VARCHAR(25)),1,19) || ''''"
        }
        else {
            $minTransform = "'''' || CAST(MIN(sourceColumn) AS VARCHAR(255)) || ''''"
        }
    }
    elseif($sourceDbType -eq "Oracle") {
        if($sourceDatatype -eq "date") {
            $minTransform = "'TO_DATE(''' || TO_CHAR(MIN(sourceColumn),'YYYY-MM-DD hh24:mi:ss') || ''',''YYYY-MM-DD hh24:mi:ss'')'"
        }
        else {
            $minTransform = "'''' || TO_CHAR(MIN(sourceColumn)) || ''''"
        }
    }
    elseif($sourceDbType -eq "SQL Server") {
        if($sourceDatatype -eq "date") {
            $minTransform = "'CAST(''' + CONVERT(NVARCHAR(10),MIN(sourceColumn),120) + ''' AS DATE)'"
        }
        elseif($sourceDatatype -eq "datetime") {
            $minTransform = "'CAST(''' + CONVERT(NVARCHAR(30),MIN(sourceColumn),120) + ''' AS DATETIME)'"
        }
        else {
            $minTransform = "'''' + CAST(MIN(sourceColumn) AS NVARCHAR(255)) + ''''"
        }
    }
    elseif($sourceDbType -eq "Redshift") {
        if($sourceDatatype -eq "date") {
            $minTransform = "'TO_DATE(''' || TO_CHAR(MIN(sourceColumn),'YYYY-MM-DD') || ''',''YYYY-MM-DD'')'"
        }
        elseif($sourceDatatype -eq "timestamp") {
            $minTransform = "'TO_DATE(''' || TO_CHAR(MIN(sourceColumn),'YYYY-MM-DD hh24:mi:ss') || ''',''YYYY-MM-DD hh24:mi:ss'')'"
        }
        else {
            $minTransform = "'''' || CAST(MIN(sourceColumn) AS VARCHAR(255)) || ''''"
        }
    }
    elseif($sourceDbType -eq "Vertica") {
        if($sourceDatatype -eq "date") {
            $minTransform = "'TO_DATE(''' || TO_CHAR(MIN(sourceColumn),'YYYY-MM-DD') || ''',''YYYY-MM-DD'')'"
        }
        elseif($sourceDatatype -eq "timestamp") {
            $minTransform = "'TO_TIMESTAMP(''' || TO_CHAR(MIN(sourceColumn),'YYYY-MM-DD hh24:mi:ss') || ''',''YYYY-MM-DD hh24:mi:ss'')'"
        }
        else {
            $minTransform = "'''' || CAST(MIN(sourceColumn) AS VARCHAR(255)) || ''''"
        }
    }
    elseif($sourceDbType -eq "Netezza") {
        if($sourceDatatype -eq "date") {
            $minTransform = "'TO_DATE(''' || TO_CHAR(MIN(sourceColumn),'YYYY-MM-DD') || ''',''YYYY-MM-DD'')'"
        }
        elseif($sourceDatatype -eq "timestamp") {
            $minTransform = "'TO_TIMESTAMP(''' || TO_CHAR(MIN(sourceColumn),'YYYY-MM-DD hh24:mi:ss') || ''',''YYYY-MM-DD hh24:mi:ss'')'"
        }
        else {
            $minTransform = "'''' || CAST(MIN(sourceColumn) AS VARCHAR(255)) || ''''"
        }
    }
    elseif($sourceDbType -eq "Greenplum") {
                if($sourceDatatype -eq "date") {
            $minTransform = "'TO_DATE(''' || TO_CHAR(MIN(sourceColumn),'YYYY-MM-DD') || ''',''YYYY-MM-DD'')'"
        }
        elseif($sourceDatatype -eq "timestamp") {
            $minTransform = "'TO_TIMESTAMP(''' || TO_CHAR(MIN(sourceColumn),'YYYY-MM-DD hh24:mi:ss') || ''',''YYYY-MM-DD hh24:mi:ss'')'"
        }
        else {
            $minTransform = "'''' || CAST(MIN(sourceColumn) AS VARCHAR(255)) || ''''"
        }
    }
    elseif($sourceDbType -eq "PostgreSQL") {
        if($sourceDatatype -eq "date") {
            $minTransform = "'TO_DATE(''' || TO_CHAR(MIN(sourceColumn),'YYYY-MM-DD') || ''',''YYYY-MM-DD'')'"
        }
        elseif($sourceDatatype -eq "timestamp") {
            $minTransform = "'TO_TIMESTAMP(''' || TO_CHAR(MIN(sourceColumn),'YYYY-MM-DD hh24:mi:ss') || ''',''YYYY-MM-DD hh24:mi:ss'')'"
        }
        else {
            $minTransform = "'''' || CAST(MIN(sourceColumn) AS VARCHAR(255)) || ''''"
        }
    }
    elseif($sourceDbType -eq "DB2") {
        if($sourceDatatype -eq "date") {
            $minTransform = "'TO_DATE(''' || TO_CHAR(MIN(sourceColumn),'YYYY-MM-DD') || ''',''YYYY-MM-DD'')'"
        }
        elseif($sourceDatatype -eq "timestamp") {
            $minTransform = "'TO_TIMESTAMP(''' || TO_CHAR(MIN(sourceColumn),'YYYY-MM-DD hh24:mi:ss') || ''',''YYYY-MM-DD hh24:mi:ss'')'"
        }
        else {
            $minTransform = "'''' || TO_CHAR(MIN(sourceColumn)) || ''''"
        }
    }

    $maxTransform = $minTransform.Replace("MIN(","MAX(")

    return $minTransform, $maxTransform
}

function GET-TAB-WHERE
{

    if(${env:rangeLocation} -eq "SNOWFLAKE") { $fromStart = "FROM (" } else { $fromStart = "(" }
    $tabWhere = @"
$fromStart
  SELECT FLOOR((ROW_NUMBER() OVER(ORDER BY sourceColumn))/$batchSize)+1 AS batch_number
  , sourceColumn
  , row_counter
  FROM
  (
    SELECT $sourceColumn AS sourceColumn
    , COUNT(*) AS row_counter
    FROM $sourceSchema.$sourceTable
    GROUP BY $sourceColumn
  ) ee
) dd
GROUP BY batch_number
UNION ALL
SELECT CAST(0 AS INTEGER)
, ''NULL''
, ''NULL''
, COUNT(*)
, ''N''
, 0
, 0
, ''1900-01-01 00:00:00''
, ''1900-01-01 00:00:00''
, ''1900-01-01 00:00:00''
, ''1900-01-01 00:00:00''
, ''-1''
, ''-1''
, ''-1''
, ''-1''
, ''-1''
, ''U''
FROM $sourceSchema.$sourceTable
WHERE $sourceColumn IS NULL
HAVING COUNT(*) > 0
"@

    return , $tabWhere

}

function GET-COL-INSERT-SQL
{
    $script:colSql = New-Object system.Data.DataTable
    $col1 = New-Object system.Data.DataColumn ColName,([String])
    $col2 = New-Object system.Data.DataColumn ColInsert,([String])
    $colSql.columns.add($col1)
    $colSql.columns.add($col2)
    if(${env:rangeLocation} -eq "SNOWFLAKE") { $TSDATATYPE = "timestamp" } else { $TSDATATYPE = "datetime" }

    $sqlHeader = @"
      INSERT INTO ws_load_col
      ( lc_obj_key, lc_col_name, lc_display_name, lc_data_type, lc_nulls_flag, lc_numeric_flag, lc_additive_flag, lc_attribute_flag, lc_src_strategy, lc_order, lc_src_table, lc_src_column, lc_transform_type, lc_transform_code, lc_transform_model)
      VALUES
"@

    $row = $colSql.NewRow()
    $row.ColName = "BATCH_NUMBER"
    $row.ColInsert = $sqlHeader + @"
      ( $objKey, 'BATCH_NUMBER', 'BATCH NUMBER', 'integer', 'Y', 'Y', 'Y', 'N', 'The batch number of the batch', 10, '$sourceTable', '$sourceColumn', 'D', 'batch_number', 'batch_number' )
"@
    $colSql.Rows.Add($row)

    $row = $colSql.NewRow()
    $row.ColName = "MIN_VALUE"
    $row.ColInsert = $sqlHeader + @"
      ( $objKey, 'MIN_VALUE', 'MIN VALUE', 'varchar(255)', 'Y', 'N', 'N', 'Y', 'Minimum value of the driving column for this batch', 20, '$sourceTable', '$sourceColumn', 'D', '$minTransform', '$minTransform' )
"@
    $colSql.Rows.Add($row)

    $row = $colSql.NewRow()
    $row.ColName = "MAX_VALUE"
    $row.ColInsert = $sqlHeader + @"
      ( $objKey, 'MAX_VALUE', 'MAX VALUE', 'varchar(255)', 'Y', 'N', 'N', 'Y', 'Maximum value of the driving column for this batch', 30, '$sourceTable', '$sourceColumn', 'D', '$maxTransform', '$maxTransform' )
"@
    $colSql.Rows.Add($row)

    $row = $colSql.NewRow()
    $row.ColName = "ROW_COUNTER"
    $row.ColInsert = $sqlHeader + @"
      ( $objKey, 'ROW_COUNTER', 'ROW COUNTER', 'integer', 'Y', 'Y', 'Y', 'N', 'Expected number of rows in batch', 40, '$sourceTable', '$sourceColumn', 'D', 'SUM(row_counter)', 'SUM(row_counter)' )
"@
    $colSql.Rows.Add($row)

    $row = $colSql.NewRow()
    $row.ColName = "STATUS"
    $row.ColInsert = $sqlHeader + @"
      ( $objKey, 'STATUS', 'STATUS', 'char(1)', 'Y', 'N', 'N', 'Y', 'Current status of batch', 50, '$sourceTable', '$sourceColumn', 'D', '''N''', '''N''' )
"@
    $colSql.Rows.Add($row)

    $row = $colSql.NewRow()
    $row.ColName = "THREAD_NUMBER"
    $row.ColInsert = $sqlHeader + @"
      ( $objKey, 'THREAD_NUMBER', 'THREAD NUMBER', 'integer', 'Y', 'Y', 'Y', 'N', 'Thread number of last process', 60, '$sourceTable', '$sourceColumn', 'D', '0', '0' )
"@
    $colSql.Rows.Add($row)

    $row = $colSql.NewRow()
    $row.ColName = "RETRY COUNT"
    $row.ColInsert = $sqlHeader + @"
      ( $objKey, 'RETRY_COUNT', 'RETRY COUNT', 'integer', 'Y', 'Y', 'Y', 'N', 'Number of retries after failure for this batch', 70, '$sourceTable', '$sourceColumn', 'D', '0', '0' )
"@
    $colSql.Rows.Add($row)

    $row = $colSql.NewRow()
    $row.ColName = "START_EXTRACT_TIMESTAMP"
    $row.ColInsert = $sqlHeader + @"
      ( $objKey, 'START_EXTRACT_TIMESTAMP', 'START EXTRACT TIMESTAMP', '$TSDATATYPE', 'Y', 'N', 'N', 'Y', 'Source system data extract start timestamp', 80, '$sourceTable', '$sourceColumn', 'D', '''1900-01-01 00:00:00''', '''1900-01-01 00:00:00''' )
"@
    $colSql.Rows.Add($row)

    $row = $colSql.NewRow()
    $row.ColName = "START_PUT_TIMESTAMP"
    $row.ColInsert = $sqlHeader + @"
      ( $objKey, 'START_PUT_TIMESTAMP', 'START PUT TIMESTAMP', '$TSDATATYPE', 'Y', 'N', 'N', 'Y', 'File put to the cloud start timestamp', 90, '$sourceTable', '$sourceColumn', 'D', '''1900-01-01 00:00:00''', '''1900-01-01 00:00:00''' )
"@
    $colSql.Rows.Add($row)

    $row = $colSql.NewRow()
    $row.ColName = "START_LOAD_TIMESTAMP"
    $row.ColInsert = $sqlHeader + @"
      ( $objKey, 'START_LOAD_TIMESTAMP', 'START LOAD TIMESTAMP', '$TSDATATYPE', 'Y', 'N', 'N', 'Y', 'File load to snowflake start timestamp', 100, '$sourceTable', '$sourceColumn', 'D', '''1900-01-01 00:00:00''', '''1900-01-01 00:00:00''' )
"@
    $colSql.Rows.Add($row)

    $row = $colSql.NewRow()
    $row.ColName = "END_TIMESTAMP"
    $row.ColInsert = $sqlHeader + @"
      ( $objKey, 'END_TIMESTAMP', 'END TIMESTAMP', '$TSDATATYPE', 'Y', 'N', 'N', 'Y', 'File load to snowflake end timestamp', 110, '$sourceTable', '$sourceColumn', 'D', '''1900-01-01 00:00:00''', '''1900-01-01 00:00:00''' )
"@
    $colSql.Rows.Add($row)

    $row = $colSql.NewRow()
    $row.ColName = "LOADED_ROWS"
    $row.ColInsert = $sqlHeader + @"
      ( $objKey, 'LOADED_ROWS', 'LOADED ROWS', 'integer', 'Y', 'Y', 'Y', 'N', 'Number of rows loaded into snowflake table', 120, '$sourceTable', '$sourceColumn', 'D', '''-1''', '''-1''' )
"@
    $colSql.Rows.Add($row)

    $row = $colSql.NewRow()
    $row.ColName = "EXTRACT_DURATION_SECONDS"
    $row.ColInsert = $sqlHeader + @"
      ( $objKey, 'EXTRACT_DURATION_SECONDS', 'EXTRACT DURATION SECONDS', 'integer', 'Y', 'Y', 'Y', 'N', 'Source system data extract duration in seconds', 130, '$sourceTable', '$sourceColumn', 'D', '''-1''', '''-1''' )
"@
    $colSql.Rows.Add($row)

    $row = $colSql.NewRow()
    $row.ColName = "PUT_DURATION_SECONDS"
    $row.ColInsert = $sqlHeader + @"
      ( $objKey, 'PUT_DURATION_SECONDS', 'PUT DURATION SECONDS', 'integer', 'Y', 'Y', 'Y', 'N', 'File put to the cloud duration in seconds', 140, '$sourceTable', '$sourceColumn', 'D', '''-1''', '''-1''' )
"@
    $colSql.Rows.Add($row)

    $row = $colSql.NewRow()
    $row.ColName = "LOAD_DURATION_SECONDS"
    $row.ColInsert = $sqlHeader + @"
      ( $objKey, 'LOAD_DURATION_SECONDS', 'LOAD DURATION SECONDS', 'integer', 'Y', 'Y', 'Y', 'N', 'File load into snowflake duration in seconds', 150, '$sourceTable', '$sourceColumn', 'D', '''-1''', '''-1''' )
"@
    $colSql.Rows.Add($row)

    $row = $colSql.NewRow()
    $row.ColName = "TOTAL_DURATION_SECONDS"
    $row.ColInsert = $sqlHeader + @"
      ( $objKey, 'TOTAL_DURATION_SECONDS', 'TOTAL DURATION SECONDS', 'integer', 'Y', 'Y', 'Y', 'N', 'Total extract, put and load duration in seconds', 160, '$sourceTable', '$sourceColumn', 'D', '''-1''', '''-1''' )
"@
    $colSql.Rows.Add($row)

    $row = $colSql.NewRow()
    $row.ColName = "ROWS_VALIDATED"
    $row.ColInsert = $sqlHeader + @"
      ( $objKey, 'ROWS_VALIDATED', 'ROWS VALIDATED', 'varchar(1)', 'Y', 'N', 'N', 'Y', 'Indicated whether or not the loaded data row count matches the expected data row count', 170, '$sourceTable', '$sourceColumn', 'D', '''U''', '''U''' )
"@
    $colSql.Rows.Add($row)

}

function INSERT-OBJ-ROW
{

    # Add new range table object to metadata
    #
    if(${env:rangeLocation} -eq "SNOWFLAKE") { $target = "oo_target_key" } else { $target = $targetKey }
    $sql = @"
      INSERT INTO ws_obj_object
      ( oo_name
      , oo_type_key
      , oo_target_key)
      SELECT '$rangeTable'
      , oo_type_key
      , $target
      FROM ws_obj_object
      WHERE oo_name = '$loadTable'
"@
    try {
        $metaOdbc.Open()
        $command = New-Object System.Data.Odbc.OdbcCommand($sql,$metaOdbc)
        $command.CommandTimeout = 0
        $rowsInserted = $command.ExecuteNonQuery()
        $metaOdbc.Close()
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Failed to create range table object $rangeTable")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Failed to create range table object $rangeTable")
        Print-Log -exitStatus -2
        exit
    }

    $sql = @"
      SELECT oo_obj_key
      FROM   ws_obj_object
      WHERE  oo_name = '$rangeTable'
"@
    try {
        $metaOdbc.Open()
        $command = New-Object System.Data.Odbc.OdbcCommand($sql,$metaOdbc)
        $command.CommandTimeout = 0
        $objKey = $command.ExecuteScalar()
        $metaOdbc.Close()
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Failed to get new object key")
        $errStream.WriteLine("Row count SQL: $sql")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Failed to get new object key")
        Print-Log -exitStatus -2
        exit
    }

    return $objKey
}

function INSERT-TAB-ROW
{

    # Add new range table row to metadata
    #
    if(${env:rangeLocation} -eq "SNOWFLAKE") { $type = "lt_type" } else { $type = "'O'" }
    if(${env:rangeLocation} -eq "SNOWFLAKE") { $scriptKey = "lt_script_connect_key" } else { $scriptKey = "NULL" }
    $sql = @"
      INSERT INTO ws_load_tab
      ( lt_obj_key
      , lt_table_name
      , lt_short_name
      , lt_active
      , lt_type
      , lt_connect_key
      , lt_pre_action
      , lt_file_wait
      , lt_wait_action
      , lt_procedure_key
      , lt_transform_ind
      , lt_script_connect_key
      , lt_where_clause)
      SELECT $objKey
      , '$rangeTable'
      , SUBSTRING('$rangeTable',1,16) + RIGHT('$objKey',6)
      , lt_active
      , $type
      , lt_connect_key
      , 'N'
      , lt_file_wait
      , lt_wait_action
      , lt_procedure_key
      , lt_transform_ind
      , $scriptKey
      , '$tabWhere' AS lt_where_clause
      FROM ws_load_tab
      JOIN ws_load_col
      ON lt_obj_key = lc_obj_key
      WHERE lt_table_name = '$loadTable'
      AND UPPER(lc_col_name) = UPPER('$rangeColumn')
"@
    try {
        $metaOdbc.Open()
        $command = New-Object System.Data.Odbc.OdbcCommand($sql,$metaOdbc)
        $command.CommandTimeout = 0
        $rowsInserted = $command.ExecuteNonQuery()
        $metaOdbc.Close()
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Failed to create range table $rangeTable")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Failed to create range table $rangeTable")
        Print-Log -exitStatus -2
        exit
    }

}

function INSERT-COL-ROW
{

    # Add new range table columns row to the metadata
    #
    $metaOdbc.Open()
    foreach ( $row in $script:colSql ) {
        $colName = $row.ColName
        $colSql = $row.ColInsert
        try {
            $command = New-Object System.Data.Odbc.OdbcCommand($colSql,$metaOdbc)
            $command.CommandTimeout = 0
            $rowsInserted = $command.ExecuteNonQuery()
        }
        catch {
            $errStream.WriteLine($_.Exception.Message)
            $errStream.WriteLine($_.InvocationInfo.PositionMessage)
            $errStream.WriteLine("Script failed. Failed to create range table column $colName")
            $errStream.WriteLine($colSql)
            $host.ui.WriteLine("-2")
            $host.ui.WriteLine("Script failed. Failed to create range table column $colName")
            Print-Log -exitStatus -2
            exit
        }
    }
    $metaOdbc.Close()

}

function ADD-EXT-PROP-VAL
{
    Param(
        $tabName, $extPropName, $extPropValue
    )

    # Remove old extended property value
    #
    $metaOdbc.Open()
    $sql = @"
      DELETE FROM ws_ext_prop_value
      WHERE  epv_def_key = (SELECT epd_key
                            FROM   ws_ext_prop_def
                            WHERE epd_display_name = '$extPropName')
      AND    epv_obj_key = (SELECT oo_obj_key
                            FROM   ws_obj_object
                            WHERE  oo_name = '$tabName')
"@
    try {
        $command = New-Object System.Data.Odbc.OdbcCommand($sql,$metaOdbc)
        $command.CommandTimeout = 0
        $rowsDeleted = $command.ExecuteNonQuery()
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Failed to remove old extended property $extPropName")
        $errStream.WriteLine("Extended Property SQL: $sql")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Failed to remove old extended property $extPropName")
        Print-Log -exitStatus -2
        exit
    }

    $sql = @"
      INSERT INTO ws_ext_prop_value
      ( epv_def_key, epv_obj_key, epv_value )
      SELECT epd_key
           , oo_obj_key
           , '$extPropValue'
      FROM   ws_ext_prop_def
      CROSS JOIN ws_obj_object
      WHERE  epd_display_name = '$extPropName'
      AND    oo_name = '$tabName'
"@
    try {
        $command = New-Object System.Data.Odbc.OdbcCommand($sql,$metaOdbc)
        $command.CommandTimeout = 0
        $rowsInserted = $command.ExecuteNonQuery()
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Failed to add new extended property $extPropName")
        $errStream.WriteLine("Extended Property SQL: $sql")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Failed to add new extended property $extPropName")
        Print-Log -exitStatus -2
        exit
    }
    $metaOdbc.Close()

}

function ADD-TEMPLATE-DEF
{
    Param(
        $tabName, $templateType, $templateName
    )

    $metaOdbc.Open()
    $sql = @"
      SELECT COUNT(*) AS row_exists
           , ISNULL(MAX(CASE WHEN NULLIF(RTRIM(ta_ind_1),'') IS NULL THEN 1
                             WHEN ta_ind_1 = $templateType THEN 1
                             WHEN NULLIF(RTRIM(ta_ind_2),'') IS NULL THEN 2
                             WHEN ta_ind_2 = $templateType THEN 2
                             WHEN NULLIF(RTRIM(ta_ind_3),'') IS NULL THEN 3
                             WHEN ta_ind_3 = $templateType THEN 3
                             WHEN NULLIF(RTRIM(ta_ind_4),'') IS NULL THEN 4
                             WHEN ta_ind_4 = $templateType THEN 4
                             WHEN NULLIF(RTRIM(ta_ind_5),'') IS NULL THEN 5
                             WHEN ta_ind_5 = $templateType THEN 5
                             WHEN NULLIF(RTRIM(ta_ind_6),'') IS NULL THEN 6
                             WHEN ta_ind_6 = $templateType THEN 6
                             END),1) AS which_index
      FROM  ws_table_attributes
      JOIN  ws_load_tab
      ON    ta_obj_key = lt_obj_key
      WHERE lt_table_name = '$tabName'
      AND   ta_type = 'L'
"@
    try {
        $command = New-Object System.Data.Odbc.OdbcCommand($sql,$metaOdbc)
        $command.CommandTimeout = 0
        $adapter = New-Object System.Data.Odbc.OdbcDataAdapter($command)
        $mdt = New-Object System.Data.DataTable
        $null = $adapter.fill($mdt)
        $rowExists = $mdt.Rows[0].row_exists
        $whichIndex = $mdt.Rows[0].which_index
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Template default current status")
        $errStream.WriteLine("Template Default SQL: $sql")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Template default current status")
        Print-Log -exitStatus -2
        exit
    }

    if ( $rowExists -eq 1 ) {
        $sql = @"
          UPDATE ws_table_attributes
          SET    ta_ind_$whichIndex = $templateType
               , ta_val_$whichIndex = (SELECT th_obj_key FROM ws_tem_header WHERE th_name = '$templateName')
          WHERE  ta_obj_key = (SELECT lt_obj_key FROM ws_load_tab WHERE lt_table_name = '$tabName')
          AND    ta_type = 'L'
"@
    }
    else {
        $sql = @"
          INSERT INTO ws_table_attributes
          ( ta_obj_key, ta_type, ta_ind_$whichIndex, ta_val_$whichIndex)
          SELECT lt_obj_key
               , 'L'
               , $templateType
               , th_obj_key
          FROM   ws_load_tab
          CROSS JOIN ws_tem_header
          WHERE  lt_table_name = '$tabName'
          AND    th_name = '$templateName'
"@
    }

    try {
        $command = New-Object System.Data.Odbc.OdbcCommand($sql,$metaOdbc)
        $command.CommandTimeout = 0
        $rowsChanged = $command.ExecuteNonQuery()
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Failed to set default template: $tabName : $templateType : $templateName")
        $errStream.WriteLine("Template Default SQL: $sql")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Failed to set default template: $tabName : $templateType : $templateName")
        Print-Log -exitStatus -2
        exit
    }
    $metaOdbc.Close()

}

function SET-TABLE-PRE-ACTION
{
    Param(
        $tabName, $preAction
    )

    $metaOdbc.Open()
    $sql = @"
      UPDATE ws_load_tab
      SET    lt_pre_action = '$preAction'
      WHERE  lt_table_name = '$tabName'
"@
    try {
        $command = New-Object System.Data.Odbc.OdbcCommand($sql,$metaOdbc)
        $command.CommandTimeout = 0
        $rowsChanged = $command.ExecuteNonQuery()
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Failed to set pre load action on $tabName")
        $errStream.WriteLine("Pre Action SQL: $sql")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Failed to set pre load action on $tabName")
        Print-Log -exitStatus -2
        exit
    }
    $metaOdbc.Close()

}

try {

    # Initialize logging and message boxes
    #
    $fileAud = Join-Path -Path ${env:WSL_WORKDIR} -ChildPath "CREATE_RANGE_TABLE_${env:WSL_SEQUENCE}.aud"
    $fileErr = Join-Path -Path ${env:WSL_WORKDIR} -ChildPath "CREATE_RANGE_TABLE_${env:WSL_SEQUENCE}.err"
    $logStream = New-Object IO.StreamWriter($fileAud,$false)
    $logStream.AutoFlush = $true
    $errStream = New-Object IO.StreamWriter($fileErr,$false)
    $errStream.AutoFlush = $true
    Add-Type -AssemblyName PresentationFramework
    try {
        ${env:DEBUG} = "$PRANGE_DEBUG_MODE$"
    }
    catch {
        ${env:DEBUG} = "TRUE"
    }
    $debugWord = ""
    if(${env:DEBUG} -eq "TRUE") {
        $debugWord = "DEBUG: "
    }
    $loopcntr = 0

    # Define metadata connection
    #
    if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Defining metadata connection") }
    $metaOdbc = New-Object System.Data.Odbc.OdbcConnection
    $metaOdbc.ConnectionString = "DSN=${env:WSL_META_DSN}"
    if( ! [string]::IsNullOrEmpty(${env:WSL_META_USER})) { $metaOdbc.ConnectionString += ";UID=${env:WSL_META_USER}" }
    $debugConnectionString = $metaOdbc.ConnectionString
    if( ! [string]::IsNullOrEmpty(${env:WSL_META_PWD})) {
        $metaOdbc.ConnectionString += ";PWD=${env:WSL_META_PWD}"
        $debugConnectionString += ";PWD=" + (New-Object string ('*', ${env:WSL_META_PWD}.Length))
    }
    if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Metadata connection defined") }
    if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Metadata connection string is: $debugConnectionString") }

    while ( 1 -eq 1 ) {

        $loopcntr = $loopcntr + 1

        # Show GUI and parse results
        #
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Starting GUI") }
        $guiResults = GUI
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: GUI Exited Successfully") }

        $loadTable = $guiResults[0]
        $rangeTable = $guiResults[1]
        $rangeColumn = $guiResults[2]
        $profileChecked = $guiResults[3]
        $rowCount = $guiResults[4]
        $avgRowLength = $guiResults[5]
        $maxRowLength = [String](([Int]$avgRowLength)*3)
        $rangeCardinality = $guiResults[6]

        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: loadTable is: $loadTable") }
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: rangeTable is: $rangeTable") }
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: rangeColumn is: $rangeColumn") }
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: profileChecked is: $profileChecked") }
        if ( $profileChecked -eq $false ) {
            if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: manual rowCount is: $rowCount") }
            if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: manual avgRowLength is: $avgRowLength") }
            if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: manual rangeCardinality is: $rangeCardinality") }
        }

        # Get additional source object and system metadata
        #
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Fetching Source Metadata") }
        $sourceMetadata = GET-SOURCE-METADATA
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Source Metadata Fetched") }
        $sourceDbType = $sourceMetadata[0]
        $sourceSchema = $sourceMetadata[1]
        $sourceTable = $sourceMetadata[2]
        $sourceOdbc = $sourceMetadata[3]
        $sourceUser = $sourceMetadata[4]
        $sourcePwd = $sourceMetadata[5]
        $sourceColumn = $sourceMetadata[6]
        $sourceConnection = $sourceMetadata[7]

        # Get password from user if encrypted
        #
        $encPwd = GET-SRC-PWD-ENC
        if($encPwd -eq "Y") {
            if( $sourceConnection -eq $prevSourceConnection ) {
                $sourcePwd = $prevSourcePwd
            }
            else {
                $sourcePwd = GET-SRCPWD
            }
        }

        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: sourceSchema is: $sourceSchema") }
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: sourceTable is: $sourceTable") }
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: sourceOdbc is: $sourceOdbc") }
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: sourceUser is: $sourceUser") }
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: sourcePwd is: " + (New-Object string ('*', $sourcePwd.Length))) }
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: sourceColumn is: $sourceColumn") }
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: sourceConnection is: $sourceConnection") }
        
        # Define source connection
        #
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Defining source connection") }
        $srcOdbc = New-Object System.Data.Odbc.OdbcConnection
        $srcOdbc.ConnectionString = "DSN=$sourceOdbc"
        if( ! [string]::IsNullOrEmpty($sourceUser)) { $srcOdbc.ConnectionString += ";UID=$sourceUser" }
        $debugConnectionString = $srcOdbc.ConnectionString
        if( ! [string]::IsNullOrEmpty($sourcePwd)) {
            $srcOdbc.ConnectionString += ";PWD=$sourcePwd"
            $debugConnectionString += ";PWD=" + (New-Object string ('*', $sourcePwd.Length))
        }
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Source connection defined") }
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Source connection string is: $debugConnectionString") }

        # Do Source Table Profiling if required
        #
        if ( $profileChecked -eq $true ) {
            if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Fetching Row Count") }
            $rowCount = GET-ROWCOUNT
            if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Fetching Row Length") }
            $rowLengthResults = GET-ROWLENGTH
            $avgRowLength = $rowLengthResults[0]
            $maxRowLength = $rowLengthResults[1]
            if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Fetching Cardinality") }
            $rangeCardinality = GET-CARDINALITY
        }

        # Get parameter values
        #
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Fetching Optimal File Size") }
        $optimalFileSize = GET-OPTIMAL-FILESIZE
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Fetching Compression Rate") }
        $compressionRate = GET-COMPRESSION-RATE
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Fetching Range Table Connection") }
        $rangeConnection = GET-RANGE-CONNECTION
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Fetching Range Table Location Database Type") }
        $env:rangeLocation = GET-RANGE-TABLE-LOCATION
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Fetching Range Table Target") }
        $rangeTarget = GET-RANGE-TARGET
        
        # Get target key
        #
        if(${env:rangeLocation} -ne "SNOWFLAKE") {
            if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Fetching Target Key") }
            $targetKey = GET-TARGET-KEY
            if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Target Key Fetched") }
        }
        
        # Calculate batch size magic number
        #
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Calculating Batch Size Magic Number") }
        $batchSize = [math]::floor(( $optimalFileSize*1024*1024 / [decimal]$avgRowLength * $compressionRate ) / [decimal]$rowCount * [decimal]$rangeCardinality)
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Batch Size Magic Number batchSize is: $batchSize") }

        # Get source data type and transformations
        #
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Fetching source datatype") }
        $sourceDatatype = GET-SOURCE-DATATYPE
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Fetching source transformations") }
        $transformResults = GET-TRANSFORMS
        $minTransform = $transformResults[0].Replace("'","''")
        $maxTransform = $transformResults[1].Replace("'","''")

        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: minTransform is: $minTransform") }
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: maxTransform is: $maxTransform") }

        # Create New Range Table
        #
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Inserting new object row") }
        $objKey = INSERT-OBJ-ROW
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: The object key is:  $objKey") }
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Fetching table where clause") }
        $tabWhere = GET-TAB-WHERE
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Inserting new table row") }
        INSERT-TAB-ROW
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Fetching column insert array") }
        GET-COL-INSERT-SQL
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Inserting new column rows") }
        INSERT-COL-ROW
        
        if(${env:rangeLocation} -eq "SNOWFLAKE") {
            if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Setting ddl template on range table") }
            ADD-TEMPLATE-DEF -tabName $rangeTable -templateType 3 -templateName "wsl_snowflake_create_table"
            if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Setting load template on range table") }
            ADD-TEMPLATE-DEF -tabName $rangeTable -templateType 4 -templateName "wsl_snowflake_pscript_load"
        }

        # Make changes to the original load table
        #
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Setting load template on load table") }
        ADD-TEMPLATE-DEF -tabName $loadTable  -templateType 4 -templateName "wsl_snowflake_pscript_load_range"
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Setting extended property RANGE_PILOT_TABLE on load table") }
        ADD-EXT-PROP-VAL -tabName $loadTable -extPropName "RANGE_PILOT_TABLE" -extPropValue $rangeTable
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Setting extended property RANGE_MAX_ROW_LENGTH on load table") }
        ADD-EXT-PROP-VAL -tabName $loadTable -extPropName "RANGE_MAX_ROW_LENGTH" -extPropValue $maxRowLength
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Setting extended property RANGE_BATCH_EXPRESSION on load table") }
        ADD-EXT-PROP-VAL -tabName $loadTable -extPropName "RANGE_BATCH_EXPRESSION" -extPropValue $rangeColumn
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Setting preload action on load table to N") }
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Setting extended property RANGE_WORK_TABLE_LOCATION on load table") }
        ADD-EXT-PROP-VAL -tabName $loadTable -extPropName "RANGE_WORK_TABLE_LOCATION" -extPropValue ${env:rangeLocation}
        if(${env:rangeLocation} -ne "SNOWFLAKE") {
            if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Setting extended property RANGE_WORK_CONNECTION on load table") }
            ADD-EXT-PROP-VAL -tabName $loadTable -extPropName "RANGE_WORK_CONNECTION" -extPropValue $rangeConnection
        }
        SET-TABLE-PRE-ACTION -tabName $loadTable -preAction "N"

        $srcOdbc.Dispose()
		$host.ui.WriteLine("1")
        $rDefine = New-Object -ComObject Wscript.Shell
		$rDefine.Popup("Range Table: $rangeTable has been defined",0,"Wherescape RED")
        $logStream.WriteLine("Range Table: $rangeTable has been defined")
        if(${env:rangeLocation} -eq "SNOWFLAKE") {
            $logStream.WriteLine("==> Please create $rangeTable then regenerate scripts for: $loadTable and $rangeTable")
        }
        else {
            $logStream.WriteLine("==> Please create $rangeTable then regenerate scripts for: $loadTable")
        }
            
        $prevSourceConnection = $sourceConnection
        $prevSourcePwd = $sourcePwd

    }

    # Tidy Up
    #
    $metaOdbc.Dispose()
    $host.ui.WriteLine("1")
    $host.ui.WriteLine("Script completed successfully")
    Print-Log -exitStatus 1
}
catch {
    $errStream.WriteLine("An unhandled exception occurred.")
    $errStream.WriteLine($_.Exception.Message)
    $errStream.WriteLine($_.InvocationInfo.PositionMessage)
    $host.ui.WriteLine("-3")
    $host.ui.WriteLine("Script failed")
    Print-Log -exitStatus -3
}
