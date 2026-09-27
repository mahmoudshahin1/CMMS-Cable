# دليل مشروع Cable Ops CMMS

هذا الدليل يشرح أجزاء المشروع ومسارات البيانات بين تطبيق Flutter ولوحة الويب وSupabase. بنية المستودع Monorepo، لكن التطبيقات والـ migrations موجودة في مجلدات مستقلة.

## 1. خريطة المستودع

| المسار | دوره |
| --- | --- |
| `mobile/` | تطبيق Flutter متعدد الشاشات، يعمل بأسلوب Offline-first ويزامن إلى Supabase عند توفر الشبكة. |
| `web/` | لوحة تشغيل Vue 3 + Vite + TypeScript، موجّهة للمتصفح وتقرأ البيانات مباشرة من Supabase. |
| `supabase/migrations/` | ملفات SQL مرتبة لتكوين المخطط والسياسات والدوال والـ views في بيئة جديدة. |
| `supabase/migrations_down/` | ملفات التراجع المقابلة لمجموعة migrations النشطة. |
| `supabase/seed.sql` | بيانات مرجعية وتجريبية لتهيئة مصنع جديد؛ راجعه قبل استخدامه في أي بيئة غير تطويرية. |
| `supabase/PRODUCTION_BASELINE.md` | سجل حالة مخطط الإنتاج وطريقة المصالحة الآمنة مع migrations المحلية. |
| `docs/SCHEMA.md` | عقد البيانات، أسماء الأعمدة، سياسات الوصول، الـ RPCs، والـ reporting views. |
| `docs/production_deployment_runbook.md` | إرشادات التشغيل والنشر. |
| `HANDOFF.md` | حالة التحقق والقيود والخطوات المتبقية للمطور التالي. |

## 2. لوحة الويب

### التقنيات والتشغيل

- Vue 3 Composition API مع `<script setup>` وTypeScript.
- Vite للبناء والتطوير، Tailwind CSS للتنسيق، Pinia للحالة العامة، وVue Router للمسارات.
- `@supabase/supabase-js` للهوية والقراءات والـ RPC وRealtime.
- Apache ECharts عبر `vue-echarts` للرسوم. يتم فصل مكتبات الرسوم إلى chunks مستقلة حتى تُحمّل صفحة التحليلات عند فتحها فقط.
- الواجهة عربية RTL، تستخدم شعار Energya وخط Cairo، وتراعي `prefers-reduced-motion` لتقليل الحركة لمن يطلب ذلك من إعدادات النظام.

تشغيل الواجهة:

```powershell
cd web
Copy-Item .env.example .env.local
# ضع VITE_SUPABASE_URL وVITE_SUPABASE_ANON_KEY في web/.env.local
npm install
npm run dev
```

للبناء والتحقق من TypeScript:

```powershell
cd web
npm run build
```

### الإعدادات والهوية

- `web/src/main.ts`: ينشئ تطبيق Vue، Pinia، Router، والأنماط العامة.
- `web/src/style.css`: Cairo وRTL، الألوان، انتقال الصفحات، حركة الظهور، وحالات التركيز وإعداد تقليل الحركة.
- `web/tailwind.config.cjs`: درجات `brand` المستخدمة في الواجهات.
- `web/public/energya-logo.png`: شعار الشركة المستخدم في صفحة الدخول والشريط الجانبي.
- `web/src/api/supabase.ts`: ينشئ عميل Supabase بمفتاح anon/publishable. لا تضع service-role key في المتصفح.
- `web/src/stores/auth.ts`: الجلسة الحالية وبيانات الاسم والدور والقسم من `user_profiles`.
- `web/src/router/index.ts`: المسارات وحارس تسجيل الدخول؛ يحول غير المسجل إلى `/login`.

### مكونات الواجهة والمسارات

