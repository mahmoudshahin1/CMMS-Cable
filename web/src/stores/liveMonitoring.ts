import { ref } from 'vue'
import { defineStore } from 'pinia'
import type { RealtimeChannel } from '@supabase/supabase-js'
import { supabase } from '../api/supabase'
import { createLiveRefresh } from '../lib/liveRefresh'

export type Machine = {
  id: string; code: string; name: string; department: string; status: string
  sub_category: string | null
  current_speed_mpm: number | null; total_meters_produced: number | null
  active_downtime_id: string | null; active_downtime_category: string | null
  active_downtime_reason: string | null; active_downtime_started_at: string | null
  active_downtime_minutes: number | null
  last_maintenance_at?: string | null
}

export const useLiveMonitoringStore = defineStore('live-monitoring', () => {
  const machines = ref<Machine[]>([])
  const loading = ref(false)
  const error = ref('')
  const connected = ref(false)
  let channel: RealtimeChannel | null = null
  let scheduler: ReturnType<typeof createLiveRefresh> | null = null

  async function refresh() {
    if (!supabase) { error.value = 'إعداد Supabase غير مكتمل.'; return }
    // Only the very first load shows the skeleton. Later refreshes swap data in
    // place so cards don't flash and entrance animations don't replay.
    const firstLoad = machines.value.length === 0
    if (firstLoad) loading.value = true
    const { data, error: queryError } = await supabase.from('v_machine_status_live').select('*').order('code')
    if (queryError) error.value = queryError.message
    else { machines.value = (data ?? []) as Machine[]; error.value = '' }
    loading.value = false
  }

  async function subscribe() {
    if (!supabase || channel) return
    await refresh()
    scheduler = createLiveRefresh(refresh)
    const onChange = () => scheduler?.request()
    channel = supabase.channel('web-live-machines')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'machines' }, onChange)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'downtime_logs' }, onChange)
      .subscribe((status) => { connected.value = status === 'SUBSCRIBED' })
  }

  async function unsubscribe() {
    scheduler?.dispose()
    scheduler = null
    if (supabase && channel) await supabase.removeChannel(channel)
    channel = null
    connected.value = false
  }

  return { machines, loading, error, connected, refresh, subscribe, unsubscribe }
})
