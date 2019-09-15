/************************************************************
* All scripts contained within are Copyright © 2015 of      *
* Mark Broadbent, whether they are derived or actual        *
* works by him or his representatives                       *
*************************************************************
* They are distributed under the Apache 2.0 licence and any *
* reproducion, transmittion, storage, or derivation must    *
* comply with the terms under the licence linked below.     *
* If in any doubt, contact the license owner for written    *
* permission by emailing contactme@sturmovik.net            *
*************************************************************
Copyright [2019] [Mark Broadbent]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*************************************************************
* Demonstrate backups from secondary replicas               *
*************************************************************
* Requires switching to SQLCMD mode                         *
*                                                           *
* Code will:                                                *
* 1. Backup replica based on is_preferred_replica property  *
************************************************************/

-- View the Backup Priority status across all replicas for database
:CONNECT SERVER2
DECLARE @database_name sysname = 'MyAGDB1'
SELECT @@servername AS 'Instance', sys.fn_hadr_backup_is_preferred_replica(@database_name) AS 'Is preferred'
GO
:CONNECT SERVER3
DECLARE @database_name sysname = 'MyAGDB1'
SELECT @@servername AS 'Instance', sys.fn_hadr_backup_is_preferred_replica(@database_name) AS 'Is preferred'
GO
:CONNECT SERVER4
DECLARE @database_name sysname = 'MyAGDB1'
SELECT @@servername AS 'Instance', sys.fn_hadr_backup_is_preferred_replica(@database_name) AS 'Is preferred'
GO


-- Look at backup priorites through the properties of the Availability Group
-- from the primary replica. Note the option for secondary only and what it does.
-- Now change the backup priority of replica server3 to 60


-- View the Backup Priority status across all replicas for database
:CONNECT SERVER2
DECLARE @database_name sysname = 'MyAGDB1'
SELECT @@servername AS 'Instance', sys.fn_hadr_backup_is_preferred_replica(@database_name) AS 'Is preferred'
GO
:CONNECT SERVER3
DECLARE @database_name sysname = 'MyAGDB1'
SELECT @@servername AS 'Instance', sys.fn_hadr_backup_is_preferred_replica(@database_name) AS 'Is preferred'
GO
:CONNECT SERVER4
DECLARE @database_name sysname = 'MyAGDB1'
SELECT @@servername AS 'Instance', sys.fn_hadr_backup_is_preferred_replica(@database_name) AS 'Is preferred'
GO



-- Notice from results Server3 wins priority



-- So let's put into action
-- We will attempt to full backup the database across replicas (as copy only)
-- and also do a log backup across them.
:CONNECT SERVER2
DECLARE @database_name sysname = 'MyAGDB1'
PRINT sys.fn_hadr_backup_is_preferred_replica(@database_name)
IF sys.fn_hadr_backup_is_preferred_replica(@database_name) = 1
BEGIN  --Preferred Replica
  PRINT 'Backup database ' + @database_name + ' on preferred replica ' + @@servername
  BACKUP DATABASE [MyAGDB1] TO DISK = '\\SERVER1\backuppath\MyAGDB1_from_replica_server2.bak' WITH STATS=100, COPY_ONLY, FORMAT
  BACKUP LOG [MyAGDB1] TO DISK = '\\SERVER1\backuppath\MyAGDB1_from_replica_server2.trn' WITH STATS=100, FORMAT
END
ELSE
BEGIN
  PRINT 'Replica ' + @@servername + ' not preferred for database backup.'
END
GO
:CONNECT SERVER3
DECLARE @database_name sysname = 'MyAGDB1'
PRINT sys.fn_hadr_backup_is_preferred_replica(@database_name)
IF sys.fn_hadr_backup_is_preferred_replica(@database_name) = 1
BEGIN  --Preferred Replica
  PRINT 'Backup database ' + @database_name + ' on preferred replica ' + @@servername
  BACKUP DATABASE [MyAGDB1] TO DISK = '\\SERVER1\backuppath\MyAGDB1_from_replica_server3.bak' WITH STATS=100, COPY_ONLY, FORMAT
  BACKUP LOG [MyAGDB1] TO DISK = '\\SERVER1\backuppath\MyAGDB1_from_replica_server3.trn' WITH STATS=100, FORMAT
