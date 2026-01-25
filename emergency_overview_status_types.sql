-- =============================================
-- Emergency Overview Status Types and Columns
-- =============================================
-- This script adds columns for missing status and total onboard count,
-- and creates a view for the emergency overview with color-coded status types
--
-- Status Types:
-- - SOS Alerts – 🔴 Red (Emergency; requires immediate response)
-- - Injured – 🟠 Orange (Alive but requires medical attention)
-- - Rescued – 🟢 Green (Successfully retrieved / assisted)
-- - Casualties – ⚫ Gray (Fatalities; no longer active cases)
-- - Missing – 🟡 Yellow (Unconfirmed status; still under search)
-- - Total Onboard – 🔵 Blue (Informational count of fishermen/passengers on the boat)

-- =============================================
-- 1. Add missing and total_onboard columns to sos_alerts
-- =============================================

-- Add missing column (number of missing persons)
ALTER TABLE public.sos_alerts 
ADD COLUMN IF NOT EXISTS missing INTEGER DEFAULT 0;

-- Add total_onboard column (total number of fishermen/passengers on the boat)
ALTER TABLE public.sos_alerts 
ADD COLUMN IF NOT EXISTS total_onboard INTEGER DEFAULT 0;

-- Add comments for documentation
COMMENT ON COLUMN public.sos_alerts.missing IS 'Number of missing persons in this emergency (unconfirmed status; still under search)';
COMMENT ON COLUMN public.sos_alerts.total_onboard IS 'Total number of fishermen/passengers on the boat during the emergency';

-- =============================================
-- 2. Create Emergency Overview View
-- =============================================

CREATE OR REPLACE VIEW public.emergency_overview AS
SELECT 
    -- Basic alert information
    sa.id,
    sa.latitude,
    sa.longitude,
    sa.message,
    sa.status,
    sa.created_at,
    sa.resolved_at,
    sa.on_the_way_at,
    
    -- Fisherman information
    sa.fisherman_uid,
    sa.fisherman_display_id,
    sa.fisherman_name,
    sa.fisherman_email,
    sa.fisherman_phone,
    sa.fisherman_profile_image_url,
    
    -- Emergency statistics
    COALESCE(sa.casualties, 0) as casualties,
    COALESCE(sa.injured, 0) as injured,
    COALESCE(sa.missing, 0) as missing,
    COALESCE(sa.total_onboard, 0) as total_onboard,
    
    -- Status type and color indicator
    CASE 
        WHEN sa.status = 'active' THEN 'SOS Alert'
        WHEN sa.status = 'on_the_way' THEN 'SOS Alert'
        WHEN sa.status = 'resolved' AND COALESCE(sa.casualties, 0) > 0 THEN 'Casualties'
        WHEN sa.status = 'resolved' AND COALESCE(sa.injured, 0) > 0 THEN 'Injured'
        WHEN sa.status = 'resolved' THEN 'Rescued'
        WHEN sa.status = 'inactive' AND COALESCE(sa.missing, 0) > 0 THEN 'Missing'
        WHEN sa.status = 'inactive' THEN 'Rescued'
        ELSE 'SOS Alert'
    END as status_type,
    
    -- Color code for UI display
    CASE 
        WHEN sa.status = 'active' THEN '🔴'
        WHEN sa.status = 'on_the_way' THEN '🔴'
        WHEN sa.status = 'resolved' AND COALESCE(sa.casualties, 0) > 0 THEN '⚫'
        WHEN sa.status = 'resolved' AND COALESCE(sa.injured, 0) > 0 THEN '🟠'
        WHEN sa.status = 'resolved' THEN '🟢'
        WHEN sa.status = 'inactive' AND COALESCE(sa.missing, 0) > 0 THEN '🟡'
        WHEN sa.status = 'inactive' THEN '🟢'
        ELSE '🔴'
    END as status_color,
    
    -- Color description
    CASE 
        WHEN sa.status = 'active' THEN 'Red - Emergency; requires immediate response'
        WHEN sa.status = 'on_the_way' THEN 'Red - Emergency; requires immediate response'
        WHEN sa.status = 'resolved' AND COALESCE(sa.casualties, 0) > 0 THEN 'Gray - Fatalities; no longer active cases'
        WHEN sa.status = 'resolved' AND COALESCE(sa.injured, 0) > 0 THEN 'Orange - Alive but requires medical attention'
        WHEN sa.status = 'resolved' THEN 'Green - Successfully retrieved / assisted'
        WHEN sa.status = 'inactive' AND COALESCE(sa.missing, 0) > 0 THEN 'Yellow - Unconfirmed status; still under search'
        WHEN sa.status = 'inactive' THEN 'Green - Successfully retrieved / assisted'
        ELSE 'Red - Emergency; requires immediate response'
    END as status_description,
    
    -- Total onboard indicator (Blue)
    CASE 
        WHEN COALESCE(sa.total_onboard, 0) > 0 THEN '🔵'
        ELSE NULL
    END as total_onboard_indicator,
    
    -- Weather data (if available)
    sa.weather_data
    
FROM public.sos_alerts sa
ORDER BY sa.created_at DESC;

