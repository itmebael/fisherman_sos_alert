-- SQL ALTER statements to add weather support to news table
-- Run these commands in your Supabase SQL editor

-- 1. Add weather-related columns to news table
ALTER TABLE public.news 
ADD COLUMN weather_data TEXT NULL,
ADD COLUMN weather_location TEXT NULL,
ADD COLUMN is_weather_related BOOLEAN DEFAULT FALSE;

-- 2. Add comment to document the new columns
COMMENT ON COLUMN public.news.weather_data IS 'JSON string containing weather data for weather-related news';
COMMENT ON COLUMN public.news.weather_location IS 'Location name for weather data (e.g., Manila, Cebu)';
COMMENT ON COLUMN public.news.is_weather_related IS 'Flag indicating if this news item is weather-related';

-- 3. Create an index on weather-related news for better query performance
CREATE INDEX IF NOT EXISTS idx_news_weather_related 
ON public.news (is_weather_related) 
WHERE is_weather_related = true;

-- 4. Create an index on weather location for filtering
CREATE INDEX IF NOT EXISTS idx_news_weather_location 
ON public.news (weather_location) 
WHERE weather_location IS NOT NULL;

-- 5. Optional: Create a function to create weather-related news
CREATE OR REPLACE FUNCTION create_weather_news(
    news_title TEXT,
    news_content TEXT,
    weather_json TEXT,
    location_name TEXT,
    author_name TEXT DEFAULT 'Weather Service'
)
RETURNS TEXT AS $$
DECLARE
    news_id TEXT;
BEGIN
    -- Generate unique news ID
    news_id := 'weather_news_' || EXTRACT(EPOCH FROM NOW())::TEXT;
    
    -- Insert weather-related news
    INSERT INTO public.news (
        id,
        title,
        content,
        weather_data,
        weather_location,
        is_weather_related,
        author,
        is_active,
        created_at
    ) VALUES (
        news_id,
        news_title,
        news_content,
        weather_json,
        location_name,
        true,
        author_name,
        true,
        NOW()
    );
    
    RETURN news_id;
END;
$$ LANGUAGE plpgsql;

-- 6. Optional: Create a function to get weather-related news by location
CREATE OR REPLACE FUNCTION get_weather_news_by_location(location_name TEXT)
RETURNS TABLE (
    id TEXT,
    title TEXT,
    content TEXT,
    weather_data TEXT,
    weather_location TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        n.id,
        n.title,
        n.content,
        n.weather_data,
        n.weather_location,
        n.created_at
    FROM public.news n
    WHERE n.is_weather_related = true
      AND n.weather_location = location_name
      AND n.is_active = true
    ORDER BY n.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- 7. Example query to get all weather-related news
-- SELECT 
--     id,
--     title,
--     weather_location,
--     created_at,
--     CASE 
--         WHEN weather_data IS NOT NULL THEN 'Has Weather Data'
--         ELSE 'No Weather Data'
--     END as weather_status
-- FROM public.news 
-- WHERE is_weather_related = true
-- ORDER BY created_at DESC;

-- 8. Example query to create weather news (call the function)
-- SELECT create_weather_news(
--     'Weather Alert: Strong Winds Expected',
--     'Strong winds are expected in Manila area. Fishermen are advised to stay ashore.',
--     '{"temperature": 28, "windSpeed": 25, "description": "Strong winds"}',
--     'Manila',
--     'Weather Service'
-- );

-- 9. Example query to get weather news by location
-- SELECT * FROM get_weather_news_by_location('Manila');

-- 10. Optional: Add trigger to automatically update timestamp when weather data changes
CREATE OR REPLACE FUNCTION trigger_update_weather_news_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at column if it doesn't exist
ALTER TABLE public.news 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Create trigger for weather news updates
CREATE TRIGGER trigger_news_weather_update
    BEFORE UPDATE ON public.news
    FOR EACH ROW
    WHEN (OLD.weather_data IS DISTINCT FROM NEW.weather_data)
    EXECUTE FUNCTION trigger_update_weather_news_timestamp();

-- 11. Optional: Create a view for easy weather news access
CREATE OR REPLACE VIEW weather_news_view AS
SELECT 
    id,
    title,
    content,
    weather_data,
    weather_location,
    author,
    created_at,
    updated_at
FROM public.news
WHERE is_weather_related = true
  AND is_active = true
ORDER BY created_at DESC;

-- 12. Grant permissions (adjust as needed for your setup)
-- GRANT SELECT ON weather_news_view TO authenticated;
-- GRANT EXECUTE ON FUNCTION create_weather_news TO authenticated;
-- GRANT EXECUTE ON FUNCTION get_weather_news_by_location TO authenticated;


