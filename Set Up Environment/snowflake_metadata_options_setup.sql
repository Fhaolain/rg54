INSERT INTO ws_obj_object (oo_name, oo_type_key) VALUES ('Snowflake', 11)
;
INSERT INTO ws_dbc_connect (dc_obj_key, dc_name) SELECT oo_obj_key, oo_name FROM ws_obj_object WHERE oo_name = 'Snowflake'
;
INSERT INTO ws_dbc_target (dt_name, dt_connect_key) SELECT 'load', oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake'
;
INSERT INTO ws_dbc_target (dt_name, dt_connect_key) SELECT 'stage', oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake'
;
INSERT INTO ws_dbc_target (dt_name, dt_connect_key) SELECT 'edw', oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake'
;
INSERT INTO ws_dbc_target (dt_name, dt_connect_key) SELECT 'data_vault', oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake'
;
UPDATE ws_dbc_connect 
SET dc_name = 'Repository' 
WHERE dc_name = 'DataWarehouse' 
;
UPDATE ws_obj_object 
SET oo_name = 'Repository' 
WHERE oo_name = 'DataWarehouse' 
;
UPDATE ws_dbc_connect 
SET dc_name = 'Runtime Connection for Scripts' 
WHERE dc_name = 'Windows' 
;
UPDATE ws_obj_object 
SET oo_name = 'Runtime Connection for Scripts' 
WHERE oo_name = 'Windows' 
;
UPDATE ws_dbc_connect 
SET dc_name = 'Database Source System' 
WHERE dc_name = 'Tutorial (OLTP)' 
;
UPDATE ws_obj_object 
SET oo_name = 'Database Source System' 
WHERE oo_name = 'Tutorial (OLTP)' 
;
UPDATE ws_dbc_connect
SET dc_type = 'D' 
, dc_method = 'IP' 
, dc_odbc_source = 'SNOWFLAKE_DW' 
, dc_extract_userid = 'SET THIS AND NEXT FIELD' 
, dc_attributes = 'DefLoad~=0013;Database link;DefLoadScriptCon~=0030;Runtime Connection for Scripts;DefUpdateScriptCon~=0030;Runtime Connection for Scripts;DefPreLoadAct~=0008;Truncate;DisplayDataSQL~=0053;SELECT * FROM $OBJECT$ SAMPLE ($MAXDISPLAYDATA$ ROWS);RowCountSQL~=0030;SELECT COUNT(*) FROM $OBJECT$ ;DropTableSQL~=0019;DROP TABLE $OBJECT$;DropViewSQL~=0018;DROP VIEW $OBJECT$;TruncateSQL~=0023;TRUNCATE TABLE $OBJECT$;OdbcDsnArch~=2;64;DefSch~=040;DEV_LOAD,DEV_STAGE,DEV_DATA_LAKE,DEV_EDW;TptLoadScriptArch~=2;32;DoNotCreateIndexes;' 
, dc_wizard_set_key = (SELECT mws_wizard_set_key FROM ws_meta_wizard_set WHERE mws_name ='SNOWFLAKE from SNOWFLAKE')
, dc_db_type_ind = 13
, dc_authentication = 'DefODBCUser~= 1;' 
WHERE  dc_name = 'Snowflake' 
;
UPDATE ws_dbc_connect
SET dc_attributes = 'DataWarehouse;Notes~=0094;This connection points back to the data warehouse and is used during drag and drop operations.;DefLoad~=0018;Database link load;FuncSet~=0009;SNOWFLAKE;LoadPortStart~=0;LoadPortEnd~=0;OdbcDsnArch~=2;64;DefSch~=003;dbo;TptLoadScriptArch~=2;32;' 
WHERE  dc_name = 'Repository' 
;
UPDATE ws_dbc_connect
SET dc_type = 'O' 
, dc_method = 'IP' 
, dc_odbc_source = 'SET THIS FIELD' 
, dc_extract_userid = 'SET THIS AND NEXT FIELD' 
, dc_attributes = 'DefLoad~=0017;Script based load;DefLoadScriptCon~=0030;Runtime Connection for Scripts;DefPreLoadAct~=0008;Truncate;LoadPortStart~=0;LoadPortEnd~=0;OdbcDsnArch~=2;64;DefSch~=003;dbo;TptLoadScriptArch~=2;32;' 
, dc_db_type_ind = 2
, dc_work_dir = 'c:\temp\' 
, dc_authentication = 'DefODBCUser~= 1;' 
WHERE  dc_name = 'Database Source System' 
;
INSERT INTO ws_obj_object (oo_name, oo_type_key) VALUES ('Windows Comma Sep Files', 11)
;
INSERT INTO ws_dbc_connect (dc_obj_key, dc_name) SELECT oo_obj_key, oo_name FROM ws_obj_object WHERE oo_name = 'Windows Comma Sep Files'
;
UPDATE ws_dbc_connect
SET dc_type = 'W' 
, dc_attributes = 'DefLoad~=0017;Script based load;LoadPortStart~=0;LoadPortEnd~=0;DefSch~=000;;' 
, dc_wizard_set_key = (SELECT mws_wizard_set_key FROM ws_meta_wizard_set WHERE mws_name ='SNOWFLAKE from File')
, dc_db_type_ind = 0
, dc_work_dir = 'C:\TEMP\' 
WHERE  dc_name = 'Windows Comma Sep Files' 
;
INSERT INTO ws_obj_object (oo_name, oo_type_key) VALUES ('Windows Pipe Sep Files', 11)
;
INSERT INTO ws_dbc_connect (dc_obj_key, dc_name) SELECT oo_obj_key, oo_name FROM ws_obj_object WHERE oo_name = 'Windows Pipe Sep Files'
;
UPDATE ws_dbc_connect
SET dc_type = 'W' 
, dc_attributes = 'DefLoad~=0017;Script based load;LoadPortStart~=0;LoadPortEnd~=0;DefSch~=000;;' 
, dc_wizard_set_key = (SELECT mws_wizard_set_key FROM ws_meta_wizard_set WHERE mws_name ='SNOWFLAKE from File')
, dc_db_type_ind = 0
, dc_work_dir = 'C:\TEMP\' 
WHERE  dc_name = 'Windows Pipe Sep Files' 
;
INSERT INTO ws_obj_object (oo_name, oo_type_key) VALUES ('Windows Fixed Width', 11)
;
INSERT INTO ws_dbc_connect (dc_obj_key, dc_name) SELECT oo_obj_key, oo_name FROM ws_obj_object WHERE oo_name = 'Windows Fixed Width'
;
UPDATE ws_dbc_connect
SET dc_type = 'W' 
, dc_attributes = 'DefLoad~=0017;Script based load;LoadPortStart~=0;LoadPortEnd~=0;DefSch~=000;;' 
, dc_wizard_set_key = (SELECT mws_wizard_set_key FROM ws_meta_wizard_set WHERE mws_name ='SNOWFLAKE from FIXED WIDTH FILE')
, dc_db_type_ind = 0
, dc_work_dir = 'C:\TEMP\' 
WHERE  dc_name = 'Windows Fixed Width' 
;
INSERT INTO ws_obj_object (oo_name, oo_type_key) VALUES ('Windows JSON Files', 11)
;
INSERT INTO ws_dbc_connect (dc_obj_key, dc_name) SELECT oo_obj_key, oo_name FROM ws_obj_object WHERE oo_name = 'Windows JSON Files'
;
UPDATE ws_dbc_connect
SET dc_type = 'W' 
, dc_attributes = 'DefLoad~=0017;Script based load;LoadPortStart~=0;LoadPortEnd~=0;DefSch~=000;;' 
, dc_wizard_set_key = (SELECT mws_wizard_set_key FROM ws_meta_wizard_set WHERE mws_name ='SNOWFLAKE from XML and JSON')
, dc_db_type_ind = 0
, dc_work_dir = 'C:\TEMP\' 
WHERE  dc_name = 'Windows JSON Files' 
;
INSERT INTO ws_obj_object (oo_name, oo_type_key) VALUES ('Windows XML Files', 11)
;
INSERT INTO ws_dbc_connect (dc_obj_key, dc_name) SELECT oo_obj_key, oo_name FROM ws_obj_object WHERE oo_name = 'Windows XML Files'
;
UPDATE ws_dbc_connect
SET dc_type = 'W' 
, dc_attributes = 'DefLoad~=0017;Script based load;LoadPortStart~=0;LoadPortEnd~=0;DefSch~=000;;' 
, dc_wizard_set_key = (SELECT mws_wizard_set_key FROM ws_meta_wizard_set WHERE mws_name ='SNOWFLAKE from XML and JSON')
, dc_db_type_ind = 0
, dc_work_dir = 'C:\TEMP\' 
WHERE  dc_name = 'Windows XML Files' 
;
UPDATE ws_dbc_target
SET    dt_database   = 'DEV_DW' 
     , dt_schema   = 'DEV_DATA_VAULT' 
     , dt_work_url   = '' 
     , dt_work_dir   = '' 
     , dt_tgt_attributes   = 'TGTCOLOR=000032960;' 
