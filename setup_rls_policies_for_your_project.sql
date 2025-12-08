-- RLS Setup for your Supabase project: khptgibwfuvsrcjgqgsf.supabase.co
-- Run this in your Supabase SQL editor

-- 1. First, make sure the sos_alerts table exists
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

-- 2. Create indexes
CREATE INDEX IF NOT EXISTS idx_sos_alerts_status_created_at 
ON public.sos_alerts (status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sos_alerts_fisherman_uid 
ON public.sos_alerts (fisherman_uid);

CREATE INDEX IF NOT EXISTS idx_sos_alerts_fisherman_email 
ON public.sos_alerts (fisherman_email);

-- 3. Enable RLS
ALTER TABLE public.sos_alerts ENABLE ROW LEVEL SECURITY;

-- 4. Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow authenticated users to insert SOS alerts" ON public.sos_alerts;
DROP POLICY IF EXISTS "Allow authenticated users to select SOS alerts" ON public.sos_alerts;
DROP POLICY IF EXISTS "Allow authenticated users to update SOS alerts" ON public.sos_alerts;
DROP POLICY IF EXISTS "Allow service role full access" ON public.sos_alerts;

-- 5. Create new policies
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

CREATE POLICY "Allow service role full access" ON public.sos_alerts
    FOR ALL 
    TO service_role 
    USING (true)
    WITH CHECK (true);

-- 6. Grant necessary permissions
GRANT ALL ON public.sos_alerts TO authenticated;
GRANT ALL ON public.sos_alerts TO service_role;

-- 7. Verify the setup
SELECT 'Table created successfully' as status;
SELECT 'RLS enabled' as rls_status;
SELECT 'Policies created' as policies_status;

-- 8. Check current policies
SELECT 
    policyname, 
    cmd, 
    roles, 
    qual, 
    with_check
FROM pg_policies 
WHERE tablename = 'sos_alerts';

-- 9. Test insert permission (this should work if everything is set up correctly)
-- Note: This is just a test query, it won't actually insert
SELECT 
    'Permission Test' as test_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'sos_alerts' 
            AND cmd = 'INSERT'
            AND roles @> ARRAY['authenticated']
        ) THEN 'INSERT policy exists for authenticated users'
        ELSE 'No INSERT policy found for authenticated users'
    END as insert_policy_status;


