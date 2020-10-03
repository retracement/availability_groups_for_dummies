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
* Setup environment to allow for AG creation                *
*************************************************************
* Requires switching to SQLCMD mode                         *
*                                                           *
* Code will:                                                *
* 1. Create Database Master Keys in Master on each instance *
* 2. Create certificates for AG auth on each instance       *
* 3. Create mirroring endpoints on each instance            *
* 4. Backup certificates on each instance                   *
* 5. Copy certificates locally on each node                 *
* 6. Create logins for certificate authentication           *
* 7. Create users from logins                               *
* 8. Add other instance Certificates to instances           *
* 9. Grant connect rights to logins for instance endpoints  *
************************************************************/

-- 0.
/*	
In GUI look at the Cluster Manager and view how to create a new cluster,
add nodes, and (if required) show enabling service for always on.

Also show where to configure quorum
*/


-- 1. Create Database Master Keys in Master on each instance
:CONNECT SERVER2
USE master
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'My Strong Password MK Server2';  
GO
:CONNECT SERVER3
USE master
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'My Strong Password MK Server3';  
GO
:CONNECT SERVER4
USE master
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'My Strong Password MK Server4';  
GO


-- 2. Create certificates for AG authentication on each instance
:CONNECT SERVER2
USE master;  
CREATE CERTIFICATE AG_server2_cert   
   WITH SUBJECT = 'Availability Group server2 certificate',   
   EXPIRY_DATE = '11/30/2020';  
GO
:CONNECT SERVER3
USE master;  
CREATE CERTIFICATE AG_server3_cert   
   WITH SUBJECT = 'Availability Group server3 certificate',   
   EXPIRY_DATE = '11/30/2020';  
GO
:CONNECT SERVER4
USE master;  
CREATE CERTIFICATE AG_server4_cert   
   WITH SUBJECT = 'Availability Group server4 certificate',   
   EXPIRY_DATE = '11/30/2020';  
GO


-- 3. Create mirroring endpoints on each instance 
-- This uses certificates to authenticate
:CONNECT SERVER2
CREATE ENDPOINT Mirroring_Endpoint 
	STATE=STARTED
	AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL)
	FOR DATABASE_MIRRORING (AUTHENTICATION = CERTIFICATE AG_server2_cert,
							ENCRYPTION = REQUIRED ALGORITHM AES,
							ROLE = ALL);  
GO
:CONNECT SERVER3
CREATE ENDPOINT Mirroring_Endpoint 
	STATE=STARTED
	AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL)
	FOR DATABASE_MIRRORING (AUTHENTICATION = CERTIFICATE AG_server3_cert,
							ENCRYPTION = REQUIRED ALGORITHM AES,
							ROLE = ALL);  
GO
:CONNECT SERVER4
CREATE ENDPOINT Mirroring_Endpoint 
	STATE=STARTED
	AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL)
	FOR DATABASE_MIRRORING (AUTHENTICATION = CERTIFICATE AG_server4_cert,
							ENCRYPTION = REQUIRED ALGORITHM AES,
							ROLE = ALL);  
GO



-- RUN Del certificates CMDFILE to remove certificates backups



-- 4. Backup certificates on each instance
-- These will need to be copied locally to other nodes
-- so we can create certificates from them
:CONNECT SERVER2
BACKUP CERTIFICATE AG_server2_cert TO FILE = '\\SERVER1\backuppath\AG_server2_cert.cer'
WITH PRIVATE KEY   
      (   
        FILE = '\\SERVER1\backuppath\AG_server2_cert.pvk' ,  
        ENCRYPTION BY PASSWORD = 'Password1'
	  );  
GO
:CONNECT SERVER3
BACKUP CERTIFICATE AG_server3_cert TO FILE = '\\SERVER1\backuppath\AG_server3_cert.cer'
WITH PRIVATE KEY   
      (   
        FILE = '\\SERVER1\backuppath\AG_server3_cert.pvk' ,  
        ENCRYPTION BY PASSWORD = 'Password1'
	  );  
GO
:CONNECT SERVER4
BACKUP CERTIFICATE AG_server4_cert TO FILE = '\\SERVER1\backuppath\AG_server4_cert.cer'
WITH PRIVATE KEY   
      (   
        FILE = '\\SERVER1\backuppath\AG_server4_cert.pvk' ,  
        ENCRYPTION BY PASSWORD = 'Password1'
	  );  
GO



-- 5. RUN Copy certificates CMDFILE to certificates locally on each node
-- This is because certificates cannot be created from remote file



-- 6. Create logins for certificate authentication
:CONNECT SERVER2
USE master;  
CREATE LOGIN AG_server3_login   
   WITH PASSWORD = 'My Strong Password Server3';  
