-- ============================================================
-- Cable Ops CMMS — Fix Supabase auth.users & auth.identities
-- شغل هذا الكود في Supabase Dashboard -> SQL Editor -> New Query
-- ============================================================

-- 1. تفعيل امتداد تشفير كلمات المرور
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- 2. تصحيح الحقول الفارغة (NULLs) في جدول auth.users لتجنب خطأ GoTrue Scan Error
-- وتعيين كلمة المرور لجميع الحسابات لتكون: 123456 للتجربة الفورية
UPDATE auth.users
SET 
  confirmation_token = COALESCE(confirmation_token, ''),
  recovery_token = COALESCE(recovery_token, ''),
  email_change_token_new = COALESCE(email_change_token_new, ''),
  email_change = COALESCE(email_change, ''),
  phone_change = COALESCE(phone_change, ''),
  phone_change_token = COALESCE(phone_change_token, ''),
  email_change_token_current = COALESCE(email_change_token_current, ''),
  reauthentication_token = COALESCE(reauthentication_token, ''),
  aud = 'authenticated',
  role = 'authenticated',
  email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
  raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
  raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb),
  instance_id = '00000000-0000-0000-0000-000000000000',
  encrypted_password = extensions.crypt('123456', extensions.gen_salt('bf'));

-- 3. إضافة سجلات الهوية (auth.identities) المفقودة لجميع المستخدمين
-- بدون هذه السجلات، يرفض نظام Supabase Auth تسجيل الدخول بالبريد
INSERT INTO auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  provider_id,
  last_sign_in_at,
  created_at,
  updated_at
)
SELECT 
  u.id,
  u.id,
  json_build_object('sub', u.id::text, 'email', u.email)::jsonb,
  'email',
  u.email,
  NOW(),
  NOW(),
  NOW()
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM auth.identities i WHERE i.user_id = u.id
);

-- 4. التأكد من وجود جدول البروفايل وربط الأدوار والأقسام (department) لجميع الحسابات
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'OPERATOR',
  department TEXT, -- drawing, stranding, extrusion, ccv, assembly, screening, tapeArmour
  specialty TEXT,
  employee_code TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- التأكد من إضافة عمود القسم في حال كان الجدول منشأ مسبقاً
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS department TEXT;

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own profile" ON public.user_profiles;
CREATE POLICY "Users can read own profile"
  ON public.user_profiles FOR SELECT
  USING (auth.uid() = id);

-- 5. إدراج أو تحديث البروفايلات للمستخدمين الـ 7 مع تحديد قسم المشغل
INSERT INTO public.user_profiles (id, full_name, role, department, specialty, employee_code)
VALUES 
  ('c79d06f1-09b2-4d01-99e9-0c8fced1e56b', 'مهندس صيانة الخطوط', 'SUPERVISOR', NULL, 'ALL', 'EMP-001'),
  ('24be4db4-d948-4b51-b497-17f2f18cf564', 'مهندس إنتاج الوردية', 'PRODUCTION_SUPERVISOR', NULL, NULL, 'EMP-002'),
  ('97d56aef-5089-4741-8942-cca54dde3750', 'منير علي - مدير الإنتاج', 'ADMIN', NULL, 'ALL', 'EMP-003'),
  -- مشغل خط الجدل والتجميع (مخصص لقسم stranding فقط)
  ('0a03468c-8212-4c44-9c1f-3ac98fe625bf', 'مشغل خط الجدل والتجميع', 'OPERATOR', 'stranding', NULL, 'EMP-004'),
  ('cc9f6212-bf05-4610-b8a5-64f911565f37', 'فني كهرباء المصنع', 'TECHNICIAN', NULL, 'ELECTRICAL', 'EMP-005'),
  ('a777edcb-e42e-4c94-aac9-1b89dd364ce5', 'أحمد فني كهرباء وتحكم', 'TECHNICIAN', NULL, 'ELECTRICAL', 'EMP-006'),
  ('90e23813-fe01-4796-8138-61f17275f432', 'محمود فني ميكانيكا وهيدروليك', 'TECHNICIAN', NULL, 'MECHANICAL', 'EMP-007')
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  role = EXCLUDED.role,
  department = EXCLUDED.department,
  specialty = EXCLUDED.specialty,
  employee_code = EXCLUDED.employee_code;
