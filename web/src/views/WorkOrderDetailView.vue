<script setup lang="ts">
import { computed, onUnmounted, ref, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import type { RealtimeChannel } from '@supabase/supabase-js'
import { supabase } from '../api/supabase'
import { useAuthStore } from '../stores/auth'
import { useLocaleStore } from '../stores/locale'
import { WORK_ORDER_ASSIGN_ROLES, WORK_ORDER_CLOSE_ROLES } from '../lib/roles'
import { assignWorkOrder, closeWorkOrder, fetchTechnicians, type Technician } from '../lib/workOrders'
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
const auth = useAuthStore()
const locale = useLocaleStore()
const t = locale.t
const order = ref<WorkOrder | null>(null)
const events = ref<WorkOrderEvent[]>([])
const parts = ref<WorkOrderPart[]>([])
const people = ref<Record<string, string>>({})
const loading = ref(true)
const error = ref('')
const notFound = ref(false)
const notice = ref('')
const actionError = ref('')
const assignDialogOpen = ref(false)
const closeDialogOpen = ref(false)
const technicians = ref<Technician[]>([])
const techniciansLoading = ref(false)
const actionLoading = ref(false)
const selectedTechnician = ref('')
const closeComments = ref('')
const realtimeConnected = ref(false)
let currentRequest = 0
let detailChannel: RealtimeChannel | null = null

const canAssign = computed(() => Boolean(order.value)
  && (WORK_ORDER_ASSIGN_ROLES as readonly string[]).includes(auth.role.toUpperCase())
  && ['open', 'assigned'].includes(order.value!.status))
const canClose = computed(() => Boolean(order.value)
  && (WORK_ORDER_CLOSE_ROLES as readonly string[]).includes(auth.role.toUpperCase())
  && ['completed', 'verified'].includes(order.value!.status))

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
    return `${locale.locale === 'ar' ? 'Status' : 'Status'}: ${statusLabel(event.old_status, locale.locale)} ← ${statusLabel(event.new_status, locale.locale)}`
  }
  return eventTypeLabel(event.event_type, locale.locale)
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

async function openAssignDialog() {
  assignDialogOpen.value = true
  actionError.value = ''
  techniciansLoading.value = true
  try {
    technicians.value = await fetchTechnicians()
    selectedTechnician.value = order.value?.assigned_to_technician_id ?? technicians.value[0]?.id ?? ''
  } catch (cause) {
    actionError.value = cause instanceof Error ? cause.message : 'تعذر تحميل قائمة الفنيين.'
  } finally {
    techniciansLoading.value = false
  }
}

function isVersionConflict(cause: unknown) {
  const message = cause instanceof Error ? cause.message : String(cause)
  return /version mismatch|conflict|40001/i.test(message)
}

async function submitAssignment() {
  if (!order.value || !selectedTechnician.value || !canAssign.value) return
  actionLoading.value = true
  actionError.value = ''
  notice.value = ''
  try {
    await assignWorkOrder(order.value, selectedTechnician.value)
    assignDialogOpen.value = false
      notice.value = t('workOrders.assignedSuccess')
    await load()
  } catch (cause) {
    if (isVersionConflict(cause)) {
      await load()
      notice.value = t('workOrders.conflict')
    } else actionError.value = cause instanceof Error ? cause.message : 'تعذر إسناد أمر الشغل.'
  } finally {
    actionLoading.value = false
  }
}

async function submitClose() {
  if (!order.value || !canClose.value) return
  actionLoading.value = true
  actionError.value = ''
  notice.value = ''
  try {
    await closeWorkOrder(order.value, closeComments.value)
    closeDialogOpen.value = false
    closeComments.value = ''
      notice.value = t('workOrders.closedSuccess')
    await load()
  } catch (cause) {
    if (isVersionConflict(cause)) {
      await load()
      notice.value = t('workOrders.conflict')
    } else actionError.value = cause instanceof Error ? cause.message : 'تعذر إغلاق أمر الشغل.'
  } finally {
    actionLoading.value = false
  }
}

