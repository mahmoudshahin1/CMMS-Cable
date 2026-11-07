<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import type { RealtimeChannel } from '@supabase/supabase-js'
import VChart from 'vue-echarts'
import { use } from 'echarts/core'
import { BarChart, LineChart, PieChart } from 'echarts/charts'
import { GridComponent, LegendComponent, TooltipComponent } from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'
import { Activity, ArrowDownLeft, ArrowUpLeft, ChartNoAxesCombined, ClipboardList, Factory, Flame, Gauge, ListTree, RefreshCw, Timer, TrendingDown, TrendingUp, TriangleAlert, Zap } from 'lucide-vue-next'
import StatTile from '../components/StatTile.vue'
import { motionMode } from '../lib/motion'
import { supabase } from '../api/supabase'
import { departmentLabels, statusLabel } from '../lib/workOrders'
import { downtimeCategoryLabel } from '../lib/downtime'
import { useLocaleStore } from '../stores/locale'
import type { Machine } from '../stores/liveMonitoring'
import { createLiveRefresh } from '../lib/liveRefresh'

use([BarChart, LineChart, PieChart, GridComponent, LegendComponent, TooltipComponent, CanvasRenderer])

type Availability = { department: string; production_date: string; machine_count: number; downtime_minutes: number; availability_pct: number }
type Pareto = { department: string; category: string; event_count: number; total_minutes: number; avg_minutes: number }
type Mttr = { department: string; closed_count: number; mttr_minutes: number | null }
type BadActor = { id: string; code: string; name: string; department: string; breakdown_count: number; total_downtime_minutes: number }
type Funnel = { status: string; count: number }
type ShiftSplit = { production_date: string; department: string; shift1_morning_minutes: number; shift2_evening_minutes: number; shift3_night_minutes: number }

const colors = ['#0C4595', '#F04E37', '#24B47E', '#F3A63B', '#7C6CE7', '#082957', '#5AA6B9']
const router = useRouter()
const locale = useLocaleStore()
const t = (key: string) => locale.t(`analytics.${key}`)
const departmentName = (key: string) => locale.t(`analytics.departments.${key}`) || key
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
const sections = [
  { id: 'overview', icon: Gauge },
  { id: 'trends', icon: TrendingUp },
  { id: 'causes', icon: ListTree },
  { id: 'badActors', icon: Flame },
] as const
const activeSection = ref<string>('overview')
let sectionObserver: IntersectionObserver | null = null
function scrollToSection(id: string) { document.getElementById(id)?.scrollIntoView({ behavior: motionMode.value === 'lite' ? 'auto' : 'smooth', block: 'start' }) }
const liveRefresh = createLiveRefresh(refresh)
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
// Previous production day with data, so the arrow compares like-for-like (skips gaps/weekends).
const previousDate = computed(() => [...new Set(availability.value.map((row) => row.production_date))].filter((date) => date < latestDate.value).sort().at(-1) ?? '')
const previousAvailability = computed(() => availability.value.filter((row) => row.production_date === previousDate.value && (!selectedDepartment.value || row.department === selectedDepartment.value)))
function weightedScore(rows: Availability[]) {
  const totalMachines = rows.reduce((sum, row) => sum + Number(row.machine_count), 0)
  if (!totalMachines) return null
  return rows.reduce((sum, row) => sum + Number(row.availability_pct) * Number(row.machine_count), 0) / totalMachines
}
const previousAvailabilityScore = computed(() => previousDate.value ? weightedScore(previousAvailability.value) : null)
const availabilityDelta = computed(() => availabilityScore.value !== null && previousAvailabilityScore.value !== null ? availabilityScore.value - previousAvailabilityScore.value : null)
const availabilityScore = computed(() => {
  const totalMachines = latestAvailability.value.reduce((sum, row) => sum + Number(row.machine_count), 0)
  if (!totalMachines) return null
  return weightedScore(latestAvailability.value)
})
const runningCount = computed(() => machines.value.filter((machine) => machine.status === 'running').length)
const activeStops = computed(() => machines.value.filter((machine) => machine.active_downtime_id))
const unloggedDowntimeMachines = computed(() => machines.value.filter((machine) => !machine.active_downtime_id && ['downtimeProcess', 'downtimeMaintenance', 'underRepair', 'preventiveMaintenance'].includes(machine.status)))
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