`web/src/components/AppShell.vue` هو الإطار المشترك: الشريط الجانبي، الشعار، التنقل، معلومات المستخدم والخروج، شريط الصفحة، وانتقال لطيف بين المسارات. `StatusBadge.vue` يترجم حالة الماكينة ويستخدم لون الحالة الوظيفي.

| المسار | الشاشة | البيانات والسلوك |
| --- | --- | --- |
| `/login` | `views/LoginView.vue` | تسجيل البريد وكلمة المرور بواسطة Supabase Auth. |
| `/plant-floor` | `views/LivePlantView.vue` | يجمع الماكينات في الأقسام السبعة ويعرض اللون والحالة ومدة التوقف. الاشتراك Realtime على `machines` و`downtime_logs`. |
| `/machines/:id` | `views/MachineDetailView.vue` | السرعة والإنتاج، سجل التوقفات، وقطع BOM المرتبطة بالماكينة. |
| `/work-orders` | `views/WorkOrdersView.vue` | قائمة أوامر الشغل وفلاتر القسم والحالة والأولوية والنوع والفني؛ تتجدد عند تغييرات الجدول. |
| `/work-orders/:id` | `views/WorkOrderDetailView.vue` | تفاصيل الأمر والماكينة والأحداث والقطع والتسلسل التشغيلي. |
| `/downtime` | `views/DowntimeView.vue` | السجل، مدة التوقف الحية، وتسجيل/إغلاق التوقف بأدوار محددة عبر RPC. |
| `/spare-parts` | `views/SparePartsView.vue` | بحث المخزون، حد إعادة الطلب، وعدد قوائم الماكينات المرتبطة. |
| `/analytics` | `views/AnalyticsView.vue` | مؤشرات مجمعة، اتجاه التوافر، Pareto للتوقف، التوافر حسب القسم، funnel أوامر الشغل، دقائق الورديات، حالة الماكينات، وأسوأ الماكينات خلال 30 يومًا. فلتر القسم يحدّث الرسوم ذات البعد الخاص بالقسم. |

### التحليلات بالتفصيل

تعتمد التحليلات على عروض Supabase، وليست بيانات ثابتة محلية:

- KPI التوافر موزون بعدد الماكينات في آخر يوم متاح.
- إجمالي الماكينات العاملة والتوقفات النشطة ومددها يأتي من `v_machine_status_live`.
- الأوامر المفتوحة والمغلقة حسب حالة الـ workflow تأتي من `v_work_order_funnel`.
- MTTR موزون بعدد أوامر الصيانة المغلقة في كل قسم.
- الخط اليومي يعرض آخر سبعة أيام، وPareto يجمّع دقائق كل فئة توقف.
- توزيع الورديات يجمع دقائق الصباح والمساء والليل حسب اليوم.
- جدول الماكينات المتكررة يعرض الأعطال وزمن التوقف في نافذة 30 يومًا؛ الضغط على صف يفتح تفاصيل الماكينة.
- التحديث اليدوي متاح، كما تستمع الشاشة إلى تغييرات الماكينات والتوقفات وأوامر الشغل.

## 3. تطبيق Flutter للموبايل

### التشغيل والتهيئة

```powershell
cd mobile
flutter pub get
flutter run
```

إعداد Supabase موجود في `mobile/lib/core/config/supabase_config.dart`. يمكن تمرير الإعدادات وقت البناء دون وضع مفاتيح خاصة في المصدر:

```powershell
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-publishable-key
```

المفتاح المسموح في العميل هو anon/publishable فقط؛ حماية البيانات تأتي من جلسة المستخدم وسياسات RLS. لا تستخدم `service_role` في تطبيق الهاتف أو الويب.

### بدء التطبيق والحالة العامة

- `mobile/lib/main.dart`: يهيئ Flutter، Supabase، Hive، ثم Service Locator.
- `mobile/lib/app.dart`: يبني `MaterialApp`، العربية والإنجليزية، الثيم الفاتح/الداكن، Cubits، وحارس جلسة الدخول.
- `mobile/lib/core/di/service_locator.dart`: تسجيل المستودعات ومصادر البيانات وخدمات المزامنة عبر GetIt.
- `mobile/lib/core/navigation/`: التبويبات وشريط التنقل الجانبي/السفلي وإعدادات التبويب حسب الدور.
- `mobile/lib/core/localization/` و`core/theme/`: النصوص والترجمة والثيمات ولوحات الألوان.

