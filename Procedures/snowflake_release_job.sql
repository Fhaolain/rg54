  CREATE PROCEDURE snowflake_release_job
  (
    @v_JobName VARCHAR(80)
  )
  AS
  BEGIN
  
    DECLARE @v_return_code VARCHAR(1)
    DECLARE @v_return_msg  VARCHAR(256)
    DECLARE @v_result_num  INTEGER
  
    EXEC Ws_Job_Release NULL
                      , NULL
                      , NULL
                      , NULL
                      , NULL
                      , @v_JobName
                      , @v_return_code OUTPUT
                      , @v_return_msg  OUTPUT
                      , @v_result_num  OUTPUT
  
  END
