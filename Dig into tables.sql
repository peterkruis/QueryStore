/*
    First show:
    - Configuration
    - Reports

    Then come back here..
        Forced a query? No, you should have..
*/


USE StackOverflow2013;
GO

/*What kind of data can we find, for example*/
SELECT
         qsqt.query_sql_text,
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
FROM     sys.query_store_query qsq
         JOIN sys.query_store_query_text qsqt ON qsq.query_text_id = qsqt.query_text_id
         JOIN sys.query_store_plan qsp ON qsq.query_id = qsp.query_id
         JOIN sys.query_store_runtime_stats rs ON qsp.plan_id = rs.plan_id
         JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
ORDER BY rsi.start_time DESC,
         qsp.query_id,
         qsp.plan_id;

/*Or, let's search for the statistics within a stored Proc*/
SELECT
         qt.query_sql_text,
         q.query_id,
         p.plan_id,
         rsi.start_time,
         rsi.end_time,
         rs.avg_duration,
         rs.avg_cpu_time,
         rs.avg_logical_io_reads,
         rs.count_executions
FROM     sys.query_store_query q
         JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
         JOIN sys.query_store_plan p ON q.query_id = p.query_id
         JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
         JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
WHERE    q.object_id = OBJECT_ID(N'dbo.GetUsersWithinPeriod')
--WHERE q.object_id = OBJECT_ID(N'dbo.GetUsersWithinPeriodExtended')
ORDER BY rsi.start_time DESC,
         query_id;


/*Or variants (2025+*/
DECLARE @ProcedureName sysname = N'dbo.GetUserBasics';

SELECT
         OBJECT_SCHEMA_NAME(parent_q.object_id) + N'.'
         + OBJECT_NAME(parent_q.object_id) AS procedure_name,
         variant.parent_query_id,
         variant.dispatcher_plan_id,
         variant.query_variant_query_id,
         child_q.query_hash,
         child_text.query_sql_text,
         child_plan.plan_id,
         child_plan.last_execution_time
FROM     sys.query_store_query_variant AS variant
         JOIN sys.query_store_query AS parent_q ON parent_q.query_id = variant.parent_query_id
         JOIN sys.query_store_query AS child_q ON child_q.query_id = variant.query_variant_query_id
         JOIN sys.query_store_query_text AS child_text ON child_text.query_text_id = child_q.query_text_id
         LEFT JOIN sys.query_store_plan AS child_plan ON child_plan.query_id = child_q.query_id
WHERE    parent_q.object_id = OBJECT_ID(@ProcedureName)
ORDER BY variant.parent_query_id,
         variant.dispatcher_plan_id,
         variant.query_variant_query_id,
         child_plan.plan_id;


SELECT *
FROM   sys.query_store_query_variant;

/*So we have 1 query which suffers parameter sniffing. We have forced it within the GUI
*/
DECLARE @QueryId INT = 1;

SELECT
      qsq.query_id,
      qsqt.query_sql_text,
      qsp.plan_id,
      CAST(qsp.query_plan AS XML),
      qsp.is_forced_plan
FROM  sys.query_store_query_text AS qsqt
      JOIN sys.query_store_query AS qsq ON qsq.query_text_id = qsqt.query_text_id
      JOIN sys.query_store_plan AS qsp ON qsp.query_id = qsq.query_id
WHERE qsq.query_id = @QueryId;

/*We can also undo that, or force it from code, or change it*/
EXEC sp_query_store_unforce_plan
   @query_id = 1,
   @plan_id = 1;

EXEC sp_query_store_force_plan
   @query_id = 1,
   @plan_id = 1;

/*Let's break it by removing the index and reexecute the query..*/
DROP INDEX [ix_creationdate]
   ON [dbo].[Users];
GO

/*Will it be smart enough to undo the forcing?*/
DECLARE @QueryId INT = 1;

SELECT
      qsq.query_id,
      qsqt.query_sql_text,
      qsp.plan_id,
      CAST(qsp.query_plan AS XML),
      qsp.is_forced_plan
FROM  sys.query_store_query_text AS qsqt
      JOIN sys.query_store_query AS qsq ON qsq.query_text_id = qsqt.query_text_id
      JOIN sys.query_store_plan AS qsp ON qsp.query_id = qsq.query_id
WHERE qsq.query_id = @QueryId;


/*Will this now execute? We removed the index which we forced..*/

EXEC dbo.GetUsersWithinPeriod
   @StartDate = '2008-12-31',
   @EndDate = '2014-01-01';
GO



DECLARE @QueryId INT = 1;

SELECT
      qsq.query_id,
      qsqt.query_sql_text,
      qsp.plan_id,
      qsp.query_plan,
      qsp.is_forced_plan,
      qsp.force_failure_count,
      qsp.last_force_failure_reason_desc
FROM  sys.query_store_query_text AS qsqt
      JOIN sys.query_store_query AS qsq ON qsq.query_text_id = qsqt.query_text_id
      JOIN sys.query_store_plan AS qsp ON qsp.query_id = qsq.query_id
WHERE qsq.query_id = @QueryId;