WHERE  dt_name   = 'data_vault' 
;
UPDATE ws_dbc_target
SET    dt_database   = 'DEV_DW' 
     , dt_schema   = 'DEV_EDW' 
     , dt_work_url   = '' 
     , dt_work_dir   = '' 
     , dt_tgt_attributes   = 'TGTCOLOR=005537792;' 
WHERE  dt_name   = 'edw' 
;
UPDATE ws_dbc_target
SET    dt_database   = 'DEV_DW' 
     , dt_schema   = 'DEV_LOAD' 
     , dt_work_url   = '' 
     , dt_work_dir   = '' 
     , dt_tgt_attributes   = 'TGTCOLOR=000000255;' 
WHERE  dt_name   = 'load' 
;
UPDATE ws_dbc_target
SET    dt_database   = 'DEV_DW' 
     , dt_schema   = 'DEV_STAGE' 
     , dt_work_url   = '' 
     , dt_work_dir   = '' 
     , dt_tgt_attributes   = 'TGTCOLOR=012582990;' 
WHERE  dt_name   = 'stage' 
;
UPDATE ws_meta
SET    meta_flags   = '~COY-Y-12CO;' 
     , meta_version_connect_save   = 'Y' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'CUSTOM_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'agg_build' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_idx' 
WHERE  mn_object   = 'agg_index' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'SRC_' 
     , mn_name   = 'Full table name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'agg_source' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'UPDATE_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'agg_update' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'CUSTOM_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'custom1_build' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'custom1_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_idx' 
