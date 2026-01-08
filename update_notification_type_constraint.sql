-- Update notification type constraint to include sos_inactive and sos_rescued
-- This fixes the check constraint violation error

ALTER TABLE public.fisherman_notifications
DROP CONSTRAINT IF EXISTS fisherman_notifications_type_check;

ALTER TABLE public.fisherman_notifications
ADD CONSTRAINT fisherman_notifications_type_check 
CHECK (notification_type IN (
  'sos_on_the_way', 
  'sos_resolved', 
  'sos_active', 
  'sos_inactive',
  'sos_rescued',
  'weather', 
  'safety', 
  'system', 
  'admin_action'
));

COMMENT ON CONSTRAINT fisherman_notifications_type_check ON public.fisherman_notifications IS 
'Allowed notification types: sos_on_the_way, sos_resolved, sos_active, sos_inactive, sos_rescued, weather, safety, system, admin_action';









