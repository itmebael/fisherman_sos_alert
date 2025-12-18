-- Add casualties and injured columns to sos_alerts table
-- These columns store rescue statistics when an alert is marked as resolved

ALTER TABLE public.sos_alerts 
ADD COLUMN IF NOT EXISTS casualties INTEGER DEFAULT 0;

ALTER TABLE public.sos_alerts 
ADD COLUMN IF NOT EXISTS injured INTEGER DEFAULT 0;

COMMENT ON COLUMN public.sos_alerts.casualties IS 'Number of casualties/dead in this rescue operation';
COMMENT ON COLUMN public.sos_alerts.injured IS 'Number of injured persons in this rescue operation';




