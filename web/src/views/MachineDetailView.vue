<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { ArrowLeft, ArrowRight } from 'lucide-vue-next'
import { useLocaleStore } from '../stores/locale'
import type { RealtimeChannel } from '@supabase/supabase-js'
import { supabase } from '../api/supabase'
import StatusBadge from '../components/StatusBadge.vue'
import type { Machine } from '../stores/liveMonitoring'
import { departmentLabel, formatDateTime } from '../lib/workOrders'
import { downtimeCategoryLabel, formatCairoDate } from '../lib/downtime'
import { createLiveRefresh } from '../lib/liveRefresh'

type Downtime = { id: string; category: string | null; reason: string; started_at: string; ended_at: string | null; shift_minutes: Record<string, number> | null; work_order_id: string | null }
type BomItem = { id: string; quantity_per_machine: number; part: { id: string; part_code: string; name: string; unit: string; quantity_on_hand: number; reorder_level: number } | null }
const route = useRoute()
const locale = useLocaleStore()
const t = locale.t
const machine = ref<Machine | null>(null)
const downtime = ref<Downtime[]>([])
const bom = ref<BomItem[]>([])
const loading = ref(true)
const error = ref('')
const machineId = computed(() => decodeURIComponent(String(route.params.id ?? '')))
const liveRefresh = createLiveRefresh(refresh)
let channel: RealtimeChannel | null = null

async function refresh() {
  if (!supabase) { error.value = t('machineDetail.supabaseMissing'); loading.value = false; return }
  const [machineResult, machineDbResult] = await Promise.all([
    supabase.from('v_machine_status_live').select('*').eq('code', machineId.value).maybeSingle(),
    supabase.from('machines').select('id,code').eq('code', machineId.value).maybeSingle(),
  ])
  if (machineResult.error) error.value = `${t('machineDetail.errMachine')}: ${machineResult.error.message}`
  else if (!machineResult.data) error.value = t('machineDetail.notFound')
  else { machine.value = machineResult.data as Machine; error.value = '' }
  if (machineDbResult.error) error.value ||= `${t('machineDetail.errId')}: ${machineDbResult.error.message}`
  const dbMachineId = machineDbResult.data?.id ?? machineId.value
  const [downtimeResult, bomResult] = await Promise.all([
    supabase.from('downtime_logs').select('id,category,reason,started_at,ended_at,shift_minutes,work_order_id').eq('machine_id', dbMachineId).order('started_at', { ascending: false }).limit(20),
    supabase.from('machine_bom').select('id,machine_id,quantity_per_machine,spare_part_id'),
  ])
  if (downtimeResult.error) error.value ||= `${t('machineDetail.errDowntime')}: ${downtimeResult.error.message}`
  else downtime.value = downtimeResult.data ?? []
  if (bomResult.error) error.value ||= `${t('machineDetail.errBom')}: ${bomResult.error.message}`
  else {
    const rows = (bomResult.data ?? []).filter((row) => row.machine_id === dbMachineId || row.machine_id === machineId.value)
    const ids = rows.map((row) => row.spare_part_id)
    const partsResult = ids.length ? await supabase.from('spare_parts').select('id,part_code,name,unit,quantity_on_hand,reorder_level').in('id', ids) : { data: [], error: null }
    if (partsResult.error) error.value ||= `${t('machineDetail.errParts')}: ${partsResult.error.message}`
    const parts = new Map((partsResult.data ?? []).map((part) => [part.id, part]))
    bom.value = rows.map((row) => ({ id: row.id, quantity_per_machine: row.quantity_per_machine, part: parts.get(row.spare_part_id) ?? null }))
  }
  loading.value = false
}

onMounted(() => {
  void refresh()
  if (supabase) channel = supabase.channel(`machine-detail-${machineId.value}`)
    .on('postgres_changes', { event: '*', schema: 'public', table: 'machines' }, () => liveRefresh.request())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'downtime_logs' }, () => liveRefresh.request())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'machine_bom' }, () => liveRefresh.request())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'spare_parts' }, () => liveRefresh.request())
    .subscribe()
})
onUnmounted(() => { liveRefresh.dispose(); if (supabase && channel) void supabase.removeChannel(channel) })
</script>

