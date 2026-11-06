<script setup lang="ts">
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Activity, ArrowLeft, ArrowRight, Eye, EyeOff, Lock, Mail, ShieldCheck, Zap } from 'lucide-vue-next'
import { useAuthStore } from '../stores/auth'
import { supabaseConfigError } from '../api/supabase'
import { useLocaleStore } from '../stores/locale'

const email = ref('')
const password = ref('')
const showPassword = ref(false)
const auth = useAuthStore()
const locale = useLocaleStore()
const t = locale.t
const router = useRouter()
const route = useRoute()
const logoUrl = `${import.meta.env.BASE_URL}energya-logo.png`
const strands = [[0, 0], [18, 0], [9, 15.6], [-9, 15.6], [-18, 0], [-9, -15.6], [9, -15.6]]

function track(event: MouseEvent) {
  const el = event.currentTarget as HTMLElement
  const rect = el.getBoundingClientRect()
  el.style.setProperty('--mx', `${event.clientX - rect.left}px`)
  el.style.setProperty('--my', `${event.clientY - rect.top}px`)
}

async function submit() {
  try {
    await auth.signIn(email.value, password.value)
    const requestedPath = typeof route.query.redirect === 'string' ? route.query.redirect : ''
    await router.replace(requestedPath || (auth.webAccess ? '/plant-floor' : '/no-access'))
  } catch { /* The auth store exposes a localized error for the form. */ }
}
</script>

