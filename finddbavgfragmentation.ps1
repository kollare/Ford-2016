<#
.SYNOPSIS 
    Finds average fragmentation for tables in a given database.

.DESCRIPTION
    This runbook finds the average fragmentation for all of the tables in a given database;
    the results are output as:
        object_id (table) and corresponding avg_fragmentation_in_percent (0-100 float value)
	(Parts of this script utilize open-source code provided by Microsoft)

.PARAMETER SqlServer
    Name of the SqlServer
.PARAMETER Database
    Name of the database
.PARAMETER SQLCredentialName
    Name of the Automation PowerShell credential setting from the Automation asset store. 
    This setting stores the username and password for the SQL Azure server
.PARAMETER FragPercentage
    Optional parameter for specifying over what percentage fragmentation to index database
    [Default is 25 percent]
.PARAMETER RebuildOffline
    Optional parameter to rebuild indexes offline if online fails 
    [Default is false]
.PARAMETER Table
    Optional parameter for specifying a specific table to index
    [Default is all tables]
.PARAMETER SqlServerPort
    Optional parameter for specifying the SQL port 
    [Default is 1433]

.NOTES
      AUTHOR: Kollar, Edward 
	USER: ekollar@azureford.onmicrosoft.com
    LASTEDIT: 2016/12/14
    REVISION: 2019/02/06
      SERVER: MASKED
#>
workflow finddbavgfragmentation {
    param(
        [parameter(Mandatory=$True)]
        [string] $SqlServer = "server",
    
        [parameter(Mandatory=$True)]
        [string] $Database = "sdn",
    
        # [parameter(Mandatory=$True)]
        # [string] $SQLCredentialName,
        
		[parameter(Mandatory=$True)]
		[string] $SqlUsername = "user",
		
		[parameter(Mandatory=$True)]
		[string] $SqlPass = "pass",
		
        [parameter(Mandatory=$False)]
        [int] $FragPercentage=25,

        [parameter(Mandatory=$False)]
        [int] $SqlServerPort=1433,
        
        # [parameter(Mandatory=$False)]
        # [boolean] $RebuildOffline = $False,

        [parameter(Mandatory=$False)]
        [string] $Table
    )
	
    $TableNames = Inlinescript {
        # Define the connection to the SQL Database
        $Conn = New-Object System.Data.SqlClient.SqlConnection(
		"Server=tcp:$using:SqlServer,$using:SqlServerPort;Database=$using:Database;User ID=$using:SqlUsername;Password=$using:SqlPass;Trusted_Connection=False;Encrypt=True;Connection Timeout=30;")
        
        # Open the SQL connection
        $Conn.Open()
        
        # SQL command to find tables and their average fragmentation
        $SQLCommandString = @"
        SELECT a.object_id, avg_fragmentation_in_percent
        FROM sys.dm_db_index_physical_stats(
               DB_ID(N'$Database')
             , OBJECT_ID(0)
             , NULL
             , NULL
             , NULL) AS a
        JOIN sys.indexes AS b 
        ON a.object_id = b.object_id AND a.index_id = b.index_id;
"@
        # Return the tables with their corresponding average fragmentation
        $Cmd=new-object system.Data.SqlClient.SqlCommand($SQLCommandString, $Conn)
        $Cmd.CommandTimeout=120
        
        # Execute the SQL command
        $FragmentedTable=New-Object system.Data.DataSet
        $Da=New-Object system.Data.SqlClient.SqlDataAdapter($Cmd)
        [void]$Da.fill($FragmentedTable)
 
        # Get the list of tables with their object ids
        $SQLCommandString = @"
        SELECT  t.name AS TableName, t.OBJECT_ID FROM sys.tables t
"@
        $Cmd=new-object system.Data.SqlClient.SqlCommand($SQLCommandString, $Conn)
        $Cmd.CommandTimeout=120

        # Execute the SQL command
        $TableSchema =New-Object system.Data.DataSet
        $Da=New-Object system.Data.SqlClient.SqlDataAdapter($Cmd)
        [void]$Da.fill($TableSchema)

        # Return the table names that have high fragmentation
        ForEach ($FragTable in $FragmentedTable.Tables[0]) {
            ## Write-Output ("Table Object ID:" + $FragTable.Item("object_id"))
            ## Write-Output ("Fragmentation:" + $FragTable.Item("avg_fragmentation_in_percent"))
            ## Write-Verbose ("Table Object ID:" + $FragTable.Item("object_id"))
            ## Write-Verbose ("Fragmentation:" + $FragTable.Item("avg_fragmentation_in_percent"))
            If ($FragTable.avg_fragmentation_in_percent -ge $Using:FragPercentage) {
                # Table is fragmented. Return this table for indexing by finding its name
                ForEach($Id in $TableSchema.Tables[0]) {
                    if ($Id.OBJECT_ID -eq $FragTable.object_id.ToString()) {
                        # Found the table name for this table object id. Return it
                        ## Write-Output ("Found a table to index! : " +  $Id.Item("TableName"))
                        ## Write-Verbose ("Found a table to index! : " +  $Id.Item("TableName"))
                        $Id.TableName
                    }
                }
            }
        }
        $Conn.Close()
    }
    Write-Output ($TableNames)
    Write-Output ("Success: Average Fragmentation for all tables in the database: " + $Database + " were found!")
    Write-Verbose ("...finished running 'finddbavgfragmentation' script successfully")
}
