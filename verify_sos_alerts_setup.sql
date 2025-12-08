-- Verify sos_alerts table setup and RLS policies

-- 1. Check if table exists and its structure
SELECT 
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
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'sos_alerts';

-- 3. Check existing policies
SELECT 
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
    indexname, 
    indexdef
FROM pg_indexes 
WHERE tablename = 'sos_alerts';

-- 5. Test insert permission (this will show if RLS is blocking)
-- Note: This is just a test query, it won't actually insert
SELECT 'RLS Test' as test_type, 
       CASE 
           WHEN EXISTS (
               SELECT 1 FROM pg_policies 
               WHERE tablename = 'sos_alerts' 
               AND cmd = 'INSERT'
           ) THEN 'INSERT policy exists'
           ELSE 'No INSERT policy found'
       END as policy_status;
