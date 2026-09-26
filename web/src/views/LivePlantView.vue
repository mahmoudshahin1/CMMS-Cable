<script setup lang="ts">
import { onMounted, onUnmounted, computed } from 'vue'
import StatusBadge from '../components/StatusBadge.vue'
import { useLiveMonitoringStore } from '../stores/liveMonitoring'
const live = useLiveMonitoringStore()
const departments: Record<string, string> = { drawing: 'السحب', ccv: 'العزل والتكسية', stranding: 'الجدل', tapeArmour: 'التسليح', extrusion: 'الغلاف الخارجي', assembly: 'إعادة لف', screening: 'التجهيز' }
const grouped = computed(() => Object.entries(departments).map(([key, name]) => ({ key, name, machines: live.machines.filter((m) => m.department === key) })))
onMounted(() => void live.subscribe())
onUnmounted(() => void live.unsubscribe())
</script>
<template>
  <div>
    <div class="mb-6 flex items-center justify-between"><div><h1 class="text-2xl font-bold">أرضية المصنع</h1><p class="mt-1 text-sm text-slate-500">حالة مباشرة لخطوط الإنتاج</p></div><span class="flex items-center gap-2 text-sm"><i class="h-2.5 w-2.5 rounded-full" :class="live.connected ? 'bg-emerald-500' : 'bg-red-500'"></i>{{ live.connected ? 'متصل' : 'منقطع' }}</span></div>
    <p v-if="live.error" class="rounded-lg bg-red-50 p-4 text-red-700">{{ live.error }}</p>
    <p v-else-if="live.loading" class="text-slate-500">جارٍ تحميل الماكينات…</p>
    <div v-else class="space-y-8">
      <section v-for="group in grouped" :key="group.key"><div class="mb-3 flex items-baseline justify-between"><h2 class="text-lg font-bold">{{ group.name }}</h2><span class="text-xs text-slate-500">{{ group.machines.filter((m) => m.status === 'running').length }} من {{ group.machines.length }} تعمل</span></div>
        <div v-if="!group.machines.length" class="rounded-xl border border-dashed p-5 text-sm text-slate-500">لا توجد بيانات كافية بعد</div>
        <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-5"><article v-for="machine in group.machines" :key="machine.id" class="rounded-xl border bg-white p-4 shadow-sm"><div class="flex items-start justify-between gap-2"><div><p class="font-bold">{{ machine.code }}</p><p class="mt-1 text-xs text-slate-500">{{ machine.name }}</p></div><StatusBadge :status="machine.status" /></div><p v-if="machine.active_downtime_id" class="mt-3 text-xs text-red-600">{{ machine.active_downtime_reason || 'توقف نشط' }}</p></article></div>
      </section>
    </div>
  </div>
</template>
