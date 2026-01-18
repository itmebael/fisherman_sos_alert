-- =============================================
-- CREATE VIEW FOR LATEST LIVE LOCATIONS
-- =============================================
-- This view returns only the most recently updated location per fisherman
-- Run this script in your Supabase SQL editor

-- Drop view if it exists
DROP VIEW IF EXISTS public.latest_live_locations;

-- Create view that returns only the most recent location per fisherman
-- Only shows locations updated within the last 1 minute (online users)
-- Using window function for better compatibility with Supabase PostgREST
CREATE VIEW public.latest_live_locations AS
SELECT 
    id,
    fisherman_uid,
    fisherman_email,
    fisherman_display_id,
    fisherman_name,
    latitude,
    longitude,
    accuracy,
    speed,
    heading,
    altitude,
    updated_at,
    created_at,
    is_active
FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY COALESCE(fisherman_uid::text, fisherman_email)
            ORDER BY updated_at DESC
        ) as rn
    FROM public.live_locations
    WHERE is_active = true
      AND updated_at >= NOW() - INTERVAL '1 minute'  -- Only show locations updated in last 1 minute
) ranked
WHERE rn = 1;

-- Grant SELECT permission on the view
GRANT SELECT ON public.latest_live_locations TO authenticated, anon, service_role;

-- Add comment for documentation
COMMENT ON VIEW public.latest_live_locations IS 'Returns only the most recently updated live location per fisherman, filtered to locations updated within the last 1 minute (online users only)';

-- Create index to support the view query performance
-- (The existing indexes should already support this, but we can add a composite index)
CREATE INDEX IF NOT EXISTS idx_live_locations_fisherman_updated 
ON public.live_locations (
    COALESCE(fisherman_uid::text, fisherman_email),
    updated_at DESC
)
WHERE is_active = true;

-- =============================================
-- ALTERNATIVE: Create a function instead of view
-- =============================================
-- This function can be used if the view doesn't work well with Supabase
CREATE OR REPLACE FUNCTION public.get_latest_live_locations()
RETURNS TABLE (
    id uuid,
    fisherman_uid uuid,
    fisherman_email text,
    fisherman_display_id text,
    fisherman_name text,
    latitude double precision,
    longitude double precision,
    accuracy double precision,
    speed double precision,
    heading double precision,
    altitude double precision,
    updated_at timestamp with time zone,
    created_at timestamp with time zone,
    is_active boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT ON (
        COALESCE(ll.fisherman_uid::text, ll.fisherman_email)
    )
        ll.id,
        ll.fisherman_uid,
        ll.fisherman_email,
        ll.fisherman_display_id,
        ll.fisherman_name,
        ll.latitude,
        ll.longitude,
        ll.accuracy,
        ll.speed,
        ll.heading,
        ll.altitude,
        ll.updated_at,
        ll.created_at,
        ll.is_active
    FROM public.live_locations ll
    WHERE ll.is_active = true
      AND ll.updated_at >= NOW() - INTERVAL '1 minute'  -- Only show locations updated in last 1 minute
    ORDER BY 
        COALESCE(ll.fisherman_uid::text, ll.fisherman_email),
        ll.updated_at DESC;
END;
$$;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.get_latest_live_locations() TO authenticated, anon, service_role;

-- Add comment for documentation
COMMENT ON FUNCTION public.get_latest_live_locations() IS 'Returns only the most recently updated live location per fisherman, filtered to locations updated within the last 1 minute (online users only)';

-- =============================================
-- END OF SCRIPT
-- =============================================