### تقسيم الخصائص

كل ميزة تتبع غالبًا طبقات `data/`, `domain/`, و`presentation/`:

- `features/auth/`: تسجيل الدخول، ملف المستخدم، الدور، القسم، والقيود المعروضة حسب الدور.
- `features/assets/`: قائمة الماكينات، عرض الأقسام، مسح QR/الباركود، نموذج الماكينة وسجل التشغيل.
- `features/downtime/`: تصنيفات التوقف، تسجيل السبب، تقسيم الدقائق على الورديات، السجل، ومزامنة أوامر البدء/الإغلاق.
- `features/work_orders/`: إنشاء الطلب، الإسناد، بدء الإصلاح، إضافة القطع والسبب والإجراء، اختبار التشغيل، والإغلاق وسجل الأحداث.
- `features/analytics/`: حساب مؤشرات المصنع وOEE ومقارنة الأقسام وأسباب التوقف.
- `core/widgets/`: بطاقات مشتركة للحالة والمؤشرات والماكينات والتسلسل الزمني.

### Offline-first والمزامنة

`core/database/hive_service.dart` يسجل Adapters ويفتح صناديق Hive للماكينات والمستخدمين والتوقفات والأوامر والأحداث والإعدادات والـ outbox. يحتفظ `FactorySeedData` ببيانات أولية محلية حتى يظهر التطبيق قبل اكتمال أول مزامنة.

`SyncManager` ينسق العملية التالية بعد استعادة الجلسة أو الشبكة:

1. يرسل الأوامر المحلية المعلقة من Outbox إلى Supabase، ويحافظ على الترتيب لنفس السجل ومعرف الأمر لإعادة المحاولة الآمنة.
2. يجلب اللقطات أو التغييرات منذ آخر مؤشر مزامنة إلى Hive.
3. تستقبل خدمة Realtime أحداث الماكينات وأوامر الشغل والتوقفات، وتتجنب الكتابة فوق تغيير محلي لا يزال معلقًا.
4. يصنف محرك Outbox أخطاء النقل القابلة لإعادة المحاولة منفصلة عن رفض الصلاحية أو تعارض الإصدار، ثم يصالح الحالة من الخادم عند الرفض النهائي.

أوامر العمل والتوقف تستخدم RPC الموجودة في قاعدة البيانات بدل تعديل سجلات التدقيق مباشرة. الملفات تحت `data/datasources/` تحتوي تطبيق القراءة البعيدة والتحويل بين JSON والنماذج. ملفات `hive_*` تحفظ النسخة المحلية. الواجهات لا تتصل بقاعدة البيانات مباشرة؛ Cubit → Repository → DataSource.

### الاختبار

```powershell
cd mobile
flutter analyze
flutter test
flutter run -d chrome --no-pub
```

نجح آخر تحقق موثق في هذا الريبو بـ 91 اختبار Flutter و`flutter analyze` دون ملاحظات. تشغيل Windows desktop قد يحتاج Visual Studio C++ Build Tools؛ Chrome خيار تشغيل بديل.

## 4. قاعدة البيانات وSupabase

### ترتيب migrations

