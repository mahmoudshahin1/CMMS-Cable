<script setup lang="ts">
import { onMounted, ref } from 'vue'
import VChart from 'vue-echarts'
import { use } from 'echarts/core'
import { BarChart } from 'echarts/charts'
import { GridComponent, TooltipComponent } from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'
import { supabase } from '../api/supabase'
use([BarChart, GridComponent, TooltipComponent, CanvasRenderer])
const option = ref<Record<string, unknown>>({}); const error = ref('')
onMounted(async () => {
  if (!supabase) { error.value = 'إعداد Supabase غير مكتمل.'; return }
  const { data, error: queryError } = await supabase.from('v_downtime_pareto').select('category, total_minutes').order('total_minutes', { ascending: false }).limit(8)
  if (queryError) { error.value = queryError.message; return }
  option.value = { tooltip: {}, grid: { left: 12, right: 24, bottom: 24, containLabel: true }, xAxis: { type: 'value' }, yAxis: { type: 'category', data: (data ?? []).map((item) => item.category).reverse() }, series: [{ type: 'bar', data: (data ?? []).map((item) => item.total_minutes).reverse(), itemStyle: { color: '#00a3e0' } }] }
})
</script>
<template><section><h1 class="mb-1 text-2xl font-bold">التقارير والتحليلات</h1><p class="mb-6 text-sm text-slate-500">ملخص أسباب التوقف</p><p v-if="error" class="rounded-lg bg-red-50 p-4 text-red-700">{{ error }}</p><VChart v-else-if="Object.keys(option).length" :option="option" autoresize class="h-96 rounded-xl border bg-white p-4" /><p v-else class="text-slate-500">جارٍ تحميل التقارير…</p></section></template>
