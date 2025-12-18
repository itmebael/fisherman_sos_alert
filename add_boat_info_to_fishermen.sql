-- SQL script to add boat information to fishermen table
-- This denormalizes boat data into the fishermen table for easier access
-- Run this script in your Supabase SQL editor

-- ============================================
-- UPDATE FISHERMEN TABLE - ADD BOAT INFORMATION
-- ============================================

-- Add boat information columns to fishermen table
DO $$ 
BEGIN
  -- Add boat_id column (reference to boats table)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fishermen' 
    AND column_name = 'boat_id'
  ) THEN
    ALTER TABLE public.fishermen ADD COLUMN boat_id text NULL;
  END IF;

  -- Add boat_name column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fishermen' 
    AND column_name = 'boat_name'
  ) THEN
    ALTER TABLE public.fishermen ADD COLUMN boat_name text NULL;
  END IF;

  -- Add boat_type column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fishermen' 
    AND column_name = 'boat_type'
  ) THEN
    ALTER TABLE public.fishermen ADD COLUMN boat_type text NULL;
  END IF;

  -- Add boat_registration_number column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fishermen' 
    AND column_name = 'boat_registration_number'
  ) THEN
    ALTER TABLE public.fishermen ADD COLUMN boat_registration_number text NULL;
  END IF;

  -- Add boat_capacity column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fishermen' 
    AND column_name = 'boat_capacity'
  ) THEN
    ALTER TABLE public.fishermen ADD COLUMN boat_capacity integer NULL;
  END IF;
END $$;

-- ============================================
-- CREATE INDEXES FOR BOAT INFORMATION
-- ============================================

-- Index on boat_id for faster lookups
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_fishermen_boat_id') THEN
    CREATE INDEX idx_fishermen_boat_id ON public.fishermen USING btree (boat_id) 
    WHERE boat_id IS NOT NULL;
  END IF;
END $$;

-- Index on boat_registration_number for searching
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_fishermen_boat_registration_number') THEN
    CREATE INDEX idx_fishermen_boat_registration_number ON public.fishermen USING btree (boat_registration_number) 
    WHERE boat_registration_number IS NOT NULL;
  END IF;
END $$;

-- ============================================
-- UPDATE EXISTING FISHERMEN WITH BOAT DATA
-- ============================================

-- Sync boat information from boats table to fishermen table
-- This updates existing records with boat data if available
UPDATE public.fishermen f
SET 
  boat_id = b.id,
  boat_name = b.name,
  boat_type = b.type,
  boat_registration_number = b.registration_number,
  boat_capacity = b.capacity
FROM public.boats b
WHERE f.id = b.owner_id
  AND b.is_active = true
  AND f.boat_id IS NULL;

-- ============================================
-- CREATE FUNCTION TO SYNC BOAT DATA
-- ============================================

-- Function to automatically sync boat data when boat is updated
CREATE OR REPLACE FUNCTION sync_fisherman_boat_info()
RETURNS TRIGGER AS $$
BEGIN
  -- Update fisherman record with boat information
  UPDATE public.fishermen
  SET 
    boat_id = NEW.id,
    boat_name = NEW.name,
    boat_type = NEW.type,
    boat_registration_number = NEW.registration_number,
    boat_capacity = NEW.capacity,
    last_active = NOW()
  WHERE id = NEW.owner_id
    AND (is_active = true OR NEW.is_active = true);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to sync boat data when boat is inserted or updated
DROP TRIGGER IF EXISTS trigger_sync_fisherman_boat_info ON public.boats;
CREATE TRIGGER trigger_sync_fisherman_boat_info
  AFTER INSERT OR UPDATE ON public.boats
  FOR EACH ROW
  WHEN (NEW.is_active = true)
  EXECUTE FUNCTION sync_fisherman_boat_info();

-- ============================================
-- ADD COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON COLUMN public.fishermen.boat_id IS 'Reference to boats table ID';
COMMENT ON COLUMN public.fishermen.boat_name IS 'Boat name or number (denormalized from boats table)';
COMMENT ON COLUMN public.fishermen.boat_type IS 'Type of boat (denormalized from boats table)';
COMMENT ON COLUMN public.fishermen.boat_registration_number IS 'Boat registration number (denormalized from boats table)';
COMMENT ON COLUMN public.fishermen.boat_capacity IS 'Boat capacity (denormalized from boats table)';

-- ============================================
-- ENSURE PROFILE IMAGE COLUMNS EXIST
-- ============================================

-- Ensure profile_image_url exists (it should already exist, but just in case)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fishermen' 
    AND column_name = 'profile_image_url'
  ) THEN
    ALTER TABLE public.fishermen ADD COLUMN profile_image_url text NULL;
  END IF;
END $$;

-- ============================================
-- REMOVE TABLESPACE FROM INDEXES (Supabase compatibility)
-- ============================================

-- Note: If you need to recreate indexes without TABLESPACE, you can drop and recreate them
-- The existing indexes should work, but if you encounter issues, you can run:

-- DROP INDEX IF EXISTS public.idx_fishermen_active;
-- CREATE INDEX idx_fishermen_active ON public.fishermen USING btree (is_active);

-- DROP INDEX IF EXISTS public.idx_fishermen_profile_image;
-- CREATE INDEX idx_fishermen_profile_image ON public.fishermen USING btree (profile_image_url) 
-- WHERE profile_image_url IS NOT NULL;

-- DROP INDEX IF EXISTS public.idx_fishermen_email;
-- CREATE INDEX idx_fishermen_email ON public.fishermen USING btree (email) 
-- WHERE email IS NOT NULL;

-- ============================================
-- END OF SCRIPT
-- ============================================


