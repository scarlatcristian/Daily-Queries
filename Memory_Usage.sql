-- 1) Current memory grant queue & hogs
SELECT 
    mg.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    s.status,
    s.login_time,
    mg.requested_memory_kb/1024.0 AS req_MB,
    mg.requested_memory_kb/1024.0/1024.0 AS req_GB,
    mg.granted_memory_kb/1024.0   AS granted_MB,
    mg.granted_memory_kb/1024.0/1024.0 AS granted_GB,
    mg.used_memory_kb/1024.0      AS used_MB,
    mg.used_memory_kb/1024.0/1024.0 AS used_GB,
    mg.max_used_memory_kb/1024.0  AS max_used_MB,
    mg.max_used_memory_kb/1024.0/1024.0 AS max_used_GB,
    mg.queue_id,
    mg.wait_order,
    mg.wait_time_ms/1000.0 AS wait_s,
    mg.is_next_candidate,
    mg.resource_semaphore_id,
    qt.text AS sql_text,
    qp.query_plan
FROM sys.dm_exec_query_memory_grants AS mg
JOIN sys.dm_exec_sessions AS s
    ON mg.session_id = s.session_id
OUTER APPLY sys.dm_exec_sql_text(mg.sql_handle) AS qt
OUTER APPLY sys.dm_exec_query_plan(mg.plan_handle) AS qp
ORDER BY login_name, mg.granted_memory_kb DESC, mg.requested_memory_kb DESC;


-- 2) Semaphores status (how full the pool is)
SELECT *
FROM sys.dm_exec_query_resource_semaphores;

-- 3) Overall memory distribution (where memory is going)
SELECT TOP (20)
  mc.type, SUM(mc.pages_kb)/1024.0 AS MB
FROM sys.dm_os_memory_clerks AS mc
GROUP BY mc.type
ORDER BY SUM(mc.pages_kb) DESC;

-- 4) Who’s waiting on RESOURCE_SEMAPHORE right now
SELECT 
    wt.session_id,
    s.login_name,
    s.original_login_name,
    s.host_name,
    s.program_name,
    wt.wait_type,
    wt.wait_duration_ms/1000.0 AS wait_s,
    rq.cpu_time/1000.0 AS cpu_s,
    rq.status,
    st.text AS sql_text
FROM sys.dm_os_waiting_tasks AS wt
JOIN sys.dm_exec_requests AS rq 
    ON rq.session_id = wt.session_id
JOIN sys.dm_exec_sessions AS s
    ON wt.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(rq.sql_handle) AS st
WHERE wt.wait_type = 'RESOURCE_SEMAPHORE'
ORDER BY  s.login_name, wait_s DESC;
