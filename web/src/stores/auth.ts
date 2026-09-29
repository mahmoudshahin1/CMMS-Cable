import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import type { User } from '@supabase/supabase-js'
import { supabase } from '../api/supabase'
import { WEB_ACCESS_ROLES, WEB_ROLE_LABELS } from '../lib/roles'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const fullName = ref('')
  const role = ref('')
  const webAccess = ref(false)
  const roleLabel = ref('')
  const department = ref<string | null>(null)
  const loading = ref(false)
  const error = ref('')
  const isAuthenticated = computed(() => Boolean(user.value))
  let initPromise: Promise<void> | null = null
  let authSubscription: { unsubscribe: () => void } | null = null
  let profileRequest = 0

  async function loadProfile(nextUser: User | null) {
    const request = ++profileRequest
    user.value = nextUser
    fullName.value = ''
    role.value = ''
    webAccess.value = false
    roleLabel.value = ''
    department.value = null
    if (!nextUser || !supabase) return

    const { data, error: profileError } = await supabase
      .from('user_profiles')
      .select('full_name, role, department')
      .eq('id', nextUser.id)
      .maybeSingle()
    if (request !== profileRequest) return

    fullName.value = data?.full_name ?? nextUser.email ?? ''
    role.value = data?.role ?? ''
    department.value = data?.department ?? null

    if (profileError || !role.value) return

    const { data: factoryRole, error: factoryRoleError } = await supabase
      .from('factory_roles')
      .select('web_access, name_ar')
      .eq('code', role.value.toUpperCase())
      .maybeSingle()
    if (request !== profileRequest) return

    const normalizedRole = role.value.toUpperCase()
    roleLabel.value = factoryRole?.name_ar || WEB_ROLE_LABELS[normalizedRole] || role.value
    const explicitlyAllowed = (WEB_ACCESS_ROLES as readonly string[]).includes(normalizedRole)
    webAccess.value = explicitlyAllowed || (!factoryRoleError && factoryRole?.web_access === true)
  }

  async function initialize() {
    if (initPromise) return initPromise

    initPromise = (async () => {
      if (!supabase) {
        await loadProfile(null)
        return
      }

      const { data, error: sessionError } = await supabase.auth.getSession()
      if (sessionError) throw sessionError
      await loadProfile(data.session?.user ?? null)

      if (!authSubscription) {
        const { data: authState } = supabase.auth.onAuthStateChange((_event, session) => {
          void loadProfile(session?.user ?? null)
        })
        authSubscription = authState.subscription
      }
    })().catch((cause: unknown) => {
      initPromise = null
      error.value = cause instanceof Error ? cause.message : 'تعذر التحقق من جلسة الدخول.'
      void loadProfile(null)
    })

    return initPromise
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

  return { user, fullName, role, webAccess, roleLabel, department, loading, error, isAuthenticated, initialize, signIn, signOut }
})
