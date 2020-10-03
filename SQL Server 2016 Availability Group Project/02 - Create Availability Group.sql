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
* Create Availability Group                                 *
*************************************************************
* Requires switching to SQLCMD mode                         *
*                                                           *
* Code will:                                                *
* 1. Test pre-requisites                                    *
* 2. Create new database MyAGDB1                            *
* 3. Backup source (future primary)                         *            
* 4. Restore source to future secondaries                   *
* 5. Create availability group                              *
* 6. Join Replicas                                          *
* 7. Join Replica Databases                                 *
* 8. Create Listener                                        *
************************************************************/

-- 1. Test pre-requisites
:CONNECT SERVER2
USE master;
DECLARE @servername VARCHAR(10) = 'server2'
SELECT @servername, name AS 'database', state_desc, recovery_model_desc FROM sys.databases WHERE name = 'MyAGDB1'
SELECT @servername AS 'instance', * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##'
SELECT @servername AS 'instance', * FROM sys.certificates WHERE name NOT LIKE '##%'; 
SELECT @servername AS 'instance', name, role_desc, state_desc, connection_auth_desc, encryption_algorithm_desc   
   FROM sys.database_mirroring_endpoints;
SELECT @servername AS 'instance', name AS principal FROM sys.server_principals WHERE name LIKE 'AG_server%'
UNION
SELECT @servername AS 'instance', name FROM sys.database_principals WHERE name LIKE 'AG_server%';
GO
:CONNECT SERVER3
USE master;
DECLARE @servername VARCHAR(10) = 'server3'
SELECT @servername, name AS 'database', state_desc, recovery_model_desc FROM sys.databases WHERE name = 'MyAGDB1'
SELECT @servername AS 'instance', * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##'
SELECT @servername AS 'instance', * FROM sys.certificates WHERE name NOT LIKE '##%'; 
SELECT @servername AS 'instance', name, role_desc, state_desc, connection_auth_desc, encryption_algorithm_desc   
   FROM sys.database_mirroring_endpoints;
SELECT @servername AS 'instance', name AS principal FROM sys.server_principals WHERE name LIKE 'AG_server%'
UNION
SELECT @servername AS 'instance', name FROM sys.database_principals WHERE name LIKE 'AG_server%';
GO
:CONNECT SERVER4
USE master;
DECLARE @servername VARCHAR(10) = 'server4'
SELECT @servername, name AS 'database', state_desc, recovery_model_desc FROM sys.databases WHERE name = 'MyAGDB1'
SELECT @servername AS 'instance', * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##'
SELECT @servername AS 'instance', * FROM sys.certificates WHERE name NOT LIKE '##%'; 
SELECT @servername AS 'instance', name, role_desc, state_desc, connection_auth_desc, encryption_algorithm_desc   
   FROM sys.database_mirroring_endpoints;
SELECT @servername AS 'instance', name AS principal FROM sys.server_principals WHERE name LIKE 'AG_server%'
UNION
SELECT @servername AS 'instance', name FROM sys.database_principals WHERE name LIKE 'AG_server%';
GO


-- 2. Create new database MyAGDB1 
-- Remove orginal source database if it
-- was left over from a previous demo
:CONNECT SERVER2
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'MyAGDB1') 
	DROP DATABASE MyAGDB1
GO
--create database and insert records
:CONNECT SERVER2
CREATE DATABASE MyAGDB1
GO
:CONNECT SERVER2
ALTER DATABASE MyAGDB1 SET RECOVERY FULL
GO
:CONNECT SERVER2
USE [MyAGDB1]
CREATE TABLE t1 (c1 INT)
GO
:CONNECT SERVER2
INSERT INTO MyAGDB1.dbo.t1 VALUES (1)
INSERT INTO MyAGDB1.dbo.t1 VALUES (2)
SELECT * FROM MyAGDB1.dbo.t1
GO


