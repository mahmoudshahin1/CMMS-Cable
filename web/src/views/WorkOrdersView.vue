<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../api/supabase'
import {
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

const router = useRouter()
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

let channel: ReturnType<NonNullable<typeof supabase>['channel']> | null = null

const technicianOptions = computed(() => {
  const ids = [...new Set(rows.value.map((row) => row.assigned_to_technician_id).filter((id): id is string => Boolean(id)))].sort()
  return ids.map((id) => ({ id, name: people.value[id] || shortId(id) }))
})

const filteredRows = computed(() => rows.value.filter((row) => {
  const machine = machineOf(row)
  return (!departmentFilter.value || machine?.department === departmentFilter.value)
    && (!statusFilter.value || row.status === statusFilter.value)
    && (!priorityFilter.value || row.priority === priorityFilter.value)
    && (!typeFilter.value || row.type === typeFilter.value)
    && (!technicianFilter.value || row.assigned_to_technician_id === technicianFilter.value)
}))

function machineOf(row: WorkOrder): Machine | null {
  if (Array.isArray(row.machine)) return row.machine[0] ?? null
  return row.machine
}

function technicianName(id: string | null): string {
  if (!id) return 'غير مسند'
  return people.value[id] || `فني #${shortId(id)}`
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
    error.value = 'إعداد Supabase غير مكتمل. أضف متغيرات البيئة المطلوبة.'
    loading.value = false
    return
  }

  refreshing.value = !loading.value
  try {
    const { data, error: queryError } = await supabase
      .from('work_orders')
      .select('id, title, description, machine_id, type, status, priority, reported_by, assigned_to_technician_id, started_at, created_at, updated_at, machine:machines!work_orders_machine_id_fkey(code, name, department)')
      .order('created_at', { ascending: false })

    if (queryError) throw queryError
    const workOrders = (data ?? []) as unknown as WorkOrder[]
    rows.value = workOrders
    error.value = ''
    await loadProfiles(workOrders)
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'تعذر تحميل أوامر الشغل.'
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
      .on('postgres_changes', { event: '*', schema: 'public', table: 'work_orders' }, () => void refresh())
      .subscribe()
  }
})

onUnmounted(() => {
  if (supabase && channel) void supabase.removeChannel(channel)
})
</script>

