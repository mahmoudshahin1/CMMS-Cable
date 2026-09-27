<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import type { RealtimeChannel } from '@supabase/supabase-js'
import { supabase } from '../api/supabase'
import { useAuthStore } from '../stores/auth'
import type { Machine } from '../stores/liveMonitoring'
import { departmentLabels } from '../lib/workOrders'
import { buildChronology, calculateShiftMinutes, downtimeCategories, downtimeCategoryLabel, formatCairoDate } from '../lib/downtime'

type Downtime = { id: string; machine_id: string; category: string | null; reason: string; is_maintenance_requested: boolean; comments: string | null; started_at: string; ended_at: string | null; work_order_id: string | null }
const auth = useAuthStore()
const route = useRoute()
const logs = ref<Downtime[]>([])
const machines = ref<Machine[]>([])
const loading = ref(true)
const saving = ref(false)
const error = ref('')
const notice = ref('')
const now = ref(Date.now())
const form = ref({ machineId: String(route.query.machine ?? ''), category: 'processSetup', reason: '', comments: '', maintenanceRequested: false })
const role = computed(() => auth.role.toUpperCase())
const canCreate = computed(() => ['OPERATOR', 'MAINTENANCE_SUPERVISOR'].includes(role.value))
const canClose = computed(() => ['MAINTENANCE_SUPERVISOR', 'PRODUCTION_SUPERVISOR'].includes(role.value))
const visibleMachines = computed(() => role.value === 'OPERATOR' && auth.department ? machines.value.filter((machine) => machine.department === auth.department) : machines.value)
const sortedLogs = computed(() => [...logs.value].sort((a, b) => new Date(b.started_at).getTime() - new Date(a.started_at).getTime()))
let channel: RealtimeChannel | null = null
let timer: ReturnType<typeof setInterval> | null = null

async function refresh() {
  if (!supabase) { error.value = 'إعداد Supabase غير مكتمل.'; loading.value = false; return }
  const [logResult, machineResult] = await Promise.all([
    supabase.from('downtime_logs').select('id,machine_id,category,reason,is_maintenance_requested,comments,started_at,ended_at,work_order_id').order('started_at', { ascending: false }).limit(500),
    supabase.from('v_machine_status_live').select('*').order('code'),
  ])
  if (logResult.error) error.value = logResult.error.message
  else { logs.value = (logResult.data ?? []) as Downtime[]; error.value = '' }
  if (machineResult.error) error.value ||= machineResult.error.message
  else {
    machines.value = (machineResult.data ?? []) as Machine[]
    if (!form.value.machineId && visibleMachines.value.length) form.value.machineId = visibleMachines.value[0].id
  }
  loading.value = false
}

async function createDowntime() {
  if (!supabase || !canCreate.value || !form.value.machineId || !form.value.reason.trim()) return
  saving.value = true; error.value = ''; notice.value = ''
  try {
    const { error: rpcError } = await supabase.rpc('rpc_create_downtime_log', {
      p_id: crypto.randomUUID(), p_machine_id: form.value.machineId, p_category: form.value.category,
      p_reason: form.value.reason.trim(), p_is_maintenance_requested: form.value.maintenanceRequested,
      p_work_order_id: null, p_comments: form.value.comments.trim() || null,
      p_start_chronology: buildChronology(), p_shift_minutes: {},
    })
    if (rpcError) throw rpcError
    notice.value = 'تم تسجيل التوقف.'
    form.value.reason = ''; form.value.comments = ''; form.value.maintenanceRequested = false
    await refresh()
  } catch (cause) { error.value = cause instanceof Error ? cause.message : 'تعذر تسجيل التوقف.' }
  finally { saving.value = false }
}

async function closeDowntime(log: Downtime) {
  if (!supabase || !canClose.value || log.ended_at) return
  saving.value = true; error.value = ''; notice.value = ''
  const endedAt = new Date()
  try {
    const { error: rpcError } = await supabase.rpc('rpc_close_downtime_log', {
      p_id: log.id, p_end_chronology: buildChronology(endedAt), p_shift_minutes: calculateShiftMinutes(log.started_at, endedAt),
    })
    if (rpcError) throw rpcError
    notice.value = 'تم إغلاق التوقف.'
    await refresh()
  } catch (cause) { error.value = cause instanceof Error ? cause.message : 'تعذر إغلاق التوقف.' }
  finally { saving.value = false }
}

function machineInfo(id: string) {
  const machine = machines.value.find((item) => item.id === id)
  return machine ? `${machine.code} · ${machine.name} · ${departmentLabels[machine.department] ?? machine.department}` : id
}
function duration(startedAt: string, endedAt: string | null) {
  const minutes = Math.max(0, Math.floor(((endedAt ? new Date(endedAt).getTime() : now.value) - new Date(startedAt).getTime()) / 60000))
  const hours = Math.floor(minutes / 60); const days = Math.floor(hours / 24)
  return days ? `${days} يوم و${hours % 24} ساعة` : hours ? `${hours} ساعة و${minutes % 60} دقيقة` : `${minutes} دقيقة`
}

