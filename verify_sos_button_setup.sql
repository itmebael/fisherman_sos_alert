-- Verification script for SOS Button Supabase setup
-- Run this after setting up the sos_alerts table

-- 1. Check if table exists and its structure
SELECT 
    'Table Structure' as check_type,
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'sos_alerts' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check if RLS is enabled
SELECT 
    'RLS Status' as check_type,
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'sos_alerts';

-- 3. Check existing policies
SELECT 
    'RLS Policies' as check_type,
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual, 
    with_check
FROM pg_policies 
WHERE tablename = 'sos_alerts';

-- 4. Check indexes
SELECT 
    'Indexes' as check_type,
    indexname, 
    indexdef
FROM pg_indexes 
WHERE tablename = 'sos_alerts';

-- 5. Test insert permission (this will show if RLS is working)
SELECT 
    'Permission Test' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'sos_alerts' 
            AND cmd = 'INSERT'
            AND roles @> ARRAY['authenticated']
        ) THEN 'INSERT policy exists for authenticated users'
        ELSE 'No INSERT policy found for authenticated users'
    END as insert_policy_status;

-- 6. Check if we can query the table (should work if authenticated)
SELECT 
    'Query Test' as check_type,
    COUNT(*) as total_alerts,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_alerts
FROM public.sos_alerts;