WHERE  mn_object   = 'custom1_index' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_key' 
WHERE  mn_object   = 'custom1_key' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'SRC_' 
     , mn_name   = 'Full table name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'custom1_source' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'UPDATE_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'custom1_update' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'CUSTOM_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dim_build' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dim_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_idx' 
WHERE  mn_object   = 'dim_index' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_KEY' 
WHERE  mn_object   = 'dim_key' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'SRC_' 
     , mn_name   = 'Full table name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dim_source' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'UPDATE_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dim_update' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dim_view_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_KEY' 
WHERE  mn_object   = 'dim_view_key' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'dss_batch' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dss_batch_table' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'DSS_CHANGE_HASH' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dss_change_hash' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'WSL_NOT_USED_BY_DSS' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dss_count' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'DSS_CREATE_TIME' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dss_create_time' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'DSS_CURRENT_FLAG' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dss_current_flag' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'DSS_END_DATE' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dss_end_date' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'dss_fact_table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dss_fact_table' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'dss_file_name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dss_file_name' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'DSS_LOAD_DATE' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dss_load_date' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'DSS_RECORD_SOURCE' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dss_record_source' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'WSL_NOT_USED_BY_DSS' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dss_source_system' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'DSS_START_DATE' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dss_start_date' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'DSS_UPDATE_TIME' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dss_update_time' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'DSS_VERSION' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'dss_version' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'POST_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'export_export' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'SCRIPT_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'export_script' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'CUSTOM_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'fact_build' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'fact_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_idx' 
WHERE  mn_object   = 'fact_index' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_KEY' 
WHERE  mn_object   = 'fact_key' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'CUSTOM_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'fact_kpi_build' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'fact_kpi_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_idx' 
WHERE  mn_object   = 'fact_kpi_index' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'UPDATE_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'fact_kpi_update' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'SRC_' 
     , mn_name   = 'Full table name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'fact_source' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'UPDATE_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'fact_update' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'CUSTOM_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'hub_build' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'hub_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_idx' 
WHERE  mn_object   = 'hub_index' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'HK_' 
     , mn_name   = 'Full table name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'hub_key' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'SRC_' 
     , mn_name   = 'Full table name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'hub_source' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'UPDATE_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'hub_update' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'CUSTOM_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'link_build' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'link_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'UPDATE_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'link_update' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_idx' 
WHERE  mn_object   = 'lnk_index' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'HK_' 
     , mn_name   = 'Full table name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'lnk_key' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'SRC_' 
     , mn_name   = 'Full table name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'lnk_source' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_idx' 
WHERE  mn_object   = 'load_index' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'POST_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'load_load' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'SCRIPT_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'load_script' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'CUSTOM_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'normal_build' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'normal_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'UPDATE_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'normal_update' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'CUSTOM_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'ods_build' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'ods_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_idx' 
WHERE  mn_object   = 'ods_index' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_KEY' 
WHERE  mn_object   = 'ods_key' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'SRC_' 
     , mn_name   = 'Full table name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'ods_source' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'UPDATE_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'ods_update' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_idx' 
WHERE  mn_object   = 'sat_index' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'HK_' 
     , mn_name   = 'Full table name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'sat_key' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'SRC_' 
     , mn_name   = 'Full table name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'sat_source' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'CUSTOM_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'satellite_build' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'satellite_get' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'UPDATE_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'satellite_update' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'CUSTOM_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'stage_build' 
;
UPDATE ws_meta_names
SET    mn_prefix   = '' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '_idx' 
WHERE  mn_object   = 'stage_index' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'SRC_' 
     , mn_name   = 'Full table name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'stage_source' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'UPDATE_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'stage_update' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'CUSTOM_' 
     , mn_name   = 'Full table' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'view_build' 
;
UPDATE ws_meta_names
SET    mn_prefix   = 'update_' 
     , mn_name   = 'Short name' 
     , mn_postfix   = '' 
