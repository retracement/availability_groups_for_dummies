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
limitations under the License.*/


-- First look in the GUI at the readonly routing


-- Set the secondary role read only url for replicas
ALTER AVAILABILITY GROUP [MyAG1]
MODIFY REPLICA ON
N'SERVER2\SQL2016' WITH
(SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://server2.retracement.me:1433'));

ALTER AVAILABILITY GROUP [MyAG1]
MODIFY REPLICA ON
N'SERVER3\SQL2016' WITH
(SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://server3.retracement.me:1433'));

ALTER AVAILABILITY GROUP [MyAG1]
MODIFY REPLICA ON
N'SERVER4\SQL2016' WITH
(SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://server4.retracement.me:1433'));


-- Set the primary role read only routing to replicas
ALTER AVAILABILITY GROUP [MyAG1]
MODIFY REPLICA ON N'SERVER2\SQL2016'
WITH (PRIMARY_ROLE(READ_ONLY_ROUTING_LIST=('SERVER3\SQL2016','SERVER4\SQL2016')));

ALTER AVAILABILITY GROUP [MyAG1]
MODIFY REPLICA ON N'SERVER3\SQL2016'
WITH (PRIMARY_ROLE(READ_ONLY_ROUTING_LIST=('SERVER2\SQL2016','SERVER4\SQL2016')));

ALTER AVAILABILITY GROUP [MyAG1]
MODIFY REPLICA ON N'SERVER4\SQL2016'
WITH (PRIMARY_ROLE(READ_ONLY_ROUTING_LIST=('SERVER3\SQL2016','SERVER2\SQL2016')));


-- Now view the Readonly routing list via the AG properties and note
-- that some of these replicas are not listed depending upon which are
-- not set with read intent


-- Set all replicas secondary role to allow reads. In otherwords set the Readable
-- Secondary to yes on each replica. 
-- You can view AG properties again -- note your settings are now visible
-- If you do not see the read-only routing list, run that code again and check the GUI


-- Play with readonly routing through the Readable secondary test.ps1