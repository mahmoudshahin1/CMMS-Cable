<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ClipboardX, Filter, SlidersHorizontal, X } from 'lucide-vue-next'
import { supabase } from '../api/supabase'
import {
  departmentLabel,
  departmentLabels,
  formatDateTime,
  priorityInfo,
  relativeTime,
  shortId,
  statusClass,
  statusLabel,
  typeLabel,
  workOrderPriorities,
  workOrderStatuses,
  workOrderTypes,
} from '../lib/workOrders'
import { useLocaleStore } from '../stores/locale'
import { createLiveRefresh } from '../lib/liveRefresh'

type Machine = { code: string; name: string; department: string }
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
  started_at: string | null
  created_at: string
  updated_at: string
  machine: Machine | Machine[] | null
}

// Cap the payload so the page stays fast as the table grows over the years.
const ROW_LIMIT = 500
const router = useRouter()
const locale = useLocaleStore()
const t = locale.t
const rows = ref<WorkOrder[]>([])
const people = ref<Record<string, string>>({})
const error = ref('')
const loading = ref(true)
const refreshing = ref(false)
const departmentFilter = ref('')
const statusFilter = ref('')
const priorityFilter = ref('')
const typeFilter = ref('')
const technicianFilter = ref('')
const showFilters = ref(false)
const departmentKeys = Object.keys(departmentLabels)

const liveRefresh = createLiveRefresh(refresh)
let channel: ReturnType<NonNullable<typeof supabase>['channel']> | null = null

const technicianOptions = computed(() => {
  const ids = [...new Set(rows.value.map((row) => row.assigned_to_technician_id).filter((id): id is string => Boolean(id)))].sort()
  return ids.map((id) => ({ id, name: people.value[id] || shortId(id) }))
})

const activeFilterCount = computed(() => [departmentFilter.value, statusFilter.value, priorityFilter.value, typeFilter.value, technicianFilter.value].filter(Boolean).length)

const filteredRows = computed(() => rows.value.filter((row) => {
  const machine = machineOf(row)
  return (!departmentFilter.value || machine?.department === departmentFilter.value)
    && (!statusFilter.value || row.status === statusFilter.value)
    && (!priorityFilter.value || row.priority === priorityFilter.value)
    && (!typeFilter.value || row.type === typeFilter.value)
    && (!technicianFilter.value || row.assigned_to_technician_id === technicianFilter.value)
}))

const truncated = computed(() => rows.value.length >= ROW_LIMIT)
const openCount = computed(() => rows.value.filter((r) => ['open', 'assigned', 'inProgress', 'pendingParts'].includes(r.status)).length)
const criticalCount = computed(() => rows.value.filter((r) => r.priority === 'critical' && !['verified', 'verifiedClosed'].includes(r.status)).length)
const completedTodayCount = computed(() => {
  const today = new Date(); today.setHours(0, 0, 0, 0)
  return rows.value.filter((r) => ['completed', 'verified', 'verifiedClosed'].includes(r.status) && new Date(r.updated_at) >= today).length
})

function machineOf(row: WorkOrder): Machine | null {
  if (Array.isArray(row.machine)) return row.machine[0] ?? null
  return row.machine
}

function technicianName(id: string | null): string {
  if (!id) return t('workOrders.unassigned')
  return people.value[id] || `${t('workOrders.techPrefix')}${shortId(id)}`
}

function openWorkOrder(id: string) {
  void router.push(`/work-orders/${id}`)
}

async function loadProfiles(workOrders: WorkOrder[]) {
  if (!supabase) return
  const ids = [...new Set(workOrders.map((row) => row.assigned_to_technician_id).filter((id): id is string => Boolean(id)))]
  if (!ids.length) {
    people.value = {}
    return
  }

  const { data } = await supabase.from('user_profiles').select('id, full_name').in('id', ids)
  people.value = Object.fromEntries((data ?? []).map((profile) => [profile.id, profile.full_name]))
}

async function refresh() {
  if (!supabase) {
    error.value = t('workOrders.supabaseMissing')
    loading.value = false
    return
  }

  refreshing.value = !loading.value
  try {
    const { data, error: queryError } = await supabase
      .from('work_orders')
      .select('id, title, description, machine_id, type, status, priority, reported_by, assigned_to_technician_id, started_at, created_at, updated_at, machine:machines!work_orders_machine_id_fkey(code, name, department)')
      .order('created_at', { ascending: false })
      .limit(ROW_LIMIT)

    if (queryError) throw queryError
    const workOrders = (data ?? []) as unknown as WorkOrder[]
    rows.value = workOrders
    error.value = ''
    await loadProfiles(workOrders)
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : t('workOrders.loadListError')
  } finally {
    loading.value = false
    refreshing.value = false
  }
}

function clearFilters() {
  departmentFilter.value = ''
  statusFilter.value = ''
  priorityFilter.value = ''
  typeFilter.value = ''
  technicianFilter.value = ''
}

