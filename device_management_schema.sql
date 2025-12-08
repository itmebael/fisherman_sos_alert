-- Device Management Database Schema
-- This file contains the SQL schema for the device management feature
-- 
-- IMPORTANT: This schema assumes that fisherman IDs are stored as UUIDs in the fishermen table
-- If your fisherman IDs are stored as text, you may need to adjust the type casting in the JOINs

-- Drop existing functions and views if they exist (to avoid conflicts)
DROP FUNCTION IF EXISTS public.add_device(text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,double precision,double precision,boolean);
DROP FUNCTION IF EXISTS public.update_device(text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,double precision,double precision,boolean);
DROP FUNCTION IF EXISTS public.toggle_device_status(text,boolean);
DROP FUNCTION IF EXISTS public.update_device_last_used(text);
DROP FUNCTION IF EXISTS public.get_device_statistics();
DROP FUNCTION IF EXISTS public.get_devices_for_map();
DROP FUNCTION IF EXISTS public.search_devices(text,text,text,boolean);
DROP FUNCTION IF EXISTS public.refresh_device_analytics();
DROP VIEW IF EXISTS public.device_management_view;
DROP MATERIALIZED VIEW IF EXISTS public.device_analytics;

-- Create devices table with denormalized fisherman information (similar to sos_alerts pattern)
CREATE TABLE public.devices (
  id text NOT NULL,
  device_number text NOT NULL,
  fisherman_uid uuid NULL,
  fisherman_display_id text NULL,
  fisherman_first_name text NULL,
  fisherman_middle_name text NULL,
  fisherman_last_name text NULL,
  fisherman_name text NULL,
  fisherman_email text NULL,
  fisherman_phone text NULL,
  fisherman_user_type text NULL,
  fisherman_address text NULL,
  fisherman_fishing_area text NULL,
  fisherman_emergency_contact_person text NULL,
  fisherman_profile_picture_url text NULL,
  fisherman_profile_image_url text NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  last_used timestamp with time zone NULL,
  device_type text NULL,
  description text NULL,
  location text NULL,
  status text NOT NULL DEFAULT 'active',
  latitude double precision NULL,
  longitude double precision NULL,
  show_on_map boolean NOT NULL DEFAULT false,
  is_sending_signal boolean NOT NULL DEFAULT false,
  last_signal_sent timestamp with time zone NULL,
  signal_message text NULL,
  CONSTRAINT devices_pkey PRIMARY KEY (id),
  CONSTRAINT devices_device_number_unique UNIQUE (device_number)
) TABLESPACE pg_default;

-- Create indexes for performance (similar to sos_alerts pattern)
CREATE INDEX IF NOT EXISTS idx_devices_status_created_at ON public.devices USING btree (status, created_at DESC) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_devices_fisherman_uid ON public.devices USING btree (fisherman_uid) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_devices_fisherman_email ON public.devices USING btree (fisherman_email) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_devices_device_type ON public.devices USING btree (device_type) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_devices_is_active ON public.devices USING btree (is_active) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_devices_show_on_map ON public.devices USING btree (show_on_map) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_devices_latitude_longitude ON public.devices USING btree (latitude, longitude) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_devices_is_sending_signal ON public.devices USING btree (is_sending_signal) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_devices_last_signal_sent ON public.devices USING btree (last_signal_sent DESC) TABLESPACE pg_default;

