<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { supabase } from '../api/supabase'
import {
  departmentLabels,
  eventTypeLabel,
  formatDateTime,
  priorityInfo,
  shortId,
  statusClass,
  statusLabel,
  typeLabel,
} from '../lib/workOrders'

type Machine = { id: string; code: string; name: string; department: string }
type WorkOrder = {
  id: string
  title: string
  description: string | null
  machine_id: string
  type: string
  status: string
  priority: string
  reported_by: string | null
  assigned_to_technician_id: string | null
  assigned_by_supervisor_id: string | null
  started_at: string | null
  completed_at: string | null
  closed_at: string | null
  closed_by: string | null
  root_cause: string | null
  actions_taken: string | null
  chronology: Record<string, unknown> | null
  version: number
  created_at: string
  updated_at: string
  machine: Machine | Machine[] | null
}
type WorkOrderEvent = {
  id: string
  event_type: string
  actor_id: string | null
  occurred_at: string | null
  received_at: string | null
  old_status: string | null
  new_status: string | null
  payload: Record<string, unknown> | null
}
type WorkOrderPart = {
  id: string
  part_code: string | null
  part_name: string
  quantity: number
  unit_cost: number | null
  added_by: string | null
  occurred_at: string | null
  received_at: string | null
}

const route = useRoute()
const order = ref<WorkOrder | null>(null)
const events = ref<WorkOrderEvent[]>([])
const parts = ref<WorkOrderPart[]>([])
const people = ref<Record<string, string>>({})
const loading = ref(true)
const error = ref('')
const notFound = ref(false)
let currentRequest = 0

const machine = computed<Machine | null>(() => {
  const value = order.value?.machine
  if (!value) return null
  return Array.isArray(value) ? value[0] ?? null : value
})

const chronologyItems = computed(() => {
  const eventChronology = [...events.value].reverse()
    .map((event) => event.payload?.chronology)
    .find((entry): entry is Record<string, unknown> => Boolean(entry && typeof entry === 'object' && !Array.isArray(entry)))
  const value = order.value?.chronology ?? eventChronology
  if (!value) return []
  const shiftNames: Record<string, string> = {
    shift1_Morning: 'صباحية',
    shift2_Evening: 'مسائية',
    shift3_Night: 'ليلية',
  }
  const rawShift = value.activeShift
  return [
    { label: 'تاريخ الإنتاج', value: displayValue(value.productionDate) },
    { label: 'وقت المصنع', value: displayValue(value.plantTimeFormatted) },
    { label: 'الوردية', value: typeof rawShift === 'string' ? shiftNames[rawShift] ?? rawShift : '—' },
    { label: 'تم التسجيل دون اتصال', value: value.isOfflineGenerated === true ? 'نعم' : value.isOfflineGenerated === false ? 'لا' : '—' },
    { label: 'وقت المزامنة', value: displayValue(value.syncedAtUtc) },
  ].filter((item) => item.value !== '—')
})

function displayValue(value: unknown): string {
  if (typeof value === 'string' || typeof value === 'number') return String(value)
  return '—'
}

function personName(id: string | null, fallback?: unknown): string {
  if (!id) return typeof fallback === 'string' && fallback ? fallback : 'غير مسجل'
  return people.value[id] || (typeof fallback === 'string' && fallback ? fallback : `مستخدم #${shortId(id)}`)
}

function eventSummary(event: WorkOrderEvent): string {
  const summary = event.payload?.summary
  if (typeof summary === 'string' && summary.trim()) return summary
  if (event.old_status || event.new_status) {
    return `الحالة: ${statusLabel(event.old_status)} ← ${statusLabel(event.new_status)}`
  }
  return eventTypeLabel(event.event_type)
}

function eventActor(event: WorkOrderEvent): string {
  return personName(event.actor_id, event.payload?.actor_name)
}

function partAdder(part: WorkOrderPart): string {
  return personName(part.added_by)
}

