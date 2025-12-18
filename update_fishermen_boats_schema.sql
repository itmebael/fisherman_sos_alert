-- SQL script to update fishermen and boats tables with all required fields
-- This script ensures compatibility with the updated application code
-- Run this script in your Supabase SQL editor

-- ============================================
-- UPDATE FISHERMEN TABLE
-- ============================================

-- Ensure all required columns exist in fishermen table
DO $$ 
BEGIN
  -- Add middle_name column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fishermen' 
    AND column_name = 'middle_name'
  ) THEN
    ALTER TABLE public.fishermen ADD COLUMN middle_name text NULL;
  END IF;

  -- Add address column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fishermen' 
    AND column_name = 'address'
  ) THEN
    ALTER TABLE public.fishermen ADD COLUMN address text NULL;
  END IF;

  -- Add fishing_area column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fishermen' 
    AND column_name = 'fishing_area'
  ) THEN
    ALTER TABLE public.fishermen ADD COLUMN fishing_area text NULL;
  END IF;

  -- Add emergency_contact_person column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fishermen' 
    AND column_name = 'emergency_contact_person'
  ) THEN
    ALTER TABLE public.fishermen ADD COLUMN emergency_contact_person text NULL;
  END IF;

  -- Add name column (full name computed from first_name, middle_name, last_name)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fishermen' 
    AND column_name = 'name'
  ) THEN
    ALTER TABLE public.fishermen ADD COLUMN name text NULL;
  END IF;

  -- Add display_id column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fishermen' 
    AND column_name = 'display_id'
  ) THEN
    ALTER TABLE public.fishermen ADD COLUMN display_id text NULL;
  END IF;

  -- Add created_at column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fishermen' 
    AND column_name = 'created_at'
  ) THEN
    ALTER TABLE public.fishermen ADD COLUMN created_at timestamp with time zone NULL DEFAULT now();
  END IF;

  -- Add last_active column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fishermen' 
    AND column_name = 'last_active'
  ) THEN
    ALTER TABLE public.fishermen ADD COLUMN last_active timestamp with time zone NULL;
  END IF;

  -- Add profile_image_url column
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
-- CREATE/UPDATE BOATS TABLE
-- ============================================

-- Create boats table if it doesn't exist
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
  CONSTRAINT boats_pkey PRIMARY KEY (id)
);

-- Add foreign key constraint if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_schema = 'public' 
    AND table_name = 'boats' 
    AND constraint_name = 'boats_owner_id_fkey'
  ) THEN
    ALTER TABLE public.boats 
    ADD CONSTRAINT boats_owner_id_fkey 
    FOREIGN KEY (owner_id) 
    REFERENCES public.fishermen(id) 
    ON DELETE CASCADE;
  END IF;
END $$;

-- Ensure all boat columns exist
DO $$ 
BEGIN
  -- Add name column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'boats' 
    AND column_name = 'name'
  ) THEN
    ALTER TABLE public.boats ADD COLUMN name text NULL;
  END IF;

  -- Add type column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'boats' 
    AND column_name = 'type'
  ) THEN
    ALTER TABLE public.boats ADD COLUMN type text NULL;
  END IF;

  -- Add registration_number column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'boats' 
    AND column_name = 'registration_number'
  ) THEN
    ALTER TABLE public.boats ADD COLUMN registration_number text NULL;
  END IF;

  -- Add capacity column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'boats' 
    AND column_name = 'capacity'
  ) THEN
    ALTER TABLE public.boats ADD COLUMN capacity integer NULL DEFAULT 0;
  END IF;

  -- Add registration_date column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'boats' 
    AND column_name = 'registration_date'
  ) THEN
    ALTER TABLE public.boats ADD COLUMN registration_date timestamp with time zone NULL DEFAULT now();
  END IF;

  -- Add is_active column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'boats' 
    AND column_name = 'is_active'
  ) THEN
    ALTER TABLE public.boats ADD COLUMN is_active boolean NOT NULL DEFAULT true;
  END IF;

  -- Add created_at column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'boats' 
    AND column_name = 'created_at'
  ) THEN
    ALTER TABLE public.boats ADD COLUMN created_at timestamp with time zone NULL DEFAULT now();
  END IF;

  -- Add last_used column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'boats' 
    AND column_name = 'last_used'
  ) THEN
    ALTER TABLE public.boats ADD COLUMN last_used timestamp with time zone NULL;
  END IF;

  -- Add profile_image_url column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'boats' 
    AND column_name = 'profile_image_url'
  ) THEN
    ALTER TABLE public.boats ADD COLUMN profile_image_url text NULL;
  END IF;
END $$;

-- ============================================
-- CREATE INDEXES (only if columns exist)
-- ============================================

-- Boats table indexes - create conditionally
DO $$
BEGIN
  -- Index on owner_id
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_boats_owner_id') THEN
    CREATE INDEX idx_boats_owner_id ON public.boats USING btree (owner_id);
  END IF;

  -- Index on is_active
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_boats_is_active') THEN
    CREATE INDEX idx_boats_is_active ON public.boats USING btree (is_active);
  END IF;

  -- Index on registration_number (only if column exists)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'boats' 
    AND column_name = 'registration_number'
  ) THEN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_boats_registration_number') THEN
      CREATE INDEX idx_boats_registration_number ON public.boats USING btree (registration_number) 
      WHERE registration_number IS NOT NULL;
    END IF;
  END IF;

  -- Index on created_at
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'boats' 
    AND column_name = 'created_at'
  ) THEN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_boats_created_at') THEN
      CREATE INDEX idx_boats_created_at ON public.boats USING btree (created_at DESC);
    END IF;
  END IF;

  -- Composite index for active boats by owner
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_boats_owner_active') THEN
    CREATE INDEX idx_boats_owner_active ON public.boats USING btree (owner_id, is_active) 
    WHERE is_active = true;
  END IF;
END $$;

-- Fishermen table indexes - create conditionally
DO $$
BEGIN
  -- Index on is_active
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_fishermen_active') THEN
    CREATE INDEX idx_fishermen_active ON public.fishermen USING btree (is_active);
  END IF;

  -- Index on profile_image_url (only if column exists)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fishermen' 
    AND column_name = 'profile_image_url'
  ) THEN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_fishermen_profile_image') THEN
      CREATE INDEX idx_fishermen_profile_image ON public.fishermen USING btree (profile_image_url) 
      WHERE profile_image_url IS NOT NULL;
    END IF;
  END IF;

  -- Index on email (only if column exists)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fishermen' 
    AND column_name = 'email'
  ) THEN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_fishermen_email') THEN
      CREATE INDEX idx_fishermen_email ON public.fishermen USING btree (email) 
      WHERE email IS NOT NULL;
    END IF;
  END IF;
END $$;

-- ============================================
-- END OF SCRIPT
-- ============================================

