-- Reporting views shared by the web dashboard.
-- security_invoker keeps the underlying table grants and RLS policies in force.

CREATE OR REPLACE VIEW public.v_machine_status_live
WITH (security_invoker = true)
AS
SELECT
  m.id,
  m.code,
  m.name,
  m.department,
  m.status,
  m.current_speed_mpm,
  m.total_meters_produced,
  active.id AS active_downtime_id,
  active.reason AS active_downtime_reason
FROM public.machines AS m
LEFT JOIN LATERAL (
  SELECT d.id, d.reason
  FROM public.downtime_logs AS d
  WHERE d.machine_id = m.id
    AND d.ended_at IS NULL
  ORDER BY d.started_at DESC, d.id DESC
  LIMIT 1
) AS active ON TRUE;

CREATE OR REPLACE VIEW public.v_downtime_pareto
WITH (security_invoker = true)
AS
WITH per_log AS (
  SELECT
    COALESCE(NULLIF(d.category, ''), 'other') AS category,
    d.started_at,
    d.ended_at,
    COALESCE((
      SELECT SUM((entry.value #>> '{}')::numeric)
      FROM jsonb_each(
        CASE WHEN jsonb_typeof(d.shift_minutes) = 'object'
          THEN d.shift_minutes ELSE '{}'::jsonb END
      ) AS entry(key, value)
      WHERE jsonb_typeof(entry.value) = 'number'
    ), 0) AS recorded_shift_minutes
  FROM public.downtime_logs AS d
)
SELECT
  category,
  ROUND(SUM(
    CASE WHEN recorded_shift_minutes > 0 THEN recorded_shift_minutes
      ELSE GREATEST(EXTRACT(EPOCH FROM (COALESCE(ended_at, NOW()) - started_at)) / 60, 0)
    END
  )::numeric, 2) AS total_minutes
FROM per_log
GROUP BY category;

CREATE OR REPLACE VIEW public.v_work_order_funnel
WITH (security_invoker = true)
AS
SELECT status, COUNT(*)::bigint AS count
FROM public.work_orders
GROUP BY status;

CREATE OR REPLACE VIEW public.v_line_availability_daily
WITH (security_invoker = true)
AS
WITH dates AS (
  SELECT generate_series(CURRENT_DATE - 6, CURRENT_DATE, INTERVAL '1 day')::date AS production_date
), departments AS (
  SELECT department, COUNT(*)::bigint AS machine_count
  FROM public.machines
  GROUP BY department
), downtime_per_day AS (
  SELECT
    d.production_date,
    m.department,
    SUM(CASE WHEN COALESCE(shift_minutes.recorded_minutes, 0) > 0
      THEN shift_minutes.recorded_minutes
      ELSE GREATEST(EXTRACT(EPOCH FROM (COALESCE(d.ended_at, NOW()) - d.started_at)) / 60, 0)
    END) AS downtime_minutes
  FROM public.downtime_logs AS d
  JOIN public.machines AS m ON m.id = d.machine_id
  CROSS JOIN LATERAL (
    SELECT COALESCE(SUM((entry.value #>> '{}')::numeric), 0) AS recorded_minutes
    FROM jsonb_each(
      CASE WHEN jsonb_typeof(d.shift_minutes) = 'object'
        THEN d.shift_minutes ELSE '{}'::jsonb END
    ) AS entry(key, value)
    WHERE jsonb_typeof(entry.value) = 'number'
  ) AS shift_minutes
  WHERE d.production_date BETWEEN CURRENT_DATE - 6 AND CURRENT_DATE
  GROUP BY d.production_date, m.department
)
SELECT
  departments.department,
  dates.production_date,
  departments.machine_count,
  ROUND(COALESCE(downtime_per_day.downtime_minutes, 0)::numeric, 2) AS downtime_minutes,
  CASE WHEN departments.machine_count = 0 THEN 100::numeric
    ELSE ROUND(GREATEST(0, LEAST(100,
      (departments.machine_count * 1440 - COALESCE(downtime_per_day.downtime_minutes, 0))
      * 100.0 / (departments.machine_count * 1440)
    ))::numeric, 2)
  END AS availability_pct
FROM dates
CROSS JOIN departments
LEFT JOIN downtime_per_day
  ON downtime_per_day.production_date = dates.production_date
  AND downtime_per_day.department = departments.department;

CREATE OR REPLACE VIEW public.v_mttr_by_department
WITH (security_invoker = true)
AS
SELECT
  m.department,
  COUNT(*)::bigint AS closed_count,
  ROUND(AVG(EXTRACT(EPOCH FROM (wo.completed_at - wo.started_at)) / 60)::numeric, 2) AS mttr_minutes
FROM public.work_orders AS wo
JOIN public.machines AS m ON m.id = wo.machine_id
WHERE wo.status IN ('completed', 'verified', 'verifiedClosed')
GROUP BY m.department;

CREATE OR REPLACE VIEW public.v_bad_actors_30d
WITH (security_invoker = true)
AS
WITH breakdowns AS (
  SELECT machine_id, COUNT(*)::bigint AS breakdown_count
  FROM public.work_orders
  WHERE type = 'breakdown'
    AND created_at >= NOW() - INTERVAL '30 days'
  GROUP BY machine_id
), downtime AS (
  SELECT
    d.machine_id,
    SUM(CASE WHEN COALESCE(minutes.recorded_minutes, 0) > 0
      THEN minutes.recorded_minutes
      ELSE GREATEST(EXTRACT(EPOCH FROM (COALESCE(d.ended_at, NOW()) - d.started_at)) / 60, 0)
    END) AS total_downtime_minutes
  FROM public.downtime_logs AS d
  CROSS JOIN LATERAL (
    SELECT COALESCE(SUM((entry.value #>> '{}')::numeric), 0) AS recorded_minutes
    FROM jsonb_each(
      CASE WHEN jsonb_typeof(d.shift_minutes) = 'object'
        THEN d.shift_minutes ELSE '{}'::jsonb END
    ) AS entry(key, value)
    WHERE jsonb_typeof(entry.value) = 'number'
  ) AS minutes
  WHERE d.started_at >= NOW() - INTERVAL '30 days'
  GROUP BY d.machine_id
)
SELECT
  m.id,
  m.code,
  m.name,
  m.department,
  COALESCE(breakdowns.breakdown_count, 0)::bigint AS breakdown_count,
  ROUND(COALESCE(downtime.total_downtime_minutes, 0)::numeric, 2) AS total_downtime_minutes
FROM public.machines AS m
LEFT JOIN breakdowns ON breakdowns.machine_id = m.id
LEFT JOIN downtime ON downtime.machine_id = m.id
WHERE COALESCE(breakdowns.breakdown_count, 0) > 0
   OR COALESCE(downtime.total_downtime_minutes, 0) > 0;

CREATE OR REPLACE VIEW public.v_shift_downtime_split
WITH (security_invoker = true)
AS
WITH per_log AS (
  SELECT
    d.production_date,
    m.department,
    d.started_at,
    d.ended_at,
    CASE WHEN jsonb_typeof(d.shift_minutes -> 'shift1_Morning') = 'number'
      THEN (d.shift_minutes ->> 'shift1_Morning')::numeric ELSE 0 END AS shift1_minutes,
    CASE WHEN jsonb_typeof(d.shift_minutes -> 'shift2_Evening') = 'number'
      THEN (d.shift_minutes ->> 'shift2_Evening')::numeric ELSE 0 END AS shift2_minutes,
    CASE WHEN jsonb_typeof(d.shift_minutes -> 'shift3_Night') = 'number'
      THEN (d.shift_minutes ->> 'shift3_Night')::numeric ELSE 0 END AS shift3_minutes
  FROM public.downtime_logs AS d
  JOIN public.machines AS m ON m.id = d.machine_id
), resolved AS (
  SELECT
    production_date,
    department,
    CASE WHEN shift1_minutes + shift2_minutes + shift3_minutes > 0
      THEN shift1_minutes
      WHEN EXTRACT(HOUR FROM started_at AT TIME ZONE 'Africa/Cairo') * 60
        + EXTRACT(MINUTE FROM started_at AT TIME ZONE 'Africa/Cairo') >= 450
       AND EXTRACT(HOUR FROM started_at AT TIME ZONE 'Africa/Cairo') * 60
        + EXTRACT(MINUTE FROM started_at AT TIME ZONE 'Africa/Cairo') < 930
      THEN GREATEST(EXTRACT(EPOCH FROM (COALESCE(ended_at, NOW()) - started_at)) / 60, 0)
      ELSE 0 END AS shift1_morning_minutes,
    CASE WHEN shift1_minutes + shift2_minutes + shift3_minutes > 0
      THEN shift2_minutes
      WHEN EXTRACT(HOUR FROM started_at AT TIME ZONE 'Africa/Cairo') * 60
        + EXTRACT(MINUTE FROM started_at AT TIME ZONE 'Africa/Cairo') >= 930
       AND EXTRACT(HOUR FROM started_at AT TIME ZONE 'Africa/Cairo') * 60
        + EXTRACT(MINUTE FROM started_at AT TIME ZONE 'Africa/Cairo') < 1380
      THEN GREATEST(EXTRACT(EPOCH FROM (COALESCE(ended_at, NOW()) - started_at)) / 60, 0)
      ELSE 0 END AS shift2_evening_minutes,
    CASE WHEN shift1_minutes + shift2_minutes + shift3_minutes > 0
      THEN shift3_minutes
      WHEN (EXTRACT(HOUR FROM started_at AT TIME ZONE 'Africa/Cairo') * 60
        + EXTRACT(MINUTE FROM started_at AT TIME ZONE 'Africa/Cairo') < 450)
        OR (EXTRACT(HOUR FROM started_at AT TIME ZONE 'Africa/Cairo') * 60
        + EXTRACT(MINUTE FROM started_at AT TIME ZONE 'Africa/Cairo') >= 1380)
      THEN GREATEST(EXTRACT(EPOCH FROM (COALESCE(ended_at, NOW()) - started_at)) / 60, 0)
      ELSE 0 END AS shift3_night_minutes
  FROM per_log
)
SELECT
  production_date,
  department,
  ROUND(SUM(shift1_morning_minutes)::numeric, 2) AS shift1_morning_minutes,
  ROUND(SUM(shift2_evening_minutes)::numeric, 2) AS shift2_evening_minutes,
  ROUND(SUM(shift3_night_minutes)::numeric, 2) AS shift3_night_minutes
FROM resolved
GROUP BY production_date, department;

GRANT SELECT ON public.v_machine_status_live,
  public.v_downtime_pareto,
  public.v_work_order_funnel,
  public.v_line_availability_daily,
  public.v_mttr_by_department,
  public.v_bad_actors_30d,
  public.v_shift_downtime_split
TO authenticated;
