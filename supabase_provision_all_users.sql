-- ==============================================================================
-- Cable Ops CMMS — Provisioning All Factory Users & Roles in Supabase
-- شغّل هذا الكود في: Supabase Dashboard -> SQL Editor -> New Query
-- كلمة المرور الموحدة لجميع الحسابات: 123456
-- ==============================================================================

-- 1. تفعيل امتداد تشفير كلمات المرور
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- 2. التأكد من وجود جدول public.user_profiles مع جميع الأعمدة المطلوبة
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'OPERATOR',
  department TEXT, -- drawing, stranding, ccv, extrusion, assembly, screening, tapeArmour
  specialty TEXT,  -- ELECTRICAL, MECHANICAL, ALL
  employee_code TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- التأكد من وجود الأعمدة إن كان الجدول منشأ سابقاً
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS department TEXT;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS specialty TEXT;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS employee_code TEXT;

-- 3. تصحيح سياسة الحماية (RLS) - السماح لجميع المستخدمين المسجلين بقراءة ملفات الفنيين والزملاء
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Allow authenticated users to read all profiles" ON public.user_profiles;
CREATE POLICY "Allow authenticated users to read all profiles"
  ON public.user_profiles FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile"
  ON public.user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- 4. دالة مساعدة لإنشاء أو تحديث المستخدم في auth.users و auth.identities و public.user_profiles
CREATE OR REPLACE FUNCTION public.create_cmms_user(
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
BEGIN
  v_encrypted_pw := extensions.crypt(p_password, extensions.gen_salt('bf'));

  -- فحص هل المستخدم موجود بالبريد الإلكتروني
  SELECT id INTO v_user_id FROM auth.users WHERE email = LOWER(TRIM(p_email));

  IF v_user_id IS NULL THEN
    -- استخدام الـ UUID المعطى إذا لم يكن مستخدماً مسبقاً
    IF EXISTS (SELECT 1 FROM auth.users WHERE id = p_id) THEN
      v_user_id := gen_random_uuid();
    ELSE
      v_user_id := p_id;
    END IF;

    -- إدراج المستخدم الجديد في auth.users
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
      LOWER(TRIM(p_email)),
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
    -- تحديث كلمة المرور والبيانات إن كان موجوداً
    UPDATE auth.users
    SET 
      encrypted_password = v_encrypted_pw,
      email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
      raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
      raw_user_meta_data = json_build_object('full_name', p_full_name, 'role', p_role)::jsonb,
      aud = 'authenticated',
      role = 'authenticated',
      updated_at = NOW()
    WHERE id = v_user_id;
  END IF;

  -- التأكد من وجود سجل الهوية (auth.identities) لتسجيل الدخول السلس
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
    json_build_object('sub', v_user_id::text, 'email', LOWER(TRIM(p_email)))::jsonb,
    'email',
    LOWER(TRIM(p_email)),
    NOW(),
    NOW(),
    NOW()
  )
  ON CONFLICT (provider, provider_id) DO UPDATE
  SET 
    identity_data = EXCLUDED.identity_data,
    updated_at = NOW();

  -- إدراج أو تحديث الملف الشخصي في public.user_profiles
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

-- ==============================================================================
-- 5. إنشاء حسابات المصنع الكاملة (الإدارة + المشرفين + الفنيين + مشغلي الأقسام الـ 7)
-- ==============================================================================

-- [1] الإدارة العليا (Plant Manager)
SELECT public.create_cmms_user(
  '97d56aef-5089-4741-8942-cca54dde3750',
  'manager.prod@cable.com',
  '123456',
  'منير علي - مدير عام المصنع',
  'ADMIN',
  NULL,
  'ALL',
  'EMP-001'
);

-- [2] مشرف الصيانة (Maintenance Supervisor)
SELECT public.create_cmms_user(
  'c79d06f1-09b2-4d01-99e9-0c8fced1e56b',
  'eng.maint@cable.com',
  '123456',
  'م. هشام راضي - مشرف الصيانة',
  'SUPERVISOR',
  NULL,
  'ALL',
  'EMP-002'
);

