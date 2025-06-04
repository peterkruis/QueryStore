USE StackOverflow2013
GO


/*Total script about 10 minutes
	Manual needed at the end (cancelling query)

*/

DROP INDEX IF EXISTS IX_Age ON dbo.Users

/*First, empty all query store data*/
ALTER DATABASE StackOverflow2013 SET QUERY_STORE CLEAR;
GO

/*Let's have some workload on it..*/
EXEC dbo.TestProc1	/*1 large query*/
GO 5

EXEC dbo.TestProc5	/*1 small query, with a higher amount*/
GO 30

/*One SP with possible parameter sniffing ADD FORCING*/
EXEC dbo.GetUsersWithinPeriod @StartDate = '2013-12-31', @EndDate = '2014-01-01'
GO 10

EXEC dbo.GetUsersWithinPeriod @StartDate = '2013-12-01', @EndDate = '2014-01-01'
GO 2

EXEC dbo.GetUsersWithinPeriod @StartDate = '2008-12-01', @EndDate = '2014-01-01'
GO 

DBCC FREEPROCCACHE

EXEC dbo.GetUsersWithinPeriod @StartDate = '2008-12-01', @EndDate = '2014-01-01'
GO 

/*Some ad-hoc*/
DECLARE @Age INT = 100;
SELECT Id FROM dbo.Users AS u WHERE u.Age = @Age
GO 1

/*Create an index for a change in above plan*/
CREATE INDEX IX_Age ON dbo.Users(Age)
GO

DECLARE @Age INT = 100;
SELECT Id FROM dbo.Users AS u WHERE u.Age = @Age
GO 30000

DROP INDEX IX_Age ON dbo.Users
GO
WAITFOR DELAY '00:04:00'
GO
DECLARE @Age INT = 100;
SELECT Id FROM dbo.Users AS u WHERE u.Age = @Age
GO 2

DECLARE @Number INT = 100;
SELECT Id FROM dbo.Users AS u WHERE u.DownVotes / @Number = 1;
GO
/*Cancel this query while running*/
DECLARE @Number INT = 100;
SELECT Id FROM dbo.Users AS u WHERE u.DownVotes / @Number = 1;
GO
DECLARE @Number INT = 0;
SELECT Id FROM dbo.Users AS u WHERE u.DownVotes / @Number = 1;
GO