<template>
  <div>
    <RouterLink to="/plant-floor" class="group inline-flex items-center gap-2 rounded-lg px-2 py-1 text-sm font-semibold text-brand-dark transition hover:bg-brand-50"><component :is="locale.direction === 'rtl' ? ArrowRight : ArrowLeft" :size="16" class="transition-transform ltr:group-hover:-translate-x-1 rtl:group-hover:translate-x-1" />{{ t('machineDetail.back') }}</RouterLink>
    <p v-if="loading" class="mt-5 text-slate-500">{{ t('machineDetail.loading') }}</p>
    <div v-else-if="error" class="mt-5 rounded-xl bg-red-50 p-4 text-red-700">{{ error }}</div>
    <template v-else-if="machine">
      <div class="page-hero enter mt-5 !items-start"><div><p class="text-sm font-semibold text-accent-light">{{ departmentLabel(machine.department, locale.locale) }}</p><h1 class="mt-1 text-3xl font-extrabold">{{ machine.code }} · {{ machine.name }}</h1><p class="mt-1 text-white/60">{{ machine.sub_category || t('machineDetail.noSub') }}</p></div><StatusBadge :status="machine.status" /></div>
      <section class="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4" :data-status="machine.status"><div class="stat-tile enter" style="--d:0ms"><p class="text-sm text-slate-500">{{ t('machineDetail.speed') }}</p><p class="mt-2 text-2xl font-bold">{{ machine.current_speed_mpm ?? 0 }} <span class="text-sm font-normal">{{ t('machineDetail.unitSpeed') }}</span></p></div><div class="stat-tile enter" style="--d:70ms"><p class="text-sm text-slate-500">{{ t('machineDetail.produced') }}</p><p class="mt-2 text-2xl font-bold">{{ Number(machine.total_meters_produced ?? 0).toLocaleString(locale.locale === 'ar' ? 'ar-EG' : 'en-US') }} <span class="text-sm font-normal">{{ t('machineDetail.unitMeters') }}</span></p></div><div class="stat-tile enter" style="--d:140ms"><p class="text-sm text-slate-500">{{ t('machineDetail.lastMaintenance') }}</p><p class="mt-2 font-semibold">{{ formatDateTime(machine.last_maintenance_at, locale.locale) }}</p></div><div class="stat-tile enter" style="--d:210ms"><p class="text-sm text-slate-500">{{ t('machineDetail.activeCause') }}</p><p class="mt-2 font-semibold">{{ machine.active_downtime_id ? `${downtimeCategoryLabel(machine.active_downtime_category, locale.locale)} · ${machine.active_downtime_reason || t('machineDetail.noDetails')}` : t('machineDetail.noActive') }}</p></div></section>
      <section class="mt-8 grid gap-6 xl:grid-cols-2"><div class="panel p-5"><div class="mb-4 flex items-center justify-between"><h2 class="text-lg font-bold">{{ t('machineDetail.downtimeLog') }}</h2><RouterLink :to="`/downtime?machine=${encodeURIComponent(machine.id)}`" class="text-sm font-semibold text-brand-dark">{{ t('machineDetail.viewLog') }}</RouterLink></div><div v-if="!downtime.length" class="text-sm text-slate-500">{{ t('machineDetail.noDowntime') }}</div><div v-else class="space-y-3"><article v-for="entry in downtime" :key="entry.id" class="rounded-lg bg-slate-50 p-3 transition hover:bg-brand-50"><div class="flex justify-between gap-3"><p class="font-semibold">{{ downtimeCategoryLabel(entry.category, locale.locale) }}</p><span :class="entry.ended_at ? 'text-slate-500' : 'text-red-700'" class="text-xs">{{ entry.ended_at ? t('machineDetail.closed') : t('machineDetail.active') }}</span></div><p class="mt-1 text-sm">{{ entry.reason || t('machineDetail.noDesc') }}</p><p class="mt-1 text-xs text-slate-500">{{ formatCairoDate(entry.started_at, locale.locale) }}<template v-if="entry.ended_at"> — {{ formatCairoDate(entry.ended_at, locale.locale) }}</template></p></article></div></div><div class="panel p-5"><h2 class="mb-4 text-lg font-bold">{{ t('machineDetail.bom') }}</h2><div v-if="!bom.length" class="text-sm text-slate-500">{{ t('machineDetail.noBom') }}</div><div v-else class="space-y-3"><article v-for="item in bom" :key="item.id" class="flex items-center justify-between gap-3 rounded-lg bg-slate-50 p-3 transition hover:bg-brand-50"><div><p class="font-semibold">{{ item.part?.name ?? t('machineDetail.partUnavailable') }}</p><p class="text-xs text-slate-500">{{ item.part?.part_code ?? '—' }} · {{ t('machineDetail.required') }} {{ item.quantity_per_machine }} {{ item.part?.unit ?? '' }}</p></div><span class="text-sm" :class="(item.part?.quantity_on_hand ?? 0) <= (item.part?.reorder_level ?? 0) ? 'text-red-700' : 'text-slate-600'">{{ t('machineDetail.stock') }}: {{ item.part?.quantity_on_hand ?? '—' }}</span></article></div></div></section>
    </template>
  </div>
</template>
