  CREATE PROCEDURE snowflake_drop_trigger
  (
    @v_MatchString NVARCHAR(20)
  )
  AS
  BEGIN
    
    DECLARE @v_trigger NVARCHAR(64)
    DECLARE @v_sql     NVARCHAR(80)
    DECLARE @v_return  BIT
    
    DECLARE c_rstriggers CURSOR
    FOR 
      SELECT [name]
      FROM [sysobjects]
      WHERE [type] = 'TR'
      AND [name] LIKE @v_MatchString
    
    OPEN c_rstriggers
    
    FETCH NEXT FROM c_rstriggers
    INTO @v_trigger
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
      
      BEGIN TRY
      
        SELECT @v_sql = N'DROP TRIGGER ' + @v_trigger
        EXECUTE sp_executesql @v_sql
        
      END TRY
      BEGIN CATCH
      
        SET @v_return = 1
      
      END CATCH
      
      FETCH NEXT FROM c_rstriggers
      INTO @v_trigger
      
    END
    
    CLOSE c_rstriggers
    DEALLOCATE c_rstriggers
    
  END
  
