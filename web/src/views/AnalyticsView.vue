<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import type { RealtimeChannel } from '@supabase/supabase-js'
import VChart from 'vue-echarts'
import { use } from 'echarts/core'
import { BarChart, LineChart, PieChart } from 'echarts/charts'
import { GridComponent, LegendComponent, TooltipComponent } from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'
import { Activity, ArrowDownLeft, ArrowUpLeft, ChartNoAxesCombined, ClipboardList, Factory, RefreshCw, Timer, TriangleAlert, Zap } from 'lucide-vue-next'
import { supabase } from '../api/supabase'
import { departmentLabels, statusLabel } from '../lib/workOrders'
import { downtimeCategoryLabel } from '../lib/downtime'
import type { Machine } from '../stores/liveMonitoring'

use([BarChart, LineChart, PieChart, GridComponent, LegendComponent, TooltipComponent, CanvasRenderer])

type Availability = { department: string; production_date: string; machine_count: number; downtime_minutes: number; availability_pct: number }
type Pareto = { department: string; category: string; event_count: number; total_minutes: number; avg_minutes: number }
type Mttr = { department: string; closed_count: number; mttr_minutes: number | null }
type BadActor = { id: string; code: string; name: string; department: string; breakdown_count: number; total_downtime_minutes: number }
type Funnel = { status: string; count: number }
type ShiftSplit = { production_date: string; department: string; shift1_morning_minutes: number; shift2_evening_minutes: number; shift3_night_minutes: number }

const colors = ['#00AEEF', '#123B66', '#24B47E', '#F3A63B', '#7C6CE7', '#F06464', '#5AA6B9']
const machines = ref<Machine[]>([])
const availability = ref<Availability[]>([])
const pareto = ref<Pareto[]>([])
const mttr = ref<Mttr[]>([])
const badActors = ref<BadActor[]>([])
const funnel = ref<Funnel[]>([])
const shifts = ref<ShiftSplit[]>([])
const loading = ref(true)
const refreshing = ref(false)
const error = ref('')
const connected = ref(false)
const selectedDepartment = ref('')
const updatedAt = ref<Date | null>(null)
let channel: RealtimeChannel | null = null

const departments = computed(() => Object.keys(departmentLabels).filter((key) => availability.value.some((row) => row.department === key) || machines.value.some((m) => m.department === key)))
const latestDate = computed(() => availability.value.reduce((latest, row) => row.production_date > latest ? row.production_date : latest, ''))
const dataLagDays = computed(() => latestDate.value ? Math.max(0, Math.floor((Date.now() - new Date(`${latestDate.value}T12:00:00Z`).getTime()) / 86400000)) : null)
const latestAvailability = computed(() => availability.value.filter((row) => row.production_date === latestDate.value && (!selectedDepartment.value || row.department === selectedDepartment.value)))
const visibleAvailability = computed(() => availability.value.filter((row) => !selectedDepartment.value || row.department === selectedDepartment.value))
const visiblePareto = computed(() => pareto.value.filter((row) => !selectedDepartment.value || row.department === selectedDepartment.value))
const visibleShifts = computed(() => shifts.value.filter((row) => !selectedDepartment.value || row.department === selectedDepartment.value))
const downtimeByCause = computed(() => {
  const groups = new Map<string, { minutes: number; events: number }>()
  for (const row of visiblePareto.value) {
    const current = groups.get(row.category) ?? { minutes: 0, events: 0 }
    current.minutes += Number(row.total_minutes) || 0
    current.events += Number(row.event_count) || 0
    groups.set(row.category, current)
  }
  return [...groups.entries()].map(([category, values]) => ({ category, ...values })).sort((a, b) => b.minutes - a.minutes).slice(0, 8)
})
const availabilityScore = computed(() => {
  const totalMachines = latestAvailability.value.reduce((sum, row) => sum + Number(row.machine_count), 0)
  if (!totalMachines) return null
  return latestAvailability.value.reduce((sum, row) => sum + Number(row.availability_pct) * Number(row.machine_count), 0) / totalMachines
})
const runningCount = computed(() => machines.value.filter((machine) => machine.status === 'running').length)
const activeStops = computed(() => machines.value.filter((machine) => machine.active_downtime_id))
const openOrders = computed(() => funnel.value.filter((item) => !['completed', 'verified', 'verifiedClosed'].includes(item.status)).reduce((sum, item) => sum + Number(item.count), 0))
const closedOrders = computed(() => funnel.value.find((item) => item.status === 'verifiedClosed')?.count ?? 0)
const averageMttr = computed(() => {
  const rows = mttr.value.filter((row) => row.mttr_minutes !== null && Number(row.mttr_minutes) > 0 && Number(row.closed_count) > 0)
  const count = rows.reduce((sum, row) => sum + Number(row.closed_count), 0)
  return count ? rows.reduce((sum, row) => sum + Number(row.mttr_minutes) * Number(row.closed_count), 0) / count : null
})
const downtimeMinutesNow = computed(() => activeStops.value.reduce((sum, machine) => sum + Number(machine.active_downtime_minutes ?? 0), 0))
const departmentAvailability = computed(() => [...latestAvailability.value].sort((a, b) => Number(b.availability_pct) - Number(a.availability_pct)))
const topActors = computed(() => [...badActors.value].sort((a, b) => Number(b.total_downtime_minutes) - Number(a.total_downtime_minutes)).slice(0, 7))
const workOrderStatus = computed(() => [...funnel.value].sort((a, b) => Number(b.count) - Number(a.count)))
const shiftsByDate = computed(() => {
  const values = new Map<string, { morning: number; evening: number; night: number }>()
  for (const row of visibleShifts.value) {
    const current = values.get(row.production_date) ?? { morning: 0, evening: 0, night: 0 }
    current.morning += Number(row.shift1_morning_minutes) || 0
    current.evening += Number(row.shift2_evening_minutes) || 0
    current.night += Number(row.shift3_night_minutes) || 0
    values.set(row.production_date, current)
  }
  return [...values.entries()].sort(([a], [b]) => a.localeCompare(b)).slice(-7)
})

