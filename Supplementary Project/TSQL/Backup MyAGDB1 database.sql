-- Your new database will need to have been backed up at least once in order 
-- to pass validation checks if using direct seeding
BACKUP DATABASE [MyAGDB1] TO DISK = '\\SERVER1\backuppath\MyAGDB1.bak' WITH FORMAT, STATS =25
BACKUP LOG [MyAGDB1] TO DISK = '\\SERVER1\backuppath\MyAGDB1.trn' WITH FORMAT, STATS =100
GO