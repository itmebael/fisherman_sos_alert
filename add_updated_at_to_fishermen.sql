-- =============================================
-- ADD updated_at COLUMN TO FISHERMEN TABLE
-- =============================================
-- This script adds an updated_at column to track when fisherman profiles are updated
-- Run this script in your Supabase SQL editor

-- Add updated_at column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fishermen' 
    AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE public.fishermen 
    ADD COLUMN updated_at timestamp with time zone NULL;
    
    -- Set initial value for existing records
    UPDATE public.fishermen 
    SET updated_at = COALESCE(last_active, created_at, NOW())
    WHERE updated_at IS NULL;
    
    -- Add comment for documentation
    COMMENT ON COLUMN public.fishermen.updated_at IS 'Timestamp when the fisherman profile was last updated';
  END IF;
END $$;

-- =============================================
-- CREATE TRIGGER TO AUTO-UPDATE updated_at
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION trigger_update_fishermen_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_fishermen_updated_at ON public.fishermen;

-- Create trigger to automatically update updated_at on any UPDATE
CREATE TRIGGER trigger_fishermen_updated_at
  BEFORE UPDATE ON public.fishermen
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_fishermen_updated_at();

-- =============================================
-- CREATE INDEX FOR PERFORMANCE
-- =============================================

-- Index on updated_at for sorting and filtering
CREATE INDEX IF NOT EXISTS idx_fishermen_updated_at 
ON public.fishermen (updated_at DESC) 
WHERE updated_at IS NOT NULL;

-- =============================================
-- VERIFICATION QUERY
-- =============================================

-- Verify the column was added successfully
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_schema = 'public' 
-- AND table_name = 'fishermen' 
-- AND column_name = 'updated_at';

-- =============================================
-- END OF SCRIPT
-- =============================================










