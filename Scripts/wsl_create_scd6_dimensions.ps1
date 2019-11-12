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

function GET-DIMTABLES {

    $query = @"
      SELECT dt_table_name
      FROM ws_dim_tab
      ORDER BY 1
"@

    try {
        $command = New-Object System.Data.Odbc.OdbcCommand($query,$metaOdbc)
        $command.CommandTimeout = 0
        $adapter = New-Object System.Data.Odbc.OdbcDataAdapter($command)
        $dimTableList = New-Object System.Data.DataTable
        $null = $adapter.fill($dimTableList)
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Dimension Table List query failed")
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Dimension Table List query failed")
        Print-Log -exitStatus -2
        exit
    }

    if($dimTableList.Rows.Count -eq 0) {
        $logStream.WriteLine("${debugWord}No dimension tables found in metadata.")
        $host.ui.WriteLine("1")
        $host.ui.WriteLine("No dimension tables found in metadata.")
        Print-Log -exitStatus 1
        exit
    }

    return , $dimTableList

}

function CREATE-SCD6($dimTableList) {

  $dimWhere = "'$($dimTableList -join "','")'"

  $query = @"
    merge into ws_dim_col tgt
    using (
    select 
    	dc.dc_obj_key
          ,dc.dc_col_key
    	  ,dc.dc_col_name_orig
          ,dc.dc_col_name 
          ,dc.dc_display_name
          ,dc.dc_data_type
          ,dc.dc_nulls_flag
          ,dc.dc_numeric_flag
          ,dc.dc_additive_flag
          ,dc.dc_attribute_flag
          ,dc.dc_eul_flag
          ,dc.dc_format
          ,dc.dc_src_table
          ,dc.dc_src_column
          ,dc.dc_src_strategy
          ,dc.dc_order
          ,dc.dc_key_type
          ,dc.dc_business_key_ind
          ,dc.dc_artificial_key_ind
          ,dc.dc_zero_key_value
          ,dc.dc_attributes
          ,dc.dc_transform_type
          ,dc.dc_transform_model
          ,dc.dc_transform_code
          ,dc.dc_doc_1
          ,dc.dc_doc_2
          ,dc.dc_doc_3
          ,dc.dc_doc_4
          ,dc.dc_doc_5
          ,dc.dc_doc_6
          ,dc.dc_doc_7
          ,dc.dc_doc_8
          ,dc.dc_doc_9
          ,dc.dc_doc_10
          ,dc.dc_doc_11
          ,dc.dc_doc_12
          ,dc.dc_doc_13
          ,dc.dc_doc_14
          ,dc.dc_doc_15
          ,dc.dc_doc_16
          ,dc.dc_primary_index_ind
          ,dc.dc_join_flag
          ,dc.dc_default_value
          ,dc.dc_case_flag
          ,dc.dc_title
          ,dc.dc_compress_flag
          ,dc.dc_compress_value
          ,dc.dc_comments
          ,dc.dc_col_type
          ,dc.dc_update_flag
          ,dc.dc_display_type
          ,dc.dc_pre_join_source
          ,dc.dc_ind_1
    from
    (select
    	dc.dc_obj_key
          ,dc.dc_col_key
    	  ,dc.dc_col_name as dc_col_name_orig
          ,dc.dc_col_name + '_curr' as dc_col_name
          ,dc.dc_display_name + ' curr' as dc_display_name
          ,dc.dc_data_type
          ,dc.dc_nulls_flag
          ,dc.dc_numeric_flag
          ,dc.dc_additive_flag
          ,dc.dc_attribute_flag
          ,dc.dc_eul_flag
          ,dc.dc_format
          ,dc.dc_src_table
          ,dc.dc_src_column
          ,dc.dc_src_strategy
          ,dc.dc_order
          ,dc.dc_key_type
          ,dc.dc_business_key_ind
          ,dc.dc_artificial_key_ind
          ,dc.dc_zero_key_value
          ,dc.dc_attributes
          ,dc.dc_transform_type
          ,dc.dc_transform_model
          ,dc.dc_transform_code
          ,dc.dc_doc_1
          ,dc.dc_doc_2
          ,dc.dc_doc_3
          ,dc.dc_doc_4
          ,dc.dc_doc_5
          ,dc.dc_doc_6
          ,dc.dc_doc_7
          ,dc.dc_doc_8
          ,dc.dc_doc_9
          ,dc.dc_doc_10
          ,dc.dc_doc_11
          ,dc.dc_doc_12
          ,dc.dc_doc_13
          ,dc.dc_doc_14
          ,dc.dc_doc_15
          ,dc.dc_doc_16
          ,dc.dc_primary_index_ind
          ,dc.dc_join_flag
          ,dc.dc_default_value
          ,dc.dc_case_flag
          ,dc.dc_title
          ,dc.dc_compress_flag
          ,dc.dc_compress_value
          ,dc.dc_comments
          ,dc.dc_col_type
          ,dc.dc_update_flag
          ,dc.dc_display_type
          ,dc.dc_pre_join_source
          ,dc.dc_ind_1
    from ws_dim_col dc
    union all
    select
    	dc.dc_obj_key
          ,-1 AS dc_col_key
    	  ,dc.dc_col_name as dc_col_name_orig
          ,dc.dc_col_name + '_hist' as dc_col_name
          ,dc.dc_display_name + ' hist' as dc_display_name
          ,dc.dc_data_type
          ,dc.dc_nulls_flag
          ,dc.dc_numeric_flag
          ,dc.dc_additive_flag
          ,dc.dc_attribute_flag
          ,dc.dc_eul_flag
          ,dc.dc_format
          ,dc.dc_src_table
          ,dc.dc_src_column
          ,dc.dc_src_strategy
          ,dc.dc_order + 1 as dc_order
          ,CASE WHEN NULLIF(dc.dc_key_type, '') IS NULL THEN '3' ELSE dc.dc_key_type end as dc_key_type
          ,dc.dc_business_key_ind
          ,dc.dc_artificial_key_ind
          ,dc.dc_zero_key_value
          ,dc.dc_attributes
          ,dc.dc_transform_type
          ,dc.dc_transform_model
          ,dc.dc_transform_code
          ,dc.dc_doc_1
          ,dc.dc_doc_2
          ,dc.dc_doc_3
          ,dc.dc_doc_4
          ,dc.dc_doc_5
          ,dc.dc_doc_6
          ,dc.dc_doc_7
          ,dc.dc_doc_8
          ,dc.dc_doc_9
          ,dc.dc_doc_10
          ,dc.dc_doc_11
          ,dc.dc_doc_12
          ,dc.dc_doc_13
          ,dc.dc_doc_14
          ,dc.dc_doc_15
          ,dc.dc_doc_16
          ,dc.dc_primary_index_ind
          ,dc.dc_join_flag
          ,dc.dc_default_value
          ,dc.dc_case_flag
          ,dc.dc_title
          ,dc.dc_compress_flag
          ,dc.dc_compress_value
          ,dc.dc_comments
          ,dc.dc_col_type
          ,dc.dc_update_flag
          ,dc.dc_display_type
          ,dc.dc_pre_join_source
          ,dc.dc_ind_1
    from ws_dim_col dc
    ) dc
    inner join ws_dim_tab dt
    on dt.dt_obj_key = dc.dc_obj_key
    where dt.dt_table_name IN ($dimWhere)
    and dc_key_type not in ('A', '0', '1')
    and dc_col_name_orig not in (
    	SELECT mn_name
    	from ws_meta_names
    	where mn_object  like 'dss%'
    )
    ) src
    on src.dc_obj_key = tgt.dc_obj_key
    and src.dc_col_key = tgt.dc_col_key
    when matched then
    update
    set tgt.dc_col_name = src.dc_col_name,
    tgt.dc_display_name = src.dc_display_name
    when not matched then
    insert values (
    	src.dc_obj_key
          ,src.dc_col_name
          ,src.dc_display_name
          ,src.dc_data_type
          ,src.dc_nulls_flag
          ,src.dc_numeric_flag
          ,src.dc_additive_flag
          ,src.dc_attribute_flag
          ,src.dc_eul_flag
          ,src.dc_format
          ,src.dc_src_table
          ,src.dc_src_column
          ,src.dc_src_strategy
          ,src.dc_order
          ,src.dc_key_type
          ,src.dc_business_key_ind
          ,src.dc_artificial_key_ind
          ,src.dc_zero_key_value
          ,src.dc_attributes
          ,src.dc_transform_type
          ,src.dc_transform_model
          ,src.dc_transform_code
          ,src.dc_doc_1
          ,src.dc_doc_2
          ,src.dc_doc_3
          ,src.dc_doc_4
          ,src.dc_doc_5
          ,src.dc_doc_6
          ,src.dc_doc_7
          ,src.dc_doc_8
          ,src.dc_doc_9
          ,src.dc_doc_10
          ,src.dc_doc_11
          ,src.dc_doc_12
          ,src.dc_doc_13
          ,src.dc_doc_14
          ,src.dc_doc_15
          ,src.dc_doc_16
          ,src.dc_primary_index_ind
          ,src.dc_join_flag
          ,src.dc_default_value
          ,src.dc_case_flag
          ,src.dc_title
          ,src.dc_compress_flag
          ,src.dc_compress_value
          ,src.dc_comments
          ,src.dc_col_type
          ,src.dc_update_flag
          ,src.dc_display_type
          ,src.dc_pre_join_source
          ,src.dc_ind_1
    );
"@

    try {
        $command = New-Object System.Data.Odbc.OdbcCommand($query,$metaOdbc)
        $command.CommandTimeout = 0
        $adapter = New-Object System.Data.Odbc.OdbcDataAdapter($command)
        $dimTableList = New-Object System.Data.DataTable
        $null = $adapter.fill($dimTableList)
				[System.Windows.Forms.MessageBox]::Show("$dimWhere" , "Table(s) converted to SCD6 successfully!")
				$logStream.WriteLine("Table(s) $dimWhere converted to SCD6")
    }
    catch {
        $errStream.WriteLine($_.Exception.Message)
        $errStream.WriteLine($_.InvocationInfo.PositionMessage)
        $errStream.WriteLine("Script failed. Dimension SCD6 creation failed")
        $errStream.WriteLine($query)
        $host.ui.WriteLine("-2")
        $host.ui.WriteLine("Script failed. Dimension SCD6 creation failed")
        Print-Log -exitStatus -2
        exit
    }
}

