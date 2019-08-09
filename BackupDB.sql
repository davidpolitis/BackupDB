IF OBJECT_ID('tempdb..#BackupDB') IS NOT NULL
    DROP PROCEDURE #BackupDB;
GO
CREATE PROCEDURE #BackupDB(@DbName nvarchar(MAX), @BackupDir nvarchar(MAX) = NULL, @ExpireDate datetime = NULL)
AS
    IF (@BackupDir IS NULL)
    BEGIN;
        SELECT TOP 1 @BackupDir = physical_name FROM master.sys.database_files WHERE [Type] = 0;
        SET @BackupDir = REVERSE(STUFF(REVERSE(@BackupDir), 1, CHARINDEX('\', REVERSE(@BackupDir)), ''));
        SET @BackupDir = REVERSE(STUFF(REVERSE(@BackupDir), 1, CHARINDEX('\', REVERSE(@BackupDir)), ''));
        SET @BackupDir = @BackupDir + '\Backup\';
    END;
	ELSE
	BEGIN;
		-- Disallow clearly invalid paths - Change for SQL Server on Linux (Unsure of if backslashes would need to be forward slashes)
		IF (LEN(@BackupDir) < 2)
		BEGIN;
			SELECT 'Path must at least be two characters, with or without a trailing \, E.g. C:'
			RETURN;
		END;

		-- Add trailing slash if need be
		IF (RIGHT(@BackupDir, 1) <> '\')
			SET @BackupDir = @BackupDir + '\';
	END;

	DECLARE @BackupDate char(19) = CONVERT(char(19), GETDATE(), 120);
	SET @BackupDate = REPLACE(@BackupDate, ' ', '_');
	SET @BackupDate = REPLACE(@BackupDate, ':', '-');

    SET @BackupDir = CONCAT(@BackupDir, @DbName, '_', @BackupDate, '.bak');

	IF (@ExpireDate IS NULL)
		BACKUP DATABASE @DbName TO DISK = @BackupDir;
	ELSE
		BACKUP DATABASE @DbName TO DISK = @BackupDir WITH EXPIREDATE = @ExpireDate;

	IF (@@ERROR <> 0)
		SELECT 'A problem occurred backing up ' + @DbName + ' to ' + @BackupDir + ' - Please check the Messages tab if using SSMS!';
	ELSE
		SELECT 'Backed up ' + @DbName + ' to ' + @BackupDir;
GO

-- Tests
/*
EXEC #BackupDB 'test', 'C:\BackupDB\test1';
EXEC #BackupDB 'test', 'C:\BackupDB\test2\';
EXEC #BackupDB 'test', NULL, '2018-08-08';
*/