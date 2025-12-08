-- SQL ALTER statements to add profile image support to fishermen table
-- Run these commands in your Supabase SQL editor or database management tool

-- 1. Add profile_image_url column to fishermen table
ALTER TABLE public.fishermen 
ADD COLUMN IF NOT EXISTS profile_image_url TEXT NULL;

-- 2. Add profile_image_url column to coastguards table (for consistency)
ALTER TABLE public.coastguards 
ADD COLUMN IF NOT EXISTS profile_image_url TEXT NULL;

-- 3. Add profile_image_url column to boats table (optional - for boat images)
ALTER TABLE public.boats 
ADD COLUMN IF NOT EXISTS profile_image_url TEXT NULL;

-- 4. Create an index on profile_image_url for better query performance (optional)
CREATE INDEX IF NOT EXISTS idx_fishermen_profile_image 
ON public.fishermen (profile_image_url) 
WHERE profile_image_url IS NOT NULL;

-- 5. Add a comment to document the new column
COMMENT ON COLUMN public.fishermen.profile_image_url IS 'URL or path to the fisherman profile image';

-- 6. Optional: Create a function to update profile image
CREATE OR REPLACE FUNCTION update_fisherman_profile_image(
    fisherman_id UUID,
    image_url TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.fishermen 
    SET profile_image_url = image_url,
        last_active = NOW()
    WHERE id = fisherman_id AND is_active = true;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- 7. Optional: Create a trigger to automatically update last_active when profile image changes
CREATE OR REPLACE FUNCTION trigger_update_last_active()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_active = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_fishermen_profile_image_update
    BEFORE UPDATE ON public.fishermen
    FOR EACH ROW
    WHEN (OLD.profile_image_url IS DISTINCT FROM NEW.profile_image_url)
    EXECUTE FUNCTION trigger_update_last_active();

-- 8. Example query to get fishermen with profile images
-- SELECT 
--     id,
--     first_name,
--     last_name,
--     email,
--     profile_image_url,
--     CASE 
--         WHEN profile_image_url IS NOT NULL THEN 'Has Profile Image'
--         ELSE 'No Profile Image'
--     END as image_status
-- FROM public.fishermen 
-- WHERE is_active = true
-- ORDER BY last_active DESC;

-- 9. Example query to update a fisherman's profile image
-- UPDATE public.fishermen 
-- SET profile_image_url = 'https://your-storage-service.com/images/fisherman_123.jpg'
-- WHERE id = 'your-fisherman-uuid-here';

-- 10. Optional: Add a constraint to ensure profile_image_url is a valid URL format
-- ALTER TABLE public.fishermen 
-- ADD CONSTRAINT check_profile_image_url_format 
-- CHECK (profile_image_url IS NULL OR profile_image_url ~ '^https?://.*');

-- Note: The above constraint is commented out as it might be too restrictive
-- depending on your storage solution (local paths, CDN URLs, etc.)



-- =============================================
-- SOS Alerts table and indexes (run in Supabase)
-- =============================================

-- Creates the table to store SOS alerts sent by fishermen. The app already
-- calls an insert into this table via DatabaseService.createSOSAlert.

CREATE TABLE public.sos_alerts (
  id TEXT NOT NULL,
  fisherman_id UUID NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  message TEXT NULL,
  status TEXT NOT NULL DEFAULT 'active'::text,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at TIMESTAMPTZ NULL,
  CONSTRAINT sos_alerts_pkey PRIMARY KEY (id),
  CONSTRAINT sos_alerts_fisherman_id_fkey FOREIGN KEY (fisherman_id) REFERENCES public.fishermen (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- Helpful indexes for admin dashboards and queries
CREATE INDEX IF NOT EXISTS idx_sos_alerts_status_created_at ON public.sos_alerts USING btree (status, created_at DESC) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_sos_alerts_fisherman ON public.sos_alerts USING btree (fisherman_id) TABLESPACE pg_default;
