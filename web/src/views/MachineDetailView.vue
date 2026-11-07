<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { ArrowLeft, ArrowRight, ClipboardList, Gauge, PackageSearch, Ruler, Timer, Wrench } from 'lucide-vue-next'
import type { RealtimeChannel } from '@supabase/supabase-js'
import { supabase } from '../api/supabase'
import StatusBadge from '../components/StatusBadge.vue'
import StatTile from '../components/StatTile.vue'
import type { Machine } from '../stores/liveMonitoring'
import { departmentLabel, formatDateTime, priorityInfo, shortId, statusClass, statusLabel } from '../lib/workOrders'
import { downtimeCategoryLabel, formatCairoDate } from '../lib/downtime'
import { createLiveRefresh } from '../lib/liveRefresh'
import { useLocaleStore } from '../stores/locale'

type Downtime = { id: string; category: string | null; reason: string; started_at: string; ended_at: string | null; shift_minutes: Record<string, number> | null; work_order_id: string | null }
type BomItem = { id: string; quantity_per_machine: number; part: { id: string; part_code: string; name: string; unit: string; quantity_on_hand: number; reorder_level: number } | null }
type WorkOrderRow = { id: string; title: string; status: string; priority: string; created_at: string }

const route = useRoute()
const locale = useLocaleStore()
const t = locale.t
const machine = ref<Machine | null>(null)
const downtime = ref<Downtime[]>([])
const bom = ref<BomItem[]>([])
const workOrders = ref<WorkOrderRow[]>([])
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

  const [downtimeResult, bomResult, workOrderResult] = await Promise.all([
    supabase.from('downtime_logs').select('id,category,reason,started_at,ended_at,shift_minutes,work_order_id').eq('machine_id', dbMachineId).order('started_at', { ascending: false }).limit(20),
    supabase.from('machine_bom').select('id,machine_id,quantity_per_machine,spare_part_id'),
    supabase.from('work_orders').select('id,title,status,priority,created_at').eq('machine_id', dbMachineId).order('created_at', { ascending: false }).limit(10),
  ])
  if (downtimeResult.error) error.value ||= `${t('machineDetail.errDowntime')}: ${downtimeResult.error.message}`
  else downtime.value = downtimeResult.data ?? []
  if (workOrderResult.error) error.value ||= `${t('machineDetail.errWorkOrders')}: ${workOrderResult.error.message}`
  else workOrders.value = (workOrderResult.data ?? []) as WorkOrderRow[]
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

const openWorkOrders = computed(() => workOrders.value.filter((w) => !['verified', 'verifiedClosed'].includes(w.status)))
const lowStockParts = computed(() => bom.value.filter((item) => item.part && item.part.quantity_on_hand <= item.part.reorder_level))
// How far current stock sits past the reorder line, visualised the same way Spare Parts does.
function barWidth(part: NonNullable<BomItem['part']>) {
  const ratio = part.reorder_level > 0 ? part.quantity_on_hand / (part.reorder_level * 2) : part.quantity_on_hand > 0 ? 1 : 0
  return `${Math.round(Math.min(1, Math.max(0, ratio)) * 100)}%`
}
const barClass = (part: NonNullable<BomItem['part']>) => part.quantity_on_hand <= 0 ? 'bg-red-500' : part.quantity_on_hand <= part.reorder_level ? 'bg-amber-500' : 'bg-emerald-500'

onMounted(() => {
  void refresh()
  if (supabase) channel = supabase.channel(`machine-detail-${machineId.value}`)
    .on('postgres_changes', { event: '*', schema: 'public', table: 'machines' }, () => liveRefresh.request())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'downtime_logs' }, () => liveRefresh.request())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'machine_bom' }, () => liveRefresh.request())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'spare_parts' }, () => liveRefresh.request())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'work_orders' }, () => liveRefresh.request())
    .subscribe()
})
onUnmounted(() => { liveRefresh.dispose(); if (supabase && channel) void supabase.removeChannel(channel) })
</script>

