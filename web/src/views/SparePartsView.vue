<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import type { RealtimeChannel } from '@supabase/supabase-js'
import { supabase } from '../api/supabase'
import { useLocaleStore } from '../stores/locale'
import { createLiveRefresh } from '../lib/liveRefresh'
import { ArrowUpDown, Package, PackageCheck, PackageMinus, PackageX } from 'lucide-vue-next'
import StatTile from '../components/StatTile.vue'

type SparePart = { id: string; part_code: string; name: string; description?: string | null; category?: string | null; unit?: string | null; quantity_on_hand?: number | string | null; reorder_level?: number | string | null; quantity_in_stock?: number | string | null; min_stock_level?: number | string | null; location?: string | null; unit_cost?: number | string | null }
const parts = ref<SparePart[]>([])
const locale = useLocaleStore()
const t = locale.t
const machineCounts = ref<Record<string, number>>({})
const search = ref('')
const loading = ref(true)
const error = ref('')
const liveRefresh = createLiveRefresh(refresh)
let channel: RealtimeChannel | null = null
type StockState = 'healthy' | 'low' | 'out'
type StockFilter = 'all' | StockState
const stockFilter = ref<StockFilter>('all')
const lowestFirst = ref(false)
function stockState(part: SparePart): StockState {
  const onHand = stock(part)
  if (onHand <= 0) return 'out'
  return onHand <= reorder(part) ? 'low' : 'healthy'
}
const stateCounts = computed(() => ({
  all: parts.value.length,
  healthy: parts.value.filter((part) => stockState(part) === 'healthy').length,
  low: parts.value.filter((part) => stockState(part) === 'low').length,
  out: parts.value.filter((part) => stockState(part) === 'out').length,
}))
const tiles = computed(() => [
  { key: 'all', label: t('spareParts.tileAll'), value: stateCounts.value.all, tone: 'brand', icon: Package },
  { key: 'healthy', label: t('spareParts.tileHealthy'), value: stateCounts.value.healthy, tone: 'emerald', icon: PackageCheck },
  { key: 'low', label: t('spareParts.tileLow'), value: stateCounts.value.low, tone: 'amber', icon: PackageMinus },
  { key: 'out', label: t('spareParts.tileOut'), value: stateCounts.value.out, tone: 'red', icon: PackageX },
] as const)
const filtered = computed(() => {
  const query = search.value.trim().toLowerCase()
  const rows = parts.value.filter((part) =>
    (stockFilter.value === 'all' || stockState(part) === stockFilter.value)
    && (!query || [part.part_code, part.name, part.category, part.location].some((value) => value?.toLowerCase().includes(query))))
  // Sort by how far each part is above its reorder level (negative = already below it).
  return lowestFirst.value ? [...rows].sort((a, b) => (stock(a) - reorder(a)) - (stock(b) - reorder(b))) : rows
})
// The reorder level sits at the middle of the bar, so "full" means twice the reorder level.
function barWidth(part: SparePart) {
  const level = reorder(part)
  const ratio = level > 0 ? stock(part) / (level * 2) : stock(part) > 0 ? 1 : 0
  return `${Math.round(Math.min(1, Math.max(0, ratio)) * 100)}%`
}
const barClass = (part: SparePart) => ({ healthy: 'bg-emerald-500', low: 'bg-amber-500', out: 'bg-red-500' })[stockState(part)]

async function refresh() {
  if (!supabase) { error.value = t('workOrders.supabaseMissing'); loading.value = false; return }
  const [partResult, bomResult] = await Promise.all([
    supabase.from('spare_parts').select('*').order('part_code'),
    supabase.from('machine_bom').select('spare_part_id'),
  ])
  if (partResult.error) error.value = partResult.error.message
  else { parts.value = (partResult.data ?? []) as SparePart[]; error.value = '' }
  if (bomResult.error) error.value ||= bomResult.error.message
  else machineCounts.value = (bomResult.data ?? []).reduce<Record<string, number>>((counts, row) => { counts[row.spare_part_id] = (counts[row.spare_part_id] ?? 0) + 1; return counts }, {})
  loading.value = false
}

function stock(part: SparePart) { return Number(part.quantity_on_hand ?? part.quantity_in_stock ?? 0) }
function reorder(part: SparePart) { return Number(part.reorder_level ?? part.min_stock_level ?? 0) }
function stockClass(part: SparePart) { return stock(part) <= reorder(part) ? 'bg-red-100 text-red-800' : 'bg-emerald-100 text-emerald-800' }

