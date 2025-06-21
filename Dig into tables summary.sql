
/*What kind of data can we find, for example*/
SELECT qsqt.query_sql_text,
       qsp.query_id,
       qsp.plan_id,
       rsi.start_time,
       rsi.end_time,
       rs.execution_type_desc,
       rs.first_execution_time,
       rs.last_execution_time,
       rs.count_executions,
       rs.avg_duration,
       rs.last_duration,
       rs.min_duration,
       rs.max_duration,
       rs.stdev_duration,
       rs.avg_cpu_time,
       rs.last_cpu_time,
       rs.min_cpu_time,
       rs.max_cpu_time,
       rs.stdev_cpu_time,
       rs.avg_logical_io_reads,
       rs.last_logical_io_reads,
       rs.min_logical_io_reads,
       rs.max_logical_io_reads,
       rs.stdev_logical_io_reads,
       rs.avg_logical_io_writes,
       rs.last_logical_io_writes,
       rs.min_logical_io_writes,
       rs.max_logical_io_writes,
       rs.stdev_logical_io_writes,
       rs.avg_physical_io_reads,
       rs.last_physical_io_reads,
       rs.min_physical_io_reads,
       rs.max_physical_io_reads,
       rs.stdev_physical_io_reads,
       rs.avg_clr_time,
       rs.last_clr_time,
       rs.min_clr_time,
       rs.max_clr_time,
       rs.stdev_clr_time,
       rs.avg_dop,
       rs.last_dop,
       rs.min_dop,
       rs.max_dop,
       rs.stdev_dop,
       rs.avg_query_max_used_memory,
       rs.last_query_max_used_memory,
       rs.min_query_max_used_memory,
       rs.max_query_max_used_memory,
       rs.stdev_query_max_used_memory,
       rs.avg_rowcount,
       rs.last_rowcount,
       rs.min_rowcount,
       rs.max_rowcount,
       rs.stdev_rowcount,
       rs.avg_num_physical_io_reads,
       rs.last_num_physical_io_reads,
       rs.min_num_physical_io_reads,
       rs.max_num_physical_io_reads,
       rs.stdev_num_physical_io_reads,
       rs.avg_log_bytes_used,
       rs.last_log_bytes_used,
       rs.min_log_bytes_used,
       rs.max_log_bytes_used,
       rs.stdev_log_bytes_used,
       rs.avg_tempdb_space_used,
       rs.last_tempdb_space_used,
       rs.min_tempdb_space_used,
       rs.max_tempdb_space_used,
       rs.stdev_tempdb_space_used,
       rs.avg_page_server_io_reads,
       rs.last_page_server_io_reads,
       rs.min_page_server_io_reads,
       rs.max_page_server_io_reads,
       rs.stdev_page_server_io_reads,
       rs.replica_group_id
FROM sys.query_store_query qsq
    JOIN sys.query_store_query_text qsqt
        ON qsq.query_text_id = qsqt.query_text_id
    JOIN sys.query_store_plan qsp
        ON qsq.query_id = qsp.query_id
    JOIN sys.query_store_runtime_stats rs
        ON qsp.plan_id = rs.plan_id
    JOIN sys.query_store_runtime_stats_interval rsi
        ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
ORDER BY rsi.start_time DESC,
         qsp.query_id,
         qsp.plan_id;

/*Or, let's search for the statistics within a stored Proc*/
SELECT qt.query_sql_text,
       q.query_id,
       p.plan_id,
       rsi.start_time,
       rsi.end_time,
       rs.avg_duration,
       rs.avg_cpu_time,
       rs.avg_logical_io_reads,
       rs.count_executions
FROM sys.query_store_query q
    JOIN sys.query_store_query_text qt
        ON q.query_text_id = qt.query_text_id
    JOIN sys.query_store_plan p
        ON q.query_id = p.query_id
    JOIN sys.query_store_runtime_stats rs
        ON p.plan_id = rs.plan_id
    JOIN sys.query_store_runtime_stats_interval rsi
        ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
WHERE q.object_id = OBJECT_ID(N'dbo.GetUsersWithinPeriodWithTempTable')
ORDER BY rsi.start_time DESC;

/*So we have 1 query which suffers parameter sniffing. We have forced it within the GUI*/
DECLARE @QueryId INT = 33;	/*Replace with the query forced*/

SELECT qsq.query_id,
       qsqt.query_sql_text,
       qsp.plan_id,
       CAST(qsp.query_plan AS XML),
       qsp.is_forced_plan
FROM sys.query_store_query_text AS qsqt
    JOIN sys.query_store_query AS qsq
        ON qsq.query_text_id = qsqt.query_text_id
    JOIN sys.query_store_plan AS qsp
        ON qsp.query_id = qsq.query_id
WHERE qsq.query_id = @QueryId;


/*We can also undo that, or force it from code, or change it*/
EXEC sp_query_store_unforce_plan @query_id = 33, @plan_id = 6;

EXEC sp_query_store_force_plan @query_id = 33, @plan_id = 6;



/*Let's break it by removing the index and reexecute the query..*/

/*Will it be smart enough to undo the forcing?*/
DECLARE @QueryId INT = 33;

SELECT qsq.query_id,
       qsqt.query_sql_text,
       qsp.plan_id,
       CAST(qsp.query_plan AS XML),
       qsp.is_forced_plan
FROM sys.query_store_query_text AS qsqt
    JOIN sys.query_store_query AS qsq
        ON qsq.query_text_id = qsqt.query_text_id
    JOIN sys.query_store_plan AS qsp
        ON qsp.query_id = qsq.query_id
WHERE qsq.query_id = @QueryId;

/*No, it keeps on saying 'forced', however, executing didnt fail*/

DECLARE @QueryId INT = 33;

SELECT qsq.query_id,
       qsqt.query_sql_text,
       qsp.plan_id,
       qsp.query_plan,
       qsp.is_forced_plan,
       qsp.force_failure_count,
       qsp.last_force_failure_reason_desc
FROM sys.query_store_query_text AS qsqt
    JOIN sys.query_store_query AS qsq
        ON qsq.query_text_id = qsqt.query_text_id
    JOIN sys.query_store_plan AS qsp
        ON qsp.query_id = qsq.query_id
WHERE qsq.query_id = @QueryId;

/*What it did do, is let it know, that it failed and the reason why*/



/*let's add an hint, instead of forcing. Note, that when a query has been forced, query below will give an error*/
EXEC sys.sp_query_store_set_hints @query_id = 33,
                                  @query_hints = N'OPTION(RECOMPILE)';

/*Stacking is also possible e.g. OPTION(RECOMPILE, MAXDOP 2)*/


/*You can find the given hints here:*/
SELECT *    
FROM sys.query_store_query_hints;
GO

/*And the hints can be removed again with*/
sp_query_store_clear_hints @query_id = 33;
GO

/*Another tool which is great to use, is the sp_quickiestore from Erik Darling, for download, see sheets*/
EXEC DBATools.dbo.sp_QuickieStore @database_name = 'StackOverflow2013', -- sysname
                                  @sort_order = 'cpu';

