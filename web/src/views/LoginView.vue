<script setup lang="ts">
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Activity, ArrowLeft, ShieldCheck } from 'lucide-vue-next'
import { useAuthStore } from '../stores/auth'
import { supabaseConfigError } from '../api/supabase'
import { useLocaleStore } from '../stores/locale'

const email = ref('')
const password = ref('')
const auth = useAuthStore()
const locale = useLocaleStore()
const t = locale.t
const router = useRouter()
const route = useRoute()
const logoUrl = `${import.meta.env.BASE_URL}energya-logo.png`
async function submit() {
  try {
    await auth.signIn(email.value, password.value)
    const requestedPath = typeof route.query.redirect === 'string' ? route.query.redirect : ''
    await router.replace(requestedPath || (auth.webAccess ? '/plant-floor' : '/no-access'))
  } catch { /* The auth store exposes a localized error for the form. */ }
}
</script>

<template>
  <main class="relative grid min-h-screen place-items-center overflow-hidden bg-[radial-gradient(ellipse_at_top_left,_#dff7ff_0%,_transparent_44%),linear-gradient(145deg,#eef4f9,#f8fbfd)] p-4 md:p-8" :dir="locale.direction">
    <div class="pointer-events-none absolute -right-28 top-20 h-72 w-72 rounded-full bg-cyan-300/20 blur-3xl"></div><div class="pointer-events-none absolute -bottom-36 left-10 h-96 w-96 rounded-full bg-blue-300/20 blur-3xl"></div>
    <section class="relative grid w-full max-w-5xl overflow-hidden rounded-[30px] border border-white/80 bg-white/90 shadow-[0_32px_90px_-35px_rgba(10,37,64,.28)] backdrop-blur-xl md:min-h-[570px] md:grid-cols-2">
      <div class="relative flex flex-col justify-between overflow-hidden bg-brand-navy p-7 text-white md:p-10">
        <div class="absolute -left-20 top-28 h-72 w-72 rounded-full border border-cyan-100/10"></div><div class="absolute -left-8 top-40 h-52 w-52 rounded-full border border-cyan-100/10"></div><div class="absolute bottom-20 right-0 h-48 w-48 rounded-full bg-brand/15 blur-3xl"></div>
        <div class="relative"><div class="inline-flex rounded-2xl bg-white px-5 py-4 shadow-lg"><img :src="logoUrl" alt="Energya Cables" class="h-14 w-[220px] object-contain" /></div><p class="mt-8 text-xs font-bold uppercase tracking-[.22em] text-cyan-300">Cable operations platform</p><h2 class="mt-3 max-w-sm text-3xl font-extrabold leading-[1.45] md:text-4xl">{{ t('login.pitch') }}</h2><p class="mt-4 max-w-sm text-sm leading-7 text-white/65">{{ t('login.intro') }}</p></div>
        <div class="relative mt-10 grid grid-cols-2 gap-3"><div class="rounded-2xl border border-white/10 bg-white/[.06] p-4"><Activity :size="18" class="text-cyan-300" /><p class="mt-3 text-sm font-bold">{{ t('login.live') }}</p><p class="mt-1 text-[11px] text-white/50">{{ t('login.liveSub') }}</p></div><div class="rounded-2xl border border-white/10 bg-white/[.06] p-4"><ShieldCheck :size="18" class="text-cyan-300" /><p class="mt-3 text-sm font-bold">{{ t('login.secure') }}</p><p class="mt-1 text-[11px] text-white/50">{{ t('login.secureSub') }}</p></div></div>
        <p class="relative mt-6 text-[10px] text-white/35">Energya Cables · Cable Ops CMMS</p>
      </div>
      <div class="flex items-center p-7 md:p-12">
        <form class="mx-auto w-full max-w-sm" @submit.prevent="submit">
          <div class="mb-7 flex items-center justify-between md:hidden"><img :src="logoUrl" alt="Energya Cables" class="h-12 w-48 object-contain object-left" /><button type="button" class="rounded-lg border px-3 py-2 text-xs font-bold" @click="locale.setLocale(locale.locale === 'ar' ? 'en' : 'ar')">{{ locale.locale === 'ar' ? 'EN' : 'عربي' }}</button></div>
          <div class="mb-3 hidden justify-end md:flex"><button type="button" class="rounded-lg border px-3 py-2 text-xs font-bold" @click="locale.setLocale(locale.locale === 'ar' ? 'en' : 'ar')">{{ locale.locale === 'ar' ? 'EN' : 'عربي' }}</button></div>
          <p class="text-xs font-extrabold tracking-[.18em] text-brand-dark">{{ t('login.welcome') }}</p><h1 class="mt-2 text-3xl font-extrabold text-brand-navy">{{ t('login.title') }}</h1><p class="mt-2 text-sm text-slate-500">{{ t('login.subtitle') }}</p>
          <label class="mt-8 block text-sm font-bold text-slate-700">{{ t('login.email') }}<div class="mt-2 flex items-center rounded-xl border border-slate-200 bg-slate-50 transition focus-within:border-brand focus-within:bg-white focus-within:ring-4 focus-within:ring-cyan-100"><input v-model="email" required type="email" autocomplete="username" placeholder="name@company.com" class="w-full rounded-xl bg-transparent px-4 py-3.5 text-sm outline-none placeholder:text-slate-400" dir="ltr" /></div></label>
          <label class="mt-5 block text-sm font-bold text-slate-700">{{ t('login.password') }}<div class="mt-2 flex items-center rounded-xl border border-slate-200 bg-slate-50 transition focus-within:border-brand focus-within:bg-white focus-within:ring-4 focus-within:ring-cyan-100"><input v-model="password" required type="password" autocomplete="current-password" placeholder="••••••••" class="w-full rounded-xl bg-transparent px-4 py-3.5 text-sm outline-none placeholder:text-slate-400" dir="ltr" /></div></label>
          <p v-if="supabaseConfigError" class="mt-4 rounded-xl bg-amber-50 p-3 text-xs leading-5 text-amber-800">{{ supabaseConfigError }}</p><p v-else-if="auth.error" class="mt-4 rounded-xl bg-red-50 p-3 text-xs leading-5 text-red-700">{{ auth.error }}</p>
          <button :disabled="auth.loading || Boolean(supabaseConfigError)" class="group mt-7 flex w-full items-center justify-center gap-2 rounded-xl bg-brand px-4 py-3.5 text-sm font-extrabold text-white shadow-lg shadow-cyan-900/15 transition duration-200 hover:-translate-y-0.5 hover:bg-brand-dark hover:shadow-xl disabled:cursor-not-allowed disabled:opacity-50">{{ auth.loading ? t('login.loading') : t('login.submit') }}<ArrowLeft :size="17" class="transition-transform group-hover:-translate-x-1" /></button>
          <p class="mt-6 text-center text-[11px] text-slate-400">{{ t('login.access') }}</p>
        </form>
      </div>
    </section>
  </main>
</template>