WHERE  mn_object   = 'view_update' 
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=10198015;OBJCOLORTXT=16777215;OBJTGTKEY=3;OBJTGTSET=1;OBJSUBTYPE=;AUTOADDKEY=N;' 
     , ot_position   = 11
     , ot_pre_fix   = 'FACT_' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = 'Kpi Fact Table' 
WHERE  ot_type_key   = 2
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=10223515;OBJCOLORTXT=0;OBJTGTKEY=0;OBJTGTSET=1;OBJSUBTYPE=;AUTOADDKEY=N;' 
     , ot_position   = 20
     , ot_pre_fix   = '' 
     , ot_end_user_visible   = 'N' 
     , ot_description   = 'Host Script' 
WHERE  ot_type_key   = 3
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=5263615;OBJCOLORTXT=16777215;OBJTGTKEY=3;OBJTGTSET=1;OBJSUBTYPE=D;AUTOADDKEY=N;' 
     , ot_position   = 11
     , ot_pre_fix   = 'FACT_' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = 'Fact Table' 
WHERE  ot_type_key   = 5
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=16751515;OBJCOLORTXT=16777215;OBJTGTKEY=3;OBJTGTSET=1;OBJSUBTYPE=D;AUTOADDKEY=Y;' 
     , ot_position   = 10
     , ot_pre_fix   = 'DIM_' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = 'Dimension' 
WHERE  ot_type_key   = 6
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=10197915;OBJCOLORTXT=16777215;OBJTGTKEY=2;OBJTGTSET=1;OBJSUBTYPE=S;AUTOADDKEY=N;' 
     , ot_position   = 4
     , ot_pre_fix   = 'STAGE_' 
     , ot_end_user_visible   = 'N' 
     , ot_description   = 'Stage Table' 
WHERE  ot_type_key   = 7
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=8970827;OBJCOLORTXT=16777215;OBJTGTKEY=1;OBJTGTSET=1;OBJSUBTYPE=;AUTOADDKEY=N;' 
     , ot_position   = 3
     , ot_pre_fix   = 'LOAD_' 
     , ot_end_user_visible   = 'N' 
     , ot_description   = 'Load Table' 
WHERE  ot_type_key   = 8
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=13158655;OBJCOLORTXT=16777215;OBJTGTKEY=3;OBJTGTSET=1;OBJSUBTYPE=A;AUTOADDKEY=N;' 
     , ot_position   = 12
     , ot_pre_fix   = 'AGG_' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = 'Aggregate' 
WHERE  ot_type_key   = 9
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=16765650;OBJCOLORTXT=16777215;OBJTGTKEY=0;OBJTGTSET=1;OBJSUBTYPE=;AUTOADDKEY=N;' 
     , ot_position   = 0
     , ot_pre_fix   = 'DIM_' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = 'Dimension View' 
WHERE  ot_type_key   = 12
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=10223515;OBJCOLORTXT=0;OBJTGTKEY=0;OBJTGTSET=1;OBJSUBTYPE=;AUTOADDKEY=N;' 
     , ot_position   = 15
     , ot_pre_fix   = 'EXP_' 
     , ot_end_user_visible   = 'N' 
     , ot_description   = 'Export' 
WHERE  ot_type_key   = 13
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=16742331;OBJCOLORTXT=16777215;OBJTGTKEY=3;OBJTGTSET=1;OBJSUBTYPE=V;AUTOADDKEY=N;' 
     , ot_position   = 13
     , ot_pre_fix   = 'VIEW_' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = 'View' 
WHERE  ot_type_key   = 18
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=10223515;OBJCOLORTXT=0;OBJTGTKEY=0;OBJTGTSET=1;OBJSUBTYPE=;AUTOADDKEY=N;' 
     , ot_position   = 0
     , ot_pre_fix   = 'JOIN_' 
     , ot_end_user_visible   = 'N' 
     , ot_description   = 'Join Index' 
WHERE  ot_type_key   = 20
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=5921525;OBJCOLORTXT=16777215;OBJTGTKEY=0;OBJTGTSET=0;OBJSUBTYPE=;AUTOADDKEY=N;' 
     , ot_position   = 0
     , ot_pre_fix   = 'OLAP_' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = 'Olap Cube' 
WHERE  ot_type_key   = 23
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=16101295;OBJCOLORTXT=16777215;OBJTGTKEY=0;OBJTGTSET=0;OBJSUBTYPE=;AUTOADDKEY=N;' 
     , ot_position   = 0
     , ot_pre_fix   = 'ODIM_' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = 'Olap Dimension' 
WHERE  ot_type_key   = 24
;
UPDATE ws_obj_type
SET    ot_options   = '' 
     , ot_position   = 0
     , ot_pre_fix   = 'OROLE_' 
     , ot_end_user_visible   = 'N' 
     , ot_description   = 'Olap Role' 