onMounted(() => {
  void refresh()
  if (supabase) {
    channel = supabase
      .channel('web-work-orders')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'work_orders' }, () => liveRefresh.request())
      .subscribe()
  }
})

onUnmounted(() => { liveRefresh.dispose();
  if (supabase && channel) void supabase.removeChannel(channel)
})
</script>

<template>
  <section :dir="locale.direction">
    <div class="mb-5 flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 class="mb-1 text-2xl font-bold text-brand-navy">{{ t('workOrders.title') }}</h1>
        <p class="text-sm text-slate-500">{{ t('workOrders.subtitle') }}</p>
      </div>
      <p v-if="refreshing" class="flex items-center gap-1.5 text-xs text-slate-500" role="status"><i class="h-1.5 w-1.5 animate-pulse rounded-full bg-brand"></i>{{ t('workOrders.refresh') }}</p>
    </div>

    <p v-if="loading" class="rounded-xl border bg-white p-6 text-slate-500" role="status">{{ t('workOrders.loading') }}</p>
    <p v-else-if="error && !rows.length" class="rounded-lg bg-accent-50 p-4 text-accent-dark" role="alert">{{ error }}</p>
    <template v-else>
      <!-- quick-glance summary strip -->
      <div class="mb-5 grid grid-cols-3 gap-3 rise-in">
        <div class="surface-card flex items-center gap-3 p-4"><span class="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-brand-50 text-brand"><ClipboardX :size="18" /></span><div><p class="text-xl font-extrabold text-brand-navy">{{ openCount }}</p><p class="text-[11px] text-slate-500">{{ t('workOrders.openOrders') }}</p></div></div>
        <div class="surface-card flex items-center gap-3 p-4"><span class="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-accent-50 text-accent-dark"><Filter :size="18" /></span><div><p class="text-xl font-extrabold text-accent-dark">{{ criticalCount }}</p><p class="text-[11px] text-slate-500">{{ t('workOrders.criticalOpen') }}</p></div></div>
        <div class="surface-card flex items-center gap-3 p-4"><span class="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-emerald-50 text-emerald-700"><SlidersHorizontal :size="18" /></span><div><p class="text-xl font-extrabold text-emerald-700">{{ completedTodayCount }}</p><p class="text-[11px] text-slate-500">{{ t('workOrders.closedToday') }}</p></div></div>
      </div>

      <!-- filter toolbar -->
      <div class="surface-card mb-5 overflow-hidden">
        <button class="flex w-full items-center justify-between gap-3 p-4 text-sm font-bold text-brand-navy" @click="showFilters = !showFilters">
          <span class="flex items-center gap-2"><SlidersHorizontal :size="16" class="text-brand" />{{ t('workOrders.filters') }}<span v-if="activeFilterCount" class="grid h-5 w-5 place-items-center rounded-full bg-accent text-[10px] font-extrabold text-white">{{ activeFilterCount }}</span></span>
          <span class="text-xs font-semibold text-slate-400">{{ showFilters ? t('workOrders.hide') : t('workOrders.show') }}</span>
        </button>
        <div v-show="showFilters" class="grid gap-3 border-t border-slate-100 p-4 sm:grid-cols-2 xl:grid-cols-5">
          <label class="grid gap-1 text-sm font-semibold text-slate-700">
            {{ t('workOrders.department') }}
            <select v-model="departmentFilter" class="rounded-lg border border-slate-300 bg-white px-3 py-2 font-normal focus:border-brand focus:outline-none">
              <option value="">{{ t('workOrders.allDepartments') }}</option>
              <option v-for="value in departmentKeys" :key="value" :value="value">{{ departmentLabel(value, locale.locale) }}</option>
            </select>
          </label>
          <label class="grid gap-1 text-sm font-semibold text-slate-700">
            {{ t('workOrders.status') }}
            <select v-model="statusFilter" class="rounded-lg border border-slate-300 bg-white px-3 py-2 font-normal focus:border-brand focus:outline-none">
              <option value="">{{ t('workOrders.allStatuses') }}</option>
              <option v-for="status in workOrderStatuses" :key="status.value" :value="status.value">{{ statusLabel(status.value, locale.locale) }}</option>
            </select>
          </label>
          <label class="grid gap-1 text-sm font-semibold text-slate-700">
            {{ t('workOrders.priority') }}
            <select v-model="priorityFilter" class="rounded-lg border border-slate-300 bg-white px-3 py-2 font-normal focus:border-brand focus:outline-none">
              <option value="">{{ t('workOrders.allPriorities') }}</option>
              <option v-for="priority in workOrderPriorities" :key="priority.value" :value="priority.value">{{ priorityInfo(priority.value, locale.locale).label }}</option>
            </select>
          </label>
          <label class="grid gap-1 text-sm font-semibold text-slate-700">
            {{ t('workOrders.type') }}
            <select v-model="typeFilter" class="rounded-lg border border-slate-300 bg-white px-3 py-2 font-normal focus:border-brand focus:outline-none">
              <option value="">{{ t('workOrders.allTypes') }}</option>
              <option v-for="type in workOrderTypes" :key="type.value" :value="type.value">{{ typeLabel(type.value, locale.locale) }}</option>
            </select>
          </label>
          <label class="grid gap-1 text-sm font-semibold text-slate-700">
            {{ t('workOrders.technician') }}
            <select v-model="technicianFilter" class="rounded-lg border border-slate-300 bg-white px-3 py-2 font-normal focus:border-brand focus:outline-none">
              <option value="">{{ t('workOrders.allTechnicians') }}</option>
              <option v-for="technician in technicianOptions" :key="technician.id" :value="technician.id">{{ technician.name }}</option>
            </select>
          </label>
          <button v-if="activeFilterCount" class="inline-flex items-center gap-1.5 self-end text-xs font-bold text-accent-dark hover:underline sm:col-span-2 xl:col-span-5" @click="clearFilters"><X :size="13" />{{ t('workOrders.clear') }}</button>
        </div>
      </div>

      <p v-if="error" class="mb-4 rounded-lg bg-amber-50 p-3 text-sm text-amber-800" role="status">{{ t('workOrders.refreshError') }} {{ error }}</p>

      <div v-if="!rows.length" class="rounded-xl border border-dashed bg-white p-8 text-center text-slate-500">
        {{ t('workOrders.empty') }}
      </div>
      <div v-else-if="!filteredRows.length" class="rounded-xl border border-dashed bg-white p-8 text-center">
        <p class="text-slate-600">{{ t('workOrders.noMatch') }}</p>
        <button class="mt-3 rounded-lg px-3 py-2 text-sm font-semibold text-brand-dark hover:bg-brand-50" @click="clearFilters">{{ t('workOrders.clear') }}</button>
      </div>
      <div v-else class="table-scroll overflow-x-auto rounded-xl border bg-white shadow-sm">
        <table class="w-full min-w-[960px] text-start text-sm">
          <thead class="bg-slate-50 text-slate-600">
            <tr>
              <th class="p-3 font-semibold">{{ t('workOrders.id') }}</th>
              <th class="p-3 font-semibold">{{ t('workOrders.heading') }}</th>
              <th class="p-3 font-semibold">{{ t('workOrders.machine') }}</th>
              <th class="p-3 font-semibold">{{ t('workOrders.department') }}</th>
              <th class="p-3 font-semibold">{{ t('workOrders.assignee') }}</th>
              <th class="p-3 font-semibold">{{ t('workOrders.type') }}</th>
              <th class="p-3 font-semibold">{{ t('workOrders.status') }}</th>
              <th class="p-3 font-semibold">{{ t('workOrders.priority') }}</th>
              <th class="p-3 font-semibold">{{ t('workOrders.created') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="(row, ri) in filteredRows"
              :key="row.id"
              class="group cursor-pointer border-t border-s-2 border-s-transparent transition duration-150 hover:border-s-accent hover:bg-brand-50/50 focus:bg-brand-50/50 focus:outline-none"
              :style="{ '--rise-delay': `${Math.min(ri, 14) * 28}ms` }"
              tabindex="0"
              :aria-label="`${t('workOrders.openAria')} ${shortId(row.id)}: ${row.title}`"
              @click="openWorkOrder(row.id)"
              @keydown.enter="openWorkOrder(row.id)"
            >
              <td class="p-3 font-mono text-xs text-brand-dark">#{{ shortId(row.id) }}</td>
              <td class="max-w-64 truncate p-3 font-semibold text-slate-800">{{ row.title }}</td>
              <td class="p-3">{{ machineOf(row)?.code ?? shortId(row.machine_id) }}</td>
              <td class="p-3">{{ departmentLabel(machineOf(row)?.department, locale.locale) }}</td>
              <td class="p-3">{{ technicianName(row.assigned_to_technician_id) }}</td>
              <td class="p-3">{{ typeLabel(row.type, locale.locale) }}</td>
              <td class="p-3"><span class="rounded-full px-2.5 py-1 text-xs font-semibold" :class="statusClass(row.status)">{{ statusLabel(row.status, locale.locale) }}</span></td>
              <td class="p-3"><span class="inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-semibold" :class="priorityInfo(row.priority, locale.locale).className"><i v-if="row.priority === 'critical'" class="h-1.5 w-1.5 animate-pulse rounded-full bg-current"></i>{{ priorityInfo(row.priority, locale.locale).label }}</span></td>
              <td class="p-3 text-slate-600" :title="formatDateTime(row.created_at, locale.locale)">{{ relativeTime(row.created_at, locale.locale) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p v-if="truncated" class="mt-3 rounded-lg bg-amber-50 p-2.5 text-xs text-amber-800">{{ t('workOrders.truncated').replace('{n}', String(ROW_LIMIT)) }}</p>
      <p v-if="rows.length" class="mt-3 text-xs text-slate-500">{{ t('workOrders.count') }} {{ filteredRows.length }} {{ t('workOrders.of') }} {{ rows.length }} {{ t('workOrders.orders') }}</p>
    </template>
  </section>
</template>
