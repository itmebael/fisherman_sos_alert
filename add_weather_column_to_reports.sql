-- Add weather column to sos_alerts table for system reports
-- This allows storing weather data for the day when the alert was created/resolved

ALTER TABLE public.sos_alerts 
ADD COLUMN IF NOT EXISTS weather_data JSONB NULL;

COMMENT ON COLUMN public.sos_alerts.weather_data IS 'Weather data for the day (temperature, condition, etc.) stored as JSON';

-- Create index for weather data queries if needed
CREATE INDEX IF NOT EXISTS idx_sos_alerts_weather_data 
ON public.sos_alerts USING gin (weather_data);