WHERE  ot_type_key   = 25
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=65535;OBJCOLORTXT=0;OBJTGTKEY=3;OBJTGTSET=1;OBJSUBTYPE=H;AUTOADDKEY=N;' 
     , ot_position   = 5
     , ot_pre_fix   = 'ODS_' 
     , ot_end_user_visible   = 'N' 
     , ot_description   = 'Data Store' 
WHERE  ot_type_key   = 26
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=1872874;OBJCOLORTXT=16777215;OBJTGTKEY=3;OBJTGTSET=1;OBJSUBTYPE=N;AUTOADDKEY=N;' 
     , ot_position   = 9
     , ot_pre_fix   = 'EDW_' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = 'EDW 3NF' 
WHERE  ot_type_key   = 27
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=16711680;OBJCOLORTXT=16777215;OBJTGTKEY=4;OBJTGTSET=1;OBJSUBTYPE=D;AUTOADDKEY=N;' 
     , ot_position   = 6
     , ot_pre_fix   = 'H_' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = 'Hub' 
WHERE  ot_type_key   = 28
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=65535;OBJCOLORTXT=0;OBJTGTKEY=4;OBJTGTSET=1;OBJSUBTYPE=H;AUTOADDKEY=N;' 
     , ot_position   = 8
     , ot_pre_fix   = 'S_' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = 'Satellite' 
WHERE  ot_type_key   = 29
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=255;OBJCOLORTXT=16777215;OBJTGTKEY=4;OBJTGTSET=1;OBJSUBTYPE=D;AUTOADDKEY=N;' 
     , ot_position   = 7
     , ot_pre_fix   = 'L_' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = 'Link' 
WHERE  ot_type_key   = 30
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=1872874;OBJCOLORTXT=16777215;OBJTGTKEY=1;OBJTGTSET=1;OBJSUBTYPE=D;AUTOADDKEY=N;' 
     , ot_position   = 2
     , ot_pre_fix   = 'FMT_RED_' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = 'File Format' 
WHERE  ot_type_key   = 31
;
UPDATE ws_obj_type
SET    ot_options   = 'OBJCOLOR=1872874;OBJCOLORTXT=16777215;OBJTGTKEY=1;OBJTGTSET=1;OBJSUBTYPE=D;AUTOADDKEY=N;' 
     , ot_position   = 18
     , ot_pre_fix   = 'SF_STG_' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = 'Extensions' 
WHERE  ot_type_key   = 32
;
UPDATE ws_obj_type
SET    ot_options   = '' 
     , ot_position   = 6
     , ot_pre_fix   = '' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = ' Column' 
WHERE  ot_type_key   = 109
;
UPDATE ws_obj_type
SET    ot_options   = '' 
     , ot_position   = 8
     , ot_pre_fix   = '' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = ' Column' 
WHERE  ot_type_key   = 110
;
UPDATE ws_obj_type
SET    ot_options   = '' 
     , ot_position   = 7
     , ot_pre_fix   = '' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = ' Column' 
WHERE  ot_type_key   = 111
;
UPDATE ws_obj_type
SET    ot_options   = '' 
     , ot_position   = 2
     , ot_pre_fix   = '' 
     , ot_end_user_visible   = 'Y' 
     , ot_description   = ' Column' 
