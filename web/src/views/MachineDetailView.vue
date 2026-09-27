<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import type { RealtimeChannel } from '@supabase/supabase-js'
import { supabase } from '../api/supabase'
import StatusBadge from '../components/StatusBadge.vue'
import type { Machine } from '../stores/liveMonitoring'
import { departmentLabels, formatDateTime } from '../lib/workOrders'
import { downtimeCategoryLabel, formatCairoDate } from '../lib/downtime'

type Downtime = { id: string; category: string | null; reason: string; started_at: string; ended_at: string | null; shift_minutes: Record<string, number> | null; work_order_id: string | null }
type BomItem = { id: string; quantity_per_machine: number; part: { id: string; part_code: string; name: string; unit: string; quantity_on_hand: number; reorder_level: number } | null }
const route = useRoute()
const machine = ref<Machine | null>(null)
const downtime = ref<Downtime[]>([])
const bom = ref<BomItem[]>([])
const loading = ref(true)
const error = ref('')
const machineId = computed(() => decodeURIComponent(String(route.params.id ?? '')))
let channel: RealtimeChannel | null = null

async function refresh() {
  if (!supabase) { error.value = 'إعداد Supabase غير مكتمل.'; loading.value = false; return }
  const [machineResult, machineDbResult] = await Promise.all([
    supabase.from('v_machine_status_live').select('*').eq('code', machineId.value).maybeSingle(),
    supabase.from('machines').select('id,code').eq('code', machineId.value).maybeSingle(),
  ])
  if (machineResult.error) error.value = `بيانات الماكينة: ${machineResult.error.message}`
  else if (!machineResult.data) error.value = 'لم يتم العثور على الماكينة أو ليس لديك صلاحية لعرضها.'
  else { machine.value = machineResult.data as Machine; error.value = '' }
  if (machineDbResult.error) error.value ||= `معرّف الماكينة: ${machineDbResult.error.message}`
  const dbMachineId = machineDbResult.data?.id ?? machineId.value
  const [downtimeResult, bomResult] = await Promise.all([
    supabase.from('downtime_logs').select('id,category,reason,started_at,ended_at,shift_minutes,work_order_id').eq('machine_id', dbMachineId).order('started_at', { ascending: false }).limit(20),
    supabase.from('machine_bom').select('id,machine_id,quantity_per_machine,spare_part_id'),
  ])
  if (downtimeResult.error) error.value ||= `سجل التوقفات: ${downtimeResult.error.message}`
  else downtime.value = downtimeResult.data ?? []
  if (bomResult.error) error.value ||= `قائمة قطع الغيار: ${bomResult.error.message}`
  else {
    const rows = (bomResult.data ?? []).filter((row) => row.machine_id === dbMachineId || row.machine_id === machineId.value)
    const ids = rows.map((row) => row.spare_part_id)
    const partsResult = ids.length ? await supabase.from('spare_parts').select('id,part_code,name,unit,quantity_on_hand,reorder_level').in('id', ids) : { data: [], error: null }
    if (partsResult.error) error.value ||= `بيانات قطع الغيار: ${partsResult.error.message}`
    const parts = new Map((partsResult.data ?? []).map((part) => [part.id, part]))
    bom.value = rows.map((row) => ({ id: row.id, quantity_per_machine: row.quantity_per_machine, part: parts.get(row.spare_part_id) ?? null }))
  }
  loading.value = false
}

onMounted(() => {
  void refresh()
  if (supabase) channel = supabase.channel(`machine-detail-${machineId.value}`)
    .on('postgres_changes', { event: '*', schema: 'public', table: 'machines' }, () => void refresh())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'downtime_logs' }, () => void refresh())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'machine_bom' }, () => void refresh())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'spare_parts' }, () => void refresh())
    .subscribe()
})
onUnmounted(() => { if (supabase && channel) void supabase.removeChannel(channel) })
</script>