const dateLabel = (value: string) => new Intl.DateTimeFormat(locale.locale === 'ar' ? 'ar-EG' : 'en-GB', { day: 'numeric', month: 'short', timeZone: 'Africa/Cairo' }).format(new Date(`${value}T12:00:00Z`))
const number = (value: number | string | null | undefined, digits = 0) => value === null || value === undefined ? '—' : Number(value).toLocaleString(locale.locale === 'ar' ? 'ar-EG' : 'en-US', { maximumFractionDigits: digits })
const availabilityTrendOption = computed<Record<string, unknown>>(() => {
  const dates = [...new Set(visibleAvailability.value.map((row) => row.production_date))].sort()
  const seriesDepartments = selectedDepartment.value ? [selectedDepartment.value] : departments.value
  return {
    color: colors,
    tooltip: { trigger: 'axis', valueFormatter: (value: number) => `${number(value, 1)}%` },
    legend: { bottom: 0, type: 'scroll', textStyle: { fontFamily: locale.locale === 'ar' ? 'Cairo' : 'Inter', fontSize: 10 } },
    grid: { top: 22, left: 8, right: 16, bottom: 48, containLabel: true },
    xAxis: { type: 'category', boundaryGap: false, data: dates.map(dateLabel), axisLine: { lineStyle: { color: '#e2e8f0' } }, axisLabel: { color: '#64748b', fontFamily: locale.locale === 'ar' ? 'Cairo' : 'Inter' } },
    yAxis: { type: 'value', min: 0, max: 100, axisLabel: { formatter: '{value}%', color: '#94a3b8' }, splitLine: { lineStyle: { color: '#edf2f7' } } },
    series: seriesDepartments.map((department) => ({ name: departmentName(department), type: 'line', smooth: true, symbol: 'circle', symbolSize: 6, emphasis: { focus: 'series' }, areaStyle: { opacity: .055 }, data: dates.map((date) => visibleAvailability.value.find((row) => row.production_date === date && row.department === department)?.availability_pct ?? null) })),
  }
})
const causesOption = computed<Record<string, unknown>>(() => ({
  color: ['#082957', '#0C4595', '#F04E37', '#24B47E', '#F3A63B', '#7C6CE7', '#F06464', '#5AA6B9', '#94A3B8'],
  tooltip: { trigger: 'item', formatter: (params: { name: string; value: number; percent: number }) => `${downtimeCategoryLabel(params.name, locale.locale)}<br/><b>${number(params.value)} ${t('minuteUnit')}</b> · ${params.percent}%` },
  series: [{ type: 'pie', radius: ['56%', '78%'], center: ['50%', '48%'], avoidLabelOverlap: true, itemStyle: { borderColor: '#fff', borderWidth: 4, borderRadius: 7 }, label: { show: false }, emphasis: { scale: true, scaleSize: 8 }, data: downtimeByCause.value.map((row) => ({ name: row.category, value: Math.round(row.minutes) })) }],
}))
const departmentOption = computed<Record<string, unknown>>(() => ({
  color: ['#0C4595'], tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, valueFormatter: (value: number) => `${number(value, 1)}%` },
  grid: { top: 12, left: 8, right: 20, bottom: 4, containLabel: true }, xAxis: { type: 'value', max: 100, axisLabel: { formatter: '{value}%', color: '#94a3b8' }, splitLine: { lineStyle: { color: '#edf2f7' } } },
  yAxis: { type: 'category', data: departmentAvailability.value.map((row) => departmentName(row.department)).reverse(), axisLabel: { color: '#475569', fontFamily: locale.locale === 'ar' ? 'Cairo' : 'Inter' }, axisLine: { show: false }, axisTick: { show: false } },
  series: [{ type: 'bar', barWidth: 15, showBackground: true, backgroundStyle: { color: '#f1f5f9', borderRadius: 8 }, itemStyle: { borderRadius: [0, 8, 8, 0], color: (params: { value: number }) => params.value >= 90 ? '#24B47E' : params.value >= 75 ? '#F3A63B' : '#F06464' }, data: departmentAvailability.value.map((row) => Number(row.availability_pct)).reverse() }],
}))
const workOrderOption = computed<Record<string, unknown>>(() => ({
  color: ['#0C4595'], tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } }, grid: { top: 10, left: 8, right: 20, bottom: 4, containLabel: true },
  xAxis: { type: 'value', minInterval: 1, splitLine: { lineStyle: { color: '#edf2f7' } }, axisLabel: { color: '#94a3b8' } }, yAxis: { type: 'category', data: workOrderStatus.value.map((row) => statusLabel(row.status, locale.locale)).reverse(), axisLabel: { color: '#475569', fontFamily: locale.locale === 'ar' ? 'Cairo' : 'Inter' }, axisLine: { show: false }, axisTick: { show: false } },
  series: [{ type: 'bar', barWidth: 17, itemStyle: { borderRadius: [0, 8, 8, 0], color: '#123B66' }, data: workOrderStatus.value.map((row) => Number(row.count)).reverse(), label: { show: true, position: 'insideRight', color: '#fff', fontWeight: 'bold' } }],
}))
const shiftOption = computed<Record<string, unknown>>(() => ({
  color: ['#0C4595', '#F04E37', '#082957'], tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, valueFormatter: (value: number) => `${number(value)} ${t('minuteUnit')}` }, legend: { bottom: 0, textStyle: { fontFamily: locale.locale === 'ar' ? 'Cairo' : 'Inter', fontSize: 10 } },
  grid: { top: 20, left: 8, right: 15, bottom: 45, containLabel: true }, xAxis: { type: 'category', data: shiftsByDate.value.map(([date]) => dateLabel(date)), axisLabel: { color: '#64748b', fontFamily: locale.locale === 'ar' ? 'Cairo' : 'Inter' } }, yAxis: { type: 'value', axisLabel: { color: '#94a3b8' }, splitLine: { lineStyle: { color: '#edf2f7' } } },
  series: [
    { name: t('shifts.morning'), type: 'bar', stack: 'total', barMaxWidth: 25, itemStyle: { borderRadius: [0, 0, 4, 4] }, data: shiftsByDate.value.map(([, value]) => Math.round(value.morning)) },
    { name: t('shifts.evening'), type: 'bar', stack: 'total', itemStyle: { borderRadius: [0, 0, 4, 4] }, data: shiftsByDate.value.map(([, value]) => Math.round(value.evening)) },
    { name: t('shifts.night'), type: 'bar', stack: 'total', itemStyle: { borderRadius: [5, 5, 0, 0] }, data: shiftsByDate.value.map(([, value]) => Math.round(value.night)) },
  ],
}))
const machineStatusLabel = (status: string) => t(`statuses.${status}`)
const machineStatusOption = computed<Record<string, unknown>>(() => {
  const statuses = new Map<string, number>()
  for (const machine of machines.value) statuses.set(machine.status, (statuses.get(machine.status) ?? 0) + 1)
  const statusNames: Record<string, string> = { running: machineStatusLabel('running'), idle: machineStatusLabel('idle'), downtimeProcess: machineStatusLabel('downtimeProcess'), downtimeMaintenance: machineStatusLabel('downtimeMaintenance'), underRepair: machineStatusLabel('underRepair'), preventiveMaintenance: machineStatusLabel('preventiveMaintenance'), offline: machineStatusLabel('offline') }
  const statusColors: Record<string, string> = { running: '#24B47E', idle: '#CBD5E1', downtimeProcess: '#F06464', downtimeMaintenance: '#DC4C64', underRepair: '#F97362', preventiveMaintenance: '#F3A63B', offline: '#475569' }
  return { tooltip: { trigger: 'item', formatter: (params: { name: string; value: number; percent: number }) => `${params.name}<br/><b>${number(params.value)}</b> ${t('machines')} · ${params.percent}%` }, legend: { bottom: 0, left: 'center', textStyle: { fontFamily: locale.locale === 'ar' ? 'Cairo' : 'Inter', fontSize: 10 } }, series: [{ type: 'pie', radius: ['54%', '76%'], center: ['50%', '43%'], itemStyle: { borderColor: '#fff', borderWidth: 4 }, label: { show: false }, data: [...statuses.entries()].map(([key, value]) => ({ name: statusNames[key] ?? key, value, itemStyle: { color: statusColors[key] ?? '#94A3B8' } })) }] }
})

