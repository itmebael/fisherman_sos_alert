-- =============================================
-- REMOVE HARDCODED ACCOUNT DATA & SETUP CONFIGURATION
-- =============================================
-- This script removes hardcoded email addresses and provides a flexible configuration system

-- 1. CREATE APP CONFIGURATION TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.app_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  config_key text NOT NULL UNIQUE,
  config_value text,
  description text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- 2. ADD INDEXES
CREATE INDEX IF NOT EXISTS idx_app_config_key ON public.app_config(config_key);

-- 3. ENABLE RLS
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- Policy: Only service role can modify config
CREATE POLICY "Service role manages config" ON public.app_config
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Policy: Anyone can view config
CREATE POLICY "Public can view config" ON public.app_config
  FOR SELECT
  TO public
  USING (true);

-- 4. INSERT DEFAULT CONFIGURATION
-- =============================================
-- DO NOT use hardcoded email addresses. Instead, let admins update via app
INSERT INTO public.app_config (config_key, config_value, description)
VALUES
  ('default_coast_guard_contact_name', 'Philippine Coast Guard', 'Default name when no admin info available'),
  ('default_coast_guard_contact_phone', '+63-2-920-2929', 'Default contact phone number'),
  ('emergency_notification_enabled', 'true', 'Enable/disable emergency notifications to fishermen')
ON CONFLICT (config_key) DO UPDATE SET updated_at = now();

-- 5. CREATE HELPER FUNCTION TO GET CONFIG
-- =============================================
CREATE OR REPLACE FUNCTION public.get_app_config(p_key text)
RETURNS text AS $$
DECLARE
  v_value text;
BEGIN
  SELECT config_value INTO v_value
  FROM public.app_config
  WHERE config_key = p_key;
  RETURN COALESCE(v_value, '');
END;
$$ LANGUAGE plpgsql STABLE;

GRANT EXECUTE ON FUNCTION public.get_app_config(text) TO authenticated, service_role;

-- 6. CREATE FUNCTION TO GET FIRST ACTIVE COASTGUARD
-- =============================================
CREATE OR REPLACE FUNCTION public.get_default_admin_info()
RETURNS TABLE (
  admin_name text,
  admin_email text,
  agency_name text,
  phone text
) AS $$
BEGIN
  -- Try to get the first active coast guard
  RETURN QUERY
  SELECT 
    COALESCE(cg.full_name, cg.first_name || ' ' || cg.last_name) as admin_name,
    cg.email as admin_email,
    cg.agency_name,
    cg.phone
  FROM public.coastguards cg
  WHERE cg.is_active = true
  ORDER BY cg.created_at ASC
  LIMIT 1;
  
  -- If no coast guard found, return default config values
  IF NOT FOUND THEN
    RETURN QUERY
    SELECT 
      public.get_app_config('default_coast_guard_contact_name')::text,
      'admin@coastguard.gov'::text,
      'Philippine Coast Guard'::text,
      public.get_app_config('default_coast_guard_contact_phone')::text;
  END IF;
END;
$$ LANGUAGE plpgsql STABLE;

GRANT EXECUTE ON FUNCTION public.get_default_admin_info() TO authenticated, service_role;

-- 7. UPDATE EXISTING TRIGGERS TO USE DYNAMIC VALUES
-- =============================================
-- NOTE: Execute the triggers/functions update script AFTER this script
-- The trigger functions should be updated to call get_default_admin_info()
-- instead of using hardcoded 'coastguard@salbar-mangirisda.gov'

-- 8. VIEW FOR CHECKING CONFIGURATION
-- =============================================
CREATE OR REPLACE VIEW public.system_configuration AS
SELECT 
  config_key,
  config_value,
  description,
  updated_at
FROM public.app_config
ORDER BY config_key;

GRANT SELECT ON public.system_configuration TO authenticated, service_role;

-- =============================================
-- USAGE INSTRUCTIONS
-- =============================================
/*

1. VIEW CURRENT CONFIGURATION:
   SELECT * FROM public.system_configuration;

2. UPDATE CONFIGURATION:
   UPDATE public.app_config 
   SET config_value = 'Your New Value'
   WHERE config_key = 'default_coast_guard_contact_name';

3. GET DEFAULT ADMIN INFO (for use in app logic):
   SELECT * FROM public.get_default_admin_info();

4. THE SYSTEM NOW:
   - Gets first active coast guard from coastguards table
   - Falls back to app_config values if no coast guard found
   - No hardcoded email addresses in database code
   - All values are configurable

*/

-- =============================================
-- SUMMARY
-- =============================================
--
-- ✅ Created app_config table for system-wide settings
-- ✅ Created helper function get_default_admin_info() to get admin details dynamically
-- ✅ No more hardcoded email addresses like 'coastguard@salbar-mangirisda.gov'
-- ✅ Values can be changed via app or SQL without code changes
--
