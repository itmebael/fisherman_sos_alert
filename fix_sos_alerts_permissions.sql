-- Fix permissions for SOS alerts to ensure Fishermen can see them
-- Run this in your Supabase SQL Editor

-- 1. Enable RLS (if not already enabled)
ALTER TABLE public.sos_alerts ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing restrictive policies to start fresh
DROP POLICY IF EXISTS "Allow authenticated users to select SOS alerts" ON public.sos_alerts;
DROP POLICY IF EXISTS "Allow anonymous users to select SOS alerts" ON public.sos_alerts;
DROP POLICY IF EXISTS "Fishermen can see all active alerts" ON public.sos_alerts;

-- 3. Create a broad policy allowing authenticated users (Fishermen, Admin, etc.) to SEE all alerts
-- This is crucial for Fishermen to see SOS alerts from others
CREATE POLICY "Allow authenticated users to select SOS alerts" ON public.sos_alerts
    FOR SELECT 
    TO authenticated 
    USING (true);

-- 4. Create a policy for anonymous users (if needed for login-free SOS viewing)
CREATE POLICY "Allow anonymous users to select SOS alerts" ON public.sos_alerts
    FOR SELECT 
    TO anon 
    USING (true);

-- 5. Ensure Service Role (Admin Dashboard) has full access
DROP POLICY IF EXISTS "Allow service role full access" ON public.sos_alerts;
CREATE POLICY "Allow service role full access" ON public.sos_alerts
    FOR ALL 
    TO service_role 
    USING (true)
    WITH CHECK (true);

-- 6. Verify policies
SELECT * FROM pg_policies WHERE tablename = 'sos_alerts';