WHERE  ot_type_key   = 112
;
UPDATE ws_database_type_attributes
SET    dta_value   = 'CAST(''1900-01-01 00:00:00'' AS TIMESTAMP)' 
WHERE  dta_key           = 'StartDateForInitialMember' 
AND    dta_part_number   = 1
AND    dta_db_type       = 13
;
UPDATE ws_database_type_attributes
SET    dta_value   = 'CAST(''2999-12-31 00:00:00'' AS TIMESTAMP)' 
WHERE  dta_key           = 'EndDateForCurrentMember' 
AND    dta_part_number   = 1
AND    dta_db_type       = 13
;
UPDATE ws_database_type_attributes
SET    dta_value   = 'CAST(CURRENT_TIMESTAMP AS TIMESTAMP)' 
WHERE  dta_key           = 'StartDateForNewMemberEntry' 
AND    dta_part_number   = 1
AND    dta_db_type       = 13
;
UPDATE ws_database_type_attributes
SET    dta_value   = 'DATEADD(DAYS, -1, CAST(CURRENT_TIMESTAMP AS TIMESTAMP))' 
WHERE  dta_key           = 'EndDateForExpiringMemberEntry' 
AND    dta_part_number   = 1
AND    dta_db_type       = 13
;
UPDATE ws_database_type_attributes
SET    dta_value   = 'CAST(CURRENT_TIMESTAMP AS TIMESTAMP)' 
WHERE  dta_key           = 'LoadDateTransformation' 
AND    dta_part_number   = 1
AND    dta_db_type       = 13
;
UPDATE ws_database_type_attributes
SET    dta_value   = 'TIMESTAMP' 
WHERE  dta_key           = 'dss_create_time Data Type' 
AND    dta_part_number   = 1
AND    dta_db_type       = 13
;
UPDATE ws_database_type_attributes
SET    dta_value   = 'TIMESTAMP' 
WHERE  dta_key           = 'dss_update_time Data Type' 
AND    dta_part_number   = 1
AND    dta_db_type       = 13
;
UPDATE ws_database_type_attributes
SET    dta_value   = 'TIMESTAMP' 
WHERE  dta_key           = 'dss_start_date Data Type' 
AND    dta_part_number   = 1
AND    dta_db_type       = 13
;
UPDATE ws_database_type_attributes
SET    dta_value   = 'TIMESTAMP' 
WHERE  dta_key           = 'dss_end_date Data Type' 
AND    dta_part_number   = 1
AND    dta_db_type       = 13
;
UPDATE ws_database_type_attributes
SET    dta_value   = 'INTEGER' 
WHERE  dta_key           = 'dss_version Data Type' 
AND    dta_part_number   = 1
AND    dta_db_type       = 13
;
UPDATE ws_database_type_attributes
SET    dta_value   = 'CHAR(1)' 
WHERE  dta_key           = 'dss_current_flag Data Type' 
AND    dta_part_number   = 1
AND    dta_db_type       = 13
;
UPDATE ws_database_type_attributes
SET    dta_value   = 'INTEGER' 
WHERE  dta_key           = 'dss_count Data Type' 
AND    dta_part_number   = 1
AND    dta_db_type       = 13
;
UPDATE ws_database_type_attributes
SET    dta_value   = 'CHAR(32)' 
WHERE  dta_key           = 'dss_change_hash Data Type' 
AND    dta_part_number   = 1
AND    dta_db_type       = 13
;
UPDATE ws_database_type_attributes
SET    dta_value   = 'TIMESTAMP' 
WHERE  dta_key           = 'dss_load_date' 
AND    dta_part_number   = 1
AND    dta_db_type       = 13
;
UPDATE ws_database_type_attributes
SET    dta_value   = 'VARCHAR(64)' 
WHERE  dta_key           = 'dss_record_source Data Type' 
AND    dta_part_number   = 1
AND    dta_db_type       = 13
;
UPDATE ws_obj_type 
SET ot_options = 'OBJCOLOR=65535;OBJCOLORTXT=0;OBJTGTKEY=0;OBJTGTSET=0;OBJSUBTYPE=H;AUTOADDKEY=N;' 
WHERE ot_type_key IN (2,5,6,7,8,9,18,26,27,28,29,30,31) 
AND NULLIF(RTRIM(CAST(ot_options AS VARCHAR(4000))),'') IS NULL 
;
UPDATE ws_obj_type 
SET ot_options = REPLACE(CAST(ot_options AS VARCHAR(4000)),'OBJTGTSET=0','OBJTGTSET=1') 
WHERE ot_type_key IN (2,5,6,7,8,9,18,26,27,28,29,30,31) 
;
UPDATE ws_obj_type 
SET ot_options = SUBSTRING(CAST(ot_options AS VARCHAR(4000)),1,CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000)))-1)+'OBJTGTKEY='+(SELECT CAST(dt_target_key AS VARCHAR(10)) FROM ws_dbc_target WHERE dt_name = 'load')+';'+SUBSTRING(CAST(ot_options AS VARCHAR(4000)),CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000)))+CHARINDEX(';',SUBSTRING(CAST(ot_options AS VARCHAR(4000)),CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000))),100)),1000) 
WHERE ot_type_key IN (8,31) 
;
UPDATE ws_obj_type 
SET ot_options = SUBSTRING(CAST(ot_options AS VARCHAR(4000)),1,CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000)))-1)+'OBJTGTKEY='+(SELECT CAST(dt_target_key AS VARCHAR(10)) FROM ws_dbc_target WHERE dt_name = 'stage')+';'+SUBSTRING(CAST(ot_options AS VARCHAR(4000)),CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000)))+CHARINDEX(';',SUBSTRING(CAST(ot_options AS VARCHAR(4000)),CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000))),100)),1000) 
WHERE ot_type_key IN (7) 
;
UPDATE ws_obj_type 
SET ot_options = SUBSTRING(CAST(ot_options AS VARCHAR(4000)),1,CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000)))-1)+'OBJTGTKEY='+(SELECT CAST(dt_target_key AS VARCHAR(10)) FROM ws_dbc_target WHERE dt_name = 'data_vault')+';'+SUBSTRING(CAST(ot_options AS VARCHAR(4000)),CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000)))+CHARINDEX(';',SUBSTRING(CAST(ot_options AS VARCHAR(4000)),CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000))),100)),1000) 
WHERE ot_type_key IN (28,29,30) 
;
UPDATE ws_obj_type 
SET ot_options = SUBSTRING(CAST(ot_options AS VARCHAR(4000)),1,CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000)))-1)+'OBJTGTKEY='+(SELECT CAST(dt_target_key AS VARCHAR(10)) FROM ws_dbc_target WHERE dt_name = 'edw')+';'+SUBSTRING(CAST(ot_options AS VARCHAR(4000)),CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000)))+CHARINDEX(';',SUBSTRING(CAST(ot_options AS VARCHAR(4000)),CHARINDEX('OBJTGTKEY=',CAST(ot_options AS VARCHAR(4000))),100)),1000) 
WHERE ot_type_key IN (6,2,5,9,18,26,27) 
;
UPDATE ws_table_attributes
SET    ta_text_1   = 'SSIS 2012' 
     , ta_text_2   = '' 
     , ta_text_3   = ';' 
     , ta_ind_1    = 'Y' 
     , ta_ind_2    = 'N' 
     , ta_ind_3    = '' 
     , ta_val_1    = 2
     , ta_val_2    = 2
     , ta_val_3    = 1
