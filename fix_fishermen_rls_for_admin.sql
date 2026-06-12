-- =============================================
-- FIX FISHERMEN RLS POLICIES FOR ADMIN ACCESS
-- =============================================
-- This script adds RLS policies to allow admin/coastguard users to view all fishermen

-- 1. Add policy to allow coastguards to view all fishermen for admin operations
CREATE POLICY "Allow coastguards to view all fishermen" ON public.fishermen
  FOR SELECT
  TO authenticated
  USING (
    -- Check if the current user exists in the coastguards table (is an admin)
    EXISTS (
      SELECT 1 FROM public.coastguards
      WHERE id = auth.uid() AND user_type = 'coastguard'
    )
  );

-- 2. Grant necessary permissions to authenticated users for coastguard viewing
GRANT SELECT ON public.fishermen TO authenticated;
GRANT SELECT ON public.coastguards TO authenticated;

-- 3. Optional: Add policy for coastguards to update fishermen records (if needed for admin operations)
CREATE POLICY "Allow coastguards to update fishermen records" ON public.fishermen
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.coastguards
      WHERE id = auth.uid() AND user_type = 'coastguard'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.coastguards
      WHERE id = auth.uid() AND user_type = 'coastguard'
    )
  );

-- Confirm the policies were created
SELECT policy_name, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'fishermen'
ORDER BY policy_name;