END
ELSE
BEGIN
  PRINT 'Replica ' + @@servername + ' not preferred for database backup.'
END
GO
:CONNECT SERVER4
DECLARE @database_name sysname = 'MyAGDB1'
PRINT sys.fn_hadr_backup_is_preferred_replica(@database_name)
IF sys.fn_hadr_backup_is_preferred_replica(@database_name) = 1
BEGIN  --Preferred Replica
  PRINT 'Backup database ' + @database_name + ' on preferred replica ' + @@servername
  BACKUP DATABASE [MyAGDB1] TO DISK = '\\SERVER1\backuppath\MyAGDB1_from_replica_server4.bak' WITH STATS=100, COPY_ONLY, FORMAT
  BACKUP LOG [MyAGDB1] TO DISK = '\\SERVER1\backuppath\MyAGDB1_from_replica_server4.trn' WITH STATS=100, FORMAT
END
ELSE
BEGIN
  PRINT 'Replica ' + @@servername + ' not preferred for database backup.'
END
GO



-- Look at backup history across replicas
:CONNECT SERVER2
SELECT 
	TOP 3 CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
	msdb.dbo.backupset.database_name, 
	msdb.dbo.backupset.backup_start_date, 
	msdb.dbo.backupset.backup_finish_date, 
	msdb.dbo.backupset.expiration_date, 
	CASE msdb..backupset.type 
	WHEN 'D' THEN 'Database' 
	WHEN 'L' THEN 'Log' 
	END AS backup_type, 
	msdb.dbo.backupset.backup_size, 
	msdb.dbo.backupmediafamily.logical_device_name, 
	msdb.dbo.backupmediafamily.physical_device_name, 
	msdb.dbo.backupset.name AS backupset_name, 
	msdb.dbo.backupset.description 
	FROM msdb.dbo.backupmediafamily 
	INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
	WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 7) 
	ORDER BY 
	msdb.dbo.backupset.database_name, 
	msdb.dbo.backupset.backup_finish_date desc
GO
:CONNECT SERVER3
SELECT 
	TOP 3 CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
	msdb.dbo.backupset.database_name, 
	msdb.dbo.backupset.backup_start_date, 
	msdb.dbo.backupset.backup_finish_date, 
	msdb.dbo.backupset.expiration_date, 
	CASE msdb..backupset.type 
	WHEN 'D' THEN 'Database' 
	WHEN 'L' THEN 'Log' 
	END AS backup_type, 
	msdb.dbo.backupset.backup_size, 
	msdb.dbo.backupmediafamily.logical_device_name, 
	msdb.dbo.backupmediafamily.physical_device_name, 
	msdb.dbo.backupset.name AS backupset_name, 
	msdb.dbo.backupset.description 
	FROM msdb.dbo.backupmediafamily 
	INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
	WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 7) 
	ORDER BY 
	msdb.dbo.backupset.database_name, 
	msdb.dbo.backupset.backup_finish_date desc
GO
:CONNECT SERVER4
SELECT 
	TOP 3 CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
	msdb.dbo.backupset.database_name, 
	msdb.dbo.backupset.backup_start_date, 
	msdb.dbo.backupset.backup_finish_date, 
	msdb.dbo.backupset.expiration_date, 
	CASE msdb..backupset.type 
	WHEN 'D' THEN 'Database' 
	WHEN 'L' THEN 'Log' 
	END AS backup_type, 
	msdb.dbo.backupset.backup_size, 
	msdb.dbo.backupmediafamily.logical_device_name, 
	msdb.dbo.backupmediafamily.physical_device_name, 
	msdb.dbo.backupset.name AS backupset_name, 
	msdb.dbo.backupset.description 
	FROM msdb.dbo.backupmediafamily 
	INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
	WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 7) 
	ORDER BY 
	msdb.dbo.backupset.database_name, 
	msdb.dbo.backupset.backup_finish_date desc
GO



-- Notice the differences between the backup history



-- Time permitting offline the Server3 VM (which has the highest backup priority)
-- and run the backup scripts again. Notice this time Server4 wins