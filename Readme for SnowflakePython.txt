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

or manually!! do the following steps:
1. Create a metadata db in sql server and add dsn with the same name to odbc.
2. Run powershell script red_installer.ps1
3. Run the registry file:    "Add Default Templates Snowflake.reg"
4. Start RED
5. Run the date dimension job and wait for it to complete

===================================================================================
Prereqs:
1.Python Installation
2.PIP Manager Installation
RED Python Setup
===================================================================================
1.  Pull "wslpython" repository from BitBucket
2.  Run batch script "Install PIP And Module - RUN AS ADMIN
3.  Load templates using install_python_templates.ps1 (run this file using powershell)

NOTE: This repository contains both powershell and python templates. Powershell templates are default.

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


