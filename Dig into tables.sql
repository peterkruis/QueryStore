USE StackOverflow2013;
GO

/*So we have 1 query which suffers parameter sniffing. We have forced it within the GUI*/
DECLARE @QueryId INT = 4;

SELECT qsq.query_id,
       qsqt.query_sql_text,
       qsp.plan_id,
       qsp.query_plan,
       qsp.is_forced_plan
FROM sys.query_store_query_text AS qsqt
    JOIN sys.query_store_query AS qsq
        ON qsq.query_text_id = qsqt.query_text_id
    JOIN sys.query_store_plan AS qsp
        ON qsp.query_id = qsq.query_id
WHERE qsq.query_id = @QueryId;

/*We can also undo that, or force it from code, or change it*/
EXEC sp_query_store_unforce_plan @query_id = 4, @plan_id = 3;

EXEC sp_query_store_force_plan @query_id = 4, @plan_id = 3;

/*Let's break it by removing the index and reexecute the query..*/
DROP INDEX [IX_CreationDate] ON [dbo].[Users];
GO

/*Will it be smart enough to undo the forcing?*/
DECLARE @QueryId INT = 4;

SELECT qsq.query_id,
       qsqt.query_sql_text,
       qsp.plan_id,
       qsp.query_plan,
       qsp.is_forced_plan
FROM sys.query_store_query_text AS qsqt
    JOIN sys.query_store_query AS qsq
        ON qsq.query_text_id = qsqt.query_text_id
    JOIN sys.query_store_plan AS qsp
        ON qsp.query_id = qsq.query_id
WHERE qsq.query_id = @QueryId;


/*Will this now execute? We removed the index which we forced..*/

EXEC dbo.GetUsersWithinPeriod @StartDate = '2008-12-31',
                              @EndDate = '2014-01-01';
GO



DECLARE @QueryId INT = 4;

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



CREATE NONCLUSTERED INDEX [ix_creationdate]
ON [dbo].[Users] ([CreationDate] ASC);

/*Will this now execute? We removed the index which we forced..*/
EXEC dbo.GetUsersWithinPeriod @StartDate = '2008-12-31',
                              @EndDate = '2014-01-01';
GO


/*But, what if they want to have it fast for ALL queries. Then we might better apply a query hint (e.g. OPTION(RECOMPILE)*/
/*Lets remove the forcing of the plan.*/
EXEC sp_query_store_unforce_plan @query_id = 4, @plan_id = 3;


/*See it is actually gone*/
DECLARE @QueryId INT = 4;

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

/*let's add an hint*/
EXEC sys.sp_query_store_set_hints 
    @query_id = 4, 
    @query_hints = N'OPTION(RECOMPILE)';

/*Stacking is also possible e.g. OPTION(RECOMPILE, MAXDOP 2)*/

EXEC dbo.GetUsersWithinPeriod @StartDate = '2008-12-31',
                              @EndDate = '2014-01-01';
GO

EXEC dbo.GetUsersWithinPeriod @StartDate = '2013-12-31',
                              @EndDate = '2014-01-01';
GO

/*Now the first one shold have the clustered index scan, where the second should have the index seek + key lookup*/

/*You can find the given hints here:*/
SELECT *
FROM sys.query_store_query_hints;

/*And can be removed again with*/
sp_query_store_clear_hints @query_id = 4


/*Another tool which is great to use, is the sp_quickiestore from Erik Darling*/
EXEC DBATools.dbo.sp_QuickieStore @database_name = 'StackOverflow2013',                       -- sysname
                                  @sort_order = 'cpu'

















USE StackOverflow2013;
GO

SELECT *
FROM sys.query_store_query_text;

SELECT *
FROM sys.query_store_query;

SELECT *
FROM sys.query_store_plan;

SELECT *
FROM sys.query_store_wait_stats;

SELECT *
FROM sys.query_store_runtime_stats;

/*And the other tables*/

SELECT *
FROM sys.query_store_plan_feedback;
SELECT *
FROM sys.query_store_plan_forcing_locations;
SELECT *
FROM sys.query_store_query_hints;
SELECT *
FROM sys.query_store_query_variant;
SELECT *
FROM sys.query_store_replicas;
SELECT *
FROM sys.query_context_settings;
SELECT *
FROM sys.database_query_store_internal_state;
SELECT *
FROM sys.database_query_store_options;

