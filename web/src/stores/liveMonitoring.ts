import { ref } from 'vue'
import { defineStore } from 'pinia'
import type { RealtimeChannel } from '@supabase/supabase-js'
import { supabase } from '../api/supabase'

export type Machine = {
  id: string; code: string; name: string; department: string; status: string
  current_speed_mpm: number | null; total_meters_produced: number | null
  active_downtime_id: string | null; active_downtime_reason: string | null
}

export const useLiveMonitoringStore = defineStore('live-monitoring', () => {
  const machines = ref<Machine[]>([])
  const loading = ref(false)
  const error = ref('')
  const connected = ref(false)
  let channel: RealtimeChannel | null = null

  async function refresh() {
    if (!supabase) { error.value = 'إعداد Supabase غير مكتمل.'; return }
    loading.value = true
    const { data, error: queryError } = await supabase.from('v_machine_status_live').select('*').order('code')
    if (queryError) error.value = queryError.message
    else { machines.value = (data ?? []) as Machine[]; error.value = '' }
    loading.value = false
  }

  async function subscribe() {
    if (!supabase || channel) return
    await refresh()
    channel = supabase.channel('web-live-machines')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'machines' }, () => void refresh())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'downtime_logs' }, () => void refresh())
      .subscribe((status) => { connected.value = status === 'SUBSCRIBED' })
  }

  async function unsubscribe() {
    if (supabase && channel) await supabase.removeChannel(channel)
    channel = null
    connected.value = false
  }

  return { machines, loading, error, connected, refresh, subscribe, unsubscribe }
})