<template>
  <div>
    <RouterLink to="/plant-floor" class="text-sm font-semibold text-brand-dark">← العودة لأرضية المصنع</RouterLink>
    <p v-if="loading" class="mt-5 text-slate-500">جارٍ تحميل بيانات الماكينة…</p>
    <div v-else-if="error" class="mt-5 rounded-xl bg-red-50 p-4 text-red-700">{{ error }}</div>
    <template v-else-if="machine">
      <div class="mt-5 flex flex-wrap items-start justify-between gap-4"><div><p class="text-sm text-slate-500">{{ departmentLabels[machine.department] ?? machine.department }}</p><h1 class="text-3xl font-bold">{{ machine.code }} · {{ machine.name }}</h1><p class="mt-1 text-slate-500">{{ machine.sub_category || 'بدون تصنيف فرعي' }}</p></div><StatusBadge :status="machine.status" /></div>
      <section class="mt-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-4"><div class="rounded-xl border bg-white p-4"><p class="text-sm text-slate-500">السرعة الحالية</p><p class="mt-2 text-2xl font-bold">{{ machine.current_speed_mpm ?? 0 }} <span class="text-sm font-normal">متر/دقيقة</span></p></div><div class="rounded-xl border bg-white p-4"><p class="text-sm text-slate-500">إجمالي الإنتاج</p><p class="mt-2 text-2xl font-bold">{{ Number(machine.total_meters_produced ?? 0).toLocaleString('ar-EG') }} <span class="text-sm font-normal">متر</span></p></div><div class="rounded-xl border bg-white p-4"><p class="text-sm text-slate-500">آخر صيانة</p><p class="mt-2 font-semibold">{{ formatDateTime(machine.last_maintenance_at) }}</p></div><div class="rounded-xl border bg-white p-4"><p class="text-sm text-slate-500">سبب التوقف النشط</p><p class="mt-2 font-semibold">{{ machine.active_downtime_id ? `${downtimeCategoryLabel(machine.active_downtime_category)} · ${machine.active_downtime_reason || 'بدون تفاصيل'}` : 'لا يوجد توقف نشط' }}</p></div></section>
      <section class="mt-8 grid gap-6 xl:grid-cols-2"><div class="rounded-xl border bg-white p-5"><div class="mb-4 flex items-center justify-between"><h2 class="text-lg font-bold">سجل التوقفات</h2><RouterLink :to="`/downtime?machine=${encodeURIComponent(machine.id)}`" class="text-sm font-semibold text-brand-dark">عرض السجل</RouterLink></div><div v-if="!downtime.length" class="text-sm text-slate-500">لا يوجد سجل توقفات لهذه الماكينة.</div><div v-else class="space-y-3"><article v-for="entry in downtime" :key="entry.id" class="rounded-lg bg-slate-50 p-3"><div class="flex justify-between gap-3"><p class="font-semibold">{{ downtimeCategoryLabel(entry.category) }}</p><span :class="entry.ended_at ? 'text-slate-500' : 'text-red-700'" class="text-xs">{{ entry.ended_at ? 'مغلق' : 'نشط' }}</span></div><p class="mt-1 text-sm">{{ entry.reason || 'بدون وصف' }}</p><p class="mt-1 text-xs text-slate-500">{{ formatCairoDate(entry.started_at) }}<template v-if="entry.ended_at"> — {{ formatCairoDate(entry.ended_at) }}</template></p></article></div></div><div class="rounded-xl border bg-white p-5"><h2 class="mb-4 text-lg font-bold">قطع الغيار المرتبطة (BOM)</h2><div v-if="!bom.length" class="text-sm text-slate-500">لا توجد قطع غيار مرتبطة بهذه الماكينة.</div><div v-else class="space-y-3"><article v-for="item in bom" :key="item.id" class="flex items-center justify-between gap-3 rounded-lg bg-slate-50 p-3"><div><p class="font-semibold">{{ item.part?.name ?? 'قطعة غير متاحة' }}</p><p class="text-xs text-slate-500">{{ item.part?.part_code ?? '—' }} · مطلوب {{ item.quantity_per_machine }} {{ item.part?.unit ?? '' }}</p></div><span class="text-sm" :class="(item.part?.quantity_on_hand ?? 0) <= (item.part?.reorder_level ?? 0) ? 'text-red-700' : 'text-slate-600'">المخزون: {{ item.part?.quantity_on_hand ?? '—' }}</span></article></div></div></section>
    </template>
  </div>
</template>