async function load() {
  const request = ++currentRequest
  const rawId = route.params.id
  const id = Array.isArray(rawId) ? rawId[0] : rawId
  order.value = null
  events.value = []
  parts.value = []
  people.value = {}
  error.value = ''
  notFound.value = false
  loading.value = true

  if (!supabase) {
    error.value = 'إعداد Supabase غير مكتمل. أضف متغيرات البيئة المطلوبة.'
    loading.value = false
    return
  }
  if (typeof id !== 'string' || !id) {
    notFound.value = true
    loading.value = false
    return
  }

  try {
    const { data, error: orderError } = await supabase
      .from('work_orders')
      .select('id, title, description, machine_id, type, status, priority, reported_by, assigned_to_technician_id, assigned_by_supervisor_id, started_at, completed_at, closed_at, closed_by, root_cause, actions_taken, chronology, version, created_at, updated_at, machine:machines!work_orders_machine_id_fkey(id, code, name, department)')
      .eq('id', id)
      .maybeSingle()

    if (orderError) throw orderError
    if (request !== currentRequest) return
    if (!data) {
      notFound.value = true
      return
    }

    const [partsResult, eventsResult] = await Promise.all([
      supabase.from('work_order_parts').select('*').eq('work_order_id', id).order('occurred_at', { ascending: true }),
      supabase.from('work_order_events').select('*').eq('work_order_id', id).order('occurred_at', { ascending: true }),
    ])
    if (partsResult.error) throw partsResult.error
    if (eventsResult.error) throw eventsResult.error
    if (request !== currentRequest) return

    const workOrder = data as unknown as WorkOrder
    const workOrderEvents = (eventsResult.data ?? []) as unknown as WorkOrderEvent[]
    const workOrderParts = (partsResult.data ?? []) as unknown as WorkOrderPart[]
    order.value = workOrder
    events.value = workOrderEvents
    parts.value = workOrderParts

    const profileIds = [...new Set([
      workOrder.reported_by,
      workOrder.assigned_to_technician_id,
      workOrder.assigned_by_supervisor_id,
      workOrder.closed_by,
      ...workOrderEvents.map((event) => event.actor_id),
      ...workOrderParts.map((part) => part.added_by),
    ].filter((value): value is string => Boolean(value)))]

    if (profileIds.length) {
      const { data: profiles } = await supabase.from('user_profiles').select('id, full_name').in('id', profileIds)
      if (request !== currentRequest) return
      people.value = Object.fromEntries((profiles ?? []).map((profile) => [profile.id, profile.full_name]))
    }
  } catch (cause) {
    if (request === currentRequest) error.value = cause instanceof Error ? cause.message : 'تعذر تحميل تفاصيل أمر الشغل.'
  } finally {
    if (request === currentRequest) loading.value = false
  }
}

watch(() => route.params.id, () => void load(), { immediate: true })
</script>

