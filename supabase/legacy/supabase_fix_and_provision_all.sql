-- ==============================================================================
-- DEPRECATED: contains an unconditional multi-user auth.users UPDATE and hardcoded credentials. Do not execute.
-- ==============================================================================
-- Cable Ops CMMS — Comprehensive Fix & Provision for 12 Factory Users (ARCHIVED)
-- تم حل جميع أنواع الـ ENUM (role, specialty, department) بتحويلها إلى TEXT
-- كلمة المرور الموحدة لجميع الحسابات: 123456
-- شغل هذا الكود بالكامل في: Supabase Dashboard -> SQL Editor -> New Query -> Run
-- ==============================================================================

-- 1. تفعيل امتداد التشفير
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- 2. تصحيح جدول البروفايلات public.user_profiles وتحويل أي ENUM إلى TEXT لمرونة تامة
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'OPERATOR',
  department TEXT,
  specialty TEXT,
  employee_code TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- تحويل أعمدة role و specialty و department إلى TEXT لتفادي أخطاء الـ ENUM نهائياً
DO $$
BEGIN
  -- 1. تحويل role
  BEGIN
    ALTER TABLE public.user_profiles ALTER COLUMN role DROP DEFAULT;
    ALTER TABLE public.user_profiles ALTER COLUMN role TYPE TEXT USING role::TEXT;
    ALTER TABLE public.user_profiles ALTER COLUMN role SET DEFAULT 'OPERATOR';
  EXCEPTION WHEN OTHERS THEN NULL;
  END;

  -- 2. تحويل specialty
  BEGIN
    ALTER TABLE public.user_profiles ALTER COLUMN specialty DROP DEFAULT;
    ALTER TABLE public.user_profiles ALTER COLUMN specialty TYPE TEXT USING specialty::TEXT;
  EXCEPTION WHEN OTHERS THEN NULL;
  END;

  -- 3. تحويل department
  BEGIN
    ALTER TABLE public.user_profiles ALTER COLUMN department DROP DEFAULT;
    ALTER TABLE public.user_profiles ALTER COLUMN department TYPE TEXT USING department::TEXT;
  EXCEPTION WHEN OTHERS THEN NULL;
  END;
END $$;

ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS department TEXT;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS specialty TEXT;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS employee_code TEXT;

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated users to read all profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can read own profile" ON public.user_profiles;
CREATE POLICY "Allow authenticated users to read all profiles"
  ON public.user_profiles FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile"
  ON public.user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- 3. دالة لإنشاء وتصحيح الحسابات بدون أي قيم NULL
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
  v_user_id UUID;
  v_encrypted_pw TEXT;
  v_clean_email TEXT;