<template>
  <section>
    <div class="mb-6 flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 class="mb-1 text-2xl font-bold">أوامر الشغل</h1>
        <p class="text-sm text-slate-500">متابعة أوامر الصيانة الحالية</p>
      </div>
      <p v-if="refreshing" class="text-xs text-slate-500" role="status">جارٍ تحديث البيانات…</p>
    </div>

    <p v-if="loading" class="rounded-xl border bg-white p-6 text-slate-500" role="status">جارٍ تحميل أوامر الشغل…</p>
    <p v-else-if="error && !rows.length" class="rounded-lg bg-red-50 p-4 text-red-700" role="alert">{{ error }}</p>
    <template v-else>
      <div class="mb-5 grid gap-3 rounded-xl border bg-white p-4 sm:grid-cols-2 xl:grid-cols-5">
        <label class="grid gap-1 text-sm font-semibold text-slate-700">
          القسم
          <select v-model="departmentFilter" class="rounded-lg border border-slate-300 bg-white px-3 py-2 font-normal focus:border-brand focus:outline-none">
            <option value="">كل الأقسام</option>
            <option v-for="(label, value) in departmentLabels" :key="value" :value="value">{{ label }}</option>
          </select>
        </label>
        <label class="grid gap-1 text-sm font-semibold text-slate-700">
          الحالة
          <select v-model="statusFilter" class="rounded-lg border border-slate-300 bg-white px-3 py-2 font-normal focus:border-brand focus:outline-none">
            <option value="">كل الحالات</option>
            <option v-for="status in workOrderStatuses" :key="status.value" :value="status.value">{{ status.label }}</option>
          </select>
        </label>
        <label class="grid gap-1 text-sm font-semibold text-slate-700">
          الأولوية
          <select v-model="priorityFilter" class="rounded-lg border border-slate-300 bg-white px-3 py-2 font-normal focus:border-brand focus:outline-none">
            <option value="">كل الأولويات</option>
            <option v-for="priority in workOrderPriorities" :key="priority.value" :value="priority.value">{{ priority.label }}</option>
          </select>
        </label>
        <label class="grid gap-1 text-sm font-semibold text-slate-700">
          النوع
          <select v-model="typeFilter" class="rounded-lg border border-slate-300 bg-white px-3 py-2 font-normal focus:border-brand focus:outline-none">
            <option value="">كل الأنواع</option>
            <option v-for="type in workOrderTypes" :key="type.value" :value="type.value">{{ type.label }}</option>
          </select>
        </label>
        <label class="grid gap-1 text-sm font-semibold text-slate-700">
          الفني المكلّف
          <select v-model="technicianFilter" class="rounded-lg border border-slate-300 bg-white px-3 py-2 font-normal focus:border-brand focus:outline-none">
            <option value="">كل الفنيين</option>
            <option v-for="technician in technicianOptions" :key="technician.id" :value="technician.id">{{ technician.name }}</option>
          </select>
        </label>
      </div>

      <p v-if="error" class="mb-4 rounded-lg bg-amber-50 p-3 text-sm text-amber-800" role="status">تعذر تحديث أحدث البيانات: {{ error }}</p>

      <div v-if="!rows.length" class="rounded-xl border border-dashed bg-white p-8 text-center text-slate-500">
        لا توجد أوامر شغل حاليًا
      </div>
      <div v-else-if="!filteredRows.length" class="rounded-xl border border-dashed bg-white p-8 text-center">
        <p class="text-slate-600">لا توجد أوامر شغل تطابق عوامل التصفية</p>
        <button class="mt-3 rounded-lg px-3 py-2 text-sm font-semibold text-brand-dark hover:bg-sky-50" @click="clearFilters">مسح عوامل التصفية</button>
      </div>
      <div v-else class="overflow-x-auto rounded-xl border bg-white shadow-sm">
        <table class="w-full min-w-[960px] text-right text-sm">
          <thead class="bg-slate-50 text-slate-600">
            <tr>
              <th class="p-3 font-semibold">رقم العرض</th>
              <th class="p-3 font-semibold">العنوان</th>
              <th class="p-3 font-semibold">الماكينة</th>
              <th class="p-3 font-semibold">القسم</th>
              <th class="p-3 font-semibold">الفني</th>
              <th class="p-3 font-semibold">النوع</th>
              <th class="p-3 font-semibold">الحالة</th>
              <th class="p-3 font-semibold">الأولوية</th>
              <th class="p-3 font-semibold">تاريخ الإنشاء</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="row in filteredRows"
              :key="row.id"
              class="cursor-pointer border-t transition hover:bg-sky-50/60 focus:bg-sky-50/60 focus:outline-none"
              tabindex="0"
              :aria-label="`فتح أمر الشغل ${shortId(row.id)}: ${row.title}`"
              @click="openWorkOrder(row.id)"
              @keydown.enter="openWorkOrder(row.id)"
            >
              <td class="p-3 font-mono text-xs text-brand-dark">#{{ shortId(row.id) }}</td>
              <td class="max-w-64 p-3 font-semibold text-slate-800">{{ row.title }}</td>
              <td class="p-3">{{ machineOf(row)?.code ?? shortId(row.machine_id) }}</td>
              <td class="p-3">{{ departmentLabels[machineOf(row)?.department ?? ''] ?? machineOf(row)?.department ?? '—' }}</td>
              <td class="p-3">{{ technicianName(row.assigned_to_technician_id) }}</td>
              <td class="p-3">{{ typeLabel(row.type) }}</td>
              <td class="p-3"><span class="rounded-full px-2.5 py-1 text-xs font-semibold" :class="statusClass(row.status)">{{ statusLabel(row.status) }}</span></td>
              <td class="p-3"><span class="rounded-full px-2.5 py-1 text-xs font-semibold" :class="priorityInfo(row.priority).className">{{ priorityInfo(row.priority).label }}</span></td>
              <td class="p-3 text-slate-600" :title="formatDateTime(row.created_at)">{{ relativeTime(row.created_at) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p v-if="rows.length" class="mt-3 text-xs text-slate-500">عرض {{ filteredRows.length }} من {{ rows.length }} أمر شغل</p>
    </template>
  </section>
</template>
