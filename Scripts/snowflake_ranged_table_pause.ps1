# ScriptVersion:001 MinVersion:8310 MaxVersion:* TargetType:Snowflake ModelType:* ScriptType:Powershell64
#--==============================================================================
#-- DBMS Name        :    SNOWFLAKE Custom*
#-- Block Name       :    snowflake_ranged_table_pause
#-- Description      :    Pause all not yet run batches in a selected range table
#-- Author           :    WhereScape
#--==============================================================================
#-- Notes / History
#-- JML v 1.0.0 2018-05-08 First Version
#-- JML v.1.0.1 2019-03-20 Branched from Migration Express
#--

try {
  $parent = (Get-WmiObject Win32_Process | select ProcessID, ParentProcessID | where { $_.ProcessID -eq  ([System.Diagnostics.Process]::GetCurrentProcess()).id }).ParentProcessID
  $caller = (Get-WmiObject Win32_Process | select ProcessID, ParentProcessID | where { $_.ProcessID -eq ([System.Diagnostics.Process]::GetProcessById($parent)).id}).parentprocessID
  if((Get-Process -Id $caller).Name -eq "WslSched") {
    $status = -2
    $return_Msg = "Unable to run in scheduler, please run interactively."
  }
  else {
    Add-Type -AssemblyName System.Windows.Forms
    $MyForm = New-Object system.Windows.Forms.Form
    $MyForm.Text = "Range Table Pause"
    $MyForm.AutoScroll = $True
    $MyForm.Width = 460
    $MyForm.Height = 150
    $MyForm.MinimizeBox = $False
    $MyForm.MaximizeBox = $False
    $MyForm.WindowState = "Normal"
    $MyForm.SizeGripStyle = "Hide"
    $MyForm.ShowInTaskbar = $False
    $MyForm.StartPosition = "CenterScreen"
    $MyIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("${env:WSL_BINDIR}med.exe")
    $MyForm.Icon = $MyIcon

    $Location = New-Object System.Drawing.Point

    $MyLabel = New-Object System.Windows.Forms.Label
    $Location.X = 10
    $Location.Y = 15
    $MyLabel.Location = $Location
    $MyLabel.Text = "Please select the ranged table to pause:"
    $MyLabel.AutoSize = $True
    $MyForm.Controls.Add($MyLabel)

    $MyOKButton = New-Object System.Windows.Forms.Button
    $Location.X = ($MyForm.Width / 2) - 1.25*$MyOKButton.Width
    $Location.Y = 75
    $MyOKButton.Location = $Location
    $MyOKButton.Text = "OK"
    $MyOKButton.Add_Click({$MyForm.DialogResult = "OK"})
    $MyForm.Controls.Add($MyOKButton)

    $MyCombo = New-Object System.Windows.Forms.ComboBox
    $Location.X = 25
    $Location.Y = 40
    $MyCombo.Location = $Location
    $MyCombo.Width = 400
    $MyCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $MyCombo.Add_SelectedIndexChanged({$MyForm.ActiveControl = $MyForm.Controls.Item(1)})
    $query = @"
        SELECT lt_table_name oo_name
        FROM   ws_ext_prop_value 
        JOIN   ws_ext_prop_def
        ON     epv_def_key = epd_key
        JOIN   ws_load_tab
        ON     epv_obj_key = lt_obj_key
        WHERE  epd_display_name = 'RANGE_PILOT_TABLE'
        ORDER BY 1
"@

    $odbcConn = New-Object Data.Odbc.OdbcConnection
    $odbcConn.ConnectionString = "DSN=${env:WSL_META_DSN}"
    $odbcConn.open()
    $odbcCommand = New-object Data.Odbc.OdbcCommand($query,$odbcConn)
    $dataTable = New-Object Data.DataTable
    $null = (New-Object Data.odbc.odbcDataAdapter($odbcCommand)).fill($dataTable)
    $MyCombo.DataSource = [array]($datatable.oo_name)
    $MyForm.Controls.Add($MyCombo)

    $MyCancelButton = New-Object System.Windows.Forms.Button
    $Location.X = ($MyForm.Width / 2) + 0.25*$MyCancelButton.Width
    $Location.Y = 75
    $MyCancelButton.Location = $Location
    $MyCancelButton.Text = "Cancel"
    $MyCancelButton.Add_Click({$MyForm.DialogResult = "CANCEL"})
    $MyForm.Controls.Add($MyCancelButton)
    $MyForm.ActiveControl = $MyForm.Controls.Item(3)

    if ( $MyForm.ShowDialog() -eq "OK" ) {
      $SelectedMETable = $MyForm.Controls.Item(2).TEXT
     
      $query = @"
        SELECT epv_value oo_name
        FROM   ws_ext_prop_value 
        JOIN   ws_ext_prop_def
        ON     epv_def_key = epd_key
        JOIN   ws_load_tab
        ON     epv_obj_key = lt_obj_key
        WHERE  epd_display_name = 'RANGE_PILOT_TABLE'
        AND    lt_table_name = '$SelectedMETable'
"@
      $odbcCommand.CommandText = $query
      $rangeTable = New-Object Data.DataTable
      $null = (New-Object Data.odbc.odbcDataAdapter($odbcCommand)).fill($rangeTable)
      $rangeName = $rangeTable.oo_name
      
      $query = @"
        SELECT 'DSN='+dc_odbc_source+';UID='+dc_extract_userid+';PWD='+dc_extract_pwd AS connectionString
             , dt_schema
        FROM   ws_obj_object
        JOIN   ws_dbc_target
        ON     oo_target_key = dt_target_key
        JOIN   ws_dbc_connect
        ON     dt_connect_key = dc_obj_key
        WHERE  oo_name = '$rangeName'
"@
      $odbcCommand.CommandText = $query
      $connectTable = New-Object Data.DataTable
      $null = (New-Object Data.odbc.odbcDataAdapter($odbcCommand)).fill($connectTable)
      $odbcConn.dispose()
      $ConnectionString = $connectTable.connectionString
      $rangeSchema = $connectTable.dt_schema
      
      $query = @"
        UPDATE $rangeSchema.$rangeName
        SET    status = 'P'
        WHERE  status = 'N'
"@

      $odbcConn2 = New-Object Data.Odbc.OdbcConnection
      $odbcConn2.ConnectionString = $ConnectionString 
      $odbcConn2.open()
      $rangeTable = New-Object Data.DataTable
      $rowCount = (new-object System.Data.Odbc.OdbcCommand($query, $odbcConn2)).ExecuteNonQuery()
      $odbcConn2.dispose()
      
      $status = 1
      $return_Msg = "Future ranges ($rowCount) paused for $SelectedMETable via range table $rangeSchema.$rangeName."
    }
    else {
      $status = -1
      $return_Msg = "No table selected."
    }
  }
}

catch {
  $status = -3
  $return_Msg = "An error has occurred.  "
  $return_Msg += $_.Exception.Message
}

$status
$return_Msg