| الملف | المحتوى الرئيسي |
| --- | --- |
| `20260921000001_profiles_hardening.sql` | تشديد ملف المستخدم وصلاحيات تغييره. |
| `20260921000002_core_schema.sql` | الماكينات وأوامر الشغل والأحداث والقطع وسجلات التوقف. |
| `20260921000003_security_and_rls.sql` | دوال role/department وسياسات RLS والوصول حسب القسم/التعيين. |
| `20260921000004_workflow_commands.sql` | RPC انتقالات أوامر الشغل وسجل الأوامر غير القابل للتكرار. |
| `20260921000005_audit_and_machine_rules.sql` | مزامنة حالة الماكينة، حراسة سجلات التدقيق، RPC بدء/إغلاق التوقف. |
| `20260921000006_realtime.sql` | إدراج جداول التشغيل في نشر Realtime. |
| `20260921000007_composite_indexes.sql` | فهارس مساعدة للاستعلامات والسياسات. |
| `20260921000008_storage_attachments.sql` | bucket خاص بالمرفقات وسياساته ومحدد معدل لبعض العمليات. |
| `20260926000009_factory_catalog.sql` | الأقسام والأدوار المرجعية وقطع الغيار وBOM وسياسات الكتالوج. |
| `20260927000010_web_reporting_views.sql` | views حالة الماكينة وPareto والتوافر وMTTR وbad actors والورديات. |

توجد ملفات rollback المقابلة تحت `supabase/migrations_down/`. بيانات Auth الفعلية لا تُزرع في SQL؛ أنشئ الحسابات من Supabase Auth ثم اربطها بملف الدور والقسم وفق إجراء موثوق.

### الكيانات التشغيلية

| الجدول | المعنى |
| --- | --- |
| `user_profiles` | هوية Auth المقابلة والاسم والدور والقسم والتخصص/كود الموظف. |
| `machines` | كود واسم وقسم وحالة الماكينة وقياسات الإنتاج والصيانة. |
| `work_orders` | طلب الصيانة، نوعه وأولويته وحالته والماكينة والمسؤولون والتوقيت والسبب والإجراء ونسخة التزامن. `id` هو UUID؛ لا يوجد رقم تسلسلي `work_order_num` في العقد الحالي. |
| `work_order_commands` | سجل command UUID ومنفذه ونتيجته لمنع تكرار أثر إعادة الإرسال. |
| `work_order_events` | سجل انتقالات الأوامر immutable مع actor وpayload والأوقات. |
| `work_order_parts` | سجل القطع المستهلكة immutable؛ لا يحتوي حاليًا مرجعًا إلى `spare_parts.id` ولا يخفض المخزون تلقائيًا. |
| `downtime_logs` | سبب التوقف وتصنيفه والبداية/النهاية وتاريخ الإنتاج والوردية والـ chronology. |
| `factory_departments`, `factory_roles` | كتالوج مرجعي لأسماء الأقسام والأدوار وإتاحة الويب. ليستا مخزن هويات Auth. |
| `spare_parts` | كود ووصف ووحدة وكمية المخزون وحد إعادة الطلب وحقول إضافية حسب النسخة. |
| `machine_bom` | قطع الغيار المرجعية لكل ماكينة والكمية المطلوبة منها. |
| `storage.objects` | مرفقات خاصة بأوامر الشغل ضمن bucket محدود الحجم والامتدادات. |

تفاصيل الأعمدة ومصفوفات السياسات موجودة في [`SCHEMA.md`](SCHEMA.md). يشرح الملف أيضًا افتراضات التقارير وحدود دقتها.

### التقارير والـ views

- `v_machine_status_live`: حالة/سرعة/إنتاج الماكينة وأحدث توقف مفتوح.
- `v_downtime_pareto`: عدد أحداث التوقف وإجمالي/متوسط الدقائق حسب القسم والفئة.
- `v_work_order_funnel`: عدد أوامر الشغل بكل حالة.
- `v_line_availability_daily`: سبعة أيام × الأقسام، التوقف، وعدد الماكينات والتوافر المحسوب.
- `v_mttr_by_department`: عدد الأوامر المنتهية ومتوسط الزمن من البداية للإكمال.
- `v_bad_actors_30d`: الماكينات ذات الأعطال أو دقائق التوقف في آخر 30 يومًا.
- `v_shift_downtime_split`: دقائق الورديات الصباحية والمسائية والليلية لكل تاريخ/قسم.

