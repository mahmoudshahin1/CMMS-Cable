<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import { supabase } from '../api/supabase'
const rows = ref<Record<string, unknown>[]>([]); const error = ref(''); const loading = ref(true)
let channel: ReturnType<NonNullable<typeof supabase>['channel']> | null = null
async function refresh() {
  if (!supabase) { error.value = 'إعداد Supabase غير مكتمل.'; loading.value = false; return }
  const { data, error: queryError } = await supabase.from('work_orders').select('id, title, status, priority, created_at, assigned_to_technician_id, machine:machines!work_orders_machine_id_fkey(code, name, department)').order('created_at', { ascending: false })
  if (queryError) error.value = queryError.message; else { rows.value = data ?? []; error.value = '' }
  loading.value = false
}
onMounted(() => {
  void refresh()
  if (supabase) channel = supabase.channel('web-work-orders').on('postgres_changes', { event: '*', schema: 'public', table: 'work_orders' }, () => void refresh()).subscribe()
})
onUnmounted(() => { if (supabase && channel) void supabase.removeChannel(channel) })
</script>
<template>
  <section><h1 class="mb-1 text-2xl font-bold">أوامر الشغل</h1><p class="mb-6 text-sm text-slate-500">متابعة أوامر الصيانة الحالية</p>
    <p v-if="loading" class="text-slate-500">جارٍ تحميل أوامر الشغل…</p><p v-else-if="error" class="rounded-lg bg-red-50 p-4 text-red-700">{{ error }}</p>
    <div v-else-if="!rows.length" class="rounded-xl border border-dashed bg-white p-8 text-center text-slate-500">لا توجد أوامر شغل حاليًا</div>
    <div v-else class="overflow-x-auto rounded-xl border bg-white"><table class="w-full text-right text-sm"><thead class="bg-slate-50"><tr><th class="p-3">معرّف الأمر</th><th class="p-3">العنوان</th><th class="p-3">الماكينة</th><th class="p-3">معرّف الفني</th><th class="p-3">الحالة</th><th class="p-3">الأولوية</th></tr></thead><tbody><tr v-for="row in rows" :key="String(row.id)" class="border-t"><td class="p-3">#{{ String(row.id).slice(0, 8) }}</td><td class="p-3">{{ row.title }}</td><td class="p-3">{{ (row.machine as { code?: string } | null)?.code ?? '—' }}</td><td class="p-3">{{ row.assigned_to_technician_id ? String(row.assigned_to_technician_id).slice(0, 8) : 'غير مسند' }}</td><td class="p-3">{{ row.status }}</td><td class="p-3">{{ row.priority }}</td></tr></tbody></table></div>
  </section>
</template>
