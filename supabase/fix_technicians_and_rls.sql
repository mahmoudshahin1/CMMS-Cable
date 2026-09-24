-- ==============================================================================
-- CABLE OPS CMMS: إصلاح وتجهيز الفنيين وسياسات الأمان في Supabase
-- شغّل هذا الملف في Supabase SQL Editor لحل مشكلة عدم ظهور الفنيين نهائياً
-- ==============================================================================

-- 1. التأكد من وجود جدول البروفايلات public.user_profiles مع جميع الأعمدة المطلوبة
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'OPERATOR',
  department TEXT,
  specialty TEXT,
  employee_code TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- التأكد من وجود الأعمدة حتى لو كان الجدول منشأ مسبقاً
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS department TEXT;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS specialty TEXT;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS employee_code TEXT;

-- 2. تصحيح سياسات الأمان (Row Level Security - RLS)
-- السماح لجميع مستخدمي التطبيق (anon و authenticated) بقراءة البروفايلات والفنيين
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated users to read all profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can read own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Allow all users to read profiles" ON public.user_profiles;

CREATE POLICY "Allow all users to read profiles"
  ON public.user_profiles FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile"
  ON public.user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- 3. دالة مساعدة لإنشاء أو تحديث الحسابات والفنيين
CREATE OR REPLACE FUNCTION public.setup_cmms_account(
  p_id UUID,
  p_email TEXT,
  p_password TEXT,
  p_full_name TEXT,
  p_role TEXT,
  p_department TEXT,
  p_specialty TEXT,
  p_employee_code TEXT
) RETURNS VOID AS $$
DECLARE
  v_encrypted_pw TEXT;
BEGIN
  v_encrypted_pw := crypt(p_password, gen_salt('bf'));

  -- إدراج المستخدم في auth.users
  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    p_id,
    'authenticated',
    'authenticated',
    p_email,
    v_encrypted_pw,
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object(
      'full_name', p_full_name,
      'role', p_role,
      'department', p_department,
      'specialty', p_specialty,
      'employee_code', p_employee_code
    ),
    now(), now(), '', ''
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = v_encrypted_pw,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    updated_at = now();

  -- إدراج الهوية في auth.identities
  INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
  ) VALUES (
    p_id,
    p_id,
    jsonb_build_object('sub', p_id::text, 'email', p_email),
    'email',
    now(), now(), now()
  )
  ON CONFLICT (provider, id) DO NOTHING;

  -- إدراج أو تحديث البروفايل في public.user_profiles
  INSERT INTO public.user_profiles (
    id, full_name, role, department, specialty, employee_code, updated_at
  ) VALUES (
    p_id,
    p_full_name,
    p_role,
    p_department,
    p_specialty,
    p_employee_code,
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role,
    department = EXCLUDED.department,
    specialty = EXCLUDED.specialty,
    employee_code = EXCLUDED.employee_code,
    updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. إدراج وتأكيد بيانات فنيي الصيانة (الكهرباء والميكانيكا)
-- [فني كهرباء وتحكم 1]
SELECT public.setup_cmms_account(
  'cc9f6212-bf05-4610-b8a5-64f911565f37',
  'tech.elec@cable.com',
  '123456',
  'طارق المنصور - فني كهرباء وتحكم',
  'TECHNICIAN', NULL, 'ELECTRICAL', 'EMP-004'
);

-- [فني كهرباء وتحكم 2 - بديل للأنظمة المحلية]
SELECT public.setup_cmms_account(
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  'tech.elec@cableops.com',
  '123456',
  'طارق المنصور - فني كهرباء',
  'TECHNICIAN', NULL, 'ELECTRICAL', 'EMP-004'
);

-- [فني ميكانيكا وهيدروليك 1]
SELECT public.setup_cmms_account(
  '90e23813-fe01-4796-8138-61f17275f432',
  'tech.mech@cable.com',
  '123456',
  'سمير فوزي - فني ميكانيكا وهيدروليك',
  'TECHNICIAN', NULL, 'MECHANICAL', 'EMP-005'
);

-- [فني ميكانيكا وهيدروليك 2 - بديل للأنظمة المحلية]
SELECT public.setup_cmms_account(
  'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  'tech.mech@cableops.com',
  '123456',
  'سمير فوزي - فني ميكانيكا',
  'TECHNICIAN', NULL, 'MECHANICAL', 'EMP-005'
);

-- 5. التحقق من النتيجة:
SELECT id, full_name, role, specialty, employee_code 
FROM public.user_profiles 
WHERE role = 'TECHNICIAN';
