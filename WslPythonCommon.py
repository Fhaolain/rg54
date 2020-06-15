#.DESCRIPTION Used to hide the evil black box of death #
import win32console
import win32gui
import pyodbc
import os
import sys
import fnmatch
import pytds
from pytds import login
import warnings
from win32ctypes.pywin32.win32api import *
from ctypes import*


#
#.DESCRIPTION
#Used to hide the evil black box of death
#win32console -- Interface to the Windows Console functions for dealing with character-mode applications
#win32gui -- Python extensions for Microsoft Windows’ Provides access to much of the Win32 API
#ShowWindow -- '0' passed to hide console window
def HideWindow():
    hwnd=int(win32console.GetConsoleWindow())
    win32gui.ShowWindow(hwnd,0) 
    return True 
#ShowWindow -- '1' passed to show console window 
def UnhideWindow():
    hwnd=int(win32console.GetConsoleWindow())
    win32gui.ShowWindow(hwnd,1)
    return True 
#
#.DESCRIPTION
#Wrapper function for the WsParameterRead API procedure.
#For more information about usage or return values, refer to the Callable Routines API section of the user guide.
#.EXAMPLE
#WsParameterRead -ParameterName "CURRENT_DAY"
#
def WsParameterRead(
        ParameterName = ''
    ):

    sql=""" 
    DECLARE @out varchar(max),@out1 varchar(max);
    EXEC WsParameterRead
	@p_parameter = ? 
   ,@p_value = @out OUTPUT
   ,@p_comment=@out1 OUTPUT;
    SELECT @out AS p_value,@out1 AS p_comment;"""
    Parameters=[ParameterName]
    ConnectionString = "DSN="+str(os.getenv('WSL_META_DSN'))
    ConnectionString += ";UID="+str(os.getenv('WSL_META_USER'))
    ConnectionString += ";PWD="+str(os.getenv('WSL_META_PWD'))  
    conn = pyodbc.connect(ConnectionString)
    cursor=conn.cursor()
    number_of_rows=cursor.execute(sql,Parameters)
    rows=cursor.fetchall()
    conn.commit()
    cursor.close()
    return rows

#
#.DESCRIPTION
#Wrapper function for the WsParameterWrite API procedure.
#For more information about usage or return values, refer to the Callable Routines API section of the user guide.
#.EXAMPLE
#WsParameterWrite -ParameterName "CURRENT_DAY" -ParameterValue "Monday" -ParameterComment "The current day of the week"
#
def WsParameterWrite(
        ParameterName    = '',
        ParameterValue   = '',
        ParameterComment = ''
    ):
    sql=""" 
    DECLARE @out nvarchar(max);
    EXEC  @out=WsParameterWrite
	@p_parameter = ? 
  , @p_value = ?    
  , @p_comment  = ?;
    SELECT @out AS return_value;"""
    Parameters=[ParameterName,ParameterValue,ParameterComment]
    ConnectionString = "DSN=EDW_SF"#+str(os.getenv('WSL_META_DSN'))
    ConnectionString += ";UID="+str(os.getenv('WSL_META_USER'))
    ConnectionString += ";PWD="+str(os.getenv('WSL_META_PWD'))  
    conn = pyodbc.connect(ConnectionString)
    cursor=conn.cursor()
    number_of_rows=cursor.execute(sql,Parameters)
    #rows=cursor.fetchall()
    conn.commit()
    cursor.close()
    return number_of_rows


 
#.DESCRIPTION
#Wrapper function for the WsWrkAudit API procedure.
#For more information about usage or return values, refer to #the Callable Routines API section of the user guide.
#.EXAMPLE
#WsWrkAudit -Message "This is an audit log INFO message created #by calling WsWrkAudit"
#WsWrkAudit -StatusCode "E" -Message "This is an audit log ERROR message created by calling WsWrkAudit"
#
def WsWrkAudit(
        StatusCode = 'I',
        Message='',
        DBCode='',
        DBMessage=''):
    
    sql=""" 
    DECLARE @out nvarchar(max);
    EXEC  @out=WsWrkAudit
	@p_status_code = ? 
  , @p_job_name = ?    
  , @p_task_name = ?    
  , @p_sequence = ?   
  , @p_message   = ?   
  , @p_db_code  = ?   
  , @p_db_msg = ?  
  , @p_task_key  = ?  
  , @p_job_key  = ?;
    SELECT @out AS return_value;"""
    
    ConnectionString = "DSN="+str(os.getenv('WSL_META_DSN'))
    ConnectionString += ";UID="+str(os.getenv('WSL_META_USER'))
    ConnectionString += ";PWD="+str(os.getenv('WSL_META_PWD'))
      
    sequence = os.environ["WSL_SEQUENCE"]
    jobName = os.environ["WSL_JOB_NAME"]
    taskName = os.environ["WSL_TASK_NAME"]
    jobId = os.environ["WSL_JOB_KEY"]
    taskId = os.environ["WSL_TASK_KEY"]
   
    Parameters=[StatusCode,jobName,taskName,sequence,Message,DBCode,DBMessage,taskId,jobId]
   
    conn = pyodbc.connect(ConnectionString)
    cursor=conn.cursor()
    number_of_rows=cursor.execute(sql,Parameters)
    #rows=cursor.fetchall()
    conn.commit()
    cursor.close()
    return number_of_rows
    