WHERE  ta_obj_key   = 0
AND    ta_type      = 'M' 
;
INSERT INTO ws_table_attributes
( ta_obj_key
, ta_type
, ta_text_1
, ta_text_2
, ta_text_3
, ta_text_4
, ta_text_5
, ta_text_6
, ta_text_7
, ta_text_8
, ta_val_1
, ta_val_2
, ta_val_3
, ta_val_4
, ta_val_5
, ta_val_6
, ta_val_7
, ta_val_8
) SELECT 0
, 'R'
, 'Add Transforms to a Fixed Width Stage Table'
, 'Create New Range Tables '
, 'Pause a Ranged Table'
, 'Restart a Ranged Table'
, 'Retrofit Fivetran Tables'
, 'Parse JSON  load->stage'
, 'Job Versioning'
, 'Job Maintenance'
, oo1.oo_obj_key
, oo2.oo_obj_key
, oo3.oo_obj_key
, oo4.oo_obj_key
, oo5.oo_obj_key
, oo6.oo_obj_key
, oo7.oo_obj_key
, oo8.oo_obj_key
FROM ws_obj_object oo1
CROSS JOIN ws_obj_object oo2
CROSS JOIN ws_obj_object oo3
CROSS JOIN ws_obj_object oo4
CROSS JOIN ws_obj_object oo5
CROSS JOIN ws_obj_object oo6
CROSS JOIN ws_obj_object oo7
CROSS JOIN ws_obj_object oo8
WHERE oo1.oo_name = 'snowflake_fixed_width_setup'
AND   oo2.oo_name = 'snowflake_create_range_table'
AND   oo3.oo_name = 'snowflake_ranged_table_pause'
AND   oo4.oo_name = 'snowflake_ranged_table_restart'
AND   oo5.oo_name = 'snowflake_retrofit_fivetran_tables'
AND   oo6.oo_name = 'snowflake_parse_json_load_tables'
AND   oo7.oo_name = 'snowflake_job_versioning_extensions'
AND   oo8.oo_name = 'snowflake_job_maintenance_extensions'
;
UPDATE ws_table_attributes
SET    ta_text_1   = 'Version=08010;sbtype=Set;sansijoin=TRUE;Distinct~;Select_Hint:~;Update~;Minus_Update:;Update_Hint:TABLOCK~;Insert~;Minus_Insert:;Insert_Hint:TABLOCK~;' 
     , ta_text_2   = '' 
     , ta_text_3   = '' 
     , ta_ind_1    = '' 
     , ta_ind_2    = '' 
     , ta_ind_3    = '' 
     , ta_val_1    = CAST(NULL AS INTEGER)
     , ta_val_2    = CAST(NULL AS INTEGER)
     , ta_val_3    = 0
WHERE  ta_obj_key   = -28
AND    ta_type      = 'M' 
;
UPDATE ws_table_attributes
SET    ta_text_1   = 'Version=08010;sbtype=Set;sansijoin=TRUE;Distinct~;Select_Hint:~;Update~;Minus_Update:;Update_Hint:TABLOCK~;Insert~;Minus_Insert:;Insert_Hint:TABLOCK~;' 
     , ta_text_2   = '' 
     , ta_text_3   = '' 
     , ta_ind_1    = '' 
     , ta_ind_2    = '' 
     , ta_ind_3    = '' 
     , ta_val_1    = CAST(NULL AS INTEGER)
     , ta_val_2    = CAST(NULL AS INTEGER)
     , ta_val_3    = 0
WHERE  ta_obj_key   = -29
AND    ta_type      = 'M' 
;
UPDATE ws_table_attributes
SET    ta_text_1   = 'Version=08010;sbtype=Set;sansijoin=TRUE;Distinct~;Select_Hint:~;Update~;Minus_Update:;Update_Hint:TABLOCK~;Insert~;Minus_Insert:;Insert_Hint:TABLOCK~;' 
     , ta_text_2   = '' 
     , ta_text_3   = '' 
     , ta_ind_1    = '' 
     , ta_ind_2    = '' 
     , ta_ind_3    = '' 
     , ta_val_1    = CAST(NULL AS INTEGER)
     , ta_val_2    = CAST(NULL AS INTEGER)
     , ta_val_3    = 0