<template>
  <section>
    <RouterLink to="/work-orders" class="mb-5 inline-flex items-center gap-2 text-sm font-semibold text-brand-dark hover:underline">العودة إلى أوامر الشغل</RouterLink>

    <p v-if="loading" class="rounded-xl border bg-white p-6 text-slate-500" role="status">جارٍ تحميل تفاصيل أمر الشغل…</p>
    <p v-else-if="error" class="rounded-lg bg-red-50 p-4 text-red-700" role="alert">{{ error }}</p>
    <div v-else-if="notFound || !order" class="rounded-xl border border-dashed bg-white p-8 text-center text-slate-500">لم يتم العثور على أمر الشغل</div>
    <template v-else>
      <header class="mb-6 rounded-2xl border bg-white p-5 shadow-sm md:p-7">
        <div class="flex flex-wrap items-start justify-between gap-4">
          <div class="min-w-0">
            <p class="font-mono text-sm text-slate-500">أمر شغل #{{ shortId(order.id) }}</p>
            <h1 class="mt-2 text-2xl font-bold text-brand-navy md:text-3xl">{{ order.title }}</h1>
            <p class="mt-2 text-sm text-slate-500">أُنشئ {{ formatDateTime(order.created_at) }}</p>
          </div>
          <div class="flex flex-wrap gap-2">
            <span class="rounded-full px-3 py-1.5 text-sm font-semibold" :class="statusClass(order.status)">{{ statusLabel(order.status) }}</span>
            <span class="rounded-full px-3 py-1.5 text-sm font-semibold" :class="priorityInfo(order.priority).className">{{ priorityInfo(order.priority).label }}</span>
          </div>
        </div>
      </header>

      <div class="grid gap-5 xl:grid-cols-[1.5fr_1fr]">
        <div class="space-y-5">
          <section class="rounded-xl border bg-white p-5">
            <h2 class="mb-4 text-lg font-bold">بيانات أمر الشغل</h2>
            <p class="whitespace-pre-wrap leading-7 text-slate-700">{{ order.description || 'لا يوجد وصف مسجل.' }}</p>
            <dl class="mt-5 grid gap-4 border-t pt-4 sm:grid-cols-2">
              <div><dt class="text-xs text-slate-500">الماكينة</dt><dd class="mt-1 font-semibold">{{ machine ? `${machine.code} — ${machine.name}` : shortId(order.machine_id) }}</dd></div>
              <div><dt class="text-xs text-slate-500">القسم</dt><dd class="mt-1 font-semibold">{{ departmentLabels[machine?.department ?? ''] ?? machine?.department ?? '—' }}</dd></div>
              <div><dt class="text-xs text-slate-500">النوع</dt><dd class="mt-1 font-semibold">{{ typeLabel(order.type) }}</dd></div>
              <div><dt class="text-xs text-slate-500">الأولوية</dt><dd class="mt-1 font-semibold">{{ priorityInfo(order.priority).label }}</dd></div>
              <div><dt class="text-xs text-slate-500">مقدم البلاغ</dt><dd class="mt-1 font-semibold">{{ personName(order.reported_by) }}</dd></div>
              <div><dt class="text-xs text-slate-500">الفني المكلّف</dt><dd class="mt-1 font-semibold">{{ personName(order.assigned_to_technician_id) }}</dd></div>
              <div><dt class="text-xs text-slate-500">تاريخ البدء</dt><dd class="mt-1 font-semibold">{{ formatDateTime(order.started_at) }}</dd></div>
              <div><dt class="text-xs text-slate-500">تاريخ الإكمال</dt><dd class="mt-1 font-semibold">{{ formatDateTime(order.completed_at) }}</dd></div>
              <div><dt class="text-xs text-slate-500">تاريخ الإغلاق</dt><dd class="mt-1 font-semibold">{{ formatDateTime(order.closed_at) }}</dd></div>
              <div><dt class="text-xs text-slate-500">الإصدار</dt><dd class="mt-1 font-semibold">{{ order.version }}</dd></div>
            </dl>
          </section>

          <section class="rounded-xl border bg-white p-5">
            <h2 class="mb-4 text-lg font-bold">السبب الجذري وإجراءات الإصلاح</h2>
            <div class="grid gap-4 md:grid-cols-2">
              <div class="rounded-lg bg-slate-50 p-4"><h3 class="text-sm font-semibold text-slate-600">السبب الجذري</h3><p class="mt-2 whitespace-pre-wrap text-sm leading-6">{{ order.root_cause || 'لم يُسجل بعد' }}</p></div>
              <div class="rounded-lg bg-slate-50 p-4"><h3 class="text-sm font-semibold text-slate-600">الإجراءات المتخذة</h3><p class="mt-2 whitespace-pre-wrap text-sm leading-6">{{ order.actions_taken || 'لم تُسجل بعد' }}</p></div>
            </div>
          </section>

          <section class="rounded-xl border bg-white p-5">
            <div class="mb-4 flex items-center justify-between gap-3">
              <h2 class="text-lg font-bold">سجل الأحداث</h2>
              <span class="rounded-full bg-slate-100 px-2.5 py-1 text-xs text-slate-600">{{ events.length }} أحداث</span>
            </div>
            <div v-if="!events.length" class="rounded-lg border border-dashed p-5 text-center text-sm text-slate-500">لا توجد أحداث مسجلة بعد</div>
            <div v-else class="space-y-0">
              <article v-for="(event, index) in events" :key="event.id" class="relative flex gap-4 pb-6 last:pb-0">
                <div class="relative flex w-4 shrink-0 justify-center">
                  <span class="mt-1.5 h-3 w-3 rounded-full border-2 border-brand bg-white"></span>
                  <span v-if="index < events.length - 1" class="absolute top-5 bottom-0 w-px bg-slate-200"></span>
                </div>
                <div class="min-w-0 flex-1">
                  <div class="flex flex-wrap items-start justify-between gap-2">
                    <h3 class="font-semibold">{{ eventTypeLabel(event.event_type) }}</h3>
                    <time class="text-xs text-slate-500">{{ formatDateTime(event.occurred_at || event.received_at) }}</time>
                  </div>
                  <p class="mt-1 text-sm leading-6 text-slate-600">{{ eventSummary(event) }}</p>
                  <p class="mt-2 text-xs text-slate-500">بواسطة {{ eventActor(event) }}</p>
                </div>
              </article>
            </div>
          </section>
        </div>

        <aside class="space-y-5">
          <section class="rounded-xl border bg-white p-5">
            <div class="mb-4 flex items-center justify-between gap-3">
              <h2 class="text-lg font-bold">قطع الغيار المستخدمة</h2>
              <span class="rounded-full bg-slate-100 px-2.5 py-1 text-xs text-slate-600">{{ parts.length }}</span>
            </div>
            <div v-if="!parts.length" class="rounded-lg border border-dashed p-5 text-center text-sm text-slate-500">لم تُسجل قطع غيار لهذا الأمر</div>
            <div v-else class="divide-y">
              <article v-for="part in parts" :key="part.id" class="py-4 first:pt-0 last:pb-0">
                <div class="flex items-start justify-between gap-3">
                  <div><h3 class="font-semibold">{{ part.part_name }}</h3><p v-if="part.part_code" class="mt-1 font-mono text-xs text-slate-500">{{ part.part_code }}</p></div>
                  <span class="shrink-0 rounded-full bg-sky-50 px-2.5 py-1 text-xs font-semibold text-sky-800">× {{ part.quantity }}</span>
                </div>
                <p v-if="part.unit_cost !== null" class="mt-2 text-xs text-slate-500">تكلفة الوحدة: {{ Number(part.unit_cost).toLocaleString('ar-EG') }}</p>
                <p class="mt-2 text-xs text-slate-500">أضيفت بواسطة {{ partAdder(part) }} · {{ formatDateTime(part.occurred_at || part.received_at) }}</p>
              </article>
            </div>
          </section>

          <section class="rounded-xl border bg-white p-5">
            <h2 class="mb-4 text-lg font-bold">التسلسل التشغيلي</h2>
            <div v-if="!chronologyItems.length" class="text-sm text-slate-500">لا توجد بيانات تسلسل تشغيلي مسجلة</div>
            <dl v-else class="space-y-3">
              <div v-for="item in chronologyItems" :key="item.label" class="flex items-start justify-between gap-3 border-b pb-3 last:border-0 last:pb-0">
                <dt class="text-sm text-slate-500">{{ item.label }}</dt><dd class="text-left text-sm font-semibold">{{ item.value }}</dd>
              </div>
            </dl>
          </section>
        </aside>
      </div>
    </template>
  </section>
</template>