BEGIN
  v_clean_email := LOWER(TRIM(p_email));
  v_encrypted_pw := extensions.crypt(p_password, extensions.gen_salt('bf'));

  SELECT id INTO v_user_id FROM auth.users WHERE email = v_clean_email;

  IF v_user_id IS NULL THEN
    v_user_id := p_id;
    IF EXISTS (SELECT 1 FROM auth.users WHERE id = v_user_id) THEN
      v_user_id := gen_random_uuid();
    END IF;

    INSERT INTO auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      aud,
      role,
      created_at,
      updated_at,
      confirmation_token,
      recovery_token,
      email_change_token_new,
      email_change,
      phone_change,
      phone_change_token,
      email_change_token_current,
      reauthentication_token
    ) VALUES (
      v_user_id,
      '00000000-0000-0000-0000-000000000000',
      v_clean_email,
      v_encrypted_pw,
      NOW(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      json_build_object('full_name', p_full_name, 'role', p_role)::jsonb,
      'authenticated',
      'authenticated',
      NOW(),
      NOW(),
      '', '', '', '', '', '', '', ''
    );
  ELSE
    UPDATE auth.users
    SET 
      encrypted_password = v_encrypted_pw,
      email_confirmed_at = NOW(),
      confirmation_token = '',
      recovery_token = '',
      email_change_token_new = '',
      email_change = '',
      phone_change = '',
      phone_change_token = '',
      email_change_token_current = '',
      reauthentication_token = '',
      aud = 'authenticated',
      role = 'authenticated',
      instance_id = '00000000-0000-0000-0000-000000000000',
      raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
      raw_user_meta_data = json_build_object('full_name', p_full_name, 'role', p_role)::jsonb,
      updated_at = NOW()
    WHERE id = v_user_id;
  END IF;

  DELETE FROM auth.identities WHERE user_id = v_user_id AND provider = 'email';

  INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    v_user_id,
    json_build_object('sub', v_user_id::text, 'email', v_clean_email)::jsonb,
    'email',
    v_user_id::text,
    NOW(),
    NOW(),
    NOW()
  );

  INSERT INTO public.user_profiles (
    id,
    full_name,
    role,
    department,
    specialty,
    employee_code,
    created_at
  ) VALUES (
    v_user_id,
    p_full_name,
    p_role,
    p_department,
    p_specialty,
    p_employee_code,
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name     = EXCLUDED.full_name,
    role          = EXCLUDED.role,
    department    = EXCLUDED.department,
    specialty     = EXCLUDED.specialty,
    employee_code = EXCLUDED.employee_code;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. تفعيل الحسابات الـ 12:
-- [1] المدير العام
SELECT public.setup_cmms_account(
  '97d56aef-5089-4741-8942-cca54dde3750',
  'manager.prod@cable.com',
  '123456',
  'مدير علي - مدير عام المصنع',
  'ADMIN', NULL, 'ALL', 'EMP-001'
);

-- [2] مشرف الصيانة
SELECT public.setup_cmms_account(
  'c79d06f1-09b2-4d01-99e9-0c8fced1e56b',
  'eng.maint@cable.com',
  '123456',
  'م. هشام راضي - مشرف الصيانة',
  'SUPERVISOR', NULL, 'ALL', 'EMP-002'
);

-- [3] مشرف الإنتاج
SELECT public.setup_cmms_account(
  '24be4db4-d948-4b51-b497-17f2f18cf564',
  'prod.sup@cable.com',
  '123456',
  'م. كريم عزت - مشرف الإنتاج',
  'PRODUCTION_SUPERVISOR', NULL, 'ALL', 'EMP-003'
);

-- [4] فني كهرباء وتحكم
SELECT public.setup_cmms_account(
  'cc9f6212-bf05-4610-b8a5-64f911565f37',
  'tech.elec@cable.com',
  '123456',
  'طارق المنصور - فني كهرباء وتحكم',
  'TECHNICIAN', NULL, 'ELECTRICAL', 'EMP-004'
);

-- [5] فني ميكانيكا وهيدروليك
SELECT public.setup_cmms_account(
  '90e23813-fe01-4796-8138-61f17275f432',
  'tech.mech@cable.com',
  '123456',
  'سمير فوزي - فني ميكانيكا وهيدروليك',
  'TECHNICIAN', NULL, 'MECHANICAL', 'EMP-005'
);

-- [6] 1. مشغل خط سحب الأسلاك
SELECT public.setup_cmms_account(
  'a1111111-1111-4111-8111-111111111111',
  'op.drawing@cable.com',
  '123456',
  'أحمد سعيد - مشغل سحب الأسلاك',
  'OPERATOR', 'drawing', 'ALL', 'EMP-006'
);

-- [7] 2. مشغل خط الجدل والتجميع
SELECT public.setup_cmms_account(
  '0a03468c-8212-4c44-9c1f-3ac98fe625bf',
  'operator@cable.com',
  '123456',
  'عمر خالد - مشغل خط الجدل والتجميع',
  'OPERATOR', 'stranding', 'ALL', 'EMP-007'
);

-- [8] 3. مشغل خطوط CCV
SELECT public.setup_cmms_account(
  'b2222222-2222-4222-8222-222222222222',
  'op.ccv@cable.com',
  '123456',
  'محمد يوسف - مشغل خطوط CCV',
  'OPERATOR', 'ccv', 'ALL', 'EMP-008'
);

-- [9] 4. مشغل خطوط العزل والبثق
SELECT public.setup_cmms_account(
  'c3333333-3333-4333-8333-333333333333',
  'op.extrusion@cable.com',
  '123456',
  'علي حسن - مشغل خطوط العزل والبثق',
  'OPERATOR', 'extrusion', 'ALL', 'EMP-009'
);

-- [10] 5. مشغل قسم التجميع والتسليح
SELECT public.setup_cmms_account(
  'd4444444-4444-4444-8444-444444444444',
  'op.assembly@cable.com',
  '123456',
  'مصطفى إبراهيم - مشغل التجميع والتسليح',
  'OPERATOR', 'assembly', 'ALL', 'EMP-010'
);

-- [11] 6. مشغل قسم الحجب والشريط
SELECT public.setup_cmms_account(
  'e5555555-5555-4555-8555-555555555555',
  'op.screening@cable.com',
  '123456',
  'ياسر حمدي - مشغل الحجب والشريط',
  'OPERATOR', 'screening', 'ALL', 'EMP-011'
);

-- [12] 7. مشغل قسم تدريع الأشرطة
SELECT public.setup_cmms_account(
  'f6666666-6666-4666-8666-666666666666',
  'op.tape@cable.com',
  '123456',
  'تامر نبيل - مشغل تدريع الأشرطة',
  'OPERATOR', 'tapeArmour', 'ALL', 'EMP-012'
);

-- 4. تنظيف وقائي إضافي لجميع الحقول في auth.users
UPDATE auth.users
SET 
  confirmation_token = COALESCE(NULLIF(confirmation_token, ''), ''),
  recovery_token = COALESCE(NULLIF(recovery_token, ''), ''),
  email_change_token_new = COALESCE(NULLIF(email_change_token_new, ''), ''),
  email_change = COALESCE(NULLIF(email_change, ''), ''),
  phone_change = COALESCE(NULLIF(phone_change, ''), ''),
  phone_change_token = COALESCE(NULLIF(phone_change_token, ''), ''),
  email_change_token_current = COALESCE(NULLIF(email_change_token_current, ''), ''),
  reauthentication_token = COALESCE(NULLIF(reauthentication_token, ''), ''),
  aud = 'authenticated',
  role = 'authenticated',
  email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
  instance_id = '00000000-0000-0000-0000-000000000000',
  raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
  encrypted_password = extensions.crypt('123456', extensions.gen_salt('bf'));

-- 5. استعراض النتيجة النهائية للتأكد
SELECT 
  p.employee_code,
  p.full_name,
  p.role,
  p.department,
  p.specialty,
  u.email
FROM public.user_profiles p
JOIN auth.users u ON u.id = p.id
ORDER BY p.employee_code;
