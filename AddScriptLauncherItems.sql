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


