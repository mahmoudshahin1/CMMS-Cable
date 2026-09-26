import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import type { User } from '@supabase/supabase-js'
import { supabase } from '../api/supabase'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const fullName = ref('')
  const role = ref('')
  const loading = ref(false)
  const error = ref('')
  const isAuthenticated = computed(() => Boolean(user.value))

  async function loadProfile(nextUser: User | null) {
    user.value = nextUser
    fullName.value = ''
    role.value = ''
    if (!nextUser || !supabase) return
    const { data } = await supabase.from('user_profiles').select('full_name, role').eq('id', nextUser.id).maybeSingle()
    fullName.value = data?.full_name ?? nextUser.email ?? ''
    role.value = data?.role ?? ''
  }

  async function initialize() {
    if (!supabase) return
    const { data } = await supabase.auth.getSession()
    await loadProfile(data.session?.user ?? null)
    supabase.auth.onAuthStateChange((_event, session) => {
      void loadProfile(session?.user ?? null)
    })
  }

  async function signIn(email: string, password: string) {
    if (!supabase) throw new Error('إعداد Supabase غير مكتمل.')
    loading.value = true
    error.value = ''
    try {
      const { data, error: authError } = await supabase.auth.signInWithPassword({ email, password })
      if (authError) throw authError
      await loadProfile(data.user)
    } catch (cause) {
      error.value = cause instanceof Error ? cause.message : 'تعذر تسجيل الدخول.'
      throw cause
    } finally {
      loading.value = false
    }
  }

  async function signOut() {
    if (!supabase) return
    await supabase.auth.signOut()
    await loadProfile(null)
  }

  return { user, fullName, role, loading, error, isAuthenticated, initialize, signIn, signOut }
})