const dateLabel = (value: string) => new Intl.DateTimeFormat('ar-EG', { day: 'numeric', month: 'short', timeZone: 'Africa/Cairo' }).format(new Date(`${value}T12:00:00Z`))
const number = (value: number | string | null | undefined, digits = 0) => value === null || value === undefined ? '—' : Number(value).toLocaleString('ar-EG', { maximumFractionDigits: digits })
const availabilityTrendOption = computed<Record<string, unknown>>(() => {
  const dates = [...new Set(visibleAvailability.value.map((row) => row.production_date))].sort()
  const seriesDepartments = selectedDepartment.value ? [selectedDepartment.value] : departments.value
  return {
    color: colors,
    tooltip: { trigger: 'axis', valueFormatter: (value: number) => `${number(value, 1)}%` },
    legend: { bottom: 0, type: 'scroll', textStyle: { fontFamily: 'Cairo', fontSize: 10 } },
    grid: { top: 22, left: 8, right: 16, bottom: 48, containLabel: true },
    xAxis: { type: 'category', boundaryGap: false, data: dates.map(dateLabel), axisLine: { lineStyle: { color: '#e2e8f0' } }, axisLabel: { color: '#64748b', fontFamily: 'Cairo' } },
    yAxis: { type: 'value', min: 0, max: 100, axisLabel: { formatter: '{value}%', color: '#94a3b8' }, splitLine: { lineStyle: { color: '#edf2f7' } } },
    series: seriesDepartments.map((department) => ({ name: departmentLabels[department] ?? department, type: 'line', smooth: true, symbol: 'circle', symbolSize: 6, emphasis: { focus: 'series' }, areaStyle: { opacity: .055 }, data: dates.map((date) => visibleAvailability.value.find((row) => row.production_date === date && row.department === department)?.availability_pct ?? null) })),
  }
})
const causesOption = computed<Record<string, unknown>>(() => ({
  color: ['#0A2540', '#00AEEF', '#24B47E', '#F3A63B', '#7C6CE7', '#F06464', '#5AA6B9', '#94A3B8'],
  tooltip: { trigger: 'item', formatter: (params: { name: string; value: number; percent: number }) => `${downtimeCategoryLabel(params.name)}<br/><b>${number(params.value)} دقيقة</b> · ${params.percent}%` },
  series: [{ type: 'pie', radius: ['56%', '78%'], center: ['50%', '48%'], avoidLabelOverlap: true, itemStyle: { borderColor: '#fff', borderWidth: 4, borderRadius: 7 }, label: { show: false }, emphasis: { scale: true, scaleSize: 8 }, data: downtimeByCause.value.map((row) => ({ name: row.category, value: Math.round(row.minutes) })) }],
}))
const departmentOption = computed<Record<string, unknown>>(() => ({
  color: ['#00AEEF'], tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, valueFormatter: (value: number) => `${number(value, 1)}%` },
  grid: { top: 12, left: 8, right: 20, bottom: 4, containLabel: true }, xAxis: { type: 'value', max: 100, axisLabel: { formatter: '{value}%', color: '#94a3b8' }, splitLine: { lineStyle: { color: '#edf2f7' } } },
  yAxis: { type: 'category', data: departmentAvailability.value.map((row) => departmentLabels[row.department] ?? row.department).reverse(), axisLabel: { color: '#475569', fontFamily: 'Cairo' }, axisLine: { show: false }, axisTick: { show: false } },
  series: [{ type: 'bar', barWidth: 15, showBackground: true, backgroundStyle: { color: '#f1f5f9', borderRadius: 8 }, itemStyle: { borderRadius: [0, 8, 8, 0], color: (params: { value: number }) => params.value >= 90 ? '#24B47E' : params.value >= 75 ? '#F3A63B' : '#F06464' }, data: departmentAvailability.value.map((row) => Number(row.availability_pct)).reverse() }],
}))
const workOrderOption = computed<Record<string, unknown>>(() => ({
  color: ['#00AEEF'], tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } }, grid: { top: 10, left: 8, right: 20, bottom: 4, containLabel: true },
  xAxis: { type: 'value', minInterval: 1, splitLine: { lineStyle: { color: '#edf2f7' } }, axisLabel: { color: '#94a3b8' } }, yAxis: { type: 'category', data: workOrderStatus.value.map((row) => statusLabel(row.status)).reverse(), axisLabel: { color: '#475569', fontFamily: 'Cairo' }, axisLine: { show: false }, axisTick: { show: false } },
  series: [{ type: 'bar', barWidth: 17, itemStyle: { borderRadius: [0, 8, 8, 0], color: '#123B66' }, data: workOrderStatus.value.map((row) => Number(row.count)).reverse(), label: { show: true, position: 'insideRight', color: '#fff', fontWeight: 'bold' } }],
}))
const shiftOption = computed<Record<string, unknown>>(() => ({
  color: ['#00AEEF', '#F3A63B', '#123B66'], tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, valueFormatter: (value: number) => `${number(value)} دقيقة` }, legend: { bottom: 0, textStyle: { fontFamily: 'Cairo', fontSize: 10 } },
  grid: { top: 20, left: 8, right: 15, bottom: 45, containLabel: true }, xAxis: { type: 'category', data: shiftsByDate.value.map(([date]) => dateLabel(date)), axisLabel: { color: '#64748b', fontFamily: 'Cairo' } }, yAxis: { type: 'value', axisLabel: { color: '#94a3b8' }, splitLine: { lineStyle: { color: '#edf2f7' } } },
  series: [
    { name: 'صباحية', type: 'bar', stack: 'total', barMaxWidth: 25, itemStyle: { borderRadius: [0, 0, 4, 4] }, data: shiftsByDate.value.map(([, value]) => Math.round(value.morning)) },
    { name: 'مسائية', type: 'bar', stack: 'total', itemStyle: { borderRadius: [0, 0, 4, 4] }, data: shiftsByDate.value.map(([, value]) => Math.round(value.evening)) },
    { name: 'ليلية', type: 'bar', stack: 'total', itemStyle: { borderRadius: [5, 5, 0, 0] }, data: shiftsByDate.value.map(([, value]) => Math.round(value.night)) },
  ],
}))
const machineStatusOption = computed<Record<string, unknown>>(() => {
  const statuses = new Map<string, number>()
  for (const machine of machines.value) statuses.set(machine.status, (statuses.get(machine.status) ?? 0) + 1)
  const statusNames: Record<string, string> = { running: 'تعمل', idle: 'متوقفة مؤقتًا', downtimeProcess: 'عطل إنتاجي', downtimeMaintenance: 'صيانة', underRepair: 'قيد الإصلاح', preventiveMaintenance: 'صيانة وقائية', offline: 'غير متصلة' }
  const statusColors: Record<string, string> = { running: '#24B47E', idle: '#CBD5E1', downtimeProcess: '#F06464', downtimeMaintenance: '#DC4C64', underRepair: '#F97362', preventiveMaintenance: '#F3A63B', offline: '#475569' }
  return { tooltip: { trigger: 'item', formatter: '{b}<br/><b>{c}</b> ماكينة · {d}%' }, legend: { bottom: 0, left: 'center', textStyle: { fontFamily: 'Cairo', fontSize: 10 } }, series: [{ type: 'pie', radius: ['54%', '76%'], center: ['50%', '43%'], itemStyle: { borderColor: '#fff', borderWidth: 4 }, label: { show: false }, data: [...statuses.entries()].map(([key, value]) => ({ name: statusNames[key] ?? key, value, itemStyle: { color: statusColors[key] ?? '#94A3B8' } })) }] }
})