onMounted(() => {
  void refresh()
  if (supabase) channel = supabase.channel('web-spare-parts-live')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'spare_parts' }, () => liveRefresh.request())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'machine_bom' }, () => liveRefresh.request())
    .subscribe()
})
onUnmounted(() => { liveRefresh.dispose(); if (supabase && channel) void supabase.removeChannel(channel) })
</script>

<template>
  <div :dir="locale.direction">
    <div class="page-hero enter"><div><h1 class="text-2xl font-extrabold md:text-3xl">{{ t('spareParts.title') }}</h1><p class="mt-1 text-sm text-white/60">{{ t('spareParts.subtitle') }}</p></div><label class="text-sm font-semibold text-white/80">{{ t('spareParts.search') }}<input v-model="search" class="form-control mt-1 w-64" :placeholder="t('spareParts.searchPlaceholder')" /></label></div>
    <div v-if="!loading && parts.length" class="mb-5 grid grid-cols-2 gap-3 lg:grid-cols-4">
<StatTile v-for="(tile, i) in tiles" :key="tile.key" interactive :active="stockFilter === tile.key" :label="tile.label" :value="tile.value" :tone="tile.tone" :icon="tile.icon" :style="{ '--d': `${i * 60}ms` }" @select="stockFilter = stockFilter === tile.key ? 'all' : tile.key" />
</div>
<div v-if="!loading && parts.length" class="mb-4 flex flex-wrap items-center justify-between gap-3">
<p class="text-xs text-slate-500">{{ t('spareParts.showingCount').replace('{n}', String(filtered.length)).replace('{total}', String(parts.length)) }}</p>
<button type="button" class="chip" :class="{ 'is-on': lowestFirst }" :aria-pressed="lowestFirst" @click="lowestFirst = !lowestFirst"><ArrowUpDown :size="14" />{{ t('spareParts.lowestFirst') }}</button>
</div>
<p v-if="error" class="mb-4 rounded-lg bg-red-50 p-4 text-red-700">{{ error }}</p>
    <p v-if="loading" class="text-slate-500">{{ t('spareParts.loading') }}</p>
    <div v-else-if="!filtered.length" class="rounded-xl border border-dashed bg-white p-10 text-center text-slate-500">{{ parts.length ? t('spareParts.noResults') : t('spareParts.empty') }}</div>
    <div v-else class="overflow-x-auto panel"><table class="w-full min-w-[850px] text-sm" :class="locale.direction === 'rtl' ? 'text-right' : 'text-left'"><thead class="bg-slate-50 text-slate-600"><tr><th class="p-3">{{ t('spareParts.code') }}</th><th class="p-3">{{ t('spareParts.nameCategory') }}</th><th class="p-3">{{ t('spareParts.stock') }}</th><th class="p-3">{{ t('spareParts.reorder') }}</th><th class="p-3">{{ t('spareParts.unit') }}</th><th class="p-3">{{ t('spareParts.location') }}</th><th class="p-3">{{ t('spareParts.machines') }}</th></tr></thead><tbody><tr v-for="part in filtered" :key="part.id" class="border-t" :class="stockState(part) === 'out' ? 'bg-red-50/60' : ''"><td class="p-3 font-bold">{{ part.part_code }}</td><td class="p-3"><p class="font-semibold">{{ part.name }}</p><p class="text-xs text-slate-500">{{ part.category || part.description || '—' }}</p></td><td class="p-3"><span class="rounded-full px-3 py-1 text-xs font-semibold" :class="stockClass(part)">{{ stock(part).toLocaleString(locale.locale === 'ar' ? 'ar-EG' : 'en-US') }}</span><div class="relative mt-2 h-1.5 w-24 overflow-hidden rounded-full bg-slate-100" aria-hidden="true"><span class="block h-full rounded-full" :class="barClass(part)" :style="{ width: barWidth(part) }"></span><i class="absolute inset-y-0 start-1/2 w-px bg-slate-500/50"></i></div></td><td class="p-3">{{ reorder(part).toLocaleString(locale.locale === 'ar' ? 'ar-EG' : 'en-US') }}</td><td class="p-3">{{ part.unit || t('spareParts.item') }}</td><td class="p-3">{{ part.location || '—' }}</td><td class="p-3">{{ machineCounts[part.id] ?? 0 }}</td></tr></tbody></table></div>
    <p v-if="!loading && parts.length" class="mt-3 text-xs text-slate-500">{{ t('spareParts.threshold') }}</p>
  </div>
</template>