-- Add comments for documentation
COMMENT ON TABLE public.devices IS 'Device management table for tracking SOS devices, GPS trackers, and other emergency equipment with denormalized fisherman information';
COMMENT ON COLUMN public.devices.id IS 'Unique identifier for the device';
COMMENT ON COLUMN public.devices.device_number IS 'Human-readable device identifier (e.g., SOS-001, GPS-002)';
COMMENT ON COLUMN public.devices.fisherman_uid IS 'UUID of the fisherman who owns this device';
COMMENT ON COLUMN public.devices.fisherman_display_id IS 'Human-readable fisherman ID';
COMMENT ON COLUMN public.devices.fisherman_first_name IS 'Fisherman first name (denormalized)';
COMMENT ON COLUMN public.devices.fisherman_last_name IS 'Fisherman last name (denormalized)';
COMMENT ON COLUMN public.devices.fisherman_email IS 'Fisherman email (denormalized)';
COMMENT ON COLUMN public.devices.fisherman_phone IS 'Fisherman phone (denormalized)';
COMMENT ON COLUMN public.devices.latitude IS 'Device latitude for map display';
COMMENT ON COLUMN public.devices.longitude IS 'Device longitude for map display';
COMMENT ON COLUMN public.devices.show_on_map IS 'Whether to display this device on the map';
COMMENT ON COLUMN public.devices.is_sending_signal IS 'Whether the device is currently sending a help signal';
COMMENT ON COLUMN public.devices.last_signal_sent IS 'Timestamp when the last help signal was sent';
COMMENT ON COLUMN public.devices.signal_message IS 'Message from the device when sending help signal';
COMMENT ON COLUMN public.devices.is_active IS 'Whether the device is currently active and operational';
COMMENT ON COLUMN public.devices.created_at IS 'Timestamp when the device was first registered';
COMMENT ON COLUMN public.devices.last_used IS 'Timestamp when the device was last used';
COMMENT ON COLUMN public.devices.device_type IS 'Type of device (SOS, GPS, Emergency, Other)';
COMMENT ON COLUMN public.devices.description IS 'Optional description of the device';
COMMENT ON COLUMN public.devices.location IS 'Physical location of the device on the boat';
COMMENT ON COLUMN public.devices.status IS 'Current status (active, inactive, maintenance, etc.)';

-- Create a view for device management (now using denormalized data)
CREATE OR REPLACE VIEW public.device_management_view AS
SELECT 
  d.id,
  d.device_number,
  d.fisherman_uid,
  d.fisherman_display_id,
  d.fisherman_first_name,
  d.fisherman_middle_name,
  d.fisherman_last_name,
  d.fisherman_name,
  d.fisherman_email,
  d.fisherman_phone,
  d.fisherman_user_type,
  d.fisherman_address,
  d.fisherman_fishing_area,
  d.fisherman_emergency_contact_person,
  d.fisherman_profile_picture_url,
  d.fisherman_profile_image_url,
  d.is_active,
  d.created_at,
  d.last_used,
  d.device_type,
  d.description,
  d.location,
  d.status,
  d.latitude,
  d.longitude,
  d.show_on_map
FROM public.devices d;

-- Add comment for the view
COMMENT ON VIEW public.device_management_view IS 'Comprehensive view of devices with associated fisherman information for management interface';