async function refresh() {
  if (!supabase) { error.value = 'إعداد Supabase غير مكتمل.'; loading.value = false; return }
  refreshing.value = !loading.value
  const results = await Promise.all([
    supabase.from('v_machine_status_live').select('*').order('code'),
    supabase.from('v_line_availability_daily').select('*').order('production_date', { ascending: true }),
    supabase.from('v_downtime_pareto').select('*').order('total_minutes', { ascending: false }),
    supabase.from('v_mttr_by_department').select('*'),
    supabase.from('v_bad_actors_30d').select('*').order('total_downtime_minutes', { ascending: false }).limit(10),
    supabase.from('v_work_order_funnel').select('*'),
    supabase.from('v_shift_downtime_split').select('*').order('production_date', { ascending: true }),
  ])
  const errors = results.flatMap((result) => result.error ? [result.error.message] : [])
  machines.value = (results[0].data ?? []) as Machine[]
  availability.value = (results[1].data ?? []) as Availability[]
  pareto.value = (results[2].data ?? []) as Pareto[]
  mttr.value = (results[3].data ?? []) as Mttr[]
  badActors.value = (results[4].data ?? []) as BadActor[]
  funnel.value = (results[5].data ?? []) as Funnel[]
  shifts.value = (results[6].data ?? []) as ShiftSplit[]
  error.value = errors.length ? errors.join(' · ') : ''
  updatedAt.value = new Date()
  loading.value = false
  refreshing.value = false
}
function availabilityColor(value: number) { return value >= 90 ? 'text-emerald-600' : value >= 75 ? 'text-amber-600' : 'text-red-600' }
function progressWidth(value: number) { return `${Math.max(0, Math.min(100, value))}%` }
function openMachine(code: string) { window.location.assign(`/machines/${encodeURIComponent(code)}`) }
onMounted(() => {
  void refresh()
  if (supabase) channel = supabase.channel('web-analytics-live')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'machines' }, () => void refresh())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'downtime_logs' }, () => void refresh())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'work_orders' }, () => void refresh())
    .subscribe((status) => { connected.value = status === 'SUBSCRIBED' })
})
onUnmounted(() => { if (supabase && channel) void supabase.removeChannel(channel) })
</script>

