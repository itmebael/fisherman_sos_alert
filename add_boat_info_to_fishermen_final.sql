-- SQL script to add boat information to fishermen table and ensure profile_image_url works
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

  -- Ensure profile_image_url exists
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
  boat_id = b.id::text,
  boat_name = b.name,
  boat_type = b.type,
  boat_registration_number = b.registration_number,
  boat_capacity = b.capacity
FROM public.boats b
WHERE f.id = b.owner_id
  AND b.is_active = true
  AND (f.boat_id IS NULL OR f.boat_id != b.id::text);

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
    boat_id = NEW.id::text,
    boat_name = NEW.name,
    boat_type = NEW.type,
    boat_registration_number = NEW.registration_number,
    boat_capacity = NEW.capacity,
    last_active = COALESCE(last_active, NOW())
  WHERE id = NEW.owner_id;
  
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
-- ENSURE TRIGGER FUNCTION EXISTS FOR PROFILE IMAGE
-- ============================================

-- Create or replace the trigger_update_last_active function if it doesn't exist
CREATE OR REPLACE FUNCTION trigger_update_last_active()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_active = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for profile image update if it doesn't exist
DROP TRIGGER IF EXISTS trigger_fishermen_profile_image_update ON public.fishermen;
CREATE TRIGGER trigger_fishermen_profile_image_update
  BEFORE UPDATE ON public.fishermen
  FOR EACH ROW
  WHEN (OLD.profile_image_url IS DISTINCT FROM NEW.profile_image_url)
  EXECUTE FUNCTION trigger_update_last_active();

-- ============================================
-- ADD COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON COLUMN public.fishermen.boat_id IS 'Reference to boats table ID (denormalized)';
COMMENT ON COLUMN public.fishermen.boat_name IS 'Boat name or number (denormalized from boats table)';
COMMENT ON COLUMN public.fishermen.boat_type IS 'Type of boat (denormalized from boats table)';
COMMENT ON COLUMN public.fishermen.boat_registration_number IS 'Boat registration number (denormalized from boats table)';
COMMENT ON COLUMN public.fishermen.boat_capacity IS 'Boat capacity (denormalized from boats table)';
COMMENT ON COLUMN public.fishermen.profile_image_url IS 'URL or path to the fisherman profile image';

-- ============================================
-- END OF SCRIPT
-- ============================================

