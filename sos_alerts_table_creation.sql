-- Create sos_alerts table with comprehensive fisherman information
CREATE TABLE public.sos_alerts (
  id text NOT NULL,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  message text,
  status text NOT NULL DEFAULT 'active',
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  resolved_at timestamp with time zone,
  fisherman_uid uuid,
  fisherman_display_id text,
  fisherman_first_name text,
  fisherman_middle_name text,
  fisherman_last_name text,
  fisherman_name text,
  fisherman_email text,
  fisherman_phone text,
  fisherman_user_type text,
  fisherman_address text,
  fisherman_fishing_area text,
  fisherman_emergency_contact_person text,
  fisherman_profile_picture_url text,
  fisherman_profile_image_url text,
  CONSTRAINT sos_alerts_pkey PRIMARY KEY (id)
);

-- Create index for efficient querying by status and creation time
CREATE INDEX IF NOT EXISTS idx_sos_alerts_status_created_at 
ON public.sos_alerts (status, created_at DESC);

-- Create index for fisherman_uid for efficient lookups
CREATE INDEX IF NOT EXISTS idx_sos_alerts_fisherman_uid 
ON public.sos_alerts (fisherman_uid);

-- Create index for fisherman_email for efficient lookups
CREATE INDEX IF NOT EXISTS idx_sos_alerts_fisherman_email 
ON public.sos_alerts (fisherman_email);

-- Add comments for documentation
COMMENT ON TABLE public.sos_alerts IS 'SOS emergency alerts from fishermen with comprehensive fisherman information';
COMMENT ON COLUMN public.sos_alerts.id IS 'Unique identifier for the SOS alert';
COMMENT ON COLUMN public.sos_alerts.latitude IS 'Latitude coordinate of the emergency location';
COMMENT ON COLUMN public.sos_alerts.longitude IS 'Longitude coordinate of the emergency location';
COMMENT ON COLUMN public.sos_alerts.message IS 'Optional message from the fisherman describing the emergency';
COMMENT ON COLUMN public.sos_alerts.status IS 'Status of the alert: active, on_the_way, resolved, cancelled';
COMMENT ON COLUMN public.sos_alerts.created_at IS 'Timestamp when the alert was created';
COMMENT ON COLUMN public.sos_alerts.resolved_at IS 'Timestamp when the alert was resolved';
COMMENT ON COLUMN public.sos_alerts.fisherman_uid IS 'UUID of the fisherman who sent the alert';
COMMENT ON COLUMN public.sos_alerts.fisherman_display_id IS 'Display ID of the fisherman';
COMMENT ON COLUMN public.sos_alerts.fisherman_first_name IS 'First name of the fisherman';
COMMENT ON COLUMN public.sos_alerts.fisherman_middle_name IS 'Middle name of the fisherman';
COMMENT ON COLUMN public.sos_alerts.fisherman_last_name IS 'Last name of the fisherman';
COMMENT ON COLUMN public.sos_alerts.fisherman_name IS 'Full name of the fisherman';
COMMENT ON COLUMN public.sos_alerts.fisherman_email IS 'Email address of the fisherman';
COMMENT ON COLUMN public.sos_alerts.fisherman_phone IS 'Phone number of the fisherman';
COMMENT ON COLUMN public.sos_alerts.fisherman_user_type IS 'Type of user (fisherman, etc.)';
COMMENT ON COLUMN public.sos_alerts.fisherman_address IS 'Address of the fisherman';
COMMENT ON COLUMN public.sos_alerts.fisherman_fishing_area IS 'Fishing area of the fisherman';
COMMENT ON COLUMN public.sos_alerts.fisherman_emergency_contact_person IS 'Emergency contact person for the fisherman';
COMMENT ON COLUMN public.sos_alerts.fisherman_profile_picture_url IS 'URL of the fisherman profile picture';
COMMENT ON COLUMN public.sos_alerts.fisherman_profile_image_url IS 'URL of the fisherman profile image';
