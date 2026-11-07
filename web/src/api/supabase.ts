import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = url && anonKey ? createClient(url, anonKey) : null
export const supabaseConfigError = !supabase
  ? 'Add VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY to web/.env.local. — أضف VITE_SUPABASE_URL و VITE_SUPABASE_ANON_KEY إلى ملف web/.env.local.'
  : null