#.DESCRIPTION
#Wrapper function for the WsWrkTask API procedure.
#For more information about usage or return values, refer to the Callable Routines API section of the user guide.
##.EXAMPLE
#WsWrkTask -Inserted 20 -Updated 35
#>
def WsWrkTask(
        Inserted = 0,
        Updated = 0,
        Replaced = 0,
        Deleted = 0,
        Discarded = 0,
        Rejected = 0,
        Errored = 0
    ):
    sequence = os.environ["WSL_SEQUENCE"]
    jobName = os.environ["WSL_JOB_NAME"]
    taskName = os.environ["WSL_TASK_NAME"]
    jobId = os.environ["WSL_JOB_KEY"]
    taskId = os.environ["WSL_TASK_KEY"]
    
    ConnectionString = "DSN="+str(os.getenv('WSL_META_DSN'))
    ConnectionString += ";UID="+str(os.getenv('WSL_META_USER'))
    ConnectionString += ";PWD="+str(os.getenv('WSL_META_PWD'))
    
    conn = pyodbc.connect(ConnectionString)
    #sql = "CALL " + str(os.getenv('WSL_META_DB'))+"."+str(os.getenv('WSL_META_SCHEMA'))+".WsWrkTask " +"(?, ?, ?, ?, ?, ?, ?, ?, ?, ?) "
    #sql = "{ ? = call WsWrkTask (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) }"

    sql=""" 
    DECLARE @out nvarchar(max);
    EXEC @out=WsWrkTask
	@p_job_key = ? 
  , @p_task_key = ?    
  , @p_sequence = ?    
  , @p_inserted = ?   
  , @p_updated   = ?   
  , @p_replaced  = ?   
  , @p_deleted    = ?  
  , @p_discarded  = ?  
  , @p_rejected  = ?   
  , @p_errored   = ?;
    SELECT @out AS return_value;"""
    ConnectionString = "DSN="+str(os.getenv('WSL_META_DSN'))
    ConnectionString += ";UID="+str(os.getenv('WSL_META_USER'))
    ConnectionString += ";PWD="+str(os.getenv('WSL_META_PWD'))
    Parameters=[jobId,taskId,sequence,Inserted,Updated,Replaced,Deleted,Discarded,Rejected,Errored]
    cursor = conn.cursor()
    cursor.fast_executemany = False
    cursor.execute(sql,Parameters)
    return_values=cursor.fetchone()
    next_num = return_values[0]
    conn.commit()
    cursor.close()
    return next_num
    
    
    