function GUI {

    $dimTableList = GET-DIMTABLES

    Add-Type -AssemblyName System.Windows.Forms
		Add-Type -AssemblyName System.Drawing
    $MyForm = New-Object system.Windows.Forms.Form
    
    $listDimTable = New-Object System.Windows.Forms.ListBox

    $btnSCD6 = New-Object System.Windows.Forms.Button

        $listDimTable.FormattingEnabled = $True
        $listDimTable.Location = New-Object System.Drawing.Point(10, 10)
        $listDimTable.Name = "dimTableList"
        $listDimTable.Size = New-Object System.Drawing.Size(240, 250)
        $listDimTable.TabIndex = 0
        $listDimTable.SelectionMode = 'MultiSimple'
        $listDimTable.DataSource = [array]($dimTableList.dt_table_name)

        $btnSCD6.Location = New-Object System.Drawing.Point(10, 270)
        $btnSCD6.Name = "btnSCD6"
        $btnSCD6.Size = New-Object System.Drawing.Size(240, 25)
        $btnSCD6.TabIndex = 1
        $btnSCD6.Text = "Create SCD6 Dimensions"
        $btnSCD6.UseVisualStyleBackColor = $True
        $btnSCD6.Add_Click({ CREATE-SCD6 -dimTableList $listDimTable.selectedItems })

				$MyForm.AutoScroll = $True
        $MyForm.MinimizeBox = $False
        $MyForm.MaximizeBox = $False
        $MyForm.WindowState = "Normal"
        $MyForm.SizeGripStyle = "Hide"
        $MyForm.ShowInTaskbar = $False
        $MyForm.StartPosition = "CenterScreen"
        $MyForm.Controls.Add($btnSCD6)
        $MyForm.Controls.Add($listDimTable)
        $MyForm.Name = "SCD6"
        $MyForm.Text = "WhereScape SCD6"
        $MyForm.Size = New-Object System.Drawing.Size(300, 350)
				$MyIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("${env:WSL_BINDIR}med.exe")
        $MyForm.Icon = $MyIcon

				$MyForm.ShowDialog() | Out-Null
}

try {

    # Initialize logging and message boxes
    #
    $fileAud = Join-Path -Path ${env:WSL_WORKDIR} -ChildPath "CREATE_SCD6_TABLE_${env:WSL_SEQUENCE}.aud"
    $fileErr = Join-Path -Path ${env:WSL_WORKDIR} -ChildPath "CREATE_SCD6_TABLE_${env:WSL_SEQUENCE}.err"
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


        $loopcntr = $loopcntr + 1

        # Show GUI and parse results
        #
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: Starting GUI") }
        $guiResults = GUI
        if(${env:DEBUG} -eq "TRUE") { $logStream.WriteLine("DEBUG: GUI Exited Successfully") }


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

