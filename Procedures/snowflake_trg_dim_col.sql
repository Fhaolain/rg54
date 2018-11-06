CREATE TRIGGER snowflake_trg_dim_col
ON ws_dim_col
AFTER INSERT,UPDATE,DELETE
AS
BEGIN

  DECLARE @v_obj_key             INTEGER;
  DECLARE @v_col_name            VARCHAR(64);
  DECLARE @v_key_type            VARCHAR(10);
  DECLARE @v_old_col_name        VARCHAR(64);
  DECLARE @v_old_key_type        VARCHAR(10);
  DECLARE @v_ext_prop_cnt        INTEGER;
  DECLARE @v_def_key             INTEGER;

	DECLARE @v_action CHAR(1);
  SET @v_action = (CASE WHEN EXISTS(SELECT * FROM INSERTED)
                        AND  EXISTS(SELECT * FROM DELETED)
                        THEN 'U'  -- Set Action to Updated.
                        WHEN EXISTS(SELECT * FROM INSERTED)
                        THEN 'I'  -- Set Action to Insert.
                        WHEN EXISTS(SELECT * FROM DELETED)
                        THEN 'D'  -- Set Action to Deleted.
                        ELSE NULL -- Skip. It may have been a "failed delete".   
                    END)

  SELECT @v_def_key = epd_key
  FROM   ws_ext_prop_def
  WHERE  epd_variable_name = 'SF_TYPE_3_COLS';

  -- If a column is added to the dimension
  IF ( @v_action = 'I' )
  BEGIN
  
    SELECT @v_obj_key = dc_obj_key
         , @v_col_name = dc_col_name
         , @v_key_type = dc_key_type
    FROM   INSERTED;

    -- If the new column is a type 3 previous value column
    IF ( ISNULL(NULLIF(RTRIM(@v_key_type),''),'~') = '4' )
    BEGIN

      SELECT @v_ext_prop_cnt = COUNT(*)
      FROM   ws_ext_prop_value
      WHERE  epv_def_key = @v_def_key
      AND    epv_obj_key = @v_obj_key;
    
      IF ( @v_ext_prop_cnt = 1 )
      BEGIN
  
        UPDATE ws_ext_prop_value
        SET    epv_value = epv_value + '|' + @v_col_name + '|'
        WHERE  epv_def_key = @v_def_key
        AND    epv_obj_key = @v_obj_key
        AND    epv_value NOT LIKE '%|' + @v_col_name + '|%';
  
      END
      ELSE
      BEGIN
  
        INSERT INTO ws_ext_prop_value
        ( epv_def_key
        , epv_obj_key
        , epv_value)
        VALUES
        ( @v_def_key
        , @v_obj_key
        , '|' + @v_col_name + '|');
  
      END
    END
  END

  -- If a dimension column is updated
  IF ( @v_action = 'U' )
  BEGIN
  
    SELECT @v_obj_key = dc_obj_key
         , @v_col_name = dc_col_name
         , @v_key_type = dc_key_type
    FROM   INSERTED;

    SELECT @v_old_col_name = dc_col_name
         , @v_old_key_type = dc_key_type
    FROM   DELETED;

    -- When the column has been renamed, fix the extended property value
    IF ( @v_col_name <> @v_old_col_name )
    BEGIN

      UPDATE ws_ext_prop_value
      SET    epv_value = REPLACE(epv_value, '|' + @v_old_col_name + '|', '|' + @v_col_name + '|')
      WHERE  epv_def_key = @v_def_key
      AND    epv_obj_key = @v_obj_key
      AND    epv_value LIKE '%|' + @v_old_col_name + '|%';

    END

    -- If the updated column is a type 3 previous value column but was NOT before the update
    IF (( ISNULL(NULLIF(RTRIM(@v_key_type),''),'~') = '4' ) AND ( ISNULL(NULLIF(RTRIM(@v_old_key_type),''),'~') <> '4' ))
    BEGIN

      SELECT @v_ext_prop_cnt = COUNT(*)
      FROM   ws_ext_prop_value
      WHERE  epv_def_key = @v_def_key
      AND    epv_obj_key = @v_obj_key;
    
      IF ( @v_ext_prop_cnt = 1 )
      BEGIN
  
        UPDATE ws_ext_prop_value
        SET    epv_value = epv_value + '|' + @v_col_name + '|'
        WHERE  epv_def_key = @v_def_key
        AND    epv_obj_key = @v_obj_key
        AND    epv_value NOT LIKE '%|' + @v_col_name + '|%';
  
      END
      ELSE
      BEGIN
  
        INSERT INTO ws_ext_prop_value
        ( epv_def_key
        , epv_obj_key
        , epv_value)
        VALUES
        ( @v_def_key
        , @v_obj_key
        , '|' + @v_col_name + '|');
  
      END
    END

    -- If the updated column is NOT a type 3 previous value column but was before the update
    IF (( ISNULL(NULLIF(RTRIM(@v_key_type),''),'~') <> '4' ) AND ( ISNULL(NULLIF(RTRIM(@v_old_key_type),''),'~') = '4' ))
    BEGIN

      UPDATE ws_ext_prop_value
      SET    epv_value = REPLACE(epv_value, '|' + @v_col_name + '|', '')
      WHERE  epv_def_key = @v_def_key
      AND    epv_obj_key = @v_obj_key
      AND    epv_value LIKE '%|' + @v_col_name + '|%';

    END
  END

  -- If a column is deleted from the dimension
  IF ( @v_action = 'D' )
  BEGIN
  
    SELECT @v_obj_key = dc_obj_key
         , @v_col_name = dc_col_name
         , @v_key_type = dc_key_type
    FROM   DELETED;

    -- If the deleted column was a type 3 previous value column
    IF ( ISNULL(NULLIF(RTRIM(@v_key_type),''),'~') = '4' )
    BEGIN

      UPDATE ws_ext_prop_value
      SET    epv_value = REPLACE(epv_value, '|' + @v_col_name + '|', '')
      WHERE  epv_def_key = @v_def_key
      AND    epv_obj_key = @v_obj_key
      AND    epv_value LIKE '%|' + @v_col_name + '|%';

    END
  END

  -- Clean up when no extended property value left (row gets deleted)
  IF ( @v_action IN ('U','D') )
  BEGIN

    SELECT @v_ext_prop_cnt = COUNT(*)
    FROM   ws_ext_prop_value
    WHERE  epv_def_key = @v_def_key
    AND    epv_obj_key = @v_obj_key
    AND    NULLIF(RTRIM(REPLACE(epv_value,'|','')),'') IS NULL;

    IF ( @v_ext_prop_cnt = 1 )
    BEGIN

      DELETE FROM ws_ext_prop_value
      WHERE  epv_def_key = @v_def_key
      AND    epv_obj_key = @v_obj_key;

    END

  END

END