onMounted(() => {
  void refresh()
  timer = setInterval(() => { now.value = Date.now() }, 30000)
  if (supabase) channel = supabase.channel('web-downtime-live')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'downtime_logs' }, () => void refresh())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'machines' }, () => void refresh())
    .subscribe()
})
onUnmounted(() => { if (timer) clearInterval(timer); if (supabase && channel) void supabase.removeChannel(channel) })
</script>

<template>
  <div>
    <div class="mb-6"><h1 class="text-2xl font-bold">سجل التوقفات</h1><p class="mt-1 text-sm text-slate-500">تسجيل ومتابعة حالات توقف الماكينات</p></div>
    <p v-if="error" class="mb-4 rounded-lg bg-red-50 p-4 text-red-700">{{ error }}</p>
    <p v-if="notice" class="mb-4 rounded-lg bg-emerald-50 p-4 text-emerald-800">{{ notice }}</p>
    <form v-if="canCreate" class="mb-7 grid gap-3 rounded-xl border bg-white p-5 md:grid-cols-2 xl:grid-cols-3" @submit.prevent="createDowntime"><h2 class="text-lg font-bold md:col-span-2 xl:col-span-3">تسجيل توقف جديد</h2><label class="text-sm">الماكينة<select v-model="form.machineId" required class="mt-1 block w-full rounded-lg border-slate-300"><option v-for="machine in visibleMachines" :key="machine.id" :value="machine.id">{{ machine.code }} · {{ machine.name }}</option></select></label><label class="text-sm">التصنيف<select v-model="form.category" class="mt-1 block w-full rounded-lg border-slate-300"><option v-for="category in downtimeCategories" :key="category.value" :value="category.value">{{ category.label }}</option></select></label><label class="text-sm">سبب التوقف<input v-model="form.reason" required maxlength="500" class="mt-1 block w-full rounded-lg border-slate-300" placeholder="اكتب سبب التوقف" /></label><label class="text-sm md:col-span-2">ملاحظات<textarea v-model="form.comments" rows="2" class="mt-1 block w-full rounded-lg border-slate-300" /></label><label class="flex items-center gap-2 text-sm"><input v-model="form.maintenanceRequested" type="checkbox" class="rounded border-slate-300 text-brand focus:ring-brand" />يتطلب متابعة صيانة</label><div class="md:col-span-2 xl:col-span-3"><button :disabled="saving || !visibleMachines.length" class="rounded-lg bg-brand px-5 py-2 font-semibold text-white hover:bg-brand-dark disabled:opacity-50">{{ saving ? 'جارٍ التسجيل…' : 'تسجيل التوقف' }}</button></div></form>
    <p v-else class="mb-7 rounded-lg border border-blue-100 bg-blue-50 p-4 text-sm text-blue-900">صلاحية تسجيل التوقف غير متاحة لدورك الحالي.</p>
    <div v-if="loading" class="text-slate-500">جارٍ تحميل سجل التوقفات…</div>
    <div v-else-if="!sortedLogs.length" class="rounded-xl border border-dashed bg-white p-10 text-center text-slate-500">لا توجد سجلات توقف حاليًا.</div>
    <div v-else class="overflow-x-auto rounded-xl border bg-white"><table class="w-full min-w-[850px] text-right text-sm"><thead class="bg-slate-50 text-slate-600"><tr><th class="p-3">الماكينة والقسم</th><th class="p-3">التصنيف والسبب</th><th class="p-3">البداية</th><th class="p-3">المدة</th><th class="p-3">الحالة</th><th class="p-3">إجراء</th></tr></thead><tbody><tr v-for="log in sortedLogs" :key="log.id" class="border-t"><td class="p-3 font-semibold">{{ machineInfo(log.machine_id) }}</td><td class="max-w-xs p-3"><p>{{ downtimeCategoryLabel(log.category) }}</p><p class="mt-1 text-xs text-slate-500">{{ log.reason || '—' }}</p><p v-if="log.is_maintenance_requested" class="mt-1 text-xs text-amber-700">متابعة صيانة مطلوبة</p></td><td class="p-3">{{ formatCairoDate(log.started_at) }}</td><td class="p-3">{{ duration(log.started_at, log.ended_at) }}</td><td class="p-3"><span class="rounded-full px-3 py-1 text-xs font-semibold" :class="log.ended_at ? 'bg-slate-100 text-slate-600' : 'bg-red-100 text-red-800'">{{ log.ended_at ? 'مغلق' : 'نشط' }}</span></td><td class="p-3"><button v-if="!log.ended_at && canClose" :disabled="saving" class="rounded-lg bg-brand px-3 py-1.5 text-xs font-semibold text-white disabled:opacity-50" @click="closeDowntime(log)">إغلاق التوقف</button><span v-else-if="!log.ended_at" class="text-xs text-slate-400">لا توجد صلاحية</span><span v-else class="text-xs text-slate-400">—</span></td></tr></tbody></table></div>
  </div>
</template>