watch(() => route.params.id, async () => {
  if (supabase && detailChannel) {
    await supabase.removeChannel(detailChannel)
    detailChannel = null
  }
  realtimeConnected.value = false
  await load()

  const rawId = route.params.id
  const id = Array.isArray(rawId) ? rawId[0] : rawId
  if (!supabase || typeof id !== 'string' || !id) return

  detailChannel = supabase.channel(`wo-detail-${id}`)
    .on('postgres_changes', { event: '*', schema: 'public', table: 'work_orders', filter: `id=eq.${id}` }, () => void load())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'work_order_events', filter: `work_order_id=eq.${id}` }, () => void load())
    .subscribe((status) => { realtimeConnected.value = status === 'SUBSCRIBED' })
}, { immediate: true })

onUnmounted(() => {
  if (supabase && detailChannel) void supabase.removeChannel(detailChannel)
})
</script>

<template>
  <section :dir="locale.direction">
    <RouterLink to="/work-orders" class="mb-5 inline-flex items-center gap-2 text-sm font-semibold text-brand-dark hover:underline">{{ t('workOrders.back') }}</RouterLink>

    <p v-if="loading" class="rounded-xl border bg-white p-6 text-slate-500" role="status">جارٍ تحميل تفاصيل أمر الشغل…</p>
    <p v-else-if="error" class="rounded-lg bg-red-50 p-4 text-red-700" role="alert">{{ error }}</p>
    <div v-else-if="notFound || !order" class="rounded-xl border border-dashed bg-white p-8 text-center text-slate-500">لم يتم العثور على أمر الشغل</div>
    <template v-else>
      <div v-if="notice || actionError" class="mb-4 space-y-2">
        <p v-if="notice" class="rounded-lg bg-emerald-50 p-3 text-sm text-emerald-800" role="status">{{ notice }}</p>
        <p v-if="actionError" class="rounded-lg bg-red-50 p-3 text-sm text-red-700" role="alert">{{ actionError }}</p>
      </div>
      <header class="mb-6 rounded-2xl border bg-white p-5 shadow-sm md:p-7">
        <div class="flex flex-wrap items-start justify-between gap-4">
          <div class="min-w-0">
            <p class="font-mono text-sm text-slate-500">{{ locale.locale === 'ar' ? 'أمر شغل' : 'Work Order' }} #{{ shortId(order.id) }}</p>
            <h1 class="mt-2 text-2xl font-bold text-brand-navy md:text-3xl">{{ order.title }}</h1>
            <p class="mt-2 text-sm text-slate-500">{{ locale.locale === 'ar' ? 'أُنشئ' : 'Created' }} {{ formatDateTime(order.created_at, locale.locale) }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <span class="rounded-full px-3 py-1.5 text-sm font-semibold" :class="statusClass(order.status)">{{ statusLabel(order.status, locale.locale) }}</span>
            <span class="rounded-full px-3 py-1.5 text-sm font-semibold" :class="priorityInfo(order.priority, locale.locale).className">{{ priorityInfo(order.priority, locale.locale).label }}</span>
            <button v-if="canAssign" class="rounded-lg bg-brand px-3 py-1.5 text-sm font-semibold text-white hover:bg-brand-dark" @click="openAssignDialog">{{ order.assigned_to_technician_id ? t('workOrders.changeTech') : t('workOrders.assign') }}</button>
            <button v-if="canClose" class="rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-1.5 text-sm font-semibold text-emerald-800 hover:bg-emerald-100" @click="closeDialogOpen = true; actionError = ''">{{ t('workOrders.close') }}</button>
          </div>
        </div>
      </header>

      <div class="grid gap-5 xl:grid-cols-[1.5fr_1fr]">
        <div class="space-y-5">
          <section class="rounded-xl border bg-white p-5">
            <h2 class="mb-4 text-lg font-bold">{{ t('workOrders.details') }}</h2>
            <p class="whitespace-pre-wrap leading-7 text-slate-700">{{ order.description || t('workOrders.noDescription') }}</p>
            <dl class="mt-5 grid gap-4 border-t pt-4 sm:grid-cols-2">
              <div><dt class="text-xs text-slate-500">{{ t('workOrders.machine') }}</dt><dd class="mt-1 font-semibold">{{ machine ? `${machine.code} — ${machine.name}` : shortId(order.machine_id) }}</dd></div>
              <div><dt class="text-xs text-slate-500">{{ t('workOrders.department') }}</dt><dd class="mt-1 font-semibold">{{ departmentLabels[machine?.department ?? ''] ?? machine?.department ?? '—' }}</dd></div>
              <div><dt class="text-xs text-slate-500">{{ t('workOrders.type') }}</dt><dd class="mt-1 font-semibold">{{ typeLabel(order.type, locale.locale) }}</dd></div>
              <div><dt class="text-xs text-slate-500">{{ t('workOrders.priority') }}</dt><dd class="mt-1 font-semibold">{{ priorityInfo(order.priority, locale.locale).label }}</dd></div>
              <div><dt class="text-xs text-slate-500">{{ t('workOrders.reporter') }}</dt><dd class="mt-1 font-semibold">{{ personName(order.reported_by) }}</dd></div>
              <div><dt class="text-xs text-slate-500">{{ t('workOrders.technician') }}</dt><dd class="mt-1 font-semibold">{{ personName(order.assigned_to_technician_id) }}</dd></div>
              <div><dt class="text-xs text-slate-500">{{ t('workOrders.started') }}</dt><dd class="mt-1 font-semibold">{{ formatDateTime(order.started_at, locale.locale) }}</dd></div>
              <div><dt class="text-xs text-slate-500">{{ t('workOrders.completed') }}</dt><dd class="mt-1 font-semibold">{{ formatDateTime(order.completed_at, locale.locale) }}</dd></div>
              <div><dt class="text-xs text-slate-500">{{ t('workOrders.closed') }}</dt><dd class="mt-1 font-semibold">{{ formatDateTime(order.closed_at, locale.locale) }}</dd></div>
              <div><dt class="text-xs text-slate-500">{{ t('workOrders.version') }}</dt><dd class="mt-1 font-semibold">{{ order.version }}</dd></div>
            </dl>
          </section>

          <section class="rounded-xl border bg-white p-5">
            <h2 class="mb-4 text-lg font-bold">{{ t('workOrders.rootActions') }}</h2>
            <div class="grid gap-4 md:grid-cols-2">
              <div class="rounded-lg bg-slate-50 p-4"><h3 class="text-sm font-semibold text-slate-600">{{ t('workOrders.root') }}</h3><p class="mt-2 whitespace-pre-wrap text-sm leading-6">{{ order.root_cause || t('workOrders.notEntered') }}</p></div>
              <div class="rounded-lg bg-slate-50 p-4"><h3 class="text-sm font-semibold text-slate-600">{{ t('workOrders.actions') }}</h3><p class="mt-2 whitespace-pre-wrap text-sm leading-6">{{ order.actions_taken || t('workOrders.notEnteredF') }}</p></div>
            </div>
          </section>

          <section class="rounded-xl border bg-white p-5">
            <div class="mb-4 flex items-center justify-between gap-3">
              <div class="flex items-center gap-3"><h2 class="text-lg font-bold">{{ t('workOrders.events') }}</h2><span class="inline-flex items-center gap-1.5 text-xs" :class="realtimeConnected ? 'text-emerald-700' : 'text-slate-400'"><span class="h-2 w-2 rounded-full" :class="realtimeConnected ? 'bg-emerald-500' : 'bg-slate-300'"></span>{{ realtimeConnected ? t('workOrders.live') : t('workOrders.disconnected') }}</span></div>
              <span class="rounded-full bg-slate-100 px-2.5 py-1 text-xs text-slate-600">{{ events.length }} {{ t('workOrders.eventCount') }}</span>
            </div>
            <div v-if="!events.length" class="rounded-lg border border-dashed p-5 text-center text-sm text-slate-500">{{ t('workOrders.noEvents') }}</div>
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
              <h2 class="text-lg font-bold">{{ t('workOrders.parts') }}</h2>
              <span class="rounded-full bg-slate-100 px-2.5 py-1 text-xs text-slate-600">{{ parts.length }}</span>
            </div>
            <div v-if="!parts.length" class="rounded-lg border border-dashed p-5 text-center text-sm text-slate-500">{{ t('workOrders.noParts') }}</div>
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
            <h2 class="mb-4 text-lg font-bold">{{ t('workOrders.timeline') }}</h2>
            <div v-if="!chronologyItems.length" class="text-sm text-slate-500">{{ t('workOrders.noTimeline') }}</div>
            <dl v-else class="space-y-3">
              <div v-for="item in chronologyItems" :key="item.label" class="flex items-start justify-between gap-3 border-b pb-3 last:border-0 last:pb-0">
                <dt class="text-sm text-slate-500">{{ item.label }}</dt><dd class="text-left text-sm font-semibold">{{ item.value }}</dd>
              </div>
            </dl>
          </section>
        </aside>
      </div>
    </template>

    <div v-if="assignDialogOpen" class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/50 p-4" @click.self="assignDialogOpen = false">
      <section role="dialog" aria-modal="true" aria-labelledby="assign-title" class="w-full max-w-lg rounded-2xl bg-white p-6 shadow-xl">
        <div class="mb-5 flex items-center justify-between gap-3"><h2 id="assign-title" class="text-xl font-bold">{{ t('workOrders.assignTitle') }}</h2><button class="rounded-lg px-3 py-1 text-slate-500 hover:bg-slate-100" aria-label="Close" @click="assignDialogOpen = false">×</button></div>
        <p v-if="techniciansLoading" class="py-5 text-sm text-slate-500" role="status">{{ t('workOrders.loadingTechs') }}</p>
        <template v-else>
          <label class="block text-sm font-medium">{{ t('workOrders.technician') }}
            <select v-model="selectedTechnician" class="mt-2 block w-full rounded-lg border-slate-300" :disabled="!technicians.length">
              <option v-for="technician in technicians" :key="technician.id" :value="technician.id">{{ technician.full_name }}<template v-if="technician.specialty"> — {{ technician.specialty }}</template></option>
            </select>
          </label>
          <p v-if="!technicians.length" class="mt-3 text-sm text-amber-700">{{ t('workOrders.noTechs') }}</p>
        </template>
        <p v-if="actionError" class="mt-3 rounded-lg bg-red-50 p-3 text-sm text-red-700" role="alert">{{ actionError }}</p>
        <div class="mt-6 flex justify-end gap-2"><button class="rounded-lg border px-4 py-2 text-sm" @click="assignDialogOpen = false">{{ t('workOrders.cancel') }}</button><button :disabled="actionLoading || techniciansLoading || !selectedTechnician" class="rounded-lg bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50" @click="submitAssignment">{{ actionLoading ? t('workOrders.assigning') : t('workOrders.confirmAssign') }}</button></div>
      </section>
    </div>

    <div v-if="closeDialogOpen" class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/50 p-4" @click.self="closeDialogOpen = false">
      <section role="dialog" aria-modal="true" aria-labelledby="close-title" class="w-full max-w-xl rounded-2xl bg-white p-6 shadow-xl">
        <div class="mb-5 flex items-center justify-between gap-3"><h2 id="close-title" class="text-xl font-bold">{{ t('workOrders.closeTitle') }}</h2><button class="rounded-lg px-3 py-1 text-slate-500 hover:bg-slate-100" aria-label="Close" @click="closeDialogOpen = false">×</button></div>
        <div class="grid gap-3 rounded-xl bg-slate-50 p-4 text-sm md:grid-cols-2"><div><p class="font-semibold text-slate-600">{{ t('workOrders.root') }}</p><p class="mt-1 whitespace-pre-wrap">{{ order?.root_cause || t('workOrders.notEntered') }}</p></div><div><p class="font-semibold text-slate-600">{{ t('workOrders.actions') }}</p><p class="mt-1 whitespace-pre-wrap">{{ order?.actions_taken || t('workOrders.notEnteredF') }}</p></div></div>
        <label class="mt-4 block text-sm font-medium">{{ t('workOrders.closeNotes') }}<textarea v-model="closeComments" rows="3" maxlength="2000" class="mt-2 block w-full rounded-lg border-slate-300" :placeholder="t('workOrders.closePlaceholder')" /></label>
        <p v-if="actionError" class="mt-3 rounded-lg bg-red-50 p-3 text-sm text-red-700" role="alert">{{ actionError }}</p>
        <div class="mt-6 flex justify-end gap-2"><button class="rounded-lg border px-4 py-2 text-sm" @click="closeDialogOpen = false">{{ t('workOrders.cancel') }}</button><button :disabled="actionLoading" class="rounded-lg bg-emerald-700 px-4 py-2 text-sm font-semibold text-white disabled:opacity-50" @click="submitClose">{{ actionLoading ? t('workOrders.closing') : t('workOrders.confirmClose') }}</button></div>
      </section>
    </div>
  </section>
</template>
