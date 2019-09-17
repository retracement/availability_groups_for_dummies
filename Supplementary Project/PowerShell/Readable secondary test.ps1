# T-SQL Code block
$sqlCommandText = @"
    SELECT @@servername AS instance, GETDATE() AS time
"@

Try {
clear-host
Invoke-Sqlcmd $sqlCommandText -ConnectionString "Data Source=MyAG1Listener;Initial Catalog=MyAGDB1;Integrated Security=True;Application Name=ListenerDemo;ApplicationIntent=ReadOnly"
}
Catch
{
 write-host "connection failed!"
}
