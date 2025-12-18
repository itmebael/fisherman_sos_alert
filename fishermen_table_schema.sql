-- =============================================
-- FISHERMEN TABLE SCHEMA
-- Complete SQL table definition for fisherman registration
-- =============================================

-- Create fishermen table with all columns
CREATE TABLE IF NOT EXISTS public.fishermen (
  -- Primary Key
  id uuid NOT NULL,
  
  -- Basic Information
  email text NOT NULL,
  first_name text NOT NULL,
  middle_name text NULL,
  last_name text NOT NULL,
  name text NULL, -- Full name (computed or stored)
  phone text NULL,
  
  -- User Type and Status
  user_type text NOT NULL DEFAULT 'fisherman',
  is_active boolean NOT NULL DEFAULT true,
  
  -- Display and Identification
  display_id text NULL, -- Optional sequential/friendly ID for UI
  
  -- Timestamps
  registration_date timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  last_active timestamp with time zone NULL,
  
  -- Profile Information
  profile_image_url text NULL,
  
  -- Location and Contact Information
  address text NULL,
  fishing_area text NULL,
  emergency_contact_person text NULL,
  
  -- Boat Information (denormalized from boats table)
  boat_id text NULL,
  boat_name text NULL,
  boat_type text NULL,
  boat_registration_number text NULL,
  boat_capacity integer NULL,
  
  -- Primary Key Constraint
  CONSTRAINT fishermen_pkey PRIMARY KEY (id),
  
  -- Unique Constraints
  CONSTRAINT fishermen_email_unique UNIQUE (email),
  
  -- Check Constraints
  CONSTRAINT fishermen_user_type_check CHECK (user_type IN ('fisherman', 'coastguard'))
);

-- =============================================
-- CREATE INDEXES FOR PERFORMANCE
-- =============================================

-- Index on email for fast lookups
CREATE INDEX IF NOT EXISTS idx_fishermen_email 
ON public.fishermen (email);

-- Index on user_type for filtering
CREATE INDEX IF NOT EXISTS idx_fishermen_user_type 
ON public.fishermen (user_type);

-- Index on is_active for filtering active users
CREATE INDEX IF NOT EXISTS idx_fishermen_is_active 
ON public.fishermen (is_active) 
WHERE is_active = true;

-- Index on registration_date for sorting
CREATE INDEX IF NOT EXISTS idx_fishermen_registration_date 
ON public.fishermen (registration_date DESC);

-- Index on last_active for tracking activity
CREATE INDEX IF NOT EXISTS idx_fishermen_last_active 
ON public.fishermen (last_active DESC) 
WHERE last_active IS NOT NULL;

-- Index on boat_id for boat lookups
CREATE INDEX IF NOT EXISTS idx_fishermen_boat_id 
ON public.fishermen (boat_id) 
WHERE boat_id IS NOT NULL;

-- Index on boat_registration_number for searching
CREATE INDEX IF NOT EXISTS idx_fishermen_boat_registration_number 
ON public.fishermen (boat_registration_number) 
WHERE boat_registration_number IS NOT NULL;

-- Index on profile_image_url (optional, for queries filtering by image presence)
CREATE INDEX IF NOT EXISTS idx_fishermen_profile_image 
ON public.fishermen (profile_image_url) 
WHERE profile_image_url IS NOT NULL;

-- Composite index for common queries (active fishermen by registration date)
CREATE INDEX IF NOT EXISTS idx_fishermen_active_registration 
ON public.fishermen (is_active, registration_date DESC) 
WHERE is_active = true;

-- =============================================
-- ADD COMMENTS FOR DOCUMENTATION
-- =============================================

COMMENT ON TABLE public.fishermen IS 'Table storing fisherman account information and registration data';

