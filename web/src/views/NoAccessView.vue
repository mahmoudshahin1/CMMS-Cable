<script setup lang="ts">
import { useRouter } from 'vue-router'
import { LogOut, ShieldAlert, Smartphone } from 'lucide-vue-next'
import { useAuthStore } from '../stores/auth'
import { useLocaleStore } from '../stores/locale'

const auth = useAuthStore()
const locale = useLocaleStore()
const t = locale.t
const router = useRouter()
const logoUrl = `${import.meta.env.BASE_URL}energya-logo.png`

async function logout() {
  await auth.signOut()
  await router.replace('/login')
}
</script>

<template>
  <main :dir="locale.direction" class="relative grid min-h-screen place-items-center overflow-hidden bg-[radial-gradient(ellipse_at_top_left,_#dff7ff_0%,_transparent_44%),linear-gradient(145deg,#eef4f9,#f8fbfd)] p-4 md:p-8">
    <div class="pointer-events-none absolute -right-28 top-20 h-72 w-72 rounded-full bg-cyan-300/20 blur-3xl"></div>
    <div class="pointer-events-none absolute -bottom-36 left-10 h-96 w-96 rounded-full bg-blue-300/20 blur-3xl"></div>

    <section class="relative w-full max-w-xl rounded-[30px] border border-white/80 bg-white/90 p-7 text-center shadow-[0_32px_90px_-35px_rgba(10,37,64,.28)] backdrop-blur-xl md:p-12">
      <div class="mx-auto mb-8 inline-flex rounded-2xl bg-white px-5 py-4 shadow-lg">
        <img :src="logoUrl" alt="Energya Cables" class="h-12 w-[200px] object-contain" />
      </div>

      <div class="mx-auto grid h-16 w-16 place-items-center rounded-2xl bg-amber-50 text-amber-700">
        <ShieldAlert :size="30" />
      </div>
      <p class="mt-6 text-xs font-extrabold tracking-[.18em] text-brand-dark">{{ t('noAccess.eyebrow') }}</p>
      <h1 class="mt-2 text-2xl font-extrabold text-brand-navy md:text-3xl">{{ t('noAccess.title') }}</h1>
      <p class="mx-auto mt-3 max-w-md text-sm leading-7 text-slate-600">{{ t('noAccess.message') }}</p>

      <div class="mx-auto mt-7 max-w-sm rounded-2xl border border-slate-200 bg-slate-50 p-4 text-right">
        <p class="text-xs text-slate-500">{{ t('noAccess.account') }}</p>
        <p class="mt-1 font-bold text-brand-navy">{{ auth.fullName || auth.user?.email || 'مستخدم' }}</p>
        <p class="mt-2 text-xs text-slate-500">{{ t('noAccess.role') }}</p>
        <p class="mt-1 font-semibold text-slate-700">{{ auth.roleLabel || 'غير محدد' }}</p>
      </div>

      <div class="mt-7 flex flex-col items-center gap-3">
        <div class="mb-3 flex justify-center"><button class="rounded-lg border px-3 py-2 text-xs font-bold" @click="locale.setLocale(locale.locale === 'ar' ? 'en' : 'ar')">{{ locale.locale === 'ar' ? 'EN' : 'عربي' }}</button></div>
        <span class="inline-flex items-center gap-2 text-xs font-semibold text-slate-500"><Smartphone :size="15" /> {{ t('noAccess.app') }}</span>
        <button class="group inline-flex items-center gap-2 rounded-xl bg-brand px-5 py-3 text-sm font-extrabold text-white shadow-lg shadow-cyan-900/15 transition hover:-translate-y-0.5 hover:bg-brand-dark" @click="logout">
          <LogOut :size="16" class="transition-transform group-hover:-translate-x-0.5" />
          {{ t('noAccess.logout') }}
        </button>
      </div>
    </section>
  </main>
</template>
