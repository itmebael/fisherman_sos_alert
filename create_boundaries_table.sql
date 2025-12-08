-- Create boundaries table for fishing zone management
CREATE TABLE IF NOT EXISTS boundaries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    tl_lat DECIMAL(10, 8) NOT NULL, -- Top Left Latitude
    tl_lng DECIMAL(11, 8) NOT NULL, -- Top Left Longitude
    tr_lat DECIMAL(10, 8) NOT NULL, -- Top Right Latitude
    tr_lng DECIMAL(11, 8) NOT NULL, -- Top Right Longitude
    br_lat DECIMAL(10, 8) NOT NULL, -- Bottom Right Latitude
    br_lng DECIMAL(11, 8) NOT NULL, -- Bottom Right Longitude
    bl_lat DECIMAL(10, 8) NOT NULL, -- Bottom Left Latitude
    bl_lng DECIMAL(11, 8) NOT NULL, -- Bottom Left Longitude
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create function to create boundaries table if not exists
CREATE OR REPLACE FUNCTION create_boundaries_table_if_not_exists()
RETURNS void AS $$
BEGIN
    -- Table creation is handled above, this function exists for compatibility
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- Create RLS policies for boundaries table
ALTER TABLE boundaries ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read boundaries
CREATE POLICY "Allow authenticated users to read boundaries" ON boundaries
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow authenticated users to insert boundaries
CREATE POLICY "Allow authenticated users to insert boundaries" ON boundaries
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow authenticated users to update boundaries
CREATE POLICY "Allow authenticated users to update boundaries" ON boundaries
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_boundaries_active ON boundaries(is_active);
CREATE INDEX IF NOT EXISTS idx_boundaries_created_at ON boundaries(created_at);
