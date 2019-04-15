Prereqs:
=========================================
1. SQL Server system (can be any level, eg: express through to enterprise, etc).
2. SQL Server database created for metadata
3. ODBC DSN for SQL Server metadata database
4. A Snowflake environment with at least one schema
5. A WhereScape RED license key (that includes enablement for a custom database called SNOWFLAKE and the object type custom1, see SnowflakeLicense.png).
6. At least powershell version 4 installed.  Check with this dos command:
     powershell -c $psversiontable

And the following software downloaded:
7. WhereScape RED 8.2.1.1 Release Version
8. Snowflake 32-bit ODBC Driver.
9. Snowflake Snowsql client.
10. TNT Drive (only if files are going to be loaded from an non-Snowflake S3 bucket)


Installation:
=========================================
1. Install Snowsql client
2. Install Snowflake ODBC Driver
3. Create Snowflake ODBC DSN for your warehouse

===================================================================================
===================================================================================
  U S E   T H E   R E D   F O R   S N O W F L A K E   I N S T A L L E R   ! ! ! ! 
===================================================================================
===================================================================================

or manually!! do the following 31 steps:

4. Install RED
5. Pin Setup Administrator to the task bar and alter shortcut to always start as Administrator
6. Stop and start Setup Administrator
7. Add RED license
8. Create repository
9. Log in to RED and click OK on Tools/Options dialog
10. Pin RED to the task bar
11. Load the Extended Properties Set
12. Open a SQL Admin window to the DataWarehouse connection
13. Load the script "Snowflake metadata_options_setup.sql" and run it
14. Close SQL Admin
15. Restart RED
16. Load all Data Type Mapping Sets
17. Load Function Set
18. Run the bat file "WslPowershell Install - RUN AS ADMIN.bat" as Administrator to install the powershell modules: when prompted, enter A for All
19. Run the registry file:    "Disable Snowflake ODBC Driver Logging.reg"
20. Install windows scheduler
21. Make changes to "Snowflake Warehouse" Connection
    - check ODBCDSN is correct
    - add extract username/password
    - add data type mapping set:                 Snowflake to Snowflake
    - make list of schema for browsing match schemas on targets
    - set all connectvity extended properties that are not set
    And on the Targets Tab:
    - change databases and schemas on individual targets
22. Stop RED
23. Pull "snowflake" repository from BitBucket
24. Pull "wslpowershell" repository from BitBucket
25. Run the file "WslPowershell Install - RUN AS ADMIN.bat" as administrator to install powershell modules
26. Load templates using install_templates.ps1 following the on screen prompts and specifying the following two naming patterns:
    - wsl_snowflake%
    - snowflake%
27. Load application for the date dimension
28. Run the registry file:    "Add Default Templates Snowflake.reg"
29. Start RED
30. Make changes to "Snowflake Warehouse" Connection
    - Default Table Create DDL Template:         wsl_snowflake_create_table
    - Default View Create DDL Template:          wsl_snowflake_create_view
    - Table/Column Information SQL Block:        wsl_snowflake_table_information
    - Default Table Alter DDL Template:          wsl_snowflake_alter_ddl
31. Create a new windows connecion called "Windows Comma Sep Files" and set it as follows:
    - default path for browsing:                 where your files are
    - new table default load type:               Script based load
    - new table default load script template:    ws_snowflake_pscript_load
    - data type mapping set:                     Snowflake from File
    - Extended Property FILE_FORMAT:             FMT_RED_CSV_SKIP_GZIP_COMMA
32. Create a new windows connecion called "Windows Pipe Sep Files" and set it as follows:
    - default path for browsing:                 where your files are
    - new table default load type:               Script based load
    - new table default load script template:    ws_snowflake_pscript_load
    - data type mapping set:                     Snowflake from File
    - Extended Property FILE_FORMAT:             FMT_RED_CSV_SKIP_GZIP_PIPE
33. Rename the tutorial connection to be your first database source then:
    - set Connection type to:                    ODBC
    - set ODBC DSN to your source
    - set Work directory to                      c:\temp\
    - set Default schema
    - new table default load type:               Script based load
    - new table default load script connection:  Runtime Connection for Scripts
    - new table default load script template:    ws_snowflake_pscript_load
    - data type mapping set:                     Snowflake from ?????
    - Extended Property RANGE_CONCATWORD:        +  for databases that use this for concatinating strings (SQL Server / SYBASE)
                                                 || for databases that use this for concatinating strings (most databases)
34. Run the date dimension job and wait for it to complete





To Add Support for Loading Files in a external S3 Bucket:
======================================================================
1. Ensure yopu have completed the following for each bucket:    https://docs.snowflake.net/manuals/user-guide/data-loading-s3-config.html
2. Install TNT Drive
3. Using TNT Drive, map your S:\ drive to your bucket
4. Version your "Runtime Connection for Scripts" Connection
5. Restore the version as a new Connection called "AWS S3 Comma Sep Files"
6. Change things on "AWS S3 Comma Sep Files" Connection
    - default path for browsing:                 where your files are in S3 using the S:\ drive
    - Extended Property:  FILE_FORMAT        => FMT_RED_CSV_SKIP_NOGZIP_COMMA
    - Extended Property:  S3_BUCKET_PREFIX   => s3://YourBucketName/FolderName1/FolderName2/
7. Set two more Extended Properties on the Snowflake connection:
    - ACCESS_KEY
    - SECRET_KEY


Notes:
=========================================
1. Windows and S3 connections created above are optimized for comma seperated files
   To load other delimited files, or fixed width files, clone connections and adjust as per instructions video
2. Use views, not dimension views
3. 


Post Installation Tests:
=========================================
1. Create a load table from a windows file and run it
2. Create a load table from a database source and run it
3. Create a stage table and run it
4. Create a type 1 dimension table and run it
5. Create a type 2 dimension table and run it


