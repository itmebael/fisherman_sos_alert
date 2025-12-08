-- Check if RLS is enabled on sos_alerts table
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'sos_alerts';

-- If RLS is enabled, we need to create policies or disable it
-- Option 1: Disable RLS (if you want to allow all operations)
-- ALTER TABLE public.sos_alerts DISABLE ROW LEVEL SECURITY;

-- Option 2: Create policies to allow operations (recommended for production)
-- Enable RLS if not already enabled
ALTER TABLE public.sos_alerts ENABLE ROW LEVEL SECURITY;

-- Policy to allow authenticated users to insert SOS alerts
CREATE POLICY "Allow authenticated users to insert SOS alerts" ON public.sos_alerts
    FOR INSERT 
    TO authenticated 
    WITH CHECK (true);

-- Policy to allow authenticated users to select SOS alerts
CREATE POLICY "Allow authenticated users to select SOS alerts" ON public.sos_alerts
    FOR SELECT 
    TO authenticated 
    USING (true);

-- Policy to allow authenticated users to update SOS alerts
CREATE POLICY "Allow authenticated users to update SOS alerts" ON public.sos_alerts
    FOR UPDATE 
    TO authenticated 
    USING (true)
    WITH CHECK (true);

-- Policy to allow service role to do everything (for admin operations)
CREATE POLICY "Allow service role full access" ON public.sos_alerts
    FOR ALL 
    TO service_role 
    USING (true)
    WITH CHECK (true);

-- Check the policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'sos_alerts';


