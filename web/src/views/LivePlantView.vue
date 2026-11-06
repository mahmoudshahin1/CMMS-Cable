<script setup lang="ts">
import { onMounted, onUnmounted, computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { Radio, WifiOff } from 'lucide-vue-next'
import StatusBadge from '../components/StatusBadge.vue'
import { useLiveMonitoringStore } from '../stores/liveMonitoring'
import { useLocaleStore } from '../stores/locale'

const live = useLiveMonitoringStore()
const locale = useLocaleStore()
const t = locale.t
const departments = computed<Record<string, string>>(() => ({ drawing: t('downtime.departments.drawing'), ccv: t('downtime.departments.ccv'), stranding: t('downtime.departments.stranding'), armouring: t('downtime.departments.armouring'), extrusion: t('downtime.departments.extrusion'), assembly: t('downtime.departments.assembly'), screening: t('downtime.departments.screening'), rewinding: t('downtime.departments.rewinding') }))
const now = ref(Date.now())
const grouped = computed(() => {
  let offset = 0
  return Object.entries(departments.value).map(([key, name]) => {
    const machines = live.machines.filter((m) => m.department === key)
    const group = { key, name, machines, offset, running: machines.filter((m) => m.status === 'running').length }
    offset += machines.length
    return group
  })
})
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
function onMove(event: MouseEvent) {
  const el = event.currentTarget as HTMLElement
  const rect = el.getBoundingClientRect()
  const x = event.clientX - rect.left
  const y = event.clientY - rect.top
  el.style.setProperty('--mx', `${x}px`)
  el.style.setProperty('--my', `${y}px`)
  el.style.setProperty('--ry', `${(x / rect.width - 0.5) * 9}deg`)
  el.style.setProperty('--rx', `${-(y / rect.height - 0.5) * 9}deg`)
}
function onLeave(event: MouseEvent) {
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
      <div class="pointer-events-none absolute -right-10 -top-12 h-52 w-52 rounded-full bg-brand/50 blur-3xl float-blob"></div>
      <div class="pointer-events-none absolute -bottom-16 left-1/3 h-48 w-48 rounded-full bg-accent/25 blur-3xl float-blob" style="animation-delay:-3s"></div>
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
          <div class="rounded-2xl border border-white/10 bg-white/[.07] px-5 py-3 text-center backdrop-blur-sm">
            <p class="text-3xl font-extrabold tabular-nums text-emerald-300 md:text-4xl">{{ shownRunning }}<span class="mx-1 text-base font-semibold text-white/40">/ {{ live.machines.length }}</span></p>
            <p class="text-[11px] text-white/50">{{ locale.locale === 'ar' ? 'ماكينة تعمل الآن' : 'machines running now' }}</p>
          </div>
          <div class="rounded-2xl border border-white/10 bg-white/[.07] px-5 py-3 text-center backdrop-blur-sm">
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

    <p v-if="live.error" class="rounded-lg bg-accent-50 p-4 text-accent-dark">{{ live.error }}</p>
    <div v-else-if="live.loading" class="grid grid-cols-2 gap-4 sm:grid-cols-3 xl:grid-cols-5">
      <div v-for="i in 10" :key="i" class="skeleton h-28 rounded-2xl"></div>
    </div>

    <div v-else class="space-y-9">
      <section v-for="group in grouped" :key="group.key">
        <div class="enter mb-4 flex items-center justify-between gap-3" :style="{ '--d': `${Math.min(group.offset, 30) * 28}ms` }">
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
            v-for="(machine, mi) in group.machines" :key="machine.id" :to="`/machines/${encodeURIComponent(machine.id)}`"
            class="machine-card enter p-4 outline-none"
            :data-status="machine.status" :data-urgent="isUrgent(machine.status)"
            :style="{ '--d': `${Math.min(group.offset + mi, 30) * 28 + 140}ms` }"
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
