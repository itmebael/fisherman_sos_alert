-- SQL script to create boats table and ensure all required columns exist
-- Run this script in your Supabase SQL editor or database management tool

-- ============================================
-- CREATE BOATS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.boats (
  id text NOT NULL,
  owner_id uuid NOT NULL,
  name text NULL,
  type text NULL,
  registration_number text NULL,
  capacity integer NULL DEFAULT 0,
  registration_date timestamp with time zone NULL DEFAULT now(),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NULL DEFAULT now(),
  last_used timestamp with time zone NULL,
  profile_image_url text NULL,
  CONSTRAINT boats_pkey PRIMARY KEY (id),
  CONSTRAINT boats_owner_id_fkey FOREIGN KEY (owner_id) 
    REFERENCES public.fishermen(id) 
    ON DELETE CASCADE
);

-- ============================================
-- CREATE INDEXES FOR PERFORMANCE
-- ============================================

-- Index on owner_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_boats_owner_id 
ON public.boats USING btree (owner_id);

-- Index on is_active for filtering active boats
CREATE INDEX IF NOT EXISTS idx_boats_is_active 
ON public.boats USING btree (is_active);

-- Index on registration_number for searching
CREATE INDEX IF NOT EXISTS idx_boats_registration_number 
ON public.boats USING btree (registration_number) 
WHERE registration_number IS NOT NULL;

-- Index on created_at for sorting
CREATE INDEX IF NOT EXISTS idx_boats_created_at 
ON public.boats USING btree (created_at DESC);

-- Composite index for active boats by owner
CREATE INDEX IF NOT EXISTS idx_boats_owner_active 
ON public.boats USING btree (owner_id, is_active) 
WHERE is_active = true;

-- ============================================
-- ADD COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON TABLE public.boats IS 'Boat registration and information table';
COMMENT ON COLUMN public.boats.id IS 'Unique identifier for the boat';
COMMENT ON COLUMN public.boats.owner_id IS 'Foreign key reference to fishermen.id';
COMMENT ON COLUMN public.boats.name IS 'Boat name or boat number';
COMMENT ON COLUMN public.boats.type IS 'Type of boat (e.g., motorized, sailboat, etc.)';
COMMENT ON COLUMN public.boats.registration_number IS 'Official boat registration number';
COMMENT ON COLUMN public.boats.capacity IS 'Boat capacity (number of passengers)';
COMMENT ON COLUMN public.boats.registration_date IS 'Date when boat was registered';
COMMENT ON COLUMN public.boats.is_active IS 'Whether the boat is currently active';
COMMENT ON COLUMN public.boats.created_at IS 'Timestamp when boat record was created';
COMMENT ON COLUMN public.boats.last_used IS 'Timestamp when boat was last used';
COMMENT ON COLUMN public.boats.profile_image_url IS 'URL or path to boat image';

-- ============================================
-- ENSURE FISHERMEN TABLE HAS ALL REQUIRED COLUMNS
-- ============================================

-- Add middle_name if it doesn't exist
ALTER TABLE public.fishermen 
ADD COLUMN IF NOT EXISTS middle_name text NULL;

-- Add address if it doesn't exist
ALTER TABLE public.fishermen 
ADD COLUMN IF NOT EXISTS address text NULL;

-- Add fishing_area if it doesn't exist
ALTER TABLE public.fishermen 
ADD COLUMN IF NOT EXISTS fishing_area text NULL;

-- Add emergency_contact_person if it doesn't exist
ALTER TABLE public.fishermen 
ADD COLUMN IF NOT EXISTS emergency_contact_person text NULL;

-- Add name column if it doesn't exist (computed from first_name, middle_name, last_name)
ALTER TABLE public.fishermen 
ADD COLUMN IF NOT EXISTS name text NULL;

-- Add display_id if it doesn't exist
ALTER TABLE public.fishermen 
ADD COLUMN IF NOT EXISTS display_id text NULL;

-- Add created_at if it doesn't exist
ALTER TABLE public.fishermen 
ADD COLUMN IF NOT EXISTS created_at timestamp with time zone NULL DEFAULT now();

-- Add last_active if it doesn't exist
ALTER TABLE public.fishermen 
ADD COLUMN IF NOT EXISTS last_active timestamp with time zone NULL;

-- Add profile_image_url if it doesn't exist
ALTER TABLE public.fishermen 
ADD COLUMN IF NOT EXISTS profile_image_url text NULL;

-- ============================================
-- CREATE INDEXES FOR FISHERMEN TABLE
-- ============================================

-- Index on is_active for filtering active fishermen
CREATE INDEX IF NOT EXISTS idx_fishermen_active 
ON public.fishermen USING btree (is_active);

-- Index on profile_image_url for boats with images
CREATE INDEX IF NOT EXISTS idx_fishermen_profile_image 
ON public.fishermen USING btree (profile_image_url) 
WHERE profile_image_url IS NOT NULL;

-- Index on email for lookups
CREATE INDEX IF NOT EXISTS idx_fishermen_email 
ON public.fishermen USING btree (email) 
WHERE email IS NOT NULL;

-- ============================================
-- END OF SCRIPT
-- ============================================