-- Add comment for documentation
COMMENT ON VIEW public.emergency_overview IS 'Emergency overview with color-coded status types: 🔴 Red (SOS/Emergency), 🟠 Orange (Injured), 🟢 Green (Rescued), ⚫ Gray (Casualties), 🟡 Yellow (Missing), 🔵 Blue (Total Onboard)';

-- =============================================
-- 3. Create Emergency Statistics Summary View
-- =============================================

CREATE OR REPLACE VIEW public.emergency_statistics_summary AS
SELECT 
    -- Count by status type
    COUNT(*) FILTER (WHERE status = 'active' OR status = 'on_the_way') as sos_alerts_count,
    COUNT(*) FILTER (WHERE status = 'resolved' AND COALESCE(injured, 0) > 0) as injured_count,
    COUNT(*) FILTER (WHERE status = 'resolved' OR (status = 'inactive' AND COALESCE(missing, 0) = 0)) as rescued_count,
    COUNT(*) FILTER (WHERE COALESCE(casualties, 0) > 0) as casualties_count,
    COUNT(*) FILTER (WHERE COALESCE(missing, 0) > 0) as missing_count,
    
    -- Sum of statistics
    COALESCE(SUM(COALESCE(casualties, 0)), 0) as total_casualties,
    COALESCE(SUM(COALESCE(injured, 0)), 0) as total_injured,
    COALESCE(SUM(COALESCE(missing, 0)), 0) as total_missing,
    COALESCE(SUM(COALESCE(total_onboard, 0)), 0) as total_onboard_sum,
    
    -- Average onboard count
    COALESCE(AVG(COALESCE(total_onboard, 0)), 0) as avg_onboard_count
    
FROM public.sos_alerts;

-- Add comment for documentation
COMMENT ON VIEW public.emergency_statistics_summary IS 'Summary statistics for emergency overview dashboard';

-- =============================================
-- 4. Create Function to Get Emergency Overview by Status Type
-- =============================================

CREATE OR REPLACE FUNCTION public.get_emergency_overview_by_status(
    p_status_type text DEFAULT NULL
)
RETURNS TABLE (
    id text,
    latitude double precision,
    longitude double precision,
    message text,
    status text,
    created_at timestamp with time zone,
    resolved_at timestamp with time zone,
    fisherman_name text,
    casualties integer,
    injured integer,
    missing integer,
    total_onboard integer,
    status_type text,
    status_color text,
    status_description text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        eo.id,
        eo.latitude,
        eo.longitude,
        eo.message,
        eo.status,
        eo.created_at,
        eo.resolved_at,
        eo.fisherman_name,
        eo.casualties,
        eo.injured,
        eo.missing,
        eo.total_onboard,
        eo.status_type,
        eo.status_color,
        eo.status_description
    FROM public.emergency_overview eo
    WHERE (p_status_type IS NULL OR eo.status_type = p_status_type)
    ORDER BY eo.created_at DESC;
END;
$$;

-- Add comment for documentation
COMMENT ON FUNCTION public.get_emergency_overview_by_status(text) IS 'Get emergency overview filtered by status type (SOS Alert, Injured, Rescued, Casualties, Missing)';

-- =============================================
-- 5. Grant Permissions
-- =============================================

-- Grant select on views to authenticated users
GRANT SELECT ON public.emergency_overview TO authenticated;
GRANT SELECT ON public.emergency_statistics_summary TO authenticated;

-- Grant execute on function to authenticated users
GRANT EXECUTE ON FUNCTION public.get_emergency_overview_by_status(text) TO authenticated;

-- =============================================
-- 6. Example Usage Queries
-- =============================================

-- Get all emergency overview records
-- SELECT * FROM public.emergency_overview;

-- Get only active SOS alerts (Red)
-- SELECT * FROM public.emergency_overview WHERE status_type = 'SOS Alert';

-- Get injured cases (Orange)
-- SELECT * FROM public.emergency_overview WHERE status_type = 'Injured';

-- Get rescued cases (Green)
-- SELECT * FROM public.emergency_overview WHERE status_type = 'Rescued';

-- Get casualties (Gray)
-- SELECT * FROM public.emergency_overview WHERE status_type = 'Casualties';

-- Get missing cases (Yellow)
-- SELECT * FROM public.emergency_overview WHERE status_type = 'Missing';

-- Get emergency statistics summary
-- SELECT * FROM public.emergency_statistics_summary;

-- Get emergency overview by status type using function
-- SELECT * FROM public.get_emergency_overview_by_status('SOS Alert');
-- SELECT * FROM public.get_emergency_overview_by_status('Injured');
-- SELECT * FROM public.get_emergency_overview_by_status('Rescued');
-- SELECT * FROM public.get_emergency_overview_by_status('Casualties');
-- SELECT * FROM public.get_emergency_overview_by_status('Missing');
-- SELECT * FROM public.get_emergency_overview_by_status(NULL); -- Get all

-- Update SOS alert with missing and total_onboard
-- UPDATE public.sos_alerts 
-- SET missing = 2, total_onboard = 5
-- WHERE id = 'sos_alert_id_here';

-- Update SOS alert with casualties, injured, and total_onboard
-- UPDATE public.sos_alerts 
-- SET casualties = 1, injured = 2, total_onboard = 5
-- WHERE id = 'sos_alert_id_here';

-- =============================================
-- END OF SCRIPT
-- =============================================












