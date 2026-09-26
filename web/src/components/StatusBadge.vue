<script setup lang="ts">
defineProps<{ status: string }>()
const labels: Record<string, string> = { running: 'تعمل', idle: 'متوقفة مؤقتًا', downtimeProcess: 'عطل إنتاجي', downtimeMaintenance: 'صيانة', underRepair: 'قيد الإصلاح', preventiveMaintenance: 'صيانة وقائية', offline: 'غير متصلة' }
</script>
<template><span class="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-700">{{ labels[status] ?? status }}</span></template>
