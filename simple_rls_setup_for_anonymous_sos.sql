-- Simple RLS Setup for Anonymous SOS Alerts
-- This allows both authenticated and anonymous users to send SOS alerts
-- Run this in your Supabase SQL editor

-- 1. Create the sos_alerts table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.sos_alerts (
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

-- 2. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_sos_alerts_status_created_at 
ON public.sos_alerts (status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sos_alerts_fisherman_uid 
ON public.sos_alerts (fisherman_uid);

CREATE INDEX IF NOT EXISTS idx_sos_alerts_fisherman_email 
ON public.sos_alerts (fisherman_email);

-- 3. Enable Row Level Security
ALTER TABLE public.sos_alerts ENABLE ROW LEVEL SECURITY;

-- 4. Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated users to insert SOS alerts" ON public.sos_alerts;
DROP POLICY IF EXISTS "Allow anonymous users to insert SOS alerts" ON public.sos_alerts;
DROP POLICY IF EXISTS "Allow authenticated users to select SOS alerts" ON public.sos_alerts;
DROP POLICY IF EXISTS "Allow anonymous users to select SOS alerts" ON public.sos_alerts;
DROP POLICY IF EXISTS "Allow authenticated users to update SOS alerts" ON public.sos_alerts;
DROP POLICY IF EXISTS "Allow service role full access" ON public.sos_alerts;

-- 5. Create policies for authenticated users
CREATE POLICY "Allow authenticated users to insert SOS alerts" ON public.sos_alerts
    FOR INSERT 
    TO authenticated 
    WITH CHECK (true);

CREATE POLICY "Allow authenticated users to select SOS alerts" ON public.sos_alerts
    FOR SELECT 
    TO authenticated 
    USING (true);

CREATE POLICY "Allow authenticated users to update SOS alerts" ON public.sos_alerts
    FOR UPDATE 
    TO authenticated 
    USING (true)
    WITH CHECK (true);

-- 6. Create policies for anonymous users (for emergency situations)
CREATE POLICY "Allow anonymous users to insert SOS alerts" ON public.sos_alerts
    FOR INSERT 
    TO anon 
    WITH CHECK (true);

CREATE POLICY "Allow anonymous users to select SOS alerts" ON public.sos_alerts
    FOR SELECT 
    TO anon 
    USING (true);

-- 7. Create policy for service role (admin operations)
CREATE POLICY "Allow service role full access" ON public.sos_alerts
    FOR ALL 
    TO service_role 
    USING (true)
    WITH CHECK (true);

-- 8. Grant necessary permissions
GRANT ALL ON public.sos_alerts TO authenticated;
GRANT ALL ON public.sos_alerts TO anon;
GRANT ALL ON public.sos_alerts TO service_role;

-- 9. Verify the setup
SELECT 'Setup completed successfully!' as status;
SELECT 'Table created' as table_status;
SELECT 'RLS enabled' as rls_status;
SELECT 'Policies created for both authenticated and anonymous users' as policies_status;

-- 10. Show current policies
SELECT 
    policyname, 
    cmd, 
    roles
FROM pg_policies 
WHERE tablename = 'sos_alerts'
ORDER BY policyname;
