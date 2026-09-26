<script setup lang="ts">
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { supabaseConfigError } from '../api/supabase'
const email = ref(''); const password = ref('')
const auth = useAuthStore(); const router = useRouter(); const route = useRoute()
async function submit() {
  try {
    await auth.signIn(email.value, password.value)
    await router.replace(typeof route.query.redirect === 'string' ? route.query.redirect : '/plant-floor')
  } catch { /* The store exposes the error for the form. */ }
}
</script>
<template>
  <main class="flex min-h-screen items-center justify-center bg-slate-100 p-5">
    <form class="w-full max-w-md rounded-2xl bg-white p-8 shadow-sm" @submit.prevent="submit">
      <p class="text-sm font-bold text-brand">ENERGYA CABLES</p><h1 class="mt-2 text-2xl font-bold">تسجيل الدخول</h1>
      <p class="mt-2 text-sm text-slate-500">لوحة متابعة عمليات المصنع والصيانة</p>
      <label class="mt-6 block text-sm font-medium">البريد الإلكتروني<input v-model="email" required type="email" autocomplete="username" class="mt-2 w-full rounded-lg border p-3" /></label>
      <label class="mt-4 block text-sm font-medium">كلمة المرور<input v-model="password" required type="password" autocomplete="current-password" class="mt-2 w-full rounded-lg border p-3" /></label>
      <p v-if="supabaseConfigError" class="mt-4 text-sm text-amber-700">{{ supabaseConfigError }}</p>
      <p v-else-if="auth.error" class="mt-4 text-sm text-red-600">{{ auth.error }}</p>
      <button :disabled="auth.loading || Boolean(supabaseConfigError)" class="mt-6 w-full rounded-lg bg-brand p-3 font-semibold text-white disabled:opacity-50">{{ auth.loading ? 'جارٍ الدخول…' : 'دخول' }}</button>
    </form>
  </main>
</template>
