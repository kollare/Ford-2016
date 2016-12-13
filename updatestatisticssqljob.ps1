<#
.SYNOPSIS 
    Update the statistics of high-use tables in the sdn.

.DESCRIPTION
    This runbook updates the statistics of known high-use tables as a temporary "hot-fix" compensating the lack of a cache in current deployment.

.NOTES
    AUTHOR: Kollar, Edward 
	USER: ekollar@azureford.onmicrosoft.com
    LASTEDIT: 2016/12/09
#>
workflow updatestatisticssqljob {
    param(
        # Fully-qualified name of the Azure DB server 
        [parameter(Mandatory=$true)]
        [string] $SqlServerName,

        # Credentials for $SqlServerName stored as an Azure Automation credential asset
        # When using in the Azure Automation UI, please enter the name of the credential asset for the "Credential" parameter
        [parameter(Mandatory=$true)] 
        [string] $SqlUserId,

        [parameter(Mandatory=$true)] 
        [string] $SqlPassword
    )

    inlinescript {
        # Setup credentials   
        $ServerName = $Using:SqlServerName
        $UserId = $Using:SqlUserId
        $Password = $Using:SqlPassword

        # Create connection to SDN DB
        $SdnDatabaseConnection = New-Object System.Data.SqlClient.SqlConnection
        $SdnDatabaseConnection.ConnectionString = "Server = $ServerName; Database = Sdn; User ID = $UserId; Password = $Password;"
        $SdnDatabaseConnection.Open();

        # Create command to query the current size of active databases in $ServerName
        $SdnDatabaseCommand = New-Object System.Data.SqlClient.SqlCommand
        $SdnDatabaseCommand.Connection = $SdnDatabaseConnection
        $SdnDatabaseCommand.CommandText = 
            "
                UPDATE STATISTICS [dbo].[Vehicle] WITH FULLSCAN;
                UPDATE STATISTICS [dbo].[VehicleType] WITH FULLSCAN;
                UPDATE STATISTICS [dbo].[Brand] WITH FULLSCAN;
                UPDATE STATISTICS [dbo].[UserVehicle] WITH FULLSCAN;
                UPDATE STATISTICS [dbo].[User] WITH FULLSCAN;
                UPDATE STATISTICS [dbo].[UserIdentity] WITH FULLSCAN;
                UPDATE STATISTICS [dbo].[UserVehicleAuthStatus] WITH FULLSCAN;
                UPDATE STATISTICS [dbo].[Country] WITH FULLSCAN;
                UPDATE STATISTICS [dbo].[Language] WITH FULLSCAN;
                UPDATE STATISTICS [dbo].[TimeZone] WITH FULLSCAN;
                UPDATE STATISTICS [dbo].[UserCommunicationPreference] WITH FULLSCAN;
                UPDATE STATISTICS [dbo].[UserRole] WITH FULLSCAN;
            "
        # Execute reader and return tuples of results <database_name, SizeMB>
        $SdnDbResult = $SdnDatabaseCommand.ExecuteNonQuery()

        # Proceed if there is at least one database
        # if ($SdnDbResult.HasRows) {
            Write-Output "updated statistics"
        # } 

        # Close connection to Sdn DB
        $SdnDatabaseConnection.Close() 
    }    
}