#
#.DESCRIPTION
#Wrapper function for the WsWrkError API procedure.
#For more information about usage or return values, refer to the Callable Routines API section of the user guide.
#.EXAMPLE
#WsWrkError -Message "This is a detail log INFO message created by calling WsWrkAudit"
#WsWrkError -StatusCode "E" -Message "This is a detail log ERROR message created by calling WsWrkAudit"
#>
def WsWrkError(
        statusCode  = 'I',
        message     = '',
        dbCode      = '',
        dbMessage   = '',
        messageType = ''
    ):
    sequence = os.environ["WSL_SEQUENCE"]
    jobName = os.environ["WSL_JOB_NAME"]
    taskName = os.environ["WSL_TASK_NAME"]
    jobId = os.environ["WSL_JOB_KEY"]
    taskId = os.environ["WSL_TASK_KEY"]
    ConnectionString = "DSN="+str(os.getenv('WSL_META_DSN'))
    ConnectionString += ";UID="+str(os.getenv('WSL_META_USER'))
    ConnectionString += ";PWD="+str(os.getenv('WSL_META_PWD')) 
    conn = pyodbc.connect(ConnectionString)
    sql=""" 
    DECLARE @out nvarchar(max);
    EXEC @out=WsWrkError
	@p_status_code = ? 
  , @p_job_name = ?    
  , @p_task_name = ?    
  , @p_sequence = ?   
  , @p_message   = ?   
  , @p_db_code  = ?   
  , @p_db_msg    = ?  
  , @p_task_key  = ?  
  , @p_job_key  = ?   
  , @p_msg_type   = ?;
    SELECT @out AS return_value;"""
    Parameters=[statusCode,jobName,taskName,sequence,message,dbCode,dbMessage,taskId,jobId,messageType]
    cursor = conn.cursor()
    #cursor.fast_executemany = False
    cnt=cursor.execute(sql,Parameters).rowcount
    if cnt>0:
     #return_values=cursor.fetchone()
     next_num = 1#return_values[0]
    else:
      next_num=0
    conn.commit()
    cursor.close()
    return next_num

#.DESCRIPTION
#Wrapper function for the Ws_Job_Schedule API procedure.
#For more information about usage or return values, refer to the Callable Routines API section of the user guide.
#.EXAMPLE
#Ws_Job_Schedule -ReleaseJob "DailyUpdate" -ReleaseTime (Get-Date "2017-10-3 19:30").DateTime
#>
def WsJobSchedule(
        ReleaseJob = '',
        ReleaseTime = ''
    ):
    
    sequence = os.environ["WSL_SEQUENCE"]
    jobName = os.environ["WSL_JOB_NAME"]
    taskName = os.environ["WSL_TASK_NAME"]
    jobId = os.environ["WSL_JOB_KEY"]
    taskId = os.environ["WSL_TASK_KEY"]
    ConnectionString = "DSN="+str(os.getenv('WSL_META_DSN'))
    ConnectionString += ";UID="+str(os.getenv('WSL_META_USER'))
    ConnectionString += ";PWD="+str(os.getenv('WSL_META_PWD')) 
    conn = pyodbc.connect(ConnectionString)
    sql=""" 
    DECLARE @out nvarchar(max),@out1 nvarchar(max),@out2 nvarchar(max);
    EXEC @rc=Ws_Job_Schedule
    @p_sequence  =?
  ,	@p_job_name  = ? 
  , @p_task_name  = ?    
  , @p_job_id = ?    
  , @p_task_id = ?   
  , @p_release_job    = ?   
  , @p_release_time = ?   
  , @p_return_code = @out OUTPUT  
  , @p_return_msg = @out1 OUTPUT   
  , @p_result   = @out2 OUTPUT;   
    SELECT rc as status,@out AS return_code,@out1 AS return_msg,@out2 AS return_result;"""
    Parameters=[sequence,jobName,taskName,jobId,taskId,statusCode,ReleaseJob,ReleaseTime]
    cursor = conn.cursor()
    cursor.execute(sql,Parameters)
    return_values=cursor.fetchall()
    conn.commit()
    cursor.close()
    return return_values
    
def GetExtendedProperty( 
        propertyName,
        tableName
    ):
    
    ConnectionString = "DSN="+str(os.getenv('WSL_META_DSN'))
    ConnectionString += ";UID="+str(os.getenv('WSL_META_USER'))
    ConnectionString += ";PWD="+str(os.getenv('WSL_META_PWD'))
    
    conn = pyodbc.connect(ConnectionString)
    sql=""" 
    DECLARE @out varchar(max);
    EXEC WsGetExtendedProperty
	@p_propertyname = ? 
   ,@p_tablename = ?
   ,@p_result=@out OUTPUT;
    SELECT @out AS return_value;"""
    Parameters=[propertyName,tableName]
    cursor = conn.cursor()
    cursor.execute(sql,Parameters)
    return_values=cursor.fetchone()
    conn.commit()
    cursor.close()
    return return_values[0]