/*
    https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-query-store-plan-transact-sql?view=sql-server-ver17
    COMPILATION_ABORTED_BY_CLIENT: client aborted query compilation before it completed
    ONLINE_INDEX_BUILD: query tries to modify data while target table has an index that is being built online
    OPTIMIZATION_REPLAY_FAILED: The optimization replay script failed to execute.
    INVALID_STARJOIN: plan contains invalid StarJoin specification
    TIME_OUT: Optimizer exceeded number of allowed operations while searching for plan specified by forced plan
    NO_DB: A database specified in the plan doesn't exist
    HINT_CONFLICT: Query can't be compiled because plan conflicts with a query hint
    DQ_NO_FORCING_SUPPORTED: Can't execute query because plan conflicts with use of distributed query or full-text operations.
    NO_PLAN: Query processor couldn't produce query plan, because forced plan couldn't be verified as valid for the query
    NO_INDEX: Index specified in plan no longer exists
    VIEW_COMPILE_FAILED: Couldn't force query plan because of a problem in an indexed view referenced in the plan
    GENERAL_FAILURE: general forcing error (not covered with other reasons)
*/


CREATE NONCLUSTERED INDEX [ix_creationdate]
   ON [dbo].[Users] ([CreationDate] ASC);

EXEC dbo.GetUsersWithinPeriod
   @StartDate = '2010-12-31',
   @EndDate = '2014-01-01';
GO


/*But, what if they want to have it fast for ALL queries. Then we might better apply a query hint (e.g. OPTION(RECOMPILE)*/
/*Lets remove the forcing of the plan.*/
EXEC sp_query_store_unforce_plan
   @query_id = 1,
   @plan_id = 1;
GO

/*See it is actually gone*/
DECLARE @QueryId INT = 1;

SELECT
      qsq.query_id,
      qsqt.query_sql_text,
      qsp.plan_id,
      qsp.query_plan,
      qsp.is_forced_plan,
      qsp.force_failure_count,
      qsp.last_force_failure_reason_desc
FROM  sys.query_store_query_text AS qsqt
      JOIN sys.query_store_query AS qsq ON qsq.query_text_id = qsqt.query_text_id
      JOIN sys.query_store_plan AS qsp ON qsp.query_id = qsq.query_id
WHERE qsq.query_id = @QueryId;

/*let's add an hint*/
EXEC sys.sp_query_store_set_hints
   @query_id = 1,
   @query_hints = N'OPTION(RECOMPILE)';

/*Stacking is also possible e.g. OPTION(RECOMPILE, MAXDOP 2)*/


/*You can find the given hints here:*/
SELECT *
FROM   sys.query_store_query_hints;
GO

/*So, does this work?*/

EXEC dbo.GetUsersWithinPeriod
   @StartDate = '2008-12-31',
   @EndDate = '2014-01-01';
GO

EXEC dbo.GetUsersWithinPeriod
   @StartDate = '2013-12-31',
   @EndDate = '2014-01-01';
GO



/*Now the first one shold have the clustered index scan, where the second should have the index seek + key lookup*/

/*And can be removed again with*/
sp_query_store_clear_hints @query_id = 1;
GO



/* And what about multiple good plans? -> SQL Server 2025 Variants*/
DECLARE @ProcedureName sysname = N'dbo.GetUserBasics';

SELECT
         OBJECT_SCHEMA_NAME(parent_q.object_id) + N'.'
         + OBJECT_NAME(parent_q.object_id) AS procedure_name,
         variant.parent_query_id,
         variant.dispatcher_plan_id,
         variant.query_variant_query_id,
         child_q.query_hash,
         child_text.query_sql_text,
         child_plan.plan_id,
         child_plan.last_execution_time
FROM     sys.query_store_query_variant AS variant
         JOIN sys.query_store_query AS parent_q ON parent_q.query_id = variant.parent_query_id
         JOIN sys.query_store_query AS child_q ON child_q.query_id = variant.query_variant_query_id
         JOIN sys.query_store_query_text AS child_text ON child_text.query_text_id = child_q.query_text_id
         LEFT JOIN sys.query_store_plan AS child_plan ON child_plan.query_id = child_q.query_id
WHERE    parent_q.object_id = OBJECT_ID(@ProcedureName)
ORDER BY variant.parent_query_id,
         variant.dispatcher_plan_id,
         variant.query_variant_query_id,
         child_plan.plan_id;




/*A great tool which you can use, is the sp_quickiestore from Erik Darling*/
EXEC sp_QuickieStore @help = 1;
GO


EXEC sp_QuickieStore
   @database_name = 'StackOverflow2013', -- sysname
   @sort_order = 'cpu';

















USE StackOverflow2013;
GO

SELECT *
FROM   sys.query_store_query_text;

SELECT *
FROM   sys.query_store_query;

SELECT *
FROM   sys.query_store_plan;

SELECT *
FROM   sys.query_store_wait_stats;

SELECT *
FROM   sys.query_store_runtime_stats;

/*And the other tables*/
SELECT *
FROM   sys.database_query_store_options;
SELECT *
FROM   sys.query_context_settings;
SELECT *
FROM   sys.query_store_plan_feedback;
SELECT *
FROM   sys.query_store_plan_forcing_locations;
SELECT *
FROM   sys.query_store_query_hints;
SELECT *
FROM   sys.query_store_query_variant;
SELECT *
FROM   sys.query_store_replicas;
SELECT *
FROM   sys.database_query_store_internal_state;


