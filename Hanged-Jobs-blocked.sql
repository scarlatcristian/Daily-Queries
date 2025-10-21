-- Blockers of currently running SQL Agent T-SQL job steps
SET NOCOUNT ON;

;WITH req AS
(
    SELECT
        r.session_id,
        r.blocking_session_id,
        r.wait_type,
        r.wait_time,
        r.start_time,
        r.command,
        r.database_id,
        DB_NAME(r.database_id) AS database_name,
        r.cpu_time,
        r.reads,
        r.writes,
        r.status,
        txt.text AS sql_text
    FROM sys.dm_exec_requests AS r
    OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS txt
),
agent_sess AS
(
    -- Sessions whose program_name indicates a SQL Agent T-SQL Job Step
    SELECT
        s.session_id,
        s.program_name,
        s.login_name,
        s.host_name,
        s.login_time,
        -- Parse JobId and Step from program_name: "SQLAgent - TSQL JobStep (Job 0x..., Step X)"
        CASE
            WHEN s.program_name LIKE 'SQLAgent - TSQL JobStep (Job 0x%' THEN
                CONVERT(uniqueidentifier,
                    CONVERT(varbinary(16),
                        SUBSTRING(s.program_name,
                                  CHARINDEX('0x', s.program_name) + 2,
                                  32), 2))
        END AS job_id,
        TRY_CONVERT(int,
            SUBSTRING(
                s.program_name,
                CHARINDEX('Step ', s.program_name) + 5,
                LEN(s.program_name)
            )
        ) AS step_id
    FROM sys.dm_exec_sessions AS s
    WHERE s.program_name LIKE 'SQLAgent - TSQL JobStep (Job 0x%'
),
job_meta AS
(
    SELECT
        a.session_id,
        a.job_id,
        a.step_id,
        j.name  AS JobName,
        js.step_name AS StepName
    FROM agent_sess AS a
    LEFT JOIN msdb.dbo.sysjobs      AS j  ON a.job_id = j.job_id
    LEFT JOIN msdb.dbo.sysjobsteps  AS js ON a.job_id = js.job_id AND a.step_id = js.step_id
)
SELECT
    br.JobName,
    br.StepName,
    r.session_id               AS blocked_session_id,
    r.blocking_session_id,
    r.status                   AS blocked_status,
    r.wait_type,
    r.wait_time,
    r.database_name,
    r.command                  AS blocked_command,
    LEFT(r.sql_text, 4000)     AS blocked_sql_text,
    -- Blocker info
    bs.program_name            AS blocker_program_name,
    bs.login_name              AS blocker_login,
    brk.status                 AS blocker_status,
    brk.wait_type              AS blocker_wait_type,
    LEFT(brk.sql_text, 4000)   AS blocker_sql_text
FROM req AS r
JOIN agent_sess AS asess
  ON asess.session_id = r.session_id
LEFT JOIN job_meta AS br
  ON br.session_id = r.session_id
LEFT JOIN sys.dm_exec_sessions AS bs
  ON bs.session_id = r.blocking_session_id
LEFT JOIN req AS brk
  ON brk.session_id = r.blocking_session_id
WHERE r.blocking_session_id <> 0
ORDER BY r.wait_time DESC;