<template>
  <section class="space-y-6">
    <header class="rise-in relative isolate overflow-hidden rounded-[26px] bg-brand-navy px-5 py-6 text-white shadow-[0_20px_55px_-28px_rgba(10,37,64,.6)] md:px-8 md:py-7">
      <div class="pointer-events-none absolute -left-12 -top-24 -z-10 h-80 w-80 rounded-full border border-cyan-100/10"></div><div class="pointer-events-none absolute -left-2 -top-16 -z-10 h-60 w-60 rounded-full border border-cyan-100/10"></div><div class="pointer-events-none absolute bottom-[-120px] right-[35%] -z-10 h-64 w-64 rounded-full bg-brand/25 blur-3xl"></div>
      <div class="flex flex-wrap items-end justify-between gap-5"><div><div class="mb-3 flex items-center gap-2 text-xs font-bold text-cyan-200"><ChartNoAxesCombined :size="16" /> مركز الرؤية التشغيلية <span class="rounded-full bg-white/10 px-2 py-1 text-[10px] text-white/65">آخر 7 أيام</span></div><h1 class="text-2xl font-extrabold md:text-3xl">التحليلات والأداء</h1><p class="mt-2 max-w-2xl text-sm leading-6 text-white/60">قراءة موحدة للتوافر، التوقفات، الصيانة، وحالة خطوط المصنع.</p></div><div class="flex flex-wrap items-center gap-2"><label title="يطبق فلتر القسم على الرسوم حسب القسم" class="flex items-center gap-2 rounded-xl border border-white/10 bg-white/[.08] px-3 py-2 text-xs"><Factory :size="15" class="text-cyan-200"/><select v-model="selectedDepartment" class="max-w-40 bg-transparent text-white outline-none [&>option]:text-slate-900"><option value="">كل الأقسام</option><option v-for="department in departments" :key="department" :value="department">{{ departmentLabels[department] ?? department }}</option></select></label><span class="flex items-center gap-2 rounded-xl border border-white/10 bg-white/[.08] px-3 py-2 text-xs"><i class="h-2 w-2 rounded-full" :class="connected ? 'bg-emerald-300 soft-pulse' : 'bg-red-300'"></i>{{ connected ? 'مباشر' : 'غير متصل' }}</span><button class="inline-flex items-center gap-2 rounded-xl bg-brand px-3.5 py-2 text-xs font-extrabold text-white shadow-lg shadow-cyan-950/25 transition hover:-translate-y-0.5 hover:bg-brand-dark disabled:opacity-60" :disabled="refreshing" @click="refresh"><RefreshCw :size="14" :class="refreshing ? 'animate-spin' : ''"/>{{ refreshing ? 'تحديث…' : 'تحديث البيانات' }}</button></div></div>
      <p class="mt-5 flex flex-wrap items-center gap-x-2 gap-y-1 text-[10px] text-white/40">آخر مزامنة: {{ updatedAt ? updatedAt.toLocaleTimeString('ar-EG', { hour: '2-digit', minute: '2-digit', timeZone: 'Africa/Cairo' }) : '—' }} <span v-if="latestDate">· بيانات الإنتاج حتى {{ dateLabel(latestDate) }}</span><span v-if="dataLagDays !== null && dataLagDays >= 1" class="rounded-md bg-amber-300/15 px-2 py-0.5 font-bold text-amber-200">مصدر بيانات الإنتاج متأخر {{ number(dataLagDays) }} يوم</span></p>
    </header>

    <div v-if="error" class="flex items-start gap-3 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900" role="status"><TriangleAlert :size="18" class="mt-0.5 shrink-0"/><div><p class="font-bold">بعض مصادر التقارير لم تستجب</p><p class="mt-1 text-xs leading-5">{{ error }}</p></div></div>

    <div v-if="loading" class="grid gap-4 sm:grid-cols-2 xl:grid-cols-5"><div v-for="i in 5" :key="i" class="h-32 animate-pulse rounded-2xl bg-white shadow-sm"><div class="skeleton m-4 h-4 w-24 rounded"></div><div class="skeleton mx-4 mt-5 h-8 w-20 rounded"></div></div></div>
    <template v-else>
      <div class="grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
        <article class="surface-card rise-in relative overflow-hidden p-4" style="--rise-delay:30ms"><span class="absolute -left-5 -top-5 h-20 w-20 rounded-full bg-emerald-100/70 blur-xl"></span><div class="relative flex items-start justify-between"><div><p class="text-xs font-bold text-slate-500">التوافر التشغيلي</p><p class="mt-3 text-3xl font-extrabold tracking-tight" :class="availabilityScore === null ? 'text-slate-400' : availabilityColor(availabilityScore)">{{ availabilityScore === null ? '—' : `${number(availabilityScore, 1)}%` }}</p><p class="mt-1 text-[10px] text-slate-400">متوسط موزون بآخر يوم إنتاج</p></div><span class="grid h-10 w-10 place-items-center rounded-xl bg-emerald-50 text-emerald-600"><Activity :size="19"/></span></div></article>
        <article class="surface-card rise-in relative overflow-hidden p-4" style="--rise-delay:80ms"><span class="absolute -left-5 -top-5 h-20 w-20 rounded-full bg-cyan-100/70 blur-xl"></span><div class="relative flex items-start justify-between"><div><p class="text-xs font-bold text-slate-500">ماكينات تعمل</p><p class="mt-3 text-3xl font-extrabold tracking-tight text-brand-navy">{{ number(runningCount) }}<span class="mr-1 text-sm font-semibold text-slate-400">/ {{ number(machines.length) }}</span></p><p class="mt-1 text-[10px] text-slate-400">إجمالي الماكينات الظاهرة لك</p></div><span class="grid h-10 w-10 place-items-center rounded-xl bg-cyan-50 text-brand-dark"><Zap :size="19"/></span></div></article>
        <article class="surface-card rise-in relative overflow-hidden p-4" style="--rise-delay:130ms"><span class="absolute -left-5 -top-5 h-20 w-20 rounded-full bg-red-100/70 blur-xl"></span><div class="relative flex items-start justify-between"><div><p class="text-xs font-bold text-slate-500">توقفات نشطة</p><p class="mt-3 text-3xl font-extrabold tracking-tight text-red-600">{{ number(activeStops.length) }}</p><p class="mt-1 text-[10px] text-slate-400">تراكم زمني {{ number(downtimeMinutesNow / 60, 1) }} ساعة</p></div><span class="grid h-10 w-10 place-items-center rounded-xl bg-red-50 text-red-600"><Timer :size="19"/></span></div></article>
        <article class="surface-card rise-in relative overflow-hidden p-4" style="--rise-delay:180ms"><span class="absolute -left-5 -top-5 h-20 w-20 rounded-full bg-amber-100/70 blur-xl"></span><div class="relative flex items-start justify-between"><div><p class="text-xs font-bold text-slate-500">أوامر مفتوحة</p><p class="mt-3 text-3xl font-extrabold tracking-tight text-brand-navy">{{ number(openOrders) }}</p><p class="mt-1 text-[10px] text-slate-400">{{ number(closedOrders) }} مغلق وفق التحقق</p></div><span class="grid h-10 w-10 place-items-center rounded-xl bg-amber-50 text-amber-600"><ClipboardList :size="19"/></span></div></article>
        <article class="surface-card rise-in relative overflow-hidden p-4" style="--rise-delay:230ms"><span class="absolute -left-5 -top-5 h-20 w-20 rounded-full bg-violet-100/70 blur-xl"></span><div class="relative flex items-start justify-between"><div><p class="text-xs font-bold text-slate-500">متوسط زمن الإصلاح</p><p class="mt-3 text-3xl font-extrabold tracking-tight text-brand-navy">{{ averageMttr === null ? '—' : number(averageMttr < 60 ? averageMttr : averageMttr / 60, 1) }}<span v-if="averageMttr !== null" class="mr-1 text-sm font-semibold text-slate-400">{{ averageMttr < 60 ? 'دقيقة' : 'ساعة' }}</span></p><p class="mt-1 text-[10px] text-slate-400">{{ averageMttr === null ? 'لا توجد مدة إصلاح مكتملة' : 'متوسط موزون بالأوامر المغلقة' }}</p></div><span class="grid h-10 w-10 place-items-center rounded-xl bg-violet-50 text-violet-600"><ArrowDownLeft :size="19"/></span></div></article>
      </div>

      <div class="grid gap-4 xl:grid-cols-[1.65fr_1fr]">
        <article class="chart-card rise-in" style="--rise-delay:100ms"><div class="mb-1 flex items-start justify-between gap-3"><div><h2 class="font-extrabold text-brand-navy">مسار التوافر اليومي</h2><p class="mt-1 text-xs text-slate-400">تغير الإتاحة خلال أيام الإنتاج السبعة الأخيرة</p></div><span class="rounded-lg bg-cyan-50 px-2.5 py-1.5 text-[10px] font-bold text-brand-dark">{{ selectedDepartment ? departmentLabels[selectedDepartment] : 'مقارنة الأقسام' }}</span></div><VChart v-if="visibleAvailability.length" :option="availabilityTrendOption" autoresize class="chart-wrap h-[280px] w-full"/><div v-else class="grid h-[280px] place-items-center text-sm text-slate-400">لا توجد بيانات كافية بعد</div></article>
        <article class="chart-card rise-in" style="--rise-delay:160ms"><div><h2 class="font-extrabold text-brand-navy">مصادر وقت التوقف</h2><p class="mt-1 text-xs text-slate-400">أعلى فئات التوقف بالدقائق</p></div><div class="relative"><VChart v-if="downtimeByCause.length" :option="causesOption" autoresize class="chart-wrap h-[250px] w-full"/><div v-else class="grid h-[250px] place-items-center text-sm text-slate-400">لا توجد بيانات توقف</div><div v-if="downtimeByCause.length" class="pointer-events-none absolute inset-0 grid place-items-center pb-2"><div class="text-center"><p class="text-[10px] text-slate-400">إجمالي الدقائق</p><p class="mt-1 text-2xl font-extrabold text-brand-navy">{{ number(downtimeByCause.reduce((sum, row) => sum + row.minutes, 0) / 60, 1) }}<span class="mr-1 text-xs font-bold text-slate-400">س</span></p></div></div></div><div class="-mt-1 space-y-2"> <div v-for="(item, i) in downtimeByCause.slice(0, 4)" :key="item.category" class="flex items-center gap-2 text-[11px]"><i class="h-2 w-2 shrink-0 rounded-full" :style="{background: colors[i]}"/><span class="min-w-0 flex-1 truncate text-slate-600">{{ downtimeCategoryLabel(item.category) }}</span><b class="text-slate-700">{{ number(item.minutes) }} د</b></div></div></article>
      </div>

      <div class="grid gap-4 xl:grid-cols-2">
        <article class="chart-card rise-in" style="--rise-delay:120ms"><div><h2 class="font-extrabold text-brand-navy">مقارنة توافر الأقسام</h2><p class="mt-1 text-xs text-slate-400">الأخضر ≥ 90% · الأصفر ≥ 75% · الأحمر أقل من 75%</p></div><VChart v-if="departmentAvailability.length" :option="departmentOption" autoresize class="chart-wrap h-[290px] w-full"/><div v-else class="grid h-[290px] place-items-center text-sm text-slate-400">لا توجد بيانات كافية بعد</div></article>
        <article class="chart-card rise-in" style="--rise-delay:180ms"><div><h2 class="font-extrabold text-brand-navy">توزيع أوامر الشغل</h2><p class="mt-1 text-xs text-slate-400">الأوامر الظاهرة حسب حالتها الحالية</p></div><VChart v-if="workOrderStatus.length" :option="workOrderOption" autoresize class="chart-wrap h-[290px] w-full"/><div v-else class="grid h-[290px] place-items-center text-sm text-slate-400">لا توجد أوامر مسجلة</div></article>
      </div>

      <div class="grid gap-4 xl:grid-cols-[1.35fr_1fr]">
        <article class="chart-card rise-in" style="--rise-delay:140ms"><div><h2 class="font-extrabold text-brand-navy">وقت التوقف حسب الوردية</h2><p class="mt-1 text-xs text-slate-400">مجموع الدقائق في الورديات الثلاث لكل يوم</p></div><VChart v-if="shiftsByDate.length" :option="shiftOption" autoresize class="chart-wrap h-[280px] w-full"/><div v-else class="grid h-[280px] place-items-center text-sm text-slate-400">لا توجد بيانات ورديات</div></article>
        <article class="chart-card rise-in" style="--rise-delay:200ms"><div><h2 class="font-extrabold text-brand-navy">حالة الماكينات الآن</h2><p class="mt-1 text-xs text-slate-400">توزيع الحالة المباشرة للماكينات</p></div><div class="relative"><VChart v-if="machines.length" :option="machineStatusOption" autoresize class="chart-wrap h-[250px] w-full"/><div v-else class="grid h-[250px] place-items-center text-sm text-slate-400">لا توجد بيانات ماكينات</div><div v-if="machines.length" class="pointer-events-none absolute inset-0 grid place-items-center pb-6"><div class="text-center"><p class="text-[10px] text-slate-400">إجمالي</p><p class="text-2xl font-extrabold text-brand-navy">{{ number(machines.length) }}</p></div></div></div><div class="flex flex-wrap gap-x-4 gap-y-2 text-[10px] text-slate-500"><span v-for="status in [{label:'تعمل',key:'running',color:'#24B47E'},{label:'عطل / صيانة',key:'downtime',color:'#F06464'},{label:'أخرى',key:'idle',color:'#CBD5E1'}]" :key="status.key" class="flex items-center gap-1.5"><i class="h-2 w-2 rounded-full" :style="{background:status.color}"/>{{ status.label }}</span></div></article>
      </div>

      <article class="chart-card rise-in overflow-hidden p-0" style="--rise-delay:180ms"><div class="flex flex-wrap items-end justify-between gap-2 p-5 pb-4"><div><h2 class="font-extrabold text-brand-navy">الماكينات الأكثر استهلاكًا لوقت الصيانة</h2><p class="mt-1 text-xs text-slate-400">ملخص الأعطال والتوقفات خلال آخر 30 يومًا</p></div><span class="rounded-lg bg-red-50 px-2.5 py-1.5 text-[10px] font-bold text-red-600">{{ topActors.length }} ماكينات</span></div><div v-if="!topActors.length" class="border-t border-dashed p-8 text-center text-sm text-slate-400">لا توجد بيانات أعطال حديثة</div><div v-else class="table-scroll overflow-x-auto"><table class="w-full min-w-[650px] text-right text-sm"><thead class="bg-slate-50 text-[11px] text-slate-500"><tr><th class="px-5 py-3 font-bold">الماكينة</th><th class="px-4 py-3 font-bold">القسم</th><th class="px-4 py-3 font-bold">أعطال</th><th class="px-4 py-3 font-bold">زمن التوقف</th><th class="px-5 py-3 font-bold">آخر أثر</th></tr></thead><tbody><tr v-for="(machine, i) in topActors" :key="machine.id" class="group cursor-pointer border-t border-slate-100 transition hover:bg-sky-50/70" @click="openMachine(machine.code)"><td class="px-5 py-3.5"><div class="flex items-center gap-3"><span class="grid h-8 w-8 place-items-center rounded-lg text-[10px] font-extrabold" :class="i < 3 ? 'bg-red-50 text-red-600' : 'bg-slate-100 text-slate-500'">0{{ i + 1 }}</span><span><b class="block text-xs text-brand-navy">{{ machine.code }} · {{ machine.name }}</b><small class="mt-0.5 block text-[10px] text-slate-400">اضغط لفتح الماكينة</small></span></div></td><td class="px-4 py-3.5 text-xs text-slate-600">{{ departmentLabels[machine.department] ?? machine.department }}</td><td class="px-4 py-3.5"><span class="rounded-lg bg-amber-50 px-2 py-1 text-xs font-bold text-amber-700">{{ number(machine.breakdown_count) }}</span></td><td class="px-4 py-3.5"><div class="min-w-32"><div class="mb-1 flex items-center justify-between text-[10px]"><span class="font-bold text-slate-700">{{ number(Number(machine.total_downtime_minutes) / 60, 1) }} س</span><span class="text-slate-400">30 يوم</span></div><div class="h-1.5 overflow-hidden rounded-full bg-slate-100"><span class="block h-full rounded-full bg-gradient-to-l from-red-400 to-orange-300 transition-all duration-700" :style="{width:progressWidth(Number(machine.total_downtime_minutes) / Math.max(...topActors.map((row) => Number(row.total_downtime_minutes)),1) * 100)}"/></div></div></td><td class="px-5 py-3.5"><span class="inline-flex items-center gap-1 text-[10px] font-semibold text-brand-dark group-hover:gap-2">عرض التفاصيل <ArrowUpLeft :size="13"/></span></td></tr></tbody></table></div></article>
      <footer class="flex items-center justify-between px-1 pb-2 text-[10px] text-slate-400"><span>المصدر: عروض Supabase التشغيلية · التحديث عبر Realtime</span><span>التوافر محسوب من نافذة الأيام السبعة</span></footer>
    </template>
  </section>
</template>