#.DESCRIPTION
#Used to run any SQL against any ODBC DSN
#.EXAMPLE
#Run-RedSQL -sql "SELECT * FROM stage_customers" -dsn "dssdemo"
#
def RunRedSQL(
                sql,
                dsn,
                uid,
                pwd,
                odbcConn,
                notrans,
                tablename
               ):
    ConnectionString=''
    ConnectionString = 'DSN='+dsn
    if uid and not uid.isspace():
        ConnectionString +=';UID='+uid
    if pwd and not pwd.isspace():
        ConnectionString +=';PWD='+pwd
    #OBJECT EVENT PART PENDING
    number_of_rows=0
    rows=None
    try:
     infoEvent=''
     if sql and not sql.isspace():
        conn = pyodbc.connect(ConnectionString)
        cursor = conn.cursor()
        number_of_rows = cursor.execute(sql).rowcount 
        #TRANSACTION NEED NOT BE EXPLICITELY OPEN IN PYODBC
        rows=''
        if number_of_rows >0 and sql[0:6] !="SELECT":
         sqlReader ="SELECT * FROM " + tablename
         cursor2 = conn.cursor()
         rows = cursor2.execute(sqlReader).fetchall()
         cursor2.close()
        elif sql[0:8]!="TRUNCATE":
         try:
          number_of_rows=len(cursor.fetchall())
          rows = cursor.execute(sql).fetchall()
         except Exception as inst:
            infoEvent=inst
        conn.commit()
        cursor.close()
        return odbcConn,1,number_of_rows,infoEvent,rows
    except pyodbc.Error as ex:
        sqlstate = ex.args[0]
        return odbcConn,-2,number_of_rows,ex.args,rows   
         
        
def SplitThresholdExceeded( sql,
                dsn,
                uid,
                pwd,
                splitThreshold
               ):
        number_of_rows=RunRedSQL(sql, dsn,uid,pwd,'','','')
        split=False
        if number_of_rows[2] >=splitThreshold :
         split = True;
        return split

def  GetDataToFile( query,  
                    dsn,  
                    uid,  
                    pwd,  
                    dataFile,  
                    delimiter,  
                    fileCount,  
                    splitThreshold,  
                    addQuotes,  
                    unicode,  
                    enclosedBy,  
                    escapeChar):
                shouldSplit = False
                if fileCount > 0 and splitThreshold > 0:
                    shouldSplit = SplitThresholdExceeded(query, dsn,uid,pwd, splitThreshold)
                fileList =[dataFile + ".txt"]
                if shouldSplit==True:
                    i=1
                    while i < fileCount:
                        fileList.append(dataFile + "_" + str(i) + ".txt")
                        i=i+1
                rowCount = 0
                cntRecords=0
                fileNumber=0
                number_of_rows=RunRedSQL(query, dsn,uid,pwd,'','','')
                rowCount=number_of_rows[2]
                colCount=len(number_of_rows[4][0])
                while cntRecords<rowCount:
                    recordList=[]
                    cntColumns=0
                    while cntColumns < colCount:
                        if number_of_rows[4][cntRecords]=='None':
                            recordList.append("")
                        else:
                           if addQuotes == True:
                              dataVal =str(number_of_rows[4][cntRecords][cntColumns])
                              if escapeChar and not escapeChar.isspace():
                                # when escapeChar occurs in the data, double it
                                dataVal = dataVal.replace(escapeChar, escapeChar + escapeChar)
                              # when enclosedBy occurs in the data, escape it with escapeChar
                              dataVal = dataVal.replace(enclosedBy,escapeChar + enclosedBy)
                              if dataVal=='None':
                                dataVal=""
                              else:
                               # enclose the value with enclosedBy chars
                               dataVal = enclosedBy + dataVal + enclosedBy
                              recordList.append(dataVal)
                              #print(recordList)
                           else:
                                #if no enclosedBy set, strip out delimiter char
                                recordList.append(str(number_of_rows[4][cntRecords]).replace(delimiter,""))
                        
                        cntColumns=cntColumns+1
                        rowNew = recordList
                    work = delimiter.join(rowNew)
                    work = work.replace("\r","")
                    work = work.replace("\n"," ")
                    try:
                     if fileNumber == fileCount and shouldSplit==True:
                        fileNumber = 0
                     encoding_type = ''
                     if unicode==True:
                        encoding_type = 'utf-8'  
                     else:
                        encoding_type = 'ascii'
                     f = open(fileList[fileNumber],encoding=encoding_type, mode='a+',errors='replace')
                     f.write(work+"\n")
                     f.close()
                     if fileNumber < fileCount and shouldSplit==True:
                       fileNumber=fileNumber+1
                    except Exception as inst:
                        print("Error  at line "+work)
                        print(inst.args)
                        print(inst)
                    cntRecords=cntRecords+1
                
                return rowCount