-- [3] مشرف الإنتاج (Production Supervisor)
SELECT public.create_cmms_user(
  '24be4db4-d948-4b51-b497-17f2f18cf564',
  'prod.sup@cable.com',
  '123456',
  'م. كريم عزت - مشرف الإنتاج',
  'PRODUCTION_SUPERVISOR',
  NULL,
  NULL,
  'EMP-003'
);

-- [4] فني صيانة كهربائية وتحكم (Electrical Maintenance Technician)
SELECT public.create_cmms_user(
  'cc9f6212-bf05-4610-b8a5-64f911565f37',
  'tech.elec@cable.com',
  '123456',
  'طارق المنصور - فني كهرباء وتحكم',
  'TECHNICIAN',
  NULL,
  'ELECTRICAL',
  'EMP-004'
);

-- [5] فني صيانة ميكانيكية وهيدروليك (Mechanical Maintenance Technician)
SELECT public.create_cmms_user(
  '90e23813-fe01-4796-8138-61f17275f432',
  'tech.mech@cable.com',
  '123456',
  'سمير فوزي - فني ميكانيكا وهيدروليك',
  'TECHNICIAN',
  NULL,
  'MECHANICAL',
  'EMP-005'
);

-- [6] مشغل قسم سحب الأسلاك (Drawing Department Operator)
SELECT public.create_cmms_user(
  'a1111111-1111-4111-8111-111111111111',
  'op.drawing@cable.com',
  '123456',
  'أحمد سعيد - مشغل سحب الأسلاك',
  'OPERATOR',
  'drawing',
  NULL,
  'EMP-006'
);

-- [7] مشغل قسم الجدل والتجميع (Stranding & Bunching Operator)
SELECT public.create_cmms_user(
  '0a03468c-8212-4c44-9c1f-3ac98fe625bf',
  'operator@cable.com',
  '123456',
  'عمر خالد - مشغل خط الجدل والتجميع',
  'OPERATOR',
  'stranding',
  NULL,
  'EMP-007'
);

-- [8] مشغل خطوط الفلكنة المستمرة (CCV Lines Operator)
SELECT public.create_cmms_user(
  'b2222222-2222-4222-8222-222222222222',
  'op.ccv@cable.com',
  '123456',
  'محمد يوسف - مشغل خطوط CCV',
  'OPERATOR',
  'ccv',
  NULL,
  'EMP-008'
);

-- [9] مشغل خطوط العزل والبثق (Extrusion Lines Operator)
SELECT public.create_cmms_user(
  'c3333333-3333-4333-8333-333333333333',
  'op.extrusion@cable.com',
  '123456',
  'علي حسن - مشغل خطوط العزل والبثق',
  'OPERATOR',
  'extrusion',
  NULL,
  'EMP-009'
);

-- [10] مشغل قسم التجميع والتسليح (Assembly & Armouring Operator)
SELECT public.create_cmms_user(
  'd4444444-4444-4444-8444-444444444444',
  'op.assembly@cable.com',
  '123456',
  'مصطفى إبراهيم - مشغل التجميع والتسليح',
  'OPERATOR',
  'assembly',
  NULL,
  'EMP-010'
);

-- [11] مشغل قسم الحجب والشريط (Screening & Taping Operator)
SELECT public.create_cmms_user(
  'e5555555-5555-4555-8555-555555555555',
  'op.screening@cable.com',
  '123456',
  'ياسر حمدي - مشغل الحجب والشريط',
  'OPERATOR',
  'screening',
  NULL,
  'EMP-011'
);

-- [12] مشغل قسم تدريع الأشرطة (Tape Armouring Operator)
SELECT public.create_cmms_user(
  'f6666666-6666-4666-8666-666666666666',
  'op.tape@cable.com',
  '123456',
  'تامر نبيل - مشغل تدريع الأشرطة',
  'OPERATOR',
  'tapeArmour',
  NULL,
  'EMP-012'
);

-- ==============================================================================
-- 6. فحص النتيجة للتأكد من نجاح الإدراج
-- ==============================================================================
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
