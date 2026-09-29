<script setup lang="ts">
import { onMounted, onUnmounted, computed, ref } from 'vue'
import { RouterLink } from 'vue-router'
import StatusBadge from '../components/StatusBadge.vue'
import { useLiveMonitoringStore } from '../stores/liveMonitoring'
import { useLocaleStore } from '../stores/locale'
const live = useLiveMonitoringStore()
const locale = useLocaleStore()
const t = locale.t
const departments = computed<Record<string, string>>(() => ({ drawing: t('downtime.departments.drawing'), ccv: t('downtime.departments.ccv'), stranding: t('downtime.departments.stranding'), tapeArmour: t('downtime.departments.tapeArmour'), extrusion: t('downtime.departments.extrusion'), assembly: t('downtime.departments.assembly'), screening: t('downtime.departments.screening') }))
const now = ref(Date.now())
const grouped = computed(() => Object.entries(departments.value).map(([key, name]) => ({ key, name, machines: live.machines.filter((m) => m.department === key) })))
const cardColors: Record<string, string> = { running: 'border-emerald-200 bg-emerald-50', idle: 'border-slate-200 bg-slate-100', downtimeProcess: 'border-red-200 bg-red-50', downtimeMaintenance: 'border-red-200 bg-red-50', underRepair: 'border-red-200 bg-red-50', preventiveMaintenance: 'border-amber-200 bg-amber-50', offline: 'border-slate-500 bg-slate-600 text-white' }
let timer: ReturnType<typeof setInterval> | null = null
onMounted(() => { void live.subscribe(); timer = setInterval(() => { now.value = Date.now() }, 30000) })
onUnmounted(() => { if (timer) clearInterval(timer); void live.unsubscribe() })
</script>
<template>
  <div :dir="locale.direction">
    <div class="mb-6 flex items-center justify-between"><div><h1 class="text-2xl font-bold">{{ t('plant.title') }}</h1><p class="mt-1 text-sm text-slate-500">{{ t('plant.subtitle') }}</p></div><span class="flex items-center gap-2 text-sm"><i class="h-2.5 w-2.5 rounded-full" :class="live.connected ? 'bg-emerald-500' : 'bg-red-500'"></i>{{ live.connected ? t('plant.connected') : t('plant.disconnected') }}</span></div>
    <p v-if="live.error" class="rounded-lg bg-red-50 p-4 text-red-700">{{ live.error }}</p>
    <p v-else-if="live.loading" class="text-slate-500">{{ t('plant.loading') }}</p>
    <div v-else class="space-y-8">
      <section v-for="group in grouped" :key="group.key"><div class="mb-3 flex items-baseline justify-between"><h2 class="text-lg font-bold">{{ group.name }}</h2><span class="text-xs text-slate-500">{{ group.machines.filter((m) => m.status === 'running').length }} من {{ group.machines.length }} تعمل</span></div>
        <div v-if="!group.machines.length" class="rounded-xl border border-dashed p-5 text-sm text-slate-500">{{ t('plant.noData') }}</div>
        <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-5"><RouterLink v-for="machine in group.machines" :key="machine.id" :to="`/machines/${encodeURIComponent(machine.id)}`" class="rounded-xl border p-4 shadow-sm transition hover:-translate-y-0.5 hover:border-brand hover:shadow-md" :class="cardColors[machine.status] ?? 'border-slate-200 bg-white'"><div class="flex items-start justify-between gap-2"><div><p class="font-bold">{{ machine.code }}</p><p class="mt-1 text-xs opacity-75">{{ machine.name }}</p></div><StatusBadge :status="machine.status" /></div><p v-if="machine.active_downtime_id" class="mt-3 text-xs text-red-700">{{ machine.active_downtime_reason || 'توقف نشط' }}</p><p v-if="machine.active_downtime_started_at" class="mt-1 text-xs opacity-75">متوقفة منذ {{ Math.max(0, Math.floor((now - new Date(machine.active_downtime_started_at).getTime()) / 60000)) }} دقيقة</p></RouterLink></div>
      </section>
    </div>
  </div>
</template>
