<script setup lang="ts">
import { computed } from 'vue'
import { RouterLink, RouterView, useRoute } from 'vue-router'
import { Activity, Boxes, ChartColumnIncreasing, ClipboardList, Factory, Gauge, LogOut, Timer, type LucideIcon } from 'lucide-vue-next'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const route = useRoute()
const links: { to: string; label: string; icon: LucideIcon }[] = [
  { to: '/plant-floor', label: 'أرضية المصنع', icon: Factory },
  { to: '/work-orders', label: 'أوامر الشغل', icon: ClipboardList },
  { to: '/downtime', label: 'سجل التوقفات', icon: Timer },
  { to: '/spare-parts', label: 'قطع الغيار', icon: Boxes },
  { to: '/analytics', label: 'التحليلات', icon: ChartColumnIncreasing },
]
const activePage = computed(() => [...links].reverse().find((link) => route.path.startsWith(link.to))?.label ?? 'لوحة التحكم')
const initials = computed(() => auth.fullName.split(/\s+/).filter(Boolean).slice(0, 2).map((part) => part[0]).join('') || 'EC')
const today = new Intl.DateTimeFormat('ar-EG', { weekday: 'long', day: 'numeric', month: 'long', timeZone: 'Africa/Cairo' }).format(new Date())
async function logout() { await auth.signOut(); location.assign('/login') }
</script>

<template>
  <div class="min-h-screen lg:flex">
    <aside class="relative z-20 w-full shrink-0 bg-brand-navy text-white lg:sticky lg:top-0 lg:h-screen lg:w-[272px] lg:overflow-y-auto">
      <div class="flex items-center justify-between gap-3 border-b border-white/10 px-4 py-3 lg:block lg:px-5 lg:pb-6 lg:pt-6">
        <RouterLink to="/plant-floor" class="block rounded-2xl bg-white px-4 py-3 shadow-lg shadow-black/10 transition duration-300 hover:-translate-y-0.5 hover:shadow-xl" aria-label="Energya Cables — الصفحة الرئيسية">
          <img src="/energya-logo.png" alt="Energya Cables" class="mx-auto h-12 w-full max-w-[205px] object-contain" />
        </RouterLink>
        <div class="hidden pt-4 lg:block"><p class="text-xs font-semibold uppercase tracking-[0.18em] text-cyan-300">Cable Ops</p><h1 class="mt-1 text-lg font-bold">مركز العمليات</h1><p class="mt-1 text-xs text-white/50">متابعة المصنع والصيانة</p></div>
        <span class="inline-flex items-center gap-2 rounded-full border border-emerald-300/20 bg-emerald-300/10 px-2.5 py-1 text-[11px] text-emerald-100 lg:hidden"><i class="h-1.5 w-1.5 animate-pulse rounded-full bg-emerald-300"></i> مباشر</span>
      </div>

      <div class="px-3 pb-3 pt-3 lg:px-4 lg:pt-6">
        <p class="mb-2 hidden px-3 text-[10px] font-bold uppercase tracking-[0.2em] text-white/40 lg:block">مساحة العمل</p>
        <nav class="flex gap-1.5 overflow-x-auto pb-1 lg:flex-col lg:gap-1 lg:overflow-visible" aria-label="التنقل الرئيسي">
          <RouterLink v-for="link in links" :key="link.to" :to="link.to" class="group relative flex shrink-0 items-center gap-3 rounded-xl px-3 py-2.5 text-sm text-white/65 transition duration-200 hover:bg-white/[0.08] hover:text-white lg:w-full" active-class="!bg-cyan-400 !text-brand-navy shadow-lg shadow-cyan-950/25">
            <component :is="link.icon" :size="18" :stroke-width="1.8" class="shrink-0 transition-transform duration-200 group-hover:scale-110" />
            <span class="whitespace-nowrap font-semibold">{{ link.label }}</span>
            <span v-if="route.path === link.to || (link.to !== '/plant-floor' && route.path.startsWith(`${link.to}/`))" class="mr-auto hidden h-1.5 w-1.5 rounded-full bg-current lg:block"></span>
          </RouterLink>
        </nav>
      </div>

      <div class="hidden px-5 pb-5 lg:absolute lg:inset-x-0 lg:bottom-0 lg:block">
        <div class="mb-4 flex items-center gap-2.5 rounded-xl border border-white/10 bg-white/[0.04] px-3 py-3">
          <span class="relative flex h-2.5 w-2.5"><span class="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-300 opacity-40"></span><span class="relative h-2.5 w-2.5 rounded-full bg-emerald-400"></span></span>
          <div><p class="text-xs font-semibold text-white/90">المصنع متصل</p><p class="mt-0.5 text-[10px] text-white/45">تحديثات لحظية من Supabase</p></div>
          <Activity :size="16" class="mr-auto text-cyan-300" />
        </div>
        <p class="px-1 text-[10px] text-white/35">Energya Cables · CMMS</p>
      </div>
    </aside>

    <div class="min-w-0 flex-1">
      <header class="sticky top-0 z-10 flex min-h-[76px] items-center justify-between gap-4 border-b border-slate-200/80 bg-white/90 px-4 backdrop-blur-xl md:px-8">
        <div class="min-w-0"><div class="flex items-center gap-2 text-xs text-slate-400"><Gauge :size="14" class="text-brand-dark" /><span>مركز العمليات</span><span>/</span><span class="truncate font-semibold text-slate-600">{{ activePage }}</span></div><p class="mt-1 hidden text-[11px] text-slate-400 sm:block">{{ today }}</p></div>
        <div class="flex shrink-0 items-center gap-2.5 md:gap-4">
          <div class="hidden items-center gap-2 rounded-full bg-emerald-50 px-3 py-1.5 text-xs font-semibold text-emerald-700 sm:flex"><i class="h-1.5 w-1.5 animate-pulse rounded-full bg-emerald-500"></i> اتصال نشط</div>
          <div class="flex items-center gap-2.5 border-r border-slate-200 pr-2.5 md:pr-4">
            <div class="hidden text-left sm:block"><p class="max-w-36 truncate text-xs font-bold text-slate-800">{{ auth.fullName || 'مستخدم' }}</p><p class="mt-0.5 text-[10px] text-slate-500">{{ auth.role || 'بدون دور' }}</p></div>
            <span class="grid h-9 w-9 place-items-center rounded-xl bg-gradient-to-br from-brand to-brand-dark text-xs font-extrabold text-white shadow-md shadow-cyan-900/15">{{ initials }}</span>
          </div>
          <button class="group inline-flex h-9 items-center gap-2 rounded-xl border border-slate-200 px-3 text-xs font-bold text-slate-600 transition hover:border-red-200 hover:bg-red-50 hover:text-red-700" @click="logout"><LogOut :size="15" class="transition-transform group-hover:-translate-x-0.5" /><span class="hidden sm:inline">خروج</span></button>
        </div>
      </header>
      <main class="mx-auto w-full max-w-[1680px] p-4 md:p-7 xl:p-9">
        <RouterView v-slot="{ Component }"><Transition name="page" mode="out-in" appear><component :is="Component" :key="route.fullPath" /></Transition></RouterView>
      </main>
    </div>
  </div>
</template>
