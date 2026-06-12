-- =============================================
-- COASTGUARDS TABLE & ACCOUNT SETUP
-- =============================================
-- This script creates the coastguards table and sets up user accounts properly
-- without hardcoding sensitive data

-- 1. CREATE COASTGUARDS TABLE (if not exists)
-- =============================================
CREATE TABLE IF NOT EXISTS public.coastguards (
  -- Primary Key
  id uuid NOT NULL,
  
  -- Basic Information
  email text NOT NULL,
  first_name text NOT NULL,
  last_name text NOT NULL,
  full_name text NULL,
  phone text NULL,
  
  -- User Type
  user_type text NOT NULL DEFAULT 'coastguard',
  
  -- Status
  is_active boolean NOT NULL DEFAULT true,
  
  -- Timestamps
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  last_active timestamp with time zone NULL,
  
  -- Profile
  profile_image_url text NULL,
  address text NULL,
  agency_name text NULL, -- e.g., "Bureau of Fisheries and Aquatic Resources", "Philippine Coast Guard"
  rank_position text NULL, -- e.g., "Commander", "Officer", "Admin"
  
  -- Primary Key Constraint
  CONSTRAINT coastguards_pkey PRIMARY KEY (id),
  
  -- Unique Constraints
  CONSTRAINT coastguards_email_unique UNIQUE (email),
  
  -- Check Constraints
  CONSTRAINT coastguards_user_type_check CHECK (user_type = 'coastguard')
);

-- 2. CREATE INDEXES FOR PERFORMANCE
-- =============================================
CREATE INDEX IF NOT EXISTS idx_coastguards_email 
ON public.coastguards (email);

CREATE INDEX IF NOT EXISTS idx_coastguards_user_type 
ON public.coastguards (user_type);

CREATE INDEX IF NOT EXISTS idx_coastguards_is_active 
ON public.coastguards (is_active) 
WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_coastguards_created_at 
ON public.coastguards (created_at DESC);

-- 3. ENABLE ROW LEVEL SECURITY
-- =============================================
ALTER TABLE public.coastguards ENABLE ROW LEVEL SECURITY;

-- Policy: Coastguards can view their own data
CREATE POLICY "Coastguards can view own data" ON public.coastguards
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Policy: Allow service role for admin operations
CREATE POLICY "Service role has full access to coastguards" ON public.coastguards
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- 4. CREATE TRIGGER FOR UPDATED_AT TIMESTAMP
-- =============================================
CREATE OR REPLACE FUNCTION public.update_coastguards_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_coastguards_updated_at ON public.coastguards;
CREATE TRIGGER trigger_update_coastguards_updated_at
BEFORE UPDATE ON public.coastguards
FOR EACH ROW
EXECUTE FUNCTION public.update_coastguards_updated_at();

-- =============================================
-- ACCOUNT CREATION TEMPLATE
-- =============================================
-- To create a coast guard account, use the template below
-- Replace the values in brackets [...] with actual data
-- Run this in your Supabase SQL Editor

/*
-- TEMPLATE: Create a new Coast Guard account
-- 1. First, create the auth user in Supabase Authentication:
--    - Go to Supabase Dashboard > Authentication > Users
--    - Click "Create new user"
--    - Email: [COASTGUARD_EMAIL]
--    - Password: [TEMPORARY_PASSWORD] (user should change on first login)
--    - Click "Create user"

-- 2. Copy the User ID (UUID) from the created user

-- 3. Run this SQL to add them to the coastguards table:

INSERT INTO public.coastguards (
  id,
  email,
  first_name,
  last_name,
  full_name,
  phone,
  agency_name,
  rank_position,
  user_type,
  is_active,
  created_at
)
VALUES (
  '[USER_ID_FROM_AUTH]',                    -- The UUID from Supabase Auth
  '[COASTGUARD_EMAIL]',                     -- e.g., commander.juan@coastguard.gov
  '[FIRST_NAME]',                           -- e.g., Juan
  '[LAST_NAME]',                            -- e.g., Dela Cruz
  '[FIRST_NAME] [LAST_NAME]',               -- e.g., Juan Dela Cruz
  '[PHONE]',                                -- e.g., +63917XXXXXXX
  '[AGENCY_NAME]',                          -- e.g., Bureau of Fisheries and Aquatic Resources
  '[RANK_POSITION]',                        -- e.g., Station Commander, Admin Officer
  'coastguard',
  true,
  now()
);

-- Example (REAL DATA - modify as needed):

INSERT INTO public.coastguards (
  id,
  email,
  first_name,
  last_name,
  full_name,
  phone,
  agency_name,
  rank_position,
  user_type,
  is_active,
  created_at
)
VALUES (
  '550e8400-e29b-41d4-a716-446655440001',   -- Replace with actual UUID from auth
  'commander.bfar@gmail.com',
  'Commander',
  'BFAR',
  'Commander BFAR',
  '+63917000000',
  'Bureau of Fisheries and Aquatic Resources',
  'Station Commander',
  'coastguard',
  true,
  now()
);

*/

-- =============================================
-- DEACTIVATE COAST GUARD ACCOUNT (template)
-- =============================================
/*
UPDATE public.coastguards
SET is_active = false, updated_at = now()
WHERE email = '[COASTGUARD_EMAIL]';
*/

-- =============================================
-- DELETE COAST GUARD ACCOUNT (template)
-- =============================================
/*
-- WARNING: This will delete the account record but NOT the auth user.
-- To fully delete, also remove from Supabase > Authentication > Users

DELETE FROM public.coastguards
WHERE email = '[COASTGUARD_EMAIL]';
*/

-- =============================================
-- VIEW ALL COAST GUARD ACCOUNTS
-- =============================================
CREATE OR REPLACE VIEW public.coastguards_view AS
SELECT 
  id,
  email,
  first_name,
  last_name,
  full_name,
  phone,
  agency_name,
  rank_position,
  is_active,
  created_at,
  updated_at,
  last_active
FROM public.coastguards
ORDER BY created_at DESC;

GRANT SELECT ON public.coastguards_view TO authenticated, service_role;

-- =============================================
-- FUNCTION: Get Coast Guard by Email
-- =============================================
CREATE OR REPLACE FUNCTION public.get_coastguard_by_email(p_email text)
RETURNS TABLE (
  id uuid,
  email text,
  first_name text,
  last_name text,
  full_name text,
  agency_name text,
  rank_position text,
  is_active boolean
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    coastguards.id,
    coastguards.email,
    coastguards.first_name,
    coastguards.last_name,
    coastguards.full_name,
    coastguards.agency_name,
    coastguards.rank_position,
    coastguards.is_active
  FROM public.coastguards
  WHERE coastguards.email = p_email AND coastguards.is_active = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_coastguard_by_email(text) TO authenticated, service_role;

-- =============================================
-- SUMMARY OF SETUP
-- =============================================
-- 
-- ✅ Coastguards table created with proper schema
-- ✅ RLS policies in place (coastguards can see own, service_role has full access)
-- ✅ Indexes created for performance
-- ✅ Helper function to query coastguards by email
-- 
-- NEXT STEPS:
-- 1. Create users in Supabase Auth (Dashboard > Authentication > Users)
-- 2. Copy their User IDs (UUIDs)
-- 3. Insert them into coastguards table using the template above
-- 4. Do NOT hardcode passwords in SQL - use Supabase Auth for password management
-- 5. Users can reset passwords via the app or Supabase dashboard
--
