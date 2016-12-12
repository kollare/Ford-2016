/* Kollar, Edward ekollar@ford.com
 * 2016/12/08
 *
 * Rebuild of indexes for tables in DB.
 * Sunday, December 04, 2016
 * 10:43 PM */

/* 1) To figure out the list of activities running in the backend we need to run below mentioned statement. We can find the spid of the query which is blocking all other queries.
 * The spid will be present in "blk by" column. */
Sp_who2 active
 
/* 2) To capture the Query which is causing the block we can use below mentioned statement. If it doesn’t give the full statement so we have to run the next two statement.
 * Dbcc inputbuffer(spid) --We got the spid from 1st query from ‘blk by’ column of the data result. */
Select * from sys.dm_exec_requests where session_id = spid -- We got the spid from 1st query from ‘blk by’ column of the data result.
Select * from sys.dm_exec_sql_text(sql_handle)-  sql_handle we will get by executing above query and the result set will have a sql_handle column which can be used in this query.
 
/* 3) We can check the fragmentation report of the database. Following query will give us all indexes fragmented above 30%. */
SELECT OBJECT_NAME(ind.OBJECT_ID) AS TableName, ind.name AS IndexName, indexstats.index_type_desc AS IndexType, indexstats.avg_fragmentation_in_percent FROM sys.dm_db_index_physical_stats(DB_ID(),     NULL, NULL, NULL, NULL) indexstats INNER JOIN sys.indexes ind ON ind.object_id = indexstats.object_id AND ind.index_id = indexstats.index_id WHERE         indexstats.avg_fragmentation_in_percent > 30 ORDER BY indexstats.avg_fragmentation_in_percent DESC

/* 4) As per MS advise Stats needs to be updated periodically, following query will help us understand when the stats were last updated. */
SELECT OBJECT_NAME(object_id) AS ObjectName, STATS_DATE(object_id, stats_id) AS StatisticsDate, * FROM sys.stats order by StatisticsDate desc
 
/* 5) We generated the script  to rebuild and update statistics for the all the tables in the database by using below mentioned statement.
 * 5.a) The following query will generate statements to rebuild indexes. */
SELECT  'ALTER INDEX ALL ON ' + SysSche.Name + '.' + SysObj.Name + ' REBUILD;' FROM Sys.Objects SysObj INNER JOIN sys.schemas SysSche ON SysObj.Schema_ID = SysSche.Schema_ID WHERE TYPE = 'U'
        
 /* 5.b) Following query will generate statements for Updating stats with full scan. */
SELECT 'UPDATE STATISTICS [' + SysObj.Name +'] WITH FULLSCAN' FROM Sys.Objects SysObj INNER JOIN sys.schemas SysSche ON SysObj.Schema_ID = SysSche.Schema_ID WHERE TYPE = 'U'