-- Backup source (future primary)
:CONNECT SERVER2
BACKUP DATABASE [MyAGDB1] TO DISK = '\\SERVER1\backuppath\MyAGDB1.bak' WITH FORMAT, STATS =25
BACKUP LOG [MyAGDB1] TO DISK = '\\SERVER1\backuppath\MyAGDB1.trn' WITH FORMAT, STATS =100
GO


-- Restore source to future secondaries
:CONNECT SERVER3
RESTORE DATABASE [MyAGDB1] FROM DISK = '\\SERVER1\backuppath\MyAGDB1.bak' WITH NORECOVERY, REPLACE, STATS = 100
GO
:CONNECT SERVER3
RESTORE LOG [MyAGDB1] FROM DISK = '\\SERVER1\backuppath\MyAGDB1.trn' WITH NORECOVERY, REPLACE, STATS = 100
GO
:CONNECT SERVER4
RESTORE DATABASE [MyAGDB1] FROM DISK = '\\SERVER1\backuppath\MyAGDB1.bak' WITH NORECOVERY, REPLACE, STATS = 100
GO
:CONNECT SERVER4
RESTORE LOG [MyAGDB1] FROM DISK = '\\SERVER1\backuppath\MyAGDB1.trn' WITH NORECOVERY, REPLACE, STATS = 100
GO



-- Create availability group
:CONNECT SERVER2
USE [master]
CREATE AVAILABILITY GROUP [MyAG1]
WITH (AUTOMATED_BACKUP_PREFERENCE = SECONDARY,
DB_FAILOVER = OFF,
DTC_SUPPORT = NONE)
FOR DATABASE [MyAGDB1]
REPLICA ON N'SERVER2\SQL2016' WITH (ENDPOINT_URL = N'TCP://server2.retracement.me:5022', FAILOVER_MODE = AUTOMATIC, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, SECONDARY_ROLE(ALLOW_CONNECTIONS = NO)),
	N'SERVER3\SQL2016' WITH (ENDPOINT_URL = N'TCP://SERVER3.retracement.me:5022', FAILOVER_MODE = AUTOMATIC, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, SECONDARY_ROLE(ALLOW_CONNECTIONS = NO)),
	N'SERVER4\SQL2016' WITH (ENDPOINT_URL = N'TCP://SERVER4.retracement.me:5022', FAILOVER_MODE = AUTOMATIC, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, SECONDARY_ROLE(ALLOW_CONNECTIONS = NO));
GO


-- See the Availability Group Resource Group in the Windows Cluster



-- See now the Availability Group Replicas (through primary replica view on the dashboard) 
-- is added but that SERVER3 and others are not joined



--join replica
:Connect SERVER3
ALTER AVAILABILITY GROUP [MyAG1] JOIN;
GO



--See now the Availability Group Replica SERVER3 is now joined



--join rest of the replicas
:Connect SERVER4
ALTER AVAILABILITY GROUP [MyAG1] JOIN;
GO



-- from primary replica dashboard you will see there is a problem synchronizing



-- also from a secondary replica availability group dashboard 
-- you can see that the availability database has a problem



-- join database in group on replica
:CONNECT SERVER3
ALTER DATABASE [MyAGDB1] 
	SET HADR AVAILABILITY GROUP =  [MyAG1];
GO



-- Notice now database on secondary is healthy (look at secondary AG replica)



-- Notice that dashboard is also displaying healthy database



-- Now join the database in group on remaining replicas
:CONNECT SERVER4
ALTER DATABASE [MyAGDB1] 
	SET HADR AVAILABILITY GROUP =  [MyAG1];
GO


-- If you want to do this again using only the GUI, then run teardown script 
-- up to and including point 5. Create with same settings as above (failover mode automatic
-- and availability mode synchronous)


-- Add (optional) listener to AG
USE [master]
GO
ALTER AVAILABILITY GROUP [MyAG1]
ADD LISTENER N'MyAG1Listener'
(
--WITH DHCP
-- ON (N'10.0.0.0', N'255.0.0.0'
WITH IP
((N'10.1.0.1', N'255.0.0.0'))
, PORT=1433
);
GO


-- See that the listener and IP are created as clustered resources
-- (via the Failover Cluster Manager)