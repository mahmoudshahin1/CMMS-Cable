<script setup lang="ts">
import { useLocaleStore } from '../stores/locale'
const props = defineProps<{ status: string; dotOnly?: boolean }>()
const locale = useLocaleStore()
const labels: Record<string, string> = { running: 'تعمل', idle: 'متوقفة مؤقتًا', downtimeProcess: 'عطل إنتاجي', downtimeMaintenance: 'صيانة', underRepair: 'قيد الإصلاح', preventiveMaintenance: 'صيانة وقائية', offline: 'غير متصلة' }
const labelsEn: Record<string, string> = { running: 'Running', idle: 'Idle', downtimeProcess: 'Process downtime', downtimeMaintenance: 'Maintenance', underRepair: 'Under repair', preventiveMaintenance: 'Preventive maintenance', offline: 'Offline' }
const colors: Record<string, string> = { running: 'bg-status-running/10 text-emerald-800', idle: 'bg-status-idle/10 text-amber-800', downtimeProcess: 'bg-status-downProcess/10 text-orange-800', downtimeMaintenance: 'bg-status-downMaintenance/10 text-red-800', underRepair: 'bg-status-underRepair/10 text-violet-800', preventiveMaintenance: 'bg-status-idle/10 text-amber-800', offline: 'bg-slate-200 text-slate-600' }
const dots: Record<string, string> = { running: 'bg-status-running', idle: 'bg-status-idle', downtimeProcess: 'bg-status-downProcess', downtimeMaintenance: 'bg-status-downMaintenance', underRepair: 'bg-status-underRepair', preventiveMaintenance: 'bg-status-idle', offline: 'bg-status-offline' }
</script>
<template>
  <span v-if="props.dotOnly" class="relative inline-flex h-2.5 w-2.5">
    <span class="relative h-2.5 w-2.5 rounded-full" :class="dots[props.status] ?? 'bg-slate-300'"></span>
  </span>
  <span v-else class="inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-semibold" :class="colors[props.status] ?? 'bg-slate-100 text-slate-700'">
    <span class="h-1.5 w-1.5 shrink-0 rounded-full" :class="[dots[props.status] ?? 'bg-slate-400', props.status === 'running' ? 'animate-pulse' : '']"></span>
    {{ (locale.locale === 'ar' ? labels : labelsEn)[props.status] ?? props.status }}
  </span>
</template>