WHERE  ta_obj_key   = -30
AND    ta_type      = 'M' 
;
INSERT INTO ws_table_attributes
( ta_obj_key
, ta_type
, ta_ind_1
, ta_val_1
) SELECT oo0.oo_obj_key
, 'L'
, '4'
, oo1.oo_obj_key
FROM ws_obj_object oo1
CROSS JOIN ws_obj_object oo0
WHERE oo1.oo_name = 'wsl_snowflake_pscript_load'
AND   oo0.oo_name = 'Database Source System'
;
INSERT INTO ws_table_attributes
( ta_obj_key
, ta_type
, ta_ind_1
, ta_ind_2
, ta_ind_3
, ta_ind_4
, ta_val_1
, ta_val_2
, ta_val_3
, ta_val_4
) SELECT oo0.oo_obj_key
, 'L'
, '3'
, '4'
, '6'
, '9'
, oo1.oo_obj_key
, oo2.oo_obj_key
, oo3.oo_obj_key
, oo4.oo_obj_key
FROM ws_obj_object oo1
CROSS JOIN ws_obj_object oo2
CROSS JOIN ws_obj_object oo3
CROSS JOIN ws_obj_object oo4
CROSS JOIN ws_obj_object oo0
WHERE oo1.oo_name = 'wsl_snowflake_create_table'
AND   oo2.oo_name = 'wsl_snowflake_pscript_load'
AND   oo3.oo_name = 'wsl_snowflake_create_view'
AND   oo4.oo_name = 'wsl_snowflake_alter_ddl'
AND   oo0.oo_name = 'Snowflake'
;
INSERT INTO ws_table_attributes
( ta_obj_key
, ta_type
, ta_text_1
, ta_val_1
) SELECT oo0.oo_obj_key
, 'E'
, ''
, oo1.oo_obj_key
FROM ws_obj_object oo1
CROSS JOIN ws_obj_object oo0
WHERE oo1.oo_name = 'wsl_snowflake_table_information'
AND   oo0.oo_name = 'Snowflake'
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'DEBUG_MODE') 
     , (SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
     , 'FALSE' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'FILE_FORMAT') 
     , (SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
     , 'FMT_RED_CSV_NOSKIP_GZIP_PIPE' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'RANGE_CONCATWORD') 
     , (SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
     , '+' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'RANGE_EXTRACT_CHARSET') 
     , (SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
     , 'ASCII' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'RANGE_FAIL_ON_THREAD_FAILURE') 
     , (SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
     , 'FALSE' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'RANGE_MAX_THREAD_FAILURES') 
     , (SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
     , '10' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'RANGE_THREAD_COUNT') 
     , (SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
     , '4' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'RANGE_UNLOAD_GZIP') 
     , (SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
     , 'TRUE' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'RANGE_UPLOAD_MAX_RETRIES') 
     , (SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
     , '3' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'SEND_FILES_ZIPPED') 
     , (SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
     , 'TRUE' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'SPLIT_FILE_COUNT') 
     , (SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
     , '1' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'SPLIT_FILE_THRESHOLD') 
     , (SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
     , '1000000' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'UNICODE_SUPPORT') 
     , (SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
     , 'FALSE' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'UNLOAD_DELIMITER') 
     , (SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
     , '|' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'UNLOAD_ENCLOSED_BY') 
     , (SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
     , '"' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'UNLOAD_ESCAPE_CHAR') 
     , (SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
     , '#' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'SNOWSQL_ACCOUNT') 
,(SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
,'Your Snowflake Account without .snowflakecomputing.com' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'SNOWSQL_DATABASE') 
,(SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
,'Your Snowflake Database' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'SNOWSQL_WAREHOUSE') 
,(SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Snowflake') 
,'Your Snowflake Warehouse' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'FILE_FORMAT') 
,(SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Windows Comma Sep Files') 
,'FMT_RED_CSV_SKIP_GZIP_COMMA' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'FILE_FORMAT') 
,(SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Windows Fixed Width') 
,'FMT_RED_FIX_NOSKIP_GZIP' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'FILE_FORMAT') 
,(SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Windows JSON Files') 
,'FMT_RED_JSON_GZIP' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'FILE_FORMAT') 
,(SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Windows Pipe Sep Files') 
,'FMT_RED_CSV_SKIP_GZIP_PIPE' 
FROM ws_meta 
;
INSERT INTO ws_ext_prop_value (epv_def_key,epv_obj_key,epv_value) 
SELECT (SELECT epd_key FROM ws_ext_prop_def WHERE epd_display_name = 'FILE_FORMAT') 
,(SELECT oo_obj_key FROM ws_obj_object WHERE oo_name = 'Windows XML Files') 
,'FMT_RED_XML_GZIP' 
FROM ws_meta 
;
