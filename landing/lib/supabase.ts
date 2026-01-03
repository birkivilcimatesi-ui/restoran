import { createClient } from '@supabase/supabase-js'

// Supabase client - Flutter uygulaması ile aynı proje
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://gilzmsjcdzptuwiwnfuy.supabase.co'
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdpbHptc2pjZHpwdHV3aXduZnV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcxNzE2MDMsImV4cCI6MjA4Mjc0NzYwM30.--2L7OpaOx2uh7GhAZUczx-OEZhTjUSY33xEZbjFEmk'

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
