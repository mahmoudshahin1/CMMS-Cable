<script setup lang="ts">
import { RouterLink, RouterView } from 'vue-router'
import { useAuthStore } from '../stores/auth'
const auth = useAuthStore()
const links = [
  { to: '/plant-floor', label: 'أرضية المصنع' },
  { to: '/work-orders', label: 'أوامر الشغل' },
  { to: '/analytics', label: 'التقارير والتحليلات' },
]
async function logout() { await auth.signOut(); location.assign('/login') }
</script>

<template>
  <div class="min-h-screen lg:flex">
    <aside class="w-full bg-brand-navy p-5 text-white lg:min-h-screen lg:w-64">
      <div class="mb-8 border-b border-white/15 pb-5">
        <p class="text-xl font-bold">Energya Cables</p><p class="mt-1 text-xs text-white/65">Cable Ops CMMS</p>
      </div>
      <nav class="flex gap-2 overflow-x-auto lg:flex-col">
        <RouterLink v-for="link in links" :key="link.to" :to="link.to" class="rounded-lg px-3 py-2 text-sm text-white/80 hover:bg-white/10" active-class="!bg-brand !text-white">{{ link.label }}</RouterLink>
      </nav>
    </aside>
    <div class="min-w-0 flex-1">
      <header class="flex items-center justify-between border-b border-slate-200 bg-white px-6 py-4">
        <div><p class="font-semibold">{{ auth.fullName || 'مستخدم' }}</p><p class="text-xs text-slate-500">{{ auth.role || 'بدون دور' }}</p></div>
        <button class="rounded-lg bg-brand px-4 py-2 text-sm font-semibold text-white hover:bg-brand-dark" @click="logout">تسجيل الخروج</button>
      </header>
      <main class="p-5 md:p-8"><RouterView /></main>
    </div>
  </div>
</template>