CREATE LOGIN AG_server4_login   
   WITH PASSWORD = 'My Strong Password Server4';  
GO  
:CONNECT SERVER3
USE master;  
CREATE LOGIN AG_server2_login   
   WITH PASSWORD = 'My Strong Password Server2';  
CREATE LOGIN AG_server4_login   
   WITH PASSWORD = 'My Strong Password Server4';  
GO    
:CONNECT SERVER4
USE master;  
CREATE LOGIN AG_server2_login   
   WITH PASSWORD = 'My Strong Password Server2';  
CREATE LOGIN AG_server3_login   
   WITH PASSWORD = 'My Strong Password Server3';  
GO  


-- 7. Create users from logins
:CONNECT SERVER2
USE master;  
CREATE USER AG_server3_user FOR LOGIN AG_server3_login;    
CREATE USER AG_server4_user FOR LOGIN AG_server4_login;  
GO
:CONNECT SERVER3
USE master;  
CREATE USER AG_server2_user FOR LOGIN AG_server2_login;  
CREATE USER AG_server4_user FOR LOGIN AG_server4_login;  
GO
:CONNECT SERVER4
USE master;  
CREATE USER AG_server2_user FOR LOGIN AG_server2_login;  
CREATE USER AG_server3_user FOR LOGIN AG_server3_login;  
GO


-- 8. Add other instance Certificates to instances
:CONNECT SERVER2
USE master;  
CREATE CERTIFICATE AG_server3_cert  
	AUTHORIZATION AG_server3_user -- PRESENTERS NOTE: This is where our logins/ users come into play
	FROM FILE = 'C:\AG_server3_cert.cer'
   	WITH PRIVATE KEY -- PRESENTERS NOTE: This is where our logins/ users come into play
	(   
		FILE ='C:\AG_server3_cert.pvk'  
		, DECRYPTION BY PASSWORD ='Password1'   
	) 
CREATE CERTIFICATE AG_server4_cert  
	AUTHORIZATION AG_server4_user  
	FROM FILE = 'C:\AG_server4_cert.cer'
   	WITH PRIVATE KEY   
	(   
		FILE ='C:\AG_server4_cert.pvk'  
		, DECRYPTION BY PASSWORD ='Password1'   
	) 
GO  
:CONNECT SERVER3
USE master;  
CREATE CERTIFICATE AG_server2_cert  
	AUTHORIZATION AG_server2_user  
	FROM FILE = 'C:\AG_server2_cert.cer'   
	WITH PRIVATE KEY   
	(   
		FILE ='C:\AG_server2_cert.pvk'  
		, DECRYPTION BY PASSWORD ='Password1'   
	)  
CREATE CERTIFICATE AG_server4_cert  
	AUTHORIZATION AG_server4_user  
	FROM FILE = 'C:\AG_server4_cert.cer'
	WITH PRIVATE KEY   
	(   
		FILE ='C:\AG_server4_cert.pvk'  
		, DECRYPTION BY PASSWORD ='Password1'   
	)  
GO    
:CONNECT SERVER4
USE master;  
CREATE CERTIFICATE AG_server2_cert  
	AUTHORIZATION AG_server2_user  
	FROM FILE = 'C:\AG_server2_cert.cer'
	WITH PRIVATE KEY   
	(   
		FILE ='C:\AG_server2_cert.pvk'  
		, DECRYPTION BY PASSWORD ='Password1'   
	)
CREATE CERTIFICATE AG_server3_cert  
	AUTHORIZATION AG_server3_user  
	FROM FILE = 'C:\AG_server3_cert.cer'
	WITH PRIVATE KEY   
	(   
		FILE ='C:\AG_server3_cert.pvk'  
		, DECRYPTION BY PASSWORD ='Password1'   
	) 
GO  


-- 9. Grant connect rights to logins for instance endpoints
:CONNECT SERVER2
USE master;  
GRANT CONNECT ON ENDPOINT::Mirroring_Endpoint TO [AG_server3_login];  
GRANT CONNECT ON ENDPOINT::Mirroring_Endpoint TO [AG_server4_login];  
GO 
:CONNECT SERVER3
USE master;  
GRANT CONNECT ON ENDPOINT::Mirroring_Endpoint TO [AG_server2_login];    
GRANT CONNECT ON ENDPOINT::Mirroring_Endpoint TO [AG_server4_login];  
GO  
:CONNECT SERVER4
USE master;  
GRANT CONNECT ON ENDPOINT::Mirroring_Endpoint TO [AG_server2_login];    
GRANT CONNECT ON ENDPOINT::Mirroring_Endpoint TO [AG_server3_login];  
GO  