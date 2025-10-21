--------------------------------------------KILL SESSIONS------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------
-- Detailed tempdb usage by file
USE tempdb
--USE master
SELECT 
    name AS FileName,
    size/128 AS TotalMB,
    CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS UsedMB,
    (size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0) AS FreeMB,
    CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) * 100.0 / size AS UsedPercent,
    (size - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)) * 100.0 / size AS FreePercent
FROM sys.database_files
--WHERE type_desc = 'LOG';   

-----------------------------------------------------------------------------------------------
USE master

-- Checks blocking sessions
SELECT  
    r.row_count, 
    r.session_id,
    r.blocking_session_id, 
    CAST(r.granted_query_memory * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS granted_query_memory_gb, 
    CAST(r.wait_time / 1000.0 / 60 AS DECIMAL(10,2)) AS wait_time_minutes, 
    s.login_name AS user_name,
    --r.cpu_time / 1000.0 AS cpu_time_seconds,        
    --r.total_elapsed_time / 1000.0 AS elapsed_time_seconds, 
    r.last_wait_type, 
    r.wait_type,
    t.text AS query_text,
    r.status,
    r.command,
	s.login_time                                  AS session_start_time,     -- when the session began
    r.start_time                                  AS request_start_time     -- when this request began
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
ORDER BY  
r.session_id
--s.login_name

-- exec sp_WhoIsActive





