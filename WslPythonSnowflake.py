import WslPythonCommon
import pyodbc
import os
import sys
import fnmatch
import pytds
from pytds import login
#
#.DESCRIPTION
#Used to run any SQL against Snowflake
#.EXAMPLE
#return_Msg = Run-Snowflake-RedSQL "SELECT * FROM stage_customers" -dsn "dssdemo" "Some Error $step"
#
def RunSnowflakeRedSQL(sql,
                        dsn,
                        uid,
                        pwd,
                        failureMsg,
                        status,
                        step
    ):
    snowflakeResult =  WslPythonCommon.RunRedSQL(sql,str(os.getenv('WSL_TGT_DSN')),str(os.getenv('WSL_TGT_USER')), str(os.getenv('WSL_TGT_PWD')),'','', str(os.getenv('WSL_LOAD_FULLNAME')))
    if snowflakeResult[1] == 1:
      if snowflakeResult[2] >= 0:
        newvar = WslPythonCommon.WsWrkAudit ('I', "Step "+ str(step) + ": rows applied: " + str(snowflakeResult[2]),'','')
      else:
        newvar = WslPythonCommon.WsWrkAudit ('I',"Step " + str(step) +": completed"+str(snowflakeResult[4]),'','')
    else:
       db_msg = snowflakeResult[3][1]
       db_code = snowflakeResult[3][0]
       newvar =  WslPythonCommon.WsWrkAudit ('E', "Step "+ str(step) + ": An error has occurred: " + db_msg,'','')
       i=0
       while i <= int(len(sql)/250):
        length_n = len(sql) - ((i*250)+1)
        if length_n > 250:
           length_n = 250
        newvar = WslPythonCommon.WsWrkError('',sql[(i*250)+1:((i*250))+250],'','','')
        i=i+1
    return snowflakeResult[0], snowflakeResult[1], snowflakeResult[2],failureMsg , snowflakeResult[4]