-- =============================================
-- Live GPS Location Tracking Table
-- =============================================
-- This table stores real-time GPS locations of fishermen
-- Both admin and fishermen can view live locations on the map

-- Create live_locations table
CREATE TABLE IF NOT EXISTS public.live_locations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  fisherman_uid uuid,
  fisherman_email text,
  fisherman_display_id text,
  fisherman_name text,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  accuracy double precision,
  speed double precision,
  heading double precision,
  altitude double precision,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT live_locations_pkey PRIMARY KEY (id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_live_locations_fisherman_uid 
ON public.live_locations (fisherman_uid) 
WHERE fisherman_uid IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_live_locations_fisherman_email 
ON public.live_locations (fisherman_email) 
WHERE fisherman_email IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_live_locations_updated_at 
ON public.live_locations (updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_live_locations_is_active 
ON public.live_locations (is_active);

CREATE INDEX IF NOT EXISTS idx_live_locations_location 
ON public.live_locations (latitude, longitude);

-- Create unique index on fisherman_uid to ensure one location per fisherman
CREATE UNIQUE INDEX IF NOT EXISTS idx_live_locations_fisherman_unique 
ON public.live_locations (fisherman_uid) 
WHERE fisherman_uid IS NOT NULL AND is_active = true;

-- Add comments for documentation
COMMENT ON TABLE public.live_locations IS 'Real-time GPS locations of fishermen for live map tracking';
COMMENT ON COLUMN public.live_locations.id IS 'Unique identifier for the location record';
COMMENT ON COLUMN public.live_locations.fisherman_uid IS 'UUID of the fisherman';
COMMENT ON COLUMN public.live_locations.fisherman_email IS 'Email of the fisherman';
COMMENT ON COLUMN public.live_locations.fisherman_name IS 'Name of the fisherman';
COMMENT ON COLUMN public.live_locations.latitude IS 'Latitude coordinate';
COMMENT ON COLUMN public.live_locations.longitude IS 'Longitude coordinate';
COMMENT ON COLUMN public.live_locations.accuracy IS 'GPS accuracy in meters';
COMMENT ON COLUMN public.live_locations.speed IS 'Speed in m/s';
COMMENT ON COLUMN public.live_locations.heading IS 'Direction in degrees (0-360)';
COMMENT ON COLUMN public.live_locations.altitude IS 'Altitude in meters';
COMMENT ON COLUMN public.live_locations.updated_at IS 'Last update timestamp';
COMMENT ON COLUMN public.live_locations.is_active IS 'Whether this location is currently active';

-- Enable Row Level Security (RLS)
ALTER TABLE public.live_locations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Allow fishermen to view their own locations
CREATE POLICY "Allow fishermen to view their own locations" ON public.live_locations
    FOR SELECT 
    TO authenticated 
    USING (
        fisherman_uid = auth.uid() 
        OR fisherman_email IN (
            SELECT email FROM auth.users WHERE id = auth.uid()
        )
    );

-- Allow authenticated users (admin/coastguard) to view all locations
CREATE POLICY "Allow admins to view all locations" ON public.live_locations
    FOR SELECT 
    TO authenticated 
    USING (true);

-- Allow fishermen to insert/update their own locations
CREATE POLICY "Allow fishermen to update their own locations" ON public.live_locations
    FOR ALL 
    TO authenticated 
    USING (
        fisherman_uid = auth.uid() 
        OR fisherman_email IN (
            SELECT email FROM auth.users WHERE id = auth.uid()
        )
    )
    WITH CHECK (
        fisherman_uid = auth.uid() 
        OR fisherman_email IN (
            SELECT email FROM auth.users WHERE id = auth.uid()
        )
    );

-- Allow service role full access
CREATE POLICY "Allow service role full access" ON public.live_locations
    FOR ALL 
    TO service_role 
    USING (true)
    WITH CHECK (true);

-- Allow anonymous users to view locations (for public map features if needed)
CREATE POLICY "Allow anonymous users to view locations" ON public.live_locations
    FOR SELECT 
    TO anon 
    USING (true);

-- Create function to upsert live location (insert or update if exists)
CREATE OR REPLACE FUNCTION public.upsert_live_location(
    p_fisherman_uid uuid,
    p_fisherman_email text,
    p_fisherman_display_id text,
    p_fisherman_name text,
    p_latitude double precision,
    p_longitude double precision,
    p_accuracy double precision DEFAULT NULL,
    p_speed double precision DEFAULT NULL,
    p_heading double precision DEFAULT NULL,
    p_altitude double precision DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    location_id uuid;
BEGIN
    -- Try to update existing location for this fisherman
    UPDATE public.live_locations
    SET 
        latitude = p_latitude,
        longitude = p_longitude,
        accuracy = COALESCE(p_accuracy, accuracy),
        speed = COALESCE(p_speed, speed),
        heading = COALESCE(p_heading, heading),
        altitude = COALESCE(p_altitude, altitude),
        updated_at = now(),
        is_active = true
    WHERE fisherman_uid = p_fisherman_uid 
      AND is_active = true
    RETURNING id INTO location_id;
    
    -- If no existing location found, insert new one
    IF location_id IS NULL THEN
        INSERT INTO public.live_locations (
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
            is_active
        ) VALUES (
            p_fisherman_uid,
            p_fisherman_email,
            p_fisherman_display_id,
            p_fisherman_name,
            p_latitude,
            p_longitude,
            p_accuracy,
            p_speed,
            p_heading,
            p_altitude,
            now(),
            true
        ) RETURNING id INTO location_id;
    END IF;
    
    RETURN location_id;
END;
$$;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.upsert_live_location TO authenticated, service_role, anon;

-- Grant necessary permissions on the table
GRANT SELECT, INSERT, UPDATE ON public.live_locations TO authenticated;
GRANT SELECT ON public.live_locations TO anon;

-- =============================================
-- END OF SCRIPT - Live GPS Location Tracking
-- =============================================