async function refresh() {
  if (!supabase) { error.value = t('supabaseError'); loading.value = false; return }
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
function progressWidth(value: number) { return `${Math.max(0, Math.min(100, value))}%` }
function openMachine(code: string) { void router.push(`/machines/${encodeURIComponent(code)}`) }
onMounted(() => {
  void refresh()
  sectionObserver = new IntersectionObserver((entries) => {
    const visible = entries.filter((entry) => entry.isIntersecting).sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)
    if (visible[0]) activeSection.value = visible[0].target.id
  }, { rootMargin: '-96px 0px -70% 0px' })
  for (const section of sections) {
    const el = document.getElementById(section.id)
    if (el) sectionObserver.observe(el)
  }
  if (supabase) channel = supabase.channel('web-analytics-live')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'machines' }, () => liveRefresh.request())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'downtime_logs' }, () => liveRefresh.request())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'work_orders' }, () => liveRefresh.request())
    .subscribe((status) => { connected.value = status === 'SUBSCRIBED' })
})
onUnmounted(() => { liveRefresh.dispose(); sectionObserver?.disconnect(); if (supabase && channel) void supabase.removeChannel(channel) })
</script>

<template>
  <section class="space-y-6">
    <header class="rise-in relative isolate overflow-hidden rounded-[26px] bg-brand-navy px-5 py-6 text-white shadow-[0_20px_55px_-28px_rgba(10,37,64,.6)] md:px-8 md:py-7">
      <div class="pointer-events-none absolute -left-12 -top-24 -z-10 h-80 w-80 rounded-full border border-accent-50/10"></div>
      <div class="pointer-events-none absolute -left-2 -top-16 -z-10 h-60 w-60 rounded-full border border-accent-50/10"></div>
      <div class="pointer-events-none absolute bottom-[-120px] right-[35%] -z-10 h-64 w-64 rounded-full bg-brand/25 blur-3xl"></div>
      <div class="flex flex-wrap items-end justify-between gap-5">
        <div>
          <div class="mb-3 flex items-center gap-2 text-xs font-bold text-accent-light"><ChartNoAxesCombined :size="16" /> {{ t('eyebrow') }} <span class="rounded-full bg-white/10 px-2 py-1 text-[10px] text-white/65">{{ t('period') }}</span></div>
          <h1 class="text-2xl font-extrabold md:text-3xl">{{ t('title') }}</h1>
          <p class="mt-2 max-w-2xl text-sm leading-6 text-white/60">{{ t('subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <label :title="t('filterHint')" class="flex items-center gap-2 rounded-xl border border-white/10 bg-white/[.08] px-3 py-2 text-xs"><Factory :size="15" class="text-accent-light"/><select v-model="selectedDepartment" class="max-w-40 bg-transparent text-white outline-none [&>option]:text-slate-900"><option value="">{{ t('allDepartments') }}</option><option v-for="department in departments" :key="department" :value="department">{{ departmentName(department) }}</option></select></label>
          <span class="flex items-center gap-2 rounded-xl border border-white/10 bg-white/[.08] px-3 py-2 text-xs"><i class="h-2 w-2 rounded-full" :class="connected ? 'bg-emerald-300 soft-pulse' : 'bg-red-300'"></i>{{ connected ? t('connected') : t('disconnected') }}</span>
          <button class="inline-flex items-center gap-2 rounded-xl bg-brand px-3.5 py-2 text-xs font-extrabold text-white shadow-lg shadow-brand-navy/25 transition hover:-translate-y-0.5 hover:bg-brand-dark disabled:opacity-60" :disabled="refreshing" @click="refresh"><RefreshCw :size="14" :class="refreshing ? 'animate-spin' : ''"/>{{ refreshing ? t('refreshing') : t('refresh') }}</button>
        </div>
      </div>
      <p class="mt-5 flex flex-wrap items-center gap-x-2 gap-y-1 text-[10px] text-white/40">{{ t('lastSync') }} {{ updatedAt ? updatedAt.toLocaleTimeString(locale.locale === 'ar' ? 'ar-EG' : 'en-US', { hour: '2-digit', minute: '2-digit', timeZone: 'Africa/Cairo' }) : '—' }} <span v-if="latestDate">· {{ t('productionThrough') }} {{ dateLabel(latestDate) }}</span><span v-if="dataLagDays !== null && dataLagDays >= 1" class="rounded-md bg-amber-300/15 px-2 py-0.5 font-bold text-amber-200">{{ t('stalePrefix') }} {{ number(dataLagDays) }} {{ t('days') }}</span></p>
    </header>

    <!-- section nav -->
    <nav v-if="!loading" class="sticky top-[76px] z-[5] -mx-1 flex gap-1.5 overflow-x-auto rounded-2xl border border-slate-200 bg-white/90 p-1.5 shadow-sm backdrop-blur" :aria-label="t('sectionNav')">
      <button v-for="section in sections" :key="section.id" type="button" class="flex shrink-0 items-center gap-1.5 rounded-xl px-3 py-2 text-xs font-bold transition" :class="activeSection === section.id ? 'bg-brand-navy text-white shadow-brand' : 'text-slate-500 hover:bg-brand-50 hover:text-brand'" @click="scrollToSection(section.id)">
        <component :is="section.icon" :size="14" />{{ t(`sections.${section.id}`) }}
      </button>
    </nav>

    <div v-if="error" class="flex items-start gap-3 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900" role="status"><TriangleAlert :size="18" class="mt-0.5 shrink-0"/><div><p class="font-bold">{{ t('sourceError') }}</p><p class="mt-1 text-xs leading-5">{{ error }}</p></div></div>

    <div v-if="unloggedDowntimeMachines.length" class="rounded-2xl border border-amber-200 bg-amber-50 p-4 text-amber-950" role="status">
      <div class="flex items-start gap-3"><TriangleAlert :size="18" class="mt-0.5 shrink-0 text-amber-700"/><div class="min-w-0 flex-1"><div class="flex flex-wrap items-center gap-2"><p class="font-bold">{{ t('unloggedTitle') }}</p><span class="rounded-full bg-amber-200 px-2 py-0.5 text-xs font-extrabold">{{ number(unloggedDowntimeMachines.length) }}</span></div><p class="mt-1 text-xs leading-5 text-amber-900/80">{{ t('unloggedDescription') }}</p><div class="mt-3 flex flex-wrap gap-2"><span v-for="machine in unloggedDowntimeMachines.slice(0, 8)" :key="machine.id" class="inline-flex items-center gap-1.5 rounded-lg border border-amber-200 bg-white px-2.5 py-1.5 text-xs"><b dir="ltr">{{ machine.code }}</b><span class="text-amber-800">{{ machineStatusLabel(machine.status) }}</span></span><span v-if="unloggedDowntimeMachines.length > 8" class="rounded-lg px-2.5 py-1.5 text-xs font-semibold">+{{ number(unloggedDowntimeMachines.length - 8) }} {{ t('moreMachines') }}</span></div></div></div>
    </div>

    <div v-if="loading" class="grid gap-4 sm:grid-cols-2 xl:grid-cols-5"><div v-for="i in 5" :key="i" class="h-32 animate-pulse rounded-2xl bg-white shadow-sm"><div class="skeleton m-4 h-4 w-24 rounded"></div><div class="skeleton mx-4 mt-5 h-8 w-20 rounded"></div></div></div>
    <template v-else>
      <div id="overview" class="grid gap-3 sm:grid-cols-2 xl:grid-cols-5" style="scroll-margin-top:150px">
        <div class="enter" style="--d:0ms">
          <StatTile :label="t('availability')" :value="availabilityScore === null ? '—' : `${number(availabilityScore, 1)}%`" :tone="availabilityScore === null ? 'brand' : availabilityScore >= 90 ? 'emerald' : availabilityScore >= 75 ? 'amber' : 'red'" :icon="Activity" />
          <p v-if="availabilityDelta !== null" class="mt-1.5 flex items-center gap-1 ps-1 text-[11px] font-bold" :class="availabilityDelta >= 0 ? 'text-emerald-600' : 'text-red-600'">
            <component :is="availabilityDelta >= 0 ? TrendingUp : TrendingDown" :size="12" />{{ availabilityDelta >= 0 ? '+' : '' }}{{ number(availabilityDelta, 1) }}% {{ t('vsPreviousDay') }}
          </p>
        </div>
        <StatTile :label="t('machinesRunning')" :value="`${number(runningCount)} / ${number(machines.length)}`" :hint="t('machinesVisible')" tone="brand" :icon="Zap" style="--d:70ms" />
        <StatTile :label="t('activeDowntimes')" :value="number(activeStops.length)" :hint="`${t('accumulatedTime')} ${number(downtimeMinutesNow / 60, 1)} ${t('hour')}`" tone="red" :icon="Timer" style="--d:140ms" />
        <StatTile :label="t('openOrders')" :value="number(openOrders)" :hint="`${number(closedOrders)} ${t('verifiedClosed')}`" tone="amber" :icon="ClipboardList" style="--d:210ms" />
        <StatTile :label="t('mttr')" :value="averageMttr === null ? '—' : `${number(averageMttr < 60 ? averageMttr : averageMttr / 60, 1)} ${averageMttr < 60 ? t('minute') : t('hour')}`" :hint="averageMttr === null ? t('noCompletedRepair') : t('weightedClosed')" tone="violet" :icon="ArrowDownLeft" style="--d:280ms" />
      </div>

      <div id="trends" class="grid gap-4 xl:grid-cols-[1.65fr_1fr]" style="scroll-margin-top:150px">
        <article class="chart-card rise-in"><div class="mb-1 flex items-start justify-between gap-3"><div><span class="me-2 inline-block h-4 w-1 rounded-full bg-gradient-to-b from-accent to-brand align-middle"></span><h2 class="font-extrabold text-brand-navy">{{ t('trend') }}</h2><p class="mt-1 text-xs text-slate-400">{{ t('trendSubtitle') }}</p></div><span class="rounded-lg bg-accent-50 px-2.5 py-1.5 text-[10px] font-bold text-brand-dark">{{ selectedDepartment ? departmentName(selectedDepartment) : t('compareDepartments') }}</span></div><VChart v-if="visibleAvailability.length" :option="availabilityTrendOption" autoresize class="chart-wrap h-[280px] w-full"/><div v-else class="grid h-[280px] place-items-center text-sm text-slate-400">{{ t('insufficient') }}</div></article>
        <article class="chart-card rise-in"><div><span class="me-2 inline-block h-4 w-1 rounded-full bg-gradient-to-b from-accent to-brand align-middle"></span><h2 class="font-extrabold text-brand-navy">{{ t('downtimeSources') }}</h2><p class="mt-1 text-xs text-slate-400">{{ t('downtimeSubtitle') }}</p></div><div class="relative"><VChart v-if="downtimeByCause.length" :option="causesOption" autoresize class="chart-wrap h-[250px] w-full"/><div v-else class="grid h-[250px] place-items-center text-sm text-slate-400">{{ t('noDowntime') }}</div><div v-if="downtimeByCause.length" class="pointer-events-none absolute inset-0 grid place-items-center pb-2"><div class="text-center"><p class="text-[10px] text-slate-400">{{ t('totalMinutes') }}</p><p class="mt-1 text-2xl font-extrabold text-brand-navy">{{ number(downtimeByCause.reduce((sum, row) => sum + row.minutes, 0) / 60, 1) }}<span class="mx-1 text-xs font-bold text-slate-400">{{ t('hour') }}</span></p></div></div></div><div class="-mt-1 space-y-2"><div v-for="(item, i) in downtimeByCause.slice(0, 4)" :key="item.category" class="flex items-center gap-2 text-[11px]"><i class="h-2 w-2 shrink-0 rounded-full" :style="{background: colors[i]}"/><span class="min-w-0 flex-1 truncate text-slate-600">{{ downtimeCategoryLabel(item.category, locale.locale) }}</span><b class="text-slate-700">{{ number(item.minutes) }} {{ t('minutesShort') }}</b></div></div></article>
      </div>

      <div id="causes" class="grid gap-4 xl:grid-cols-2" style="scroll-margin-top:150px">
        <article class="chart-card rise-in"><div><span class="me-2 inline-block h-4 w-1 rounded-full bg-gradient-to-b from-accent to-brand align-middle"></span><h2 class="font-extrabold text-brand-navy">{{ t('departmentAvailability') }}</h2><p class="mt-1 text-xs text-slate-400">{{ t('thresholds') }}</p></div><VChart v-if="departmentAvailability.length" :option="departmentOption" autoresize class="chart-wrap h-[290px] w-full"/><div v-else class="grid h-[290px] place-items-center text-sm text-slate-400">{{ t('insufficient') }}</div></article>
        <article class="chart-card rise-in"><div><span class="me-2 inline-block h-4 w-1 rounded-full bg-gradient-to-b from-accent to-brand align-middle"></span><h2 class="font-extrabold text-brand-navy">{{ t('workOrderDistribution') }}</h2><p class="mt-1 text-xs text-slate-400">{{ t('currentStatus') }}</p></div><VChart v-if="workOrderStatus.length" :option="workOrderOption" autoresize class="chart-wrap h-[290px] w-full"/><div v-else class="grid h-[290px] place-items-center text-sm text-slate-400">{{ t('noOrders') }}</div></article>
      </div>

      <div class="grid gap-4 xl:grid-cols-[1.35fr_1fr]">
        <article class="chart-card rise-in"><div><span class="me-2 inline-block h-4 w-1 rounded-full bg-gradient-to-b from-accent to-brand align-middle"></span><h2 class="font-extrabold text-brand-navy">{{ t('shiftDowntime') }}</h2><p class="mt-1 text-xs text-slate-400">{{ t('shiftSubtitle') }}</p></div><VChart v-if="shiftsByDate.length" :option="shiftOption" autoresize class="chart-wrap h-[280px] w-full"/><div v-else class="grid h-[280px] place-items-center text-sm text-slate-400">{{ t('noShiftData') }}</div></article>
        <article class="chart-card rise-in"><div><span class="me-2 inline-block h-4 w-1 rounded-full bg-gradient-to-b from-accent to-brand align-middle"></span><h2 class="font-extrabold text-brand-navy">{{ t('machineStatus') }}</h2><p class="mt-1 text-xs text-slate-400">{{ t('machineStatusSubtitle') }}</p></div><div class="relative"><VChart v-if="machines.length" :option="machineStatusOption" autoresize class="chart-wrap h-[250px] w-full"/><div v-else class="grid h-[250px] place-items-center text-sm text-slate-400">{{ t('noMachineData') }}</div><div v-if="machines.length" class="pointer-events-none absolute inset-0 grid place-items-center pb-6"><div class="text-center"><p class="text-[10px] text-slate-400">{{ t('total') }}</p><p class="text-2xl font-extrabold text-brand-navy">{{ number(machines.length) }}</p></div></div></div><div class="flex flex-wrap gap-x-4 gap-y-2 text-[10px] text-slate-500"><span v-for="status in [{label:t('running'),key:'running',color:'#24B47E'},{label:t('stoppedOrMaintenance'),key:'downtime',color:'#F06464'},{label:t('other'),key:'idle',color:'#CBD5E1'}]" :key="status.key" class="flex items-center gap-1.5"><i class="h-2 w-2 rounded-full" :style="{background:status.color}"/>{{ status.label }}</span></div></article>
      </div>

      <article id="badActors" class="chart-card rise-in overflow-hidden p-0" style="scroll-margin-top:150px"><div class="flex flex-wrap items-end justify-between gap-2 p-5 pb-4"><div><span class="me-2 inline-block h-4 w-1 rounded-full bg-gradient-to-b from-accent to-brand align-middle"></span><h2 class="font-extrabold text-brand-navy">{{ t('badActors') }}</h2><p class="mt-1 text-xs text-slate-400">{{ t('badActorsSubtitle') }}</p></div><span class="rounded-lg bg-red-50 px-2.5 py-1.5 text-[10px] font-bold text-red-600">{{ topActors.length }} {{ t('machines') }}</span></div><div v-if="!topActors.length" class="border-t border-dashed p-8 text-center text-sm text-slate-400">{{ t('noRecentBreakdowns') }}</div><div v-else class="table-scroll overflow-x-auto"><table :class="['w-full min-w-[650px] text-sm', locale.direction === 'rtl' ? 'text-right' : 'text-left']"><thead class="bg-slate-50 text-[11px] text-slate-500"><tr><th class="px-5 py-3 font-bold">{{ t('machine') }}</th><th class="px-4 py-3 font-bold">{{ t('department') }}</th><th class="px-4 py-3 font-bold">{{ t('breakdowns') }}</th><th class="px-4 py-3 font-bold">{{ t('downtime') }}</th><th class="px-5 py-3 font-bold">{{ t('lastImpact') }}</th></tr></thead><tbody><tr v-for="(machine, i) in topActors" :key="machine.id" class="enter group cursor-pointer border-t border-slate-100 transition hover:bg-sky-50/70" :style="{ '--d': `${Math.min(i, 8) * 45}ms` }" @click="openMachine(machine.code)"><td class="px-5 py-3.5"><div class="flex items-center gap-3"><span class="grid h-8 w-8 place-items-center rounded-lg text-[11px] font-extrabold" :class="[i === 0 ? 'bg-gradient-to-br from-amber-300 to-amber-500 text-white shadow-md shadow-amber-300/50' : i === 1 ? 'bg-gradient-to-br from-slate-300 to-slate-400 text-white' : i === 2 ? 'bg-gradient-to-br from-orange-300 to-orange-500 text-white' : 'bg-slate-100 text-slate-500']">{{ i < 3 ? ['🥇','🥈','🥉'][i] : `0${i + 1}` }}</span><span><b class="block text-xs text-brand-navy">{{ machine.code }} · {{ machine.name }}</b><small class="mt-0.5 block text-[10px] text-slate-400">{{ t('clickMachine') }}</small></span></div></td><td class="px-4 py-3.5 text-xs text-slate-600">{{ departmentName(machine.department) }}</td><td class="px-4 py-3.5"><span class="rounded-lg bg-amber-50 px-2 py-1 text-xs font-bold text-amber-700">{{ number(machine.breakdown_count) }}</span></td><td class="px-4 py-3.5"><div class="min-w-32"><div class="mb-1 flex items-center justify-between text-[10px]"><span class="font-bold text-slate-700">{{ number(Number(machine.total_downtime_minutes) / 60, 1) }} {{ t('hour') }}</span><span class="text-slate-400">{{ t('days30') }}</span></div><div class="h-1.5 overflow-hidden rounded-full bg-slate-100"><span class="block h-full rounded-full bg-gradient-to-l from-red-400 to-orange-300 transition-all duration-700" :style="{width:progressWidth(Number(machine.total_downtime_minutes) / Math.max(...topActors.map((row) => Number(row.total_downtime_minutes)),1) * 100)}"/></div></div></td><td class="px-5 py-3.5"><span class="inline-flex items-center gap-1 text-[10px] font-semibold text-brand-dark group-hover:gap-2">{{ t('viewDetails') }} <ArrowUpLeft :size="13"/></span></td></tr></tbody></table></div></article>
      <footer class="flex items-center justify-between px-1 pb-2 text-[10px] text-slate-400"><span>{{ t('dataSource') }}</span><span>{{ t('availabilityWindow') }}</span></footer>
    </template>
  </section>
</template>
