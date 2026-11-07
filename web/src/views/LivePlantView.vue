<script setup lang="ts">
import { onMounted, onUnmounted, computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { Radio, Search, TriangleAlert, WifiOff, X } from 'lucide-vue-next'
import StatusBadge from '../components/StatusBadge.vue'
import { useLiveMonitoringStore, type Machine } from '../stores/liveMonitoring'
import { useLocaleStore } from '../stores/locale'

const live = useLiveMonitoringStore()
const locale = useLocaleStore()
const t = locale.t
const departments = computed<Record<string, string>>(() => ({ drawing: t('downtime.departments.drawing'), ccv: t('downtime.departments.ccv'), stranding: t('downtime.departments.stranding'), armouring: t('downtime.departments.armouring'), extrusion: t('downtime.departments.extrusion'), assembly: t('downtime.departments.assembly'), screening: t('downtime.departments.screening'), rewinding: t('downtime.departments.rewinding') }))
const now = ref(Date.now())
type StatusFilter = 'all' | 'running' | 'idle' | 'down' | 'repair'
const statusGroups: Record<Exclude<StatusFilter, 'all'>, string[]> = {
  running: ['running'],
  idle: ['idle', 'preventiveMaintenance', 'offline'],
  down: ['downtimeProcess', 'downtimeMaintenance'],
  repair: ['underRepair'],
}
const statusFilter = ref<StatusFilter>('all')
const search = ref('')
const filtering = computed(() => statusFilter.value !== 'all' || Boolean(search.value.trim()))
const counts = computed(() => ({
  all: live.machines.length,
  running: live.machines.filter((m) => statusGroups.running.includes(m.status)).length,
  idle: live.machines.filter((m) => statusGroups.idle.includes(m.status)).length,
  down: live.machines.filter((m) => statusGroups.down.includes(m.status)).length,
  repair: live.machines.filter((m) => statusGroups.repair.includes(m.status)).length,
}))
const filterChips = computed(() => [
  { key: 'all' as const, label: t('plant.filterAll'), dot: 'bg-slate-400' },
  { key: 'running' as const, label: t('plant.filterRunning'), dot: 'bg-status-running' },
  { key: 'idle' as const, label: t('plant.filterIdle'), dot: 'bg-status-idle' },
  { key: 'down' as const, label: t('plant.filterDown'), dot: 'bg-status-downMaintenance' },
  { key: 'repair' as const, label: t('plant.filterRepair'), dot: 'bg-status-underRepair' },
])
function matches(machine: Machine) {
  if (statusFilter.value !== 'all' && !statusGroups[statusFilter.value].includes(machine.status)) return false
  const query = search.value.trim().toLowerCase()
  return !query || machine.code.toLowerCase().includes(query) || (machine.name ?? '').toLowerCase().includes(query)
}
const grouped = computed(() => {
  let offset = 0
  return Object.entries(departments.value)
    .map(([key, name]) => {
      const machines = live.machines.filter((m) => m.department === key && matches(m))
      const group = { key, name, machines, offset, running: machines.filter((m) => m.status === 'running').length }
      offset += machines.length
      return group
    })
    .filter((group) => group.machines.length || !filtering.value)
})
const matchCount = computed(() => grouped.value.reduce((sum, group) => sum + group.machines.length, 0))
// Machines that need someone's attention right now, longest-down first.
const attention = computed(() => live.machines
  .filter((m) => [...statusGroups.down, ...statusGroups.repair].includes(m.status))
  .sort((a, b) => (b.active_downtime_minutes ?? 0) - (a.active_downtime_minutes ?? 0)))
const totalRunning = computed(() => live.machines.filter((m) => m.status === 'running').length)
const totalDown = computed(() => live.machines.filter((m) => m.status === 'downtimeProcess' || m.status === 'downtimeMaintenance' || m.status === 'underRepair').length)
const isUrgent = (status: string) => status === 'downtimeProcess' || status === 'downtimeMaintenance'

// count-up for the headline number
const shownRunning = ref(0)
let raf = 0
watch(totalRunning, (to) => {
  const from = shownRunning.value
  const start = performance.now()
  cancelAnimationFrame(raf)
  const step = (time: number) => {
    const p = Math.min(1, (time - start) / 800)
    shownRunning.value = Math.round(from + (to - from) * (1 - Math.pow(1 - p, 3)))
    if (p < 1) raf = requestAnimationFrame(step)
  }
  raf = requestAnimationFrame(step)
}, { immediate: true })

// spotlight + tilt that follow the pointer
let pending = 0
function onMove(event: MouseEvent) {
  const el = event.currentTarget as HTMLElement
  const { clientX, clientY } = event
  if (pending) return // at most one style write per frame
  pending = requestAnimationFrame(() => {
    pending = 0
    const rect = el.getBoundingClientRect()
    const x = clientX - rect.left
    const y = clientY - rect.top
    el.style.setProperty('--mx', `${x}px`)
    el.style.setProperty('--my', `${y}px`)
    el.style.setProperty('--ry', `${(x / rect.width - 0.5) * 9}deg`)
    el.style.setProperty('--rx', `${-(y / rect.height - 0.5) * 9}deg`)
  })
}
function onLeave(event: MouseEvent) {
  cancelAnimationFrame(pending); pending = 0
  const el = event.currentTarget as HTMLElement
  el.style.setProperty('--rx', '0deg')
  el.style.setProperty('--ry', '0deg')
}

let timer: ReturnType<typeof setInterval> | null = null
onMounted(() => { void live.subscribe(); timer = setInterval(() => { now.value = Date.now() }, 30000) })
onUnmounted(() => { if (timer) clearInterval(timer); cancelAnimationFrame(raf); void live.unsubscribe() })
</script>

<template>
  <div :dir="locale.direction">
    <!-- hero -->
    <div class="enter relative mb-8 overflow-hidden rounded-3xl bg-brand-navy p-5 text-white shadow-[0_30px_60px_-30px_rgba(8,41,87,.8)] md:p-8">
      <div class="pointer-events-none absolute inset-x-0 top-0 h-[3px] cable-flow"></div>
      <div class="pointer-events-none absolute -right-10 -top-12 h-52 w-52 rounded-full bg-brand/50 blur-3xl"></div>
      <div class="pointer-events-none absolute -bottom-16 left-1/3 h-48 w-48 rounded-full bg-accent/25 blur-3xl"></div>
      <svg class="pointer-events-none absolute inset-x-0 bottom-0 h-16 w-full opacity-70" viewBox="0 0 400 60" preserveAspectRatio="none" aria-hidden="true">
        <path d="M0 34 H70 L82 34 L92 10 L104 54 L114 34 H210 L222 34 L231 18 L241 48 L250 34 H400" fill="none" stroke="rgba(255,255,255,.12)" stroke-width="1.5" vector-effect="non-scaling-stroke" />
        <path class="pulse-trace" pathLength="100" d="M0 34 H70 L82 34 L92 10 L104 54 L114 34 H210 L222 34 L231 18 L241 48 L250 34 H400" fill="none" stroke="#FF7A5C" stroke-width="2.2" stroke-linecap="round" vector-effect="non-scaling-stroke" />
      </svg>
      <div class="relative flex flex-wrap items-center justify-between gap-5">
        <div>
          <h1 class="text-2xl font-extrabold md:text-3xl">{{ t('plant.title') }}</h1>
          <p class="mt-1 text-sm text-white/60">{{ t('plant.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-4 md:gap-6">
          <div class="rounded-2xl border border-white/10 bg-white/[.07] px-5 py-3 text-center">
            <p class="text-3xl font-extrabold tabular-nums text-emerald-300 md:text-4xl">{{ shownRunning }}<span class="mx-1 text-base font-semibold text-white/40">/ {{ live.machines.length }}</span></p>
            <p class="text-[11px] text-white/50">{{ locale.locale === 'ar' ? 'ماكينة تعمل الآن' : 'machines running now' }}</p>
          </div>
          <div class="rounded-2xl border border-white/10 bg-white/[.07] px-5 py-3 text-center">
            <p class="text-3xl font-extrabold tabular-nums md:text-4xl" :class="totalDown ? 'text-red-300' : 'text-white/80'">{{ totalDown }}</p>
            <p class="text-[11px] text-white/50">{{ locale.locale === 'ar' ? 'متوقفة / قيد الإصلاح' : 'down / in repair' }}</p>
          </div>
          <span class="inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-xs font-semibold" :class="live.connected ? 'border-emerald-300/30 bg-emerald-300/10 text-emerald-200' : 'border-red-300/30 bg-red-300/10 text-red-200'">
            <Radio v-if="live.connected" :size="13" class="animate-pulse" />
            <WifiOff v-else :size="13" />
            {{ live.connected ? t('plant.connected') : t('plant.disconnected') }}
          </span>
        </div>
      </div>
    </div>

    <!-- needs attention -->
    <div v-if="attention.length && !live.loading" class="enter mb-5 flex flex-wrap items-center gap-2 rounded-2xl border border-red-200 bg-gradient-to-r from-red-50 to-white p-3 shadow-[0_14px_28px_-20px_rgba(239,68,68,.6)]" style="--d:80ms">
      <span class="inline-flex items-center gap-1.5 pe-1 text-xs font-extrabold text-red-700"><TriangleAlert :size="15" />{{ t('plant.needsAttention') }}</span>
      <RouterLink v-for="m in attention.slice(0, 8)" :key="m.id" :to="`/machines/${encodeURIComponent(m.code || m.id)}`" class="inline-flex items-center gap-1.5 rounded-full border border-red-200 bg-white px-2.5 py-1 text-xs font-bold text-red-800 transition hover:-translate-y-0.5 hover:border-red-400 hover:shadow-md">
        <i class="h-1.5 w-1.5 rounded-full" :class="m.status === 'underRepair' ? 'bg-status-underRepair' : 'bg-status-downMaintenance'"></i>{{ m.code }}
      </RouterLink>
      <span v-if="attention.length > 8" class="text-xs font-semibold text-red-700">{{ t('plant.more').replace('{n}', String(attention.length - 8)) }}</span>
    </div>

    <!-- filters -->
    <div v-if="!live.loading && live.machines.length" class="enter mb-6 flex flex-wrap items-center justify-between gap-3" style="--d:120ms">
      <div class="flex flex-wrap gap-2" role="group">
        <button v-for="chip in filterChips" :key="chip.key" type="button" class="chip" :class="{ 'is-on': statusFilter === chip.key }" :aria-pressed="statusFilter === chip.key" @click="statusFilter = chip.key">
          <i class="h-2 w-2 rounded-full" :class="chip.dot"></i>{{ chip.label }}<b>{{ counts[chip.key] }}</b>
        </button>
      </div>
      <label class="relative block w-full sm:w-64">
        <Search :size="15" class="pointer-events-none absolute start-3 top-1/2 -translate-y-1/2 text-slate-400" />
        <input v-model="search" type="search" class="form-control !min-h-10 !ps-9 !text-sm" :placeholder="t('plant.searchPlaceholder')" :aria-label="t('plant.searchPlaceholder')" />
      </label>
    </div>

    <p v-if="live.error" class="rounded-lg bg-accent-50 p-4 text-accent-dark">{{ live.error }}</p>
    <div v-else-if="live.loading" class="grid grid-cols-2 gap-4 sm:grid-cols-3 xl:grid-cols-5">
      <div v-for="i in 10" :key="i" class="skeleton h-28 rounded-2xl"></div>
    </div>

    <div v-else-if="filtering && !matchCount" class="rounded-2xl border border-dashed bg-white p-10 text-center text-slate-500">
      {{ t('plant.noMatch') }}
      <button type="button" class="mt-3 inline-flex items-center gap-1.5 rounded-lg px-3 py-2 text-sm font-bold text-brand-dark hover:bg-brand-50" @click="statusFilter = 'all'; search = ''"><X :size="14" />{{ t('workOrders.clear') }}</button>
    </div>
    <div v-else class="space-y-9">
      <section v-for="group in grouped" :key="group.key" class="dept-section">
        <div class="enter mb-4 flex items-center justify-between gap-3" :style="{ '--d': `${Math.min(group.offset, 24) * 18}ms` }">
          <h2 class="flex items-center gap-2.5 text-lg font-extrabold text-brand-navy"><span class="h-5 w-1.5 rounded-full bg-gradient-to-b from-accent to-brand"></span>{{ group.name }}</h2>
          <div class="flex items-center gap-2.5 rounded-full border border-slate-200 bg-white px-3 py-1.5 shadow-sm">
            <span class="text-xs font-bold tabular-nums text-slate-600">{{ group.running }}/{{ group.machines.length }}</span>
            <div class="h-1.5 w-24 overflow-hidden rounded-full bg-slate-100">
              <span class="meter-fill block h-full rounded-full bg-gradient-to-r from-emerald-500 to-emerald-300 transition-all duration-1000" :style="{ width: `${group.machines.length ? (group.running / group.machines.length) * 100 : 0}%` }"></span>
            </div>
          </div>
        </div>

        <div v-if="!group.machines.length" class="rounded-xl border border-dashed p-5 text-sm text-slate-500">{{ t('plant.noData') }}</div>
        <div v-else class="grid grid-cols-2 gap-4 sm:grid-cols-3 xl:grid-cols-5">
          <RouterLink
            v-for="(machine, mi) in group.machines" :key="machine.id" :to="`/machines/${encodeURIComponent(machine.code || machine.id)}`"
            class="machine-card enter p-4 outline-none"
            :data-status="machine.status" :data-urgent="isUrgent(machine.status)"
            :style="{ '--d': `${Math.min(group.offset + mi, 24) * 18 + 120}ms` }"
            @mousemove="onMove" @mouseleave="onLeave"
          >
            <div class="flex items-start justify-between gap-2">
              <div class="min-w-0">
                <p class="truncate text-base font-extrabold tracking-wide text-brand-navy">{{ machine.code }}</p>
                <p class="mt-0.5 truncate text-xs text-slate-500">{{ machine.name }}</p>
              </div>
              <StatusBadge :status="machine.status" dot-only class="mt-1.5 shrink-0" />
            </div>

            <p v-if="machine.status === 'running' && machine.current_speed_mpm" class="mt-3.5 inline-flex items-center gap-2 text-[11px] font-bold text-emerald-700">
              <span class="eq"><i></i><i></i><i></i></span>{{ machine.current_speed_mpm }} {{ locale.locale === 'ar' ? 'م/د' : 'm/min' }}
            </p>
            <p v-else-if="machine.status === 'running'" class="mt-3.5 text-[11px] font-bold text-emerald-700">{{ locale.locale === 'ar' ? 'تعمل' : 'Running' }}</p>
            <template v-if="machine.active_downtime_id">
              <p class="mt-3.5 line-clamp-1 text-xs font-bold text-red-600">{{ machine.active_downtime_reason || (locale.locale === 'ar' ? 'توقف نشط' : 'Active downtime') }}</p>
              <p v-if="machine.active_downtime_started_at" class="mt-1 text-[11px] font-semibold tabular-nums text-slate-500">{{ locale.locale === 'ar' ? 'متوقفة منذ' : 'down for' }} {{ Math.max(0, Math.floor((now - new Date(machine.active_downtime_started_at).getTime()) / 60000)) }} {{ locale.locale === 'ar' ? 'دقيقة' : 'min' }}</p>
            </template>
            <p v-else-if="machine.status !== 'running'" class="mt-3.5"><StatusBadge :status="machine.status" /></p>
          </RouterLink>
        </div>
      </section>
    </div>
  </div>
</template>