COMMENT ON COLUMN public.fishermen.id IS 'UUID primary key (matches Supabase auth.users.id)';
COMMENT ON COLUMN public.fishermen.email IS 'Fisherman email address (unique)';
COMMENT ON COLUMN public.fishermen.first_name IS 'Fisherman first name';
COMMENT ON COLUMN public.fishermen.middle_name IS 'Fisherman middle name (optional)';
COMMENT ON COLUMN public.fishermen.last_name IS 'Fisherman last name';
COMMENT ON COLUMN public.fishermen.name IS 'Full name (computed or stored for display)';
COMMENT ON COLUMN public.fishermen.phone IS 'Fisherman phone number';
COMMENT ON COLUMN public.fishermen.user_type IS 'Type of user: fisherman or coastguard';
COMMENT ON COLUMN public.fishermen.is_active IS 'Whether the account is active';
COMMENT ON COLUMN public.fishermen.display_id IS 'Optional sequential/friendly ID for UI display';
COMMENT ON COLUMN public.fishermen.registration_date IS 'Date when the account was registered';
COMMENT ON COLUMN public.fishermen.created_at IS 'Timestamp when the record was created';
COMMENT ON COLUMN public.fishermen.last_active IS 'Timestamp of last activity';
COMMENT ON COLUMN public.fishermen.profile_image_url IS 'URL or path to the fisherman profile image';
COMMENT ON COLUMN public.fishermen.address IS 'Fisherman residential address';
COMMENT ON COLUMN public.fishermen.fishing_area IS 'Preferred fishing area or location';
COMMENT ON COLUMN public.fishermen.emergency_contact_person IS 'Emergency contact person name';
COMMENT ON COLUMN public.fishermen.boat_id IS 'Reference to boats table ID (denormalized)';
COMMENT ON COLUMN public.fishermen.boat_name IS 'Boat name or number (denormalized from boats table)';
COMMENT ON COLUMN public.fishermen.boat_type IS 'Type of boat (denormalized from boats table)';
COMMENT ON COLUMN public.fishermen.boat_registration_number IS 'Boat registration number (denormalized from boats table)';
COMMENT ON COLUMN public.fishermen.boat_capacity IS 'Boat capacity (denormalized from boats table)';

-- =============================================
-- ENABLE ROW LEVEL SECURITY (RLS)
-- =============================================

ALTER TABLE public.fishermen ENABLE ROW LEVEL SECURITY;

-- Policy: Allow fishermen to view their own data
CREATE POLICY "Allow fishermen to view own data" ON public.fishermen
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Policy: Allow fishermen to update their own data
CREATE POLICY "Allow fishermen to update own data" ON public.fishermen
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Policy: Allow service role to insert (for registration)
CREATE POLICY "Allow service role to insert" ON public.fishermen
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Policy: Allow authenticated users to insert their own record (for registration)
CREATE POLICY "Allow users to insert own record" ON public.fishermen
  FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- Policy: Allow service role to select all (for admin operations)
CREATE POLICY "Allow service role to select all" ON public.fishermen
  FOR SELECT
  TO service_role
  USING (true);

-- =============================================
-- CREATE TRIGGER FOR AUTOMATIC TIMESTAMP UPDATES
-- =============================================

-- Function to update last_active timestamp
CREATE OR REPLACE FUNCTION trigger_update_last_active()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_active = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update last_active on profile image changes
DROP TRIGGER IF EXISTS trigger_fishermen_profile_image_update ON public.fishermen;
CREATE TRIGGER trigger_fishermen_profile_image_update
  BEFORE UPDATE ON public.fishermen
  FOR EACH ROW
  WHEN (OLD.profile_image_url IS DISTINCT FROM NEW.profile_image_url)
  EXECUTE FUNCTION trigger_update_last_active();

-- Trigger to update last_active on any update
DROP TRIGGER IF EXISTS trigger_fishermen_update_last_active ON public.fishermen;
CREATE TRIGGER trigger_fishermen_update_last_active
  BEFORE UPDATE ON public.fishermen
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_last_active();

-- =============================================
-- EXAMPLE QUERIES
-- =============================================

-- Get all active fishermen
-- SELECT * FROM public.fishermen WHERE is_active = true ORDER BY registration_date DESC;

-- Get fisherman by email
-- SELECT * FROM public.fishermen WHERE email = 'fisherman@example.com';

-- Get fishermen with boats
-- SELECT * FROM public.fishermen WHERE boat_id IS NOT NULL;

-- Get fishermen by fishing area
-- SELECT * FROM public.fishermen WHERE fishing_area = 'Area Name';

-- Update fisherman profile
-- UPDATE public.fishermen 
-- SET profile_image_url = 'https://example.com/image.jpg',
--     address = 'New Address',
--     last_active = NOW()
-- WHERE id = 'fisherman-uuid-here';

-- =============================================
-- END OF SCRIPT
-- =============================================

