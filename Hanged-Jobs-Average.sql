-- Current running SQL Agent jobs + avg duration from history
DECLARE @session_id INT =
(
  SELECT TOP (1) session_id
  FROM msdb.dbo.syssessions
  ORDER BY agent_start_date DESC
);

WITH Running AS
(
  SELECT
      ja.job_id,
      j.name AS JobName,
      ja.start_execution_date AS StartTime,
      CAST(DATEDIFF(SECOND, ja.start_execution_date, GETDATE())/60.0  AS DECIMAL(10,2)) AS DurationMinutes,
      CAST(DATEDIFF(SECOND, ja.start_execution_date, GETDATE())/3600.0 AS DECIMAL(10,2)) AS DurationHours
  FROM msdb.dbo.sysjobactivity AS ja
  JOIN msdb.dbo.sysjobs        AS j  ON j.job_id = ja.job_id
  WHERE ja.session_id = @session_id
    AND ja.start_execution_date IS NOT NULL
    AND ja.stop_execution_date IS NULL
),
Hist AS
(
  -- Step_id = 0 -> one row per completed job run (whole job)
  SELECT
      jh.job_id,
      jh.run_date,
      jh.run_time,
      jh.run_status,       -- 1 = Succeeded
      DurationSec =
          ((jh.run_duration / 10000) * 3600) +            -- HH
          (((jh.run_duration % 10000) / 100) * 60) +      -- MM
          (jh.run_duration % 100)                          -- SS
  FROM msdb.dbo.sysjobhistory AS jh
  WHERE jh.step_id = 0
),
HistRank AS
(
  -- last 10 successful runs per job
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY job_id ORDER BY run_date DESC, run_time DESC) AS rn
  FROM Hist
  WHERE run_status = 1
),
HistAgg AS
(
  SELECT
      job_id,
      RunsCount10 = COUNT(*) ,
      AvgSec10    = AVG(CAST(DurationSec AS BIGINT))
  FROM HistRank
  WHERE rn <= 10
  GROUP BY job_id
)
SELECT
    r.JobName,
    r.StartTime,
    r.DurationMinutes,
    r.DurationHours,
    CASE WHEN r.StartTime IS NOT NULL THEN 'Running' ELSE 'Not running' END AS RunStatus,
    ha.RunsCount10                       AS PrevRunsUsed,
    CAST(ha.AvgSec10 / 60.0 AS DECIMAL(10,2)) AS AvgDurationMinutes_Last10,
    -- ETA based on avg of last 10 successes
    ETA = CASE WHEN ha.AvgSec10 IS NOT NULL
               THEN DATEADD(SECOND, ha.AvgSec10, r.StartTime)
               END,
    -- Remaining minutes (avg - elapsed)
    RemainingMinutes = CASE WHEN ha.AvgSec10 IS NOT NULL
                            THEN CAST( (ha.AvgSec10 - DATEDIFF(SECOND, r.StartTime, GETDATE())) / 60.0 AS DECIMAL(10,2))
                            END
FROM Running r
LEFT JOIN HistAgg ha
  ON ha.job_id = r.job_id
ORDER BY r.DurationHours DESC;
