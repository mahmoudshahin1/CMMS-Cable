# تقرير اختلاف سجل Supabase عن migrations المحلية

**تاريخ الفحص:** 6 نوفمبر 2026

**المستودع والفرع:** `mahmoudshahin1/CMMS-Cable`, `feature/mobile-logic`

**رأس الفرع المحلي والبعيد وقت الفحص:** `c9da0bb43f70dc6571e06a821663caaac2a1f6c2`

**Supabase project ref:** `ptlzpwfrrxfqfprkvbuf`

## حالة تجهيز بيئة التطوير المحلية

- ثبت بالتجربة أن Supabase CLI غير موجود كأمر عام، لكن `npx --yes supabase@latest --version` يعمل ويعيد `3.0.0`.
- نُفذ `npx --yes supabase@latest init` محليًا وأنشأ `supabase/config.toml` بمعرّف مشروع محلي `cmms-mobile-logic`.
- Docker Desktop مثبت للمستخدم بالإصدار `4.91.0`؛ تحديث `4.98.0` الظاهر عبر `winget` لم ينطبق على هذا النظام.
- اكتمل تثبيت WSL `3.0.3.0` والـkernel `6.18.5.4-1`. فحص المعالج أكد أن virtualization مدعوم ومفعّل في firmware.
- فُعّل Windows optional feature `VirtualMachinePlatform` عبر DISM بصلاحية مسؤول ومن دون إعادة تشغيل تلقائية. رمز الخروج `3010` يعني أن العملية نجحت لكنها تتطلب إعادة تشغيل.
- كشف فحص DISM المرتفع أن `Microsoft-Windows-Subsystem-Linux` كان `Disabled`. فُعّل الآن بصلاحية مسؤول؛ أحدث فحص أكد أن كلا المكونين `Microsoft-Windows-Subsystem-Linux` و`VirtualMachinePlatform` حالتهما `Enabled`.
- بعد تفعيل المكوّن الثاني، لم نعد تشغيل Windows بعد؛ فحص WSL السابق لا يعكس بالضرورة التفعيل الجديد. فحص المعالج أعاد CPU virtualization flags = `True`، بينما `HypervisorPresent = False` قبل هذا التفعيل.
- قراءة BCD بصلاحية مسؤول لم تجد `hypervisorlaunchtype Off`؛ الحقل غير موجود في الإدخال الحالي، ولم نغير إعداد الإقلاع.
- سجلات Docker أظهرت socket links عالقة لا يستطيع Windows فتحها (`ERROR_CANT_ACCESS_FILE`): أولًا `Docker\\run\\sailor-ingest.sock` ثم `docker-secrets-engine\\engine.sock`. حُفظ مجلدا runtime كما هما تحت `run.stale-20261106-182818`, `run.stale-20261106-183157`, و`docker-secrets-engine.stale-20261106-183015` بدل حذف أي شيء. ظهرت آلية الخطأ نفسها في [Docker Desktop issue #15064](https://github.com/docker/for-win/issues/15064). بعد ذلك وصل Docker إلى رسالة `API proxy is serving requests (no virtualization available)`، لكن Docker API بقي غير سليم (HTTP 500)، و`docker version` لا يعرض Server.
**الحالة:** CLI وWSL وVirtual Machine Platform مهيأة؛ مكوّن WSL تم تفعيله للتو ويحتاج إعادة تشغيل Windows يدويًا. بعدها نعيد فحص `wsl --status`, `HypervisorPresent`, وDocker API قبل `supabase start`. لم تُنفذ أي أوامر مستهدفة لقاعدة Supabase البعيدة.

## النتيجة

سجل Supabase الحي لا يطابق سلسلة migrations الموجودة في Git. المستودع يحتوي 11 migration من `20260921000001` إلى `20261003000011`. Supabase يسجل 22 migration، ولا توجد مطابقة في أرقام الإصدارات بين السلسلتين. ملفات migrations الحية ذات الأسماء الجديدة غير موجودة على فرع GitHub `feature/mobile-logic`؛ جرى التحقق من ملفات `task2_p1_*` بالمسار المباشر والبحث في المستودع ولم تظهر نتائج. لذلك لا يمكن إعادة بناء سجل الإنتاج بمجرد نسخ قائمة الأسماء.

## سجل Supabase المسجل

الأسماء أدناه مأخوذة بقراءة `supabase_migrations.schema_migrations` ونتيجة أداة قائمة migrations. لم تُقرأ صفوف تشغيلية ولم يُستدعَ أي RPC.

| الإصدار | الاسم |
| --- | --- |
| `20260922075802` | `security_hardening_role_and_provisioning` |
| `20260922075910` | `align_work_orders_schema_with_flutter` |
| `20260922075928` | `rename_activity_logs_to_work_order_events` |
| `20260922080043` | `align_machines_and_departments_with_flutter` |
| `20260922080116` | `work_order_rpc_functions` |
| `20260922080215` | `fix_role_column_type_mismatch_v2` |
| `20260922080233` | `normalize_priority_enum_casing` |
| `20260922080249` | `make_failure_category_nullable` |
| `20260922080316` | `make_spare_parts_category_nullable` |
| `20260923103647` | `dashboard_kpi_views` |
| `20260923103720` | `fix_shift_split_view_keys_v2` |
| `20260924091435` | `re_lock_provisioning_functions` |
| `20260927073853` | `reconcile_role_helpers_and_spare_parts_rls` |
| `20260928064408` | `lock_create_cmms_user_execute` |
| `20260928064433` | `revoke_anon_table_grants_defense_in_depth` |
| `20260928184113` | `realtime_spare_parts_and_bom` |
| `20261104215801` | `task2_p1_bounce_back_check_phase` |
| `20261104225308` | `task2_p1_server_side_department_check` |
| `20261104225341` | `task2_p1_drop_old_rpc_overload` |
| `20261105094556` | `task2_p3_p4_repair_steps_voice_notes` |
| `20261105094615` | `drop_old_rpc_overloads_task2_p3_p4` |
| `20261105110138` | `downtime_rpc_authorization_option_a` |

## اختلافات schema المؤكدة

نتيجة `list_tables` الحية مقارنةً بـ11 migration والمرجع المحلي:

- جداول حية غير معرفة في سلسلة migrations المحلية: `public.departments`, `public.preventive_schedules`, و`public.email_notifications`.
- `public.machine_bom.machine_id` حي من نوع UUID، بينما migration المحلية `20260926000009_factory_catalog.sql` تعرفه `TEXT` مرتبطًا بـ`machines.id`.
- `public.work_orders` الحية تحتوي `checks`, `repair_steps`, `voice_note_url`, و`repair_voice_url`؛ هذه الإضافات غير موجودة في migrations المحلية.
- سجل الإنتاج يتضمن migrations لاحقة لمعالجة نتيجة اختبار التشغيل، نطاق القسم، حذف overloads قديمة، خطوات الإصلاح والملاحظات الصوتية، وصلاحيات عمليات التوقف.

هذه ملاحظات بنيوية فقط. نتيجة أداة الجداول قد تعرض أعداد صفوف، لكن لم تُقرأ أي سجلات تشغيلية أو بيانات مستخدمين.

## خطة المصالحة الآمنة

1. عدم تشغيل `db push`, `migration repair`, `db pull` أو أي DDL على مشروع الإنتاج خلال هذا العمل. حسب دليل Supabase الحالي، `db pull` قد يسجل baseline في جدول migrations البعيد؛ لذلك لا نستخدمه على المشروع المرتبط قبل فهم أثره ومراجعته.
2. الحصول على تعريف schema الحالي فقط إلى ملف محلي بعد توفر runtime محلي موثوق أو أداة dump محلية. مراجعة الملف بحثًا عن بيانات أو أسرار قبل الاحتفاظ به في المستودع.
3. استعادة SQL الأصلي للـ22 migration من مصدره/تاريخه إن وجد. إن لم يتوفر المصدر، لا نخترع ملفات تاريخية بأسماء migrations فقط؛ نختار baseline محليًا موثقًا منفصلًا عن سجل الإنتاج، ونختبر إعادة البناء محليًا.
4. قارن الـbaseline مع DDL التطبيق الحالي (`rpc_confirm_test_run` وصلاحياتها وRLS والجداول) ثم أنشئ migration إصلاح جديدة بعد نجاح إعادة البناء واختبارات SQL محلية.
5. المستخدم رفض إنشاء Supabase branch؛ لا فرع ولا تعديل schema على Supabase ضمن هذا المسار.

دليل العمل المستخدم: [Supabase local development workflow](https://supabase.com/docs/guides/local-development/cli-workflows) و[Deploy database migrations / diagnosing sync errors](https://supabase.com/docs/guides/deployment/database-migrations). كما يوضح changelog بتاريخ 2026-11-02 انتقال Supabase CLI v3 إلى سلوك افتراضي محلي وتأكيدات على العمليات المستضافة؛ تحقّق من `--help` للنسخة المثبتة قبل استخدام أوامر CLI لاحقًا.
