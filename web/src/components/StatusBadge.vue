<script setup lang="ts">
defineProps<{ status: string }>()
const labels: Record<string, string> = { running: 'تعمل', idle: 'متوقفة مؤقتًا', downtimeProcess: 'عطل إنتاجي', downtimeMaintenance: 'صيانة', underRepair: 'قيد الإصلاح', preventiveMaintenance: 'صيانة وقائية', offline: 'غير متصلة' }
const colors: Record<string, string> = { running: 'bg-emerald-100 text-emerald-800', idle: 'bg-slate-100 text-slate-700', downtimeProcess: 'bg-red-100 text-red-800', downtimeMaintenance: 'bg-red-100 text-red-800', underRepair: 'bg-red-100 text-red-800', preventiveMaintenance: 'bg-amber-100 text-amber-800', offline: 'bg-slate-300 text-slate-700' }
</script>
<template><span class="rounded-full px-3 py-1 text-xs font-semibold" :class="colors[status] ?? 'bg-slate-100 text-slate-700'">{{ labels[status] ?? status }}</span></template>
