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
* Teardown                                                  *
*************************************************************
* Requires switching to SQLCMD mode                         *
*                                                           *
* Code will:                                                *
* 1. Stop all Always On XE sessions                         * 
* 2. Remove listener from primary replica ag                *
* 3. Take database out of primary replica ag                *
* 4. Remove secondary replicas                              *
* 5. Drop Availability Group                                *
* 6. Drop database from secondary instances                 *
* 7. Drop all endpoints on all instances                    *
* 8. Drop all certificates from all instances               *
* 9. Drop all users from all instances                      *
* 10. Drop all logins from all instances                    *
* 11. Drop Database Master Keys from all instances          *
************************************************************/

-- 1. Stop XE AlwaysOn Health Sessions
:CONNECT SERVER2
ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=STOP;
GO
:CONNECT SERVER3
ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=STOP;
GO
:CONNECT SERVER4
ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=STOP;
GO


-- 2. Remove listener
:CONNECT SERVER2
ALTER AVAILABILITY GROUP [MyAG1]
REMOVE LISTENER N'MyAGDB1Listener';
GO

-- 3. Take database out of primary replica ag
:CONNECT SERVER2
ALTER AVAILABILITY GROUP [MyAG1]
	REMOVE DATABASE [MyAGDB1]
GO


-- 4. Remove secondary replicas
:CONNECT SERVER2
ALTER AVAILABILITY GROUP [MyAG1]
REMOVE REPLICA ON N'SERVER3\SQL2016';
ALTER AVAILABILITY GROUP [MyAG1]
REMOVE REPLICA ON N'SERVER4\SQL2016';
GO


-- 5. Drop Availability Group from last (primary) replica
:CONNECT SERVER2
DROP AVAILABILITY GROUP [MyAG1];
GO


-- 6. Drop database from secondary instances
:CONNECT SERVER3
DROP DATABASE MyAGDB1
GO
:CONNECT SERVER4
DROP DATABASE MyAGDB1
GO
/*At this point you should have removed all Availability
Group specific components. Do not remove the following
components if you plan to set up another Availability
Group across the replicas.


The following components allow communication and
security across availability group replicas. Only
remove if you are clearing all components from your
SQL Server instances.*/

-- 7. Drop all endpoints on all instances
:CONNECT SERVER2
DROP ENDPOINT [Mirroring_Endpoint]
GO
:CONNECT SERVER3
DROP ENDPOINT [Mirroring_Endpoint]
GO
:CONNECT SERVER4
DROP ENDPOINT [Mirroring_Endpoint]
GO


-- 8. Drop all certificates from all instances
:CONNECT SERVER2
USE master
DROP CERTIFICATE [AG_server2_cert]
DROP CERTIFICATE [AG_server3_cert]
DROP CERTIFICATE [AG_server4_cert]
GO
:CONNECT SERVER3
DROP CERTIFICATE [AG_server2_cert]
DROP CERTIFICATE [AG_server3_cert]
DROP CERTIFICATE [AG_server4_cert]
GO
:CONNECT SERVER4
DROP CERTIFICATE [AG_server2_cert]
DROP CERTIFICATE [AG_server3_cert]
DROP CERTIFICATE [AG_server4_cert]
GO


-- 9. Drop all users from all instances
:CONNECT SERVER2
USE master
DROP USER [AG_server2_user]
DROP USER [AG_server3_user]
DROP USER [AG_server4_user]
GO
:CONNECT SERVER3
USE master
DROP USER [AG_server2_user]
DROP USER [AG_server3_user]
DROP USER [AG_server4_user]
GO
:CONNECT SERVER4
USE master
DROP USER [AG_server2_user]
DROP USER [AG_server3_user]
DROP USER [AG_server4_user]
GO


-- 10. Drop all logins from all instances 
:CONNECT SERVER2
USE master
DROP LOGIN [AG_server2_login]
DROP LOGIN [AG_server3_login]
DROP LOGIN [AG_server4_login]
GO
:CONNECT SERVER3
USE master
DROP LOGIN [AG_server2_login]
DROP LOGIN [AG_server3_login]
DROP LOGIN [AG_server4_login]
GO
:CONNECT SERVER4
USE master
DROP LOGIN [AG_server2_login]
DROP LOGIN [AG_server3_login]
DROP LOGIN [AG_server4_login]
GO


-- 11. Drop Database Master Keys from all instance
:CONNECT SERVER2
USE master
DROP MASTER KEY
GO
:CONNECT SERVER3
USE master
DROP MASTER KEY
GO
:CONNECT SERVER4
USE master
DROP MASTER KEY
GO
/*End of Teardown*/