تعتمد دقة التوافر على افتراض 1,440 دقيقة مجدولة لكل ماكينة يوميًا. أحداث التوقف القديمة التي لا تملك `shift_minutes` رقمية تُقدّر من المدة؛ لذلك لا تستخدم أرقام الماضي المقدرة لتسويات الرواتب أو تقارير OEE المحاسبية دون مراجعة.

### الأمان ومسارات الكتابة

- الجداول التشغيلية محمية بـ Row-Level Security؛ الواجهة تخفي الأزرار حسب الدور لتسهيل الاستخدام، لكن RLS وRPC هما حد الأمان الفعلي.
- الأدوار المرجعية تشمل `ADMIN`, `PLANT_MANAGER`, `SUPERVISOR`, `MAINTENANCE_SUPERVISOR`, `PRODUCTION_SUPERVISOR`, `TECHNICIAN`/`MAINTENANCE_TECH`, و`OPERATOR`. راجع policy لكل إجراء؛ لا تفترض أن أسماء الأدوار أو الصلاحيات متطابقة بين كل نسخة عميل.
- انتقالات أوامر الشغل تُنفذ عبر `rpc_create_work_order`, `rpc_assign_work_order`, `rpc_start_work_order`, `rpc_add_work_order_part`, `rpc_complete_work_order`, `rpc_confirm_test_run`, و`rpc_close_work_order`.
- التوقف يبدأ عبر `rpc_create_downtime_log` ويغلق عبر `rpc_close_downtime_log`. لا تُجرِ INSERT/UPDATE مباشرة من واجهة الويب.
- Realtime يستخدم أحداث الجداول المصدرية، ثم يعيد العميل جلب العرض/الاستعلام؛ الـ views نفسها ليست مصدر أحداث PostgreSQL.

## 5. إعداد البيئات والنشر

- `web/.env.local` محلي وغير مرفوع إلى Git؛ انسخ `web/.env.example` واضبط عنوان المشروع وanon/publishable key.
- مفاتيح `SUPABASE_URL` و`SUPABASE_ANON_KEY` للموبايل تُمرر عبر `--dart-define`. لا تحفظ كلمات مرور المستخدمين أو service-role key في الملفات.
- استخدم حسابات Auth واقعية وسياسات RLS معتمدة. بيانات `seed.sql` لأغراض إعداد/تطوير، ولا تضف fixtures تشغيلية إلى الإنتاج لمجرد اختبار الواجهة.
- إعداد الاستضافة للويب يكون بجذر المشروع `web` ومتغيرات `VITE_SUPABASE_URL` و`VITE_SUPABASE_ANON_KEY`.
- قاعدة الإنتاج لديها تاريخ migrations غير مطابق تمامًا للمجلد المحلي؛ بعض التغييرات طبقت يدويًا، وعروض التقرير كانت موجودة قبل ملف migration المحلي. **لا تشغل `supabase db push` ولا تعدل `supabase_migrations.schema_migrations` يدويًا** قبل snapshot للمخطط وخطة baseline ومراجعة واعتمادها.
- اختبر RPC التي تكتب وRLS والـ Realtime الفعلي في Supabase تطويري منفصل. القراءة الناجحة من الإنتاج لا تثبت أن الكتابة آمنة ولا أن كل السياسات طابقت ملفات SQL المحلية.

## 6. التحقق المتاح حاليًا

آخر تحقق آلي موثق: `flutter pub get` و`flutter analyze` و`flutter test` (91 اختبارًا) و`npm run build` جميعها نجحت. اختبار التوقف الحي وقطع الغيار وأرضية المصنع كان قرائيًا على بيانات Supabase؛ لم تُختبر كتابة RPC على الإنتاج. التحذير الوحيد في بناء الويب كان حجم chunk التحليلات قبل فصل ECharts؛ إعداد البناء الحالي يفصل ECharts عن شاشة التحليلات لتقليل ما يُحمّل مع بقية التطبيق.
