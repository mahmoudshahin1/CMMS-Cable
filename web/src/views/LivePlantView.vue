<script setup lang="ts">
import { onMounted, onUnmounted, computed, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { Gauge, Radio, WifiOff } from 'lucide-vue-next'
import StatusBadge from '../components/StatusBadge.vue'
import { useLiveMonitoringStore } from '../stores/liveMonitoring'
import { useLocaleStore } from '../stores/locale'

const live = useLiveMonitoringStore()
const locale = useLocaleStore()
const t = locale.t
const departments = computed<Record<string, string>>(() => ({ drawing: t('downtime.departments.drawing'), ccv: t('downtime.departments.ccv'), stranding: t('downtime.departments.stranding'), armouring: t('downtime.departments.armouring'), extrusion: t('downtime.departments.extrusion'), assembly: t('downtime.departments.assembly'), screening: t('downtime.departments.screening'), rewinding: t('downtime.departments.rewinding') }))
const now = ref(Date.now())
const grouped = computed(() => Object.entries(departments.value).map(([key, name]) => ({ key, name, machines: live.machines.filter((m) => m.department === key) })))
const totalRunning = computed(() => live.machines.filter((m) => m.status === 'running').length)
const railColors: Record<string, string> = { running: 'bg-status-running', idle: 'bg-status-idle', downtimeProcess: 'bg-status-downProcess', downtimeMaintenance: 'bg-status-downMaintenance', underRepair: 'bg-status-underRepair', preventiveMaintenance: 'bg-status-idle', offline: 'bg-status-offline' }
const isUrgent = (status: string) => status === 'downtimeProcess' || status === 'downtimeMaintenance'
let timer: ReturnType<typeof setInterval> | null = null
onMounted(() => { void live.subscribe(); timer = setInterval(() => { now.value = Date.now() }, 30000) })
onUnmounted(() => { if (timer) clearInterval(timer); void live.unsubscribe() })
</script>

<template>
  <div :dir="locale.direction">
    <!-- hero status strip -->
    <div class="relative mb-7 overflow-hidden rounded-2xl bg-brand-navy p-5 text-white md:p-7">
      <div class="pointer-events-none absolute inset-x-0 top-0 h-[2px] cable-flow opacity-70"></div>
      <div class="pointer-events-none absolute -right-10 -top-10 h-44 w-44 rounded-full bg-brand/40 blur-3xl float-blob"></div>
      <div class="relative flex flex-wrap items-center justify-between gap-5">
        <div>
          <h1 class="text-2xl font-bold">{{ t('plant.title') }}</h1>
          <p class="mt-1 text-sm text-white/55">{{ t('plant.subtitle') }}</p>
        </div>
        <div class="flex items-center gap-5">
          <div class="text-end">
            <p class="text-3xl font-extrabold tabular-nums">{{ totalRunning }}<span class="mx-1 text-base font-semibold text-white/40">/ {{ live.machines.length }}</span></p>
            <p class="text-[11px] text-white/45">{{ locale.locale === 'ar' ? 'ماكينة تعمل الآن' : 'machines running now' }}</p>
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
    <div v-else-if="live.loading" class="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-5">
      <div v-for="i in 10" :key="i" class="skeleton h-24 rounded-xl"></div>
    </div>

    <div v-else class="space-y-8">
      <section v-for="(group, gi) in grouped" :key="group.key" class="rise-in" :style="{ '--rise-delay': `${gi * 60}ms` }">
        <div class="mb-3 flex items-center justify-between gap-3">
          <h2 class="text-lg font-bold text-brand-navy">{{ group.name }}</h2>
          <div class="flex min-w-[120px] items-center gap-2">
            <span class="text-xs font-semibold text-slate-500">{{ group.machines.filter((m) => m.status === 'running').length }}/{{ group.machines.length }}</span>
            <div class="h-1.5 w-20 overflow-hidden rounded-full bg-slate-100">
              <span class="block h-full rounded-full bg-status-running transition-all duration-700" :style="{ width: `${group.machines.length ? (group.machines.filter((m) => m.status === 'running').length / group.machines.length) * 100 : 0}%` }"></span>
            </div>
          </div>
        </div>

        <div v-if="!group.machines.length" class="rounded-xl border border-dashed p-5 text-sm text-slate-500">{{ t('plant.noData') }}</div>
        <div v-else class="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-5">
          <RouterLink
            v-for="machine in group.machines" :key="machine.id" :to="`/machines/${encodeURIComponent(machine.id)}`"
            class="group relative overflow-hidden rounded-xl border border-slate-200 bg-white p-4 ps-5 shadow-sm transition duration-200 hover:-translate-y-1 hover:border-brand/30 hover:shadow-lg"
            :class="isUrgent(machine.status) ? 'ring-1 ring-status-downMaintenance/20' : ''"
          >
            <span class="absolute inset-y-0 start-0 w-1.5" :class="railColors[machine.status] ?? 'bg-slate-300'"></span>
            <div class="flex items-start justify-between gap-2">
              <div class="min-w-0">
                <p class="truncate font-bold text-brand-navy">{{ machine.code }}</p>
                <p class="mt-0.5 truncate text-xs text-slate-500">{{ machine.name }}</p>
              </div>
              <StatusBadge :status="machine.status" dot-only class="mt-1 shrink-0" />
            </div>

            <p v-if="machine.status === 'running' && machine.current_speed_mpm" class="mt-3 inline-flex items-center gap-1 text-[11px] font-semibold text-emerald-700">
              <Gauge :size="12" />{{ machine.current_speed_mpm }} {{ locale.locale === 'ar' ? 'م/د' : 'm/min' }}
            </p>
            <p v-if="machine.active_downtime_id" class="mt-3 line-clamp-1 text-xs font-semibold text-status-downMaintenance">{{ machine.active_downtime_reason || (locale.locale === 'ar' ? 'توقف نشط' : 'Active downtime') }}</p>
            <p v-if="machine.active_downtime_started_at" class="mt-1 text-[11px] text-slate-400">{{ locale.locale === 'ar' ? 'متوقفة منذ' : 'down for' }} {{ Math.max(0, Math.floor((now - new Date(machine.active_downtime_started_at).getTime()) / 60000)) }} {{ locale.locale === 'ar' ? 'دقيقة' : 'min' }}</p>
          </RouterLink>
        </div>
      </section>
    </div>
  </div>
</template>
