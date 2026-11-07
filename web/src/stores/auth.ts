import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import type { User } from '@supabase/supabase-js'
import { useLocaleStore } from './locale'
import { supabase } from '../api/supabase'
import { WEB_ACCESS_ROLES, WEB_ROLE_LABELS, WEB_ROLE_LABELS_EN } from '../lib/roles'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const fullName = ref('')
  const role = ref('')
  const webAccess = ref(false)
  const roleNameAr = ref('')
  const roleNameEn = ref('')
  // Role names come from factory_roles (name_ar / name_en) and follow the UI language.
  const roleLabel = computed(() => (useLocaleStore().locale === 'ar' ? roleNameAr.value : roleNameEn.value))
  const pick = (en: string, ar: string) => (useLocaleStore().locale === 'ar' ? ar : en)
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
    roleNameAr.value = ''
    roleNameEn.value = ''
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
      .select('web_access, name_ar, name_en')
      .eq('code', role.value.toUpperCase())
      .maybeSingle()
    if (request !== profileRequest) return

    const normalizedRole = role.value.toUpperCase()
    roleNameAr.value = factoryRole?.name_ar || WEB_ROLE_LABELS[normalizedRole] || role.value
    roleNameEn.value = factoryRole?.name_en || WEB_ROLE_LABELS_EN[normalizedRole] || role.value
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
          // A background token refresh fires this with the SAME user and no
          // profile change. Re-running loadProfile for it would still be
          // correct eventually, but it starts by zeroing webAccess/role back
          // to false/'' before the (two-step) re-fetch resolves — and if a
          // navigation lands in that window, the router reads that transient
          // false and bounces a fully-authorized user to /no-access. Only
          // reload when the signed-in identity actually changes.
          const nextId = session?.user?.id ?? null
          if (nextId === (user.value?.id ?? null)) return
          void loadProfile(session?.user ?? null)
        })
        authSubscription = authState.subscription
      }
    })().catch((cause: unknown) => {
      initPromise = null
      error.value = cause instanceof Error ? cause.message : pick('Could not verify your session.', 'تعذر التحقق من جلسة الدخول.')
      void loadProfile(null)
    })

    return initPromise
  }

  async function signIn(email: string, password: string) {
    if (!supabase) throw new Error(pick('Supabase is not configured.', 'إعداد Supabase غير مكتمل.'))
    loading.value = true
    error.value = ''
    try {
      const { data, error: authError } = await supabase.auth.signInWithPassword({ email, password })
      if (authError) throw authError
      await loadProfile(data.user)
    } catch (cause) {
      error.value = cause instanceof Error ? cause.message : pick('Could not sign in.', 'تعذر تسجيل الدخول.')
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