<template>
  <main class="relative grid min-h-screen place-items-center overflow-hidden bg-[radial-gradient(ellipse_at_top_left,_#dfe9fb_0%,_transparent_48%),linear-gradient(145deg,#eaf1f9,#f8fbfd)] p-4 md:p-8" :dir="locale.direction">
    <div class="pointer-events-none absolute -right-28 top-16 h-80 w-80 rounded-full bg-accent/20 blur-3xl float-blob"></div>
    <div class="pointer-events-none absolute -bottom-40 left-6 h-[26rem] w-[26rem] rounded-full bg-brand/20 blur-3xl float-blob" style="animation-delay:-5s"></div>

    <div class="aurora-border enter w-full max-w-5xl rounded-[32px] p-[2px] shadow-[0_50px_100px_-40px_rgba(8,41,87,.55),0_18px_40px_-24px_rgba(240,78,55,.35)]">
      <section class="grid overflow-hidden rounded-[30px] bg-white md:min-h-[590px] md:grid-cols-2">
        <!-- brand panel -->
        <div class="group/panel relative flex flex-col justify-between overflow-hidden bg-brand-navy p-7 text-white md:p-10" @mousemove="track">
          <div class="pointer-events-none absolute inset-0 opacity-0 transition-opacity duration-500 group-hover/panel:opacity-100" style="background:radial-gradient(380px circle at var(--mx,50%) var(--my,30%),rgba(240,78,55,.22),transparent 65%)"></div>
          <div class="pointer-events-none absolute inset-0 bg-brand-grid opacity-40 [background-size:34px_34px] [mask-image:radial-gradient(ellipse_at_center,black,transparent_75%)]"></div>
          <div class="pointer-events-none absolute inset-x-0 top-0 h-[3px] cable-flow"></div>

          <!-- animated cable cross-section -->
          <svg class="pointer-events-none absolute -bottom-10 -end-20 h-[22rem] w-[22rem] opacity-80 md:-end-14" viewBox="-90 -90 180 180" aria-hidden="true">
            <defs>
              <radialGradient id="cu" cx="35%" cy="30%"><stop offset="0" stop-color="#FFB38A"/><stop offset=".6" stop-color="#F04E37"/><stop offset="1" stop-color="#B8321F"/></radialGradient>
              <radialGradient id="glow"><stop offset=".5" stop-color="#FF7A5C" stop-opacity=".55"/><stop offset="1" stop-color="#FF7A5C" stop-opacity="0"/></radialGradient>
              <linearGradient id="sheath" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F04E37"/><stop offset="1" stop-color="#FF7A5C"/></linearGradient>
            </defs>
            <circle r="80" fill="rgba(255,255,255,.03)" stroke="rgba(255,255,255,.08)" />
            <circle r="72" fill="none" stroke="url(#sheath)" stroke-width="7" opacity=".9" />
            <g class="cable-spin-rev"><circle r="60" fill="none" stroke="#9fb7de" stroke-width="5" stroke-dasharray="5 3.4" opacity=".75" /></g>
            <circle r="52" fill="#0f3a7d" opacity=".9" />
            <g class="cable-spin"><circle r="40" fill="none" stroke="#2563EB" stroke-width="8" opacity=".85" /><circle r="40" fill="none" stroke="#fff" stroke-width="1" stroke-dasharray="2 10" opacity=".5" /></g>
            <circle r="31" fill="#082957" />
            <g class="cable-core"><circle r="38" fill="url(#glow)" /><circle v-for="(s, i) in strands" :key="i" :cx="s[0]" :cy="s[1]" r="8.4" fill="url(#cu)" /></g>
            <g class="cable-orbit"><circle cx="72" cy="0" r="4.5" fill="#fff" /><circle cx="72" cy="0" r="10" fill="#FF7A5C" opacity=".35" /></g>
          </svg>

          <div class="relative">
            <div class="enter inline-flex rounded-2xl bg-white px-5 py-4 shadow-xl shadow-black/25" style="--d:120ms"><img :src="logoUrl" alt="Energya Cables" class="h-14 w-[220px] object-contain" /></div>
            <p class="enter mt-8 flex items-center gap-1.5 text-xs font-bold uppercase tracking-[.22em] text-accent-light" style="--d:220ms"><Zap :size="13" class="fill-current" />Cable operations platform</p>
            <h2 class="enter mt-3 max-w-sm text-3xl font-extrabold leading-[1.45] md:text-4xl" style="--d:300ms">{{ t('login.pitch') }}</h2>
            <p class="enter mt-4 max-w-xs text-sm leading-7 text-white/65" style="--d:380ms">{{ t('login.intro') }}</p>
          </div>

          <div class="relative mt-10 grid max-w-md grid-cols-2 gap-3">
            <div class="enter group rounded-2xl border border-white/10 bg-white/[.07] p-4 shadow-lg shadow-black/20 transition duration-300 hover:-translate-y-1.5 hover:border-accent/50 hover:bg-white/[.12] hover:shadow-accent" style="--d:480ms">
              <Activity :size="18" class="text-accent-light transition duration-300 group-hover:scale-125" />
              <p class="mt-3 text-sm font-bold">{{ t('login.live') }}</p>
              <p class="mt-1 text-[11px] text-white/55">{{ t('login.liveSub') }}</p>
            </div>
            <div class="enter group rounded-2xl border border-white/10 bg-white/[.07] p-4 shadow-lg shadow-black/20 transition duration-300 hover:-translate-y-1.5 hover:border-accent/50 hover:bg-white/[.12] hover:shadow-accent" style="--d:560ms">
              <ShieldCheck :size="18" class="text-accent-light transition duration-300 group-hover:scale-125" />
              <p class="mt-3 text-sm font-bold">{{ t('login.secure') }}</p>
              <p class="mt-1 text-[11px] text-white/55">{{ t('login.secureSub') }}</p>
            </div>
          </div>
        </div>

        <!-- form panel -->
        <div class="relative flex items-center bg-[linear-gradient(180deg,#fff,#f6f9fd)] p-7 md:p-12">
          <form class="mx-auto w-full max-w-sm" @submit.prevent="submit">
            <div class="enter mb-7 flex items-center justify-between md:hidden" style="--d:100ms"><img :src="logoUrl" alt="Energya Cables" class="h-12 w-48 object-contain object-left" /><button type="button" class="rounded-lg border px-3 py-2 text-xs font-bold" @click="locale.setLocale(locale.locale === 'ar' ? 'en' : 'ar')">{{ locale.locale === 'ar' ? 'EN' : 'عربي' }}</button></div>
            <div class="enter mb-3 hidden justify-end md:flex" style="--d:100ms"><button type="button" class="rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs font-bold shadow-sm transition hover:-translate-y-0.5 hover:border-brand" @click="locale.setLocale(locale.locale === 'ar' ? 'en' : 'ar')">{{ locale.locale === 'ar' ? 'EN' : 'عربي' }}</button></div>
            <p class="enter text-xs font-extrabold tracking-[.18em] text-accent" style="--d:180ms">{{ t('login.welcome') }}</p>
            <h1 class="enter mt-2 text-3xl font-extrabold brand-gradient-text" style="--d:240ms">{{ t('login.title') }}</h1>
            <p class="enter mt-2 text-sm text-slate-500" style="--d:300ms">{{ t('login.subtitle') }}</p>

            <label class="enter mt-8 block text-sm font-bold text-slate-700" style="--d:380ms">{{ t('login.email') }}
              <div class="field-wrap mt-2 flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-3 shadow-sm transition duration-300 focus-within:-translate-y-0.5 focus-within:border-brand/60 focus-within:shadow-[0_14px_28px_-16px_rgba(12,69,149,.55)]">
                <Mail :size="17" class="shrink-0 text-slate-400 transition-colors group-focus-within:text-brand" />
                <input v-model="email" required type="email" autocomplete="username" placeholder="name@company.com" class="w-full bg-transparent py-3.5 text-sm outline-none placeholder:text-slate-400" dir="ltr" />
              </div>
            </label>
            <label class="enter mt-5 block text-sm font-bold text-slate-700" style="--d:450ms">{{ t('login.password') }}
              <div class="field-wrap mt-2 flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-3 shadow-sm transition duration-300 focus-within:-translate-y-0.5 focus-within:border-brand/60 focus-within:shadow-[0_14px_28px_-16px_rgba(12,69,149,.55)]">
                <Lock :size="17" class="shrink-0 text-slate-400" />
                <input v-model="password" required :type="showPassword ? 'text' : 'password'" autocomplete="current-password" placeholder="••••••••" class="w-full bg-transparent py-3.5 text-sm outline-none placeholder:text-slate-400" dir="ltr" />
                <button type="button" class="rounded-md p-1.5 text-slate-400 transition hover:bg-slate-100 hover:text-brand" :aria-label="showPassword ? (locale.locale === 'ar' ? 'إخفاء كلمة المرور' : 'Hide password') : (locale.locale === 'ar' ? 'إظهار كلمة المرور' : 'Show password')" @click="showPassword = !showPassword"><component :is="showPassword ? EyeOff : Eye" :size="17" /></button>
              </div>
            </label>

            <p v-if="supabaseConfigError" class="mt-4 rounded-xl bg-amber-50 p-3 text-xs leading-5 text-amber-800">{{ supabaseConfigError }}</p>
            <p v-else-if="auth.error" class="rise-in mt-4 rounded-xl border border-accent/20 bg-accent-50 p-3 text-xs leading-5 text-accent-dark">{{ auth.error }}</p>

            <button :disabled="auth.loading || Boolean(supabaseConfigError)" class="enter btn-shine group mt-7 flex w-full items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-brand via-brand-light to-brand-dark px-4 py-3.5 text-sm font-extrabold text-white shadow-[0_16px_30px_-12px_rgba(12,69,149,.8)] transition duration-300 hover:-translate-y-1 hover:shadow-[0_22px_36px_-12px_rgba(240,78,55,.6)] active:translate-y-0 disabled:cursor-not-allowed disabled:opacity-60" style="--d:540ms">
              <span v-if="auth.loading" class="h-4 w-4 animate-spin rounded-full border-2 border-white/40 border-t-white"></span>
              {{ auth.loading ? t('login.loading') : t('login.submit') }}
              <component :is="locale.direction === 'rtl' ? ArrowLeft : ArrowRight" v-if="!auth.loading" :size="17" class="transition-transform duration-300 ltr:group-hover:translate-x-1.5 rtl:group-hover:-translate-x-1.5" />
            </button>
            <p class="enter mt-6 text-center text-[11px] text-slate-400" style="--d:620ms">{{ t('login.access') }}</p>
          </form>
        </div>
      </section>
    </div>
  </main>
</template>