<template>
  <div>
    <RouterLink to="/plant-floor" class="group inline-flex items-center gap-2 rounded-lg px-2 py-1 text-sm font-semibold text-brand-dark transition hover:bg-brand-50">
      <component :is="locale.direction === 'rtl' ? ArrowRight : ArrowLeft" :size="16" class="transition-transform ltr:group-hover:-translate-x-1 rtl:group-hover:translate-x-1" />{{ t('machineDetail.back') }}
    </RouterLink>

    <p v-if="loading" class="mt-5 text-slate-500">{{ t('machineDetail.loading') }}</p>
    <div v-else-if="error" class="mt-5 rounded-xl bg-red-50 p-4 text-red-700">{{ error }}</div>

    <template v-else-if="machine">
      <div class="page-hero enter mt-5 !items-start" :data-status="machine.status">
        <div>
          <p class="text-sm font-semibold text-accent-light">{{ departmentLabel(machine.department, locale.locale) }}</p>
          <h1 class="mt-1 text-3xl font-extrabold">{{ machine.code }} · {{ machine.name }}</h1>
          <p class="mt-1 text-white/60">{{ machine.sub_category || t('machineDetail.noSub') }}</p>
        </div>
        <StatusBadge :status="machine.status" />
      </div>

      <section class="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatTile :label="t('machineDetail.speed')" :value="`${machine.current_speed_mpm ?? 0} ${t('machineDetail.unitSpeed')}`" tone="emerald" :icon="Gauge" style="--d:0ms" />
        <StatTile :label="t('machineDetail.produced')" :value="`${Number(machine.total_meters_produced ?? 0).toLocaleString(locale.locale === 'ar' ? 'ar-EG' : 'en-US')} ${t('machineDetail.unitMeters')}`" tone="brand" :icon="Ruler" style="--d:70ms" />
        <StatTile :label="t('machineDetail.lastMaintenance')" :value="formatDateTime(machine.last_maintenance_at, locale.locale)" tone="violet" :icon="Wrench" style="--d:140ms" />
        <StatTile
          :label="t('machineDetail.activeCause')"
          :value="machine.active_downtime_id ? downtimeCategoryLabel(machine.active_downtime_category, locale.locale) : t('machineDetail.noActive')"
          :hint="machine.active_downtime_id ? (machine.active_downtime_reason || t('machineDetail.noDetails')) : undefined"
          :tone="machine.active_downtime_id ? 'red' : 'brand'" :icon="Timer" style="--d:210ms"
        />
      </section>

      <section class="mt-8 grid gap-6 xl:grid-cols-2">
        <!-- downtime timeline -->
        <div class="panel p-5">
          <div class="mb-4 flex items-center justify-between">
            <h2 class="flex items-center gap-2 text-lg font-extrabold text-brand-navy"><span class="h-5 w-1.5 rounded-full bg-gradient-to-b from-accent to-brand"></span>{{ t('machineDetail.downtimeLog') }}</h2>
            <RouterLink :to="`/downtime?machine=${encodeURIComponent(machine.id)}`" class="text-sm font-semibold text-brand-dark hover:underline">{{ t('machineDetail.viewLog') }}</RouterLink>
          </div>
          <div v-if="!downtime.length" class="rounded-lg border border-dashed p-5 text-center text-sm text-slate-500">{{ t('machineDetail.noDowntime') }}</div>
          <ol v-else class="relative">
            <li v-for="(entry, i) in downtime" :key="entry.id" class="enter relative flex gap-3 pb-5 last:pb-0" :style="{ '--d': `${Math.min(i, 8) * 45}ms` }">
              <span v-if="i < downtime.length - 1" class="absolute top-4 h-full w-px bg-slate-200 start-[5px]"></span>
              <span class="relative mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full" :class="entry.ended_at ? 'bg-slate-300' : 'bg-status-downMaintenance ring-4 ring-red-100'"></span>
              <div class="min-w-0 flex-1 rounded-lg bg-slate-50 p-3 transition hover:bg-brand-50">
                <div class="flex items-start justify-between gap-3">
                  <p class="font-bold text-brand-navy">{{ downtimeCategoryLabel(entry.category, locale.locale) }}</p>
                  <span class="shrink-0 text-xs font-bold" :class="entry.ended_at ? 'text-slate-500' : 'text-red-600'">{{ entry.ended_at ? t('machineDetail.closed') : t('machineDetail.active') }}</span>
                </div>
                <p class="mt-1 text-sm text-slate-600">{{ entry.reason || t('machineDetail.noDesc') }}</p>
                <p class="mt-1.5 text-xs text-slate-400">{{ formatCairoDate(entry.started_at, locale.locale) }}<template v-if="entry.ended_at"> — {{ formatCairoDate(entry.ended_at, locale.locale) }}</template></p>
              </div>
            </li>
          </ol>
        </div>

        <!-- spare parts / BOM -->
        <div class="panel p-5">
          <div class="mb-4 flex items-center justify-between">
            <h2 class="flex items-center gap-2 text-lg font-extrabold text-brand-navy"><span class="h-5 w-1.5 rounded-full bg-gradient-to-b from-accent to-brand"></span>{{ t('machineDetail.bom') }}</h2>
            <span v-if="lowStockParts.length" class="inline-flex items-center gap-1.5 rounded-full bg-amber-50 px-2.5 py-1 text-xs font-bold text-amber-800"><PackageSearch :size="13" />{{ lowStockParts.length }} {{ t('machineDetail.lowStock') }}</span>
          </div>
          <div v-if="!bom.length" class="rounded-lg border border-dashed p-5 text-center text-sm text-slate-500">{{ t('machineDetail.noBom') }}</div>
          <div v-else class="space-y-3">
            <article v-for="(item, i) in bom" :key="item.id" class="enter rounded-lg bg-slate-50 p-3 transition hover:bg-brand-50" :style="{ '--d': `${Math.min(i, 8) * 45}ms` }">
              <div class="flex items-center justify-between gap-3">
                <div class="min-w-0">
                  <p class="truncate font-semibold text-brand-navy">{{ item.part?.name ?? t('machineDetail.partUnavailable') }}</p>
                  <p class="text-xs text-slate-500">{{ item.part?.part_code ?? '—' }} · {{ t('machineDetail.required') }} {{ item.quantity_per_machine }} {{ item.part?.unit ?? '' }}</p>
                </div>
                <span class="shrink-0 text-sm font-bold" :class="item.part && item.part.quantity_on_hand <= item.part.reorder_level ? 'text-red-700' : 'text-slate-700'">{{ t('machineDetail.stock') }}: {{ item.part?.quantity_on_hand ?? '—' }}</span>
              </div>
              <div v-if="item.part" class="relative mt-2 h-1.5 w-full overflow-hidden rounded-full bg-slate-200"><span class="block h-full rounded-full" :class="barClass(item.part)" :style="{ width: barWidth(item.part) }"></span></div>
            </article>
          </div>
        </div>
      </section>

      <!-- work orders for this machine -->
      <section class="panel mt-6 p-5">
        <div class="mb-4 flex items-center justify-between">
          <h2 class="flex items-center gap-2 text-lg font-extrabold text-brand-navy"><span class="h-5 w-1.5 rounded-full bg-gradient-to-b from-accent to-brand"></span>{{ t('machineDetail.workOrders') }}</h2>
          <span v-if="openWorkOrders.length" class="inline-flex items-center gap-1.5 rounded-full bg-accent-50 px-2.5 py-1 text-xs font-bold text-accent-dark"><ClipboardList :size="13" />{{ openWorkOrders.length }} {{ t('machineDetail.open') }}</span>
        </div>
        <div v-if="!workOrders.length" class="rounded-lg border border-dashed p-5 text-center text-sm text-slate-500">{{ t('machineDetail.noWorkOrders') }}</div>
        <div v-else class="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
          <RouterLink v-for="(order, i) in workOrders" :key="order.id" :to="`/work-orders/${order.id}`" class="enter group rounded-xl border border-slate-200 bg-white p-3.5 transition hover:-translate-y-0.5 hover:border-brand/30 hover:shadow-md" :style="{ '--d': `${Math.min(i, 8) * 45}ms` }">
            <p class="font-mono text-xs text-brand-dark">#{{ shortId(order.id) }}</p>
            <p class="mt-1 truncate text-sm font-bold text-brand-navy">{{ order.title }}</p>
            <div class="mt-2.5 flex flex-wrap items-center gap-1.5">
              <span class="rounded-full px-2 py-0.5 text-[11px] font-semibold" :class="statusClass(order.status)">{{ statusLabel(order.status, locale.locale) }}</span>
              <span class="rounded-full px-2 py-0.5 text-[11px] font-semibold" :class="priorityInfo(order.priority, locale.locale).className">{{ priorityInfo(order.priority, locale.locale).label }}</span>
            </div>
          </RouterLink>
        </div>
      </section>
    </template>
  </div>
</template>
