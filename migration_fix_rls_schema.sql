-- 1. Add owner_id column to companies table
ALTER TABLE companies
ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) DEFAULT auth.uid();

-- 2. Update RLS policies for companies
DROP POLICY IF EXISTS "Herkes şirket oluşturabilir" ON companies;
DROP POLICY IF EXISTS "Kullanıcı kendi şirketini görebilir" ON companies;
DROP POLICY IF EXISTS "Kullanıcı kendi şirketini güncelleyebilir" ON companies;

-- Allow authenticated users to create companies.
-- The owner_id will be automatically set to auth.uid() due to the default value.
CREATE POLICY "Users can create companies" ON companies
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = owner_id);

-- Allow users to view their own companies (based on owner_id) OR if they are assigned via metadata
-- This fixes the issue where a user creates a company but metadata isn't updated yet.
CREATE POLICY "Users can view their own companies" ON companies
  FOR SELECT
  TO authenticated
  USING (
    owner_id = auth.uid()
    OR
    id::text = (auth.jwt() -> 'user_metadata' ->> 'company_id')
  );

-- Allow users to update their own companies
CREATE POLICY "Users can update their own companies" ON companies
  FOR UPDATE
  TO authenticated
  USING (owner_id = auth.uid());

-- 3. Create a secure function for subdomain lookup (used by middleware)
-- This function runs with SECURITY DEFINER, bypassing RLS to allow public subdomain resolution
CREATE OR REPLACE FUNCTION get_company_by_subdomain(lookup_subdomain TEXT)
RETURNS TABLE (id UUID, subdomain TEXT)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT c.id, c.subdomain
  FROM companies c
  WHERE c.subdomain = lookup_subdomain;
END;
$$ LANGUAGE plpgsql;

-- Grant access to public (anon) users
GRANT EXECUTE ON FUNCTION get_company_by_subdomain(TEXT) TO public;
GRANT EXECUTE ON FUNCTION get_company_by_subdomain(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION get_company_by_subdomain(TEXT) TO authenticated;