-- Create function to add a new device with denormalized fisherman information
CREATE OR REPLACE FUNCTION public.add_device(
  p_device_number text,
  p_fisherman_uid uuid,
  p_fisherman_display_id text DEFAULT NULL,
  p_fisherman_first_name text DEFAULT NULL,
  p_fisherman_middle_name text DEFAULT NULL,
  p_fisherman_last_name text DEFAULT NULL,
  p_fisherman_name text DEFAULT NULL,
  p_fisherman_email text DEFAULT NULL,
  p_fisherman_phone text DEFAULT NULL,
  p_fisherman_user_type text DEFAULT NULL,
  p_fisherman_address text DEFAULT NULL,
  p_fisherman_fishing_area text DEFAULT NULL,
  p_fisherman_emergency_contact_person text DEFAULT NULL,
  p_fisherman_profile_picture_url text DEFAULT NULL,
  p_fisherman_profile_image_url text DEFAULT NULL,
  p_device_type text DEFAULT NULL,
  p_description text DEFAULT NULL,
  p_location text DEFAULT NULL,
  p_status text DEFAULT 'active',
  p_latitude double precision DEFAULT NULL,
  p_longitude double precision DEFAULT NULL,
  p_show_on_map boolean DEFAULT false
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_device_id text;
BEGIN
  -- Generate a new device ID
  v_device_id := gen_random_uuid()::text;
  
  -- Insert the new device with denormalized fisherman information
  INSERT INTO public.devices (
    id,
    device_number,
    fisherman_uid,
    fisherman_display_id,
    fisherman_first_name,
    fisherman_middle_name,
    fisherman_last_name,
    fisherman_name,
    fisherman_email,
    fisherman_phone,
    fisherman_user_type,
    fisherman_address,
    fisherman_fishing_area,
    fisherman_emergency_contact_person,
    fisherman_profile_picture_url,
    fisherman_profile_image_url,
    device_type,
    description,
    location,
    status,
    latitude,
    longitude,
    show_on_map
  ) VALUES (
    v_device_id,
    p_device_number,
    p_fisherman_uid,
    p_fisherman_display_id,
    p_fisherman_first_name,
    p_fisherman_middle_name,
    p_fisherman_last_name,
    p_fisherman_name,
    p_fisherman_email,
    p_fisherman_phone,
    p_fisherman_user_type,
    p_fisherman_address,
    p_fisherman_fishing_area,
    p_fisherman_emergency_contact_person,
    p_fisherman_profile_picture_url,
    p_fisherman_profile_image_url,
    p_device_type,
    p_description,
    p_location,
    p_status,
    p_latitude,
    p_longitude,
    p_show_on_map
  );
  
  RETURN v_device_id;
END;
$$;

-- Create function to update device information
CREATE OR REPLACE FUNCTION public.update_device(
  p_device_id text,
  p_device_number text DEFAULT NULL,
  p_fisherman_id text DEFAULT NULL,
  p_device_type text DEFAULT NULL,
  p_description text DEFAULT NULL,
  p_location text DEFAULT NULL,
  p_status text DEFAULT NULL,
  p_is_active boolean DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.devices SET
    device_number = COALESCE(p_device_number, device_number),
    fisherman_id = COALESCE(p_fisherman_id, fisherman_id),
    device_type = COALESCE(p_device_type, device_type),
    description = COALESCE(p_description, description),
    location = COALESCE(p_location, location),
    status = COALESCE(p_status, status),
    is_active = COALESCE(p_is_active, is_active)
  WHERE id = p_device_id;
  
  RETURN FOUND;
END;
$$;

-- Create function to toggle device status
CREATE OR REPLACE FUNCTION public.toggle_device_status(
  p_device_id text,
  p_is_active boolean
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.devices 
  SET is_active = p_is_active
  WHERE id = p_device_id;
  
  RETURN FOUND;
END;
$$;

-- Create function to update device last used timestamp
CREATE OR REPLACE FUNCTION public.update_device_last_used(
  p_device_id text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.devices 
  SET last_used = now()
  WHERE id = p_device_id;
  
  RETURN FOUND;
END;
$$;

-- Create function to get device statistics
CREATE OR REPLACE FUNCTION public.get_device_statistics()
RETURNS TABLE(
  total_devices bigint,
  active_devices bigint,
  inactive_devices bigint,
  maintenance_devices bigint,
  sos_devices bigint,
  gps_devices bigint,
  emergency_devices bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_devices,
    COUNT(*) FILTER (WHERE is_active = true) as active_devices,
    COUNT(*) FILTER (WHERE is_active = false) as inactive_devices,
    COUNT(*) FILTER (WHERE status = 'maintenance') as maintenance_devices,
    COUNT(*) FILTER (WHERE device_type = 'SOS') as sos_devices,
    COUNT(*) FILTER (WHERE device_type = 'GPS') as gps_devices,
    COUNT(*) FILTER (WHERE device_type = 'Emergency') as emergency_devices
  FROM public.devices;
END;
$$;

-- Create function to get devices for map display
CREATE OR REPLACE FUNCTION public.get_devices_for_map()
RETURNS TABLE(
  id text,
  device_number text,
  device_type text,
  fisherman_first_name text,
  fisherman_last_name text,
  fisherman_phone text,
  latitude double precision,
  longitude double precision,
  is_active boolean,
  status text,
  created_at timestamp with time zone,
  last_used timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    d.id,
    d.device_number,
    d.device_type,
    d.fisherman_first_name,
    d.fisherman_last_name,
    d.fisherman_phone,
    d.latitude,
    d.longitude,
    d.is_active,
    d.status,
    d.created_at,
    d.last_used
  FROM public.devices d
  WHERE d.show_on_map = true 
    AND d.latitude IS NOT NULL 
    AND d.longitude IS NOT NULL
  ORDER BY d.created_at DESC;
END;
$$;

-- Create function to search devices (using denormalized data)
CREATE OR REPLACE FUNCTION public.search_devices(
  p_search_query text DEFAULT NULL,
  p_device_type text DEFAULT NULL,
  p_status text DEFAULT NULL,
  p_is_active boolean DEFAULT NULL
)
RETURNS TABLE(
  id text,
  device_number text,
  fisherman_uid uuid,
  fisherman_display_id text,
  fisherman_first_name text,
  fisherman_last_name text,
  fisherman_email text,
  fisherman_phone text,
  is_active boolean,
  created_at timestamp with time zone,
  last_used timestamp with time zone,
  device_type text,
  description text,
  location text,
  status text,
  latitude double precision,
  longitude double precision,
  show_on_map boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    d.id,
    d.device_number,
    d.fisherman_uid,
    d.fisherman_display_id,
    d.fisherman_first_name,
    d.fisherman_last_name,
    d.fisherman_email,
    d.fisherman_phone,
    d.is_active,
    d.created_at,
    d.last_used,
    d.device_type,
    d.description,
    d.location,
    d.status,
    d.latitude,
    d.longitude,
    d.show_on_map
  FROM public.devices d
  WHERE 
    (p_search_query IS NULL OR 
     d.device_number ILIKE '%' || p_search_query || '%' OR
     d.fisherman_display_id ILIKE '%' || p_search_query || '%' OR
     d.fisherman_first_name ILIKE '%' || p_search_query || '%' OR
     d.fisherman_last_name ILIKE '%' || p_search_query || '%' OR
     d.fisherman_email ILIKE '%' || p_search_query || '%')
    AND (p_device_type IS NULL OR d.device_type = p_device_type)
    AND (p_status IS NULL OR d.status = p_status)
    AND (p_is_active IS NULL OR d.is_active = p_is_active)
  ORDER BY d.created_at DESC;
END;
$$;

-- Create trigger to automatically update last_used when device is accessed
CREATE OR REPLACE FUNCTION public.update_device_last_used_trigger()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- This trigger would be used if you have a table that tracks device usage
  -- For now, it's a placeholder for future implementation
  RETURN NEW;
END;
$$;

-- Create RLS (Row Level Security) policies
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;

-- Policy for admins to access all devices
CREATE POLICY "Admins can access all devices" ON public.devices
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.coastguards 
      WHERE id = auth.uid() AND is_active = true
    )
  );

-- Policy for fishermen to access their own devices
CREATE POLICY "Fishermen can access their own devices" ON public.devices
  FOR SELECT USING (
    fisherman_uid = auth.uid()
  );

-- Search devices
-- SELECT * FROM public.search_devices('SOS', 'SOS', 'active', true);

-- Get device statistics
-- SELECT * FROM public.get_device_statistics();

-- Add a new device with full fisherman information
-- SELECT public.add_device(
--   'SOS-004',
--   '00000000-0000-0000-0000-000000000004',
--   'FISH-004',
--   'Carlos',
--   'Garcia',
--   'carlos.garcia@email.com',
--   '+639456789012',
--   'SOS',
--   'New emergency device',
--   'Bridge',
--   'active',
--   14.6000,
--   120.9800,
--   true
-- );

-- Update device information
-- SELECT public.update_device('dev_001', 'SOS-001-UPDATED', NULL, 'SOS', 'Updated description', 'Updated location', 'active', true);

-- Toggle device status
-- SELECT public.toggle_device_status('dev_001', false);

-- Get devices that should be shown on map
-- SELECT device_number, fisherman_first_name, fisherman_last_name, latitude, longitude, device_type 
-- FROM public.devices 
-- WHERE show_on_map = true AND latitude IS NOT NULL AND longitude IS NOT NULL;
