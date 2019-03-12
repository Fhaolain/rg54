# ScriptVersion:005 MinVersion:8310 MaxVersion:* TargetType:Snowflake ModelType:* ScriptType:Powershell64
#--==============================================================================
#-- DBMS Name        :    SNOWFLAKE Custom*
#-- Block Name       :    snowflake_fixed_width_setup
#-- Description      :    Set fixed width transformations on a RED Stage table
#-- Author           :    Jason Laws
#--==============================================================================
#-- Notes / History
#-- JML v 1.0.0 2017-09-17 First Version
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
    $MyForm.Text = "Choose RED Table"
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
    $MyLabel.Text = "Please select the STAGE table to add fixed width column transformations:"
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
    $query = "SELECT oo_name FROM ws_obj_object WHERE oo_type_key = 7 ORDER BY 1"
    $odbcConn = New-Object Data.Odbc.OdbcConnection
    $odbcConn.ConnectionString = "DSN=${env:WSL_META_DSN}"
    $odbcConn.open()
    $odbcCommand = New-object Data.Odbc.OdbcCommand($query,$odbcConn)
    $dataTable = New-Object Data.DataTable
    $null = (New-Object Data.odbc.odbcDataAdapter($odbcCommand)).fill($dataTable)
    $MyCombo.DataSource = $datatable.oo_name
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
      $SelectedStageTable = $MyForm.Controls.Item(2).TEXT
      $query = @"
              UPDATE ws_stage_col
              SET    sc_transform_type = 'D'
                   , sc_transform_code = new_transform
                   , sc_transform_model = new_transform
              FROM ( SELECT sc_obj_key
                          , sc_col_name
                          , 'SUBSTR(' + sc_src_table + '.' + sc_src_column + ',' +
                                  (CAST(SUM(CAST(REPLACE(REPLACE(REPLACE(sc_data_type,'varchar(',''),'char(',''),')','') AS INTEGER))
                                        OVER(ORDER BY sc_order ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                                  -CAST(REPLACE(REPLACE(REPLACE(sc_data_type,'varchar(',''),'char(',''),')','') AS INTEGER) + 1 AS VARCHAR(20))) + ',' +
                                  (REPLACE(REPLACE(REPLACE(sc_data_type,'varchar(',''),'char(',''),')','')) + ')' new_transform
                      FROM   ws_stage_tab
                      JOIN   ws_stage_col
                      ON     st_obj_key = sc_obj_key
                      WHERE  st_table_name = '$SelectedStageTable'
                      AND    sc_order <> ( SELECT MIN(sc_order)
                                           FROM   ws_stage_tab
                                           JOIN   ws_stage_col
                                           ON     st_obj_key = sc_obj_key
                                           WHERE  st_table_name = '$SelectedStageTable'
                                         )
                      AND    sc_col_name NOT IN ( SELECT mn_name
                                                  FROM   ws_meta_names
                                                  WHERE  mn_object LIKE 'dss%'
                                                )
              ) AS src
              WHERE  ws_stage_col.sc_obj_key = src.sc_obj_key
              AND    ws_stage_col.sc_col_name = src.sc_col_name
"@
      $null = (new-object System.Data.Odbc.OdbcCommand($query, $odbcConn)).ExecuteNonQuery()
      $status = 1
      $return_Msg = "Table $SelectedStageTable modified for fixed width processing."
    }
    else {
      $status = -1
      $return_Msg = "No table selected."
    }
  }
}

catch {
  $status = -3
  $return_Msg = "An error has occurred."
}

$status
$return_Msg
