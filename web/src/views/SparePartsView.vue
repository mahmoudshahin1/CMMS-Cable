<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import type { RealtimeChannel } from '@supabase/supabase-js'
import { supabase } from '../api/supabase'

type SparePart = { id: string; part_code: string; name: string; description?: string | null; category?: string | null; unit?: string | null; quantity_on_hand?: number | string | null; reorder_level?: number | string | null; quantity_in_stock?: number | string | null; min_stock_level?: number | string | null; location?: string | null; unit_cost?: number | string | null }
const parts = ref<SparePart[]>([])
const machineCounts = ref<Record<string, number>>({})
const search = ref('')
const loading = ref(true)
const error = ref('')
let channel: RealtimeChannel | null = null
const filtered = computed(() => {
  const query = search.value.trim().toLocaleLowerCase('ar')
  return parts.value.filter((part) => !query || [part.part_code, part.name, part.category, part.location].some((value) => value?.toLocaleLowerCase('ar').includes(query)))
})

async function refresh() {
  if (!supabase) { error.value = 'إعداد Supabase غير مكتمل.'; loading.value = false; return }
  const [partResult, bomResult] = await Promise.all([
    supabase.from('spare_parts').select('*').order('part_code'),
    supabase.from('machine_bom').select('spare_part_id'),
  ])
  if (partResult.error) error.value = partResult.error.message
  else { parts.value = (partResult.data ?? []) as SparePart[]; error.value = '' }
  if (bomResult.error) error.value ||= bomResult.error.message
  else machineCounts.value = (bomResult.data ?? []).reduce<Record<string, number>>((counts, row) => { counts[row.spare_part_id] = (counts[row.spare_part_id] ?? 0) + 1; return counts }, {})
  loading.value = false
}

function stock(part: SparePart) { return Number(part.quantity_on_hand ?? part.quantity_in_stock ?? 0) }
function reorder(part: SparePart) { return Number(part.reorder_level ?? part.min_stock_level ?? 0) }
function stockClass(part: SparePart) { return stock(part) <= reorder(part) ? 'bg-red-100 text-red-800' : 'bg-emerald-100 text-emerald-800' }

onMounted(() => {
  void refresh()
  if (supabase) channel = supabase.channel('web-spare-parts-live')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'spare_parts' }, () => void refresh())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'machine_bom' }, () => void refresh())
    .subscribe()
})
onUnmounted(() => { if (supabase && channel) void supabase.removeChannel(channel) })
</script>

<template>
  <div>
    <div class="mb-6 flex flex-wrap items-end justify-between gap-4"><div><h1 class="text-2xl font-bold">قطع الغيار</h1><p class="mt-1 text-sm text-slate-500">مستويات المخزون والارتباط بقوائم الماكينات</p></div><label class="text-sm">بحث<input v-model="search" class="mt-1 block w-64 rounded-lg border-slate-300" placeholder="كود القطعة أو الاسم أو الموقع" /></label></div>
    <p v-if="error" class="mb-4 rounded-lg bg-red-50 p-4 text-red-700">{{ error }}</p>
    <p v-if="loading" class="text-slate-500">جارٍ تحميل قطع الغيار…</p>
    <div v-else-if="!filtered.length" class="rounded-xl border border-dashed bg-white p-10 text-center text-slate-500">{{ parts.length ? 'لا توجد نتائج مطابقة للبحث.' : 'لا توجد قطع غيار مسجلة حاليًا.' }}</div>
    <div v-else class="overflow-x-auto rounded-xl border bg-white"><table class="w-full min-w-[850px] text-right text-sm"><thead class="bg-slate-50 text-slate-600"><tr><th class="p-3">كود القطعة</th><th class="p-3">الاسم والتصنيف</th><th class="p-3">المخزون</th><th class="p-3">حد إعادة الطلب</th><th class="p-3">الوحدة</th><th class="p-3">الموقع</th><th class="p-3">ماكينات مرتبطة</th></tr></thead><tbody><tr v-for="part in filtered" :key="part.id" class="border-t"><td class="p-3 font-bold">{{ part.part_code }}</td><td class="p-3"><p class="font-semibold">{{ part.name }}</p><p class="text-xs text-slate-500">{{ part.category || part.description || '—' }}</p></td><td class="p-3"><span class="rounded-full px-3 py-1 text-xs font-semibold" :class="stockClass(part)">{{ stock(part).toLocaleString('ar-EG') }}</span></td><td class="p-3">{{ reorder(part).toLocaleString('ar-EG') }}</td><td class="p-3">{{ part.unit || 'قطعة' }}</td><td class="p-3">{{ part.location || '—' }}</td><td class="p-3">{{ machineCounts[part.id] ?? 0 }}</td></tr></tbody></table></div>
    <p v-if="!loading && parts.length" class="mt-3 text-xs text-slate-500">المخزون عند حد إعادة الطلب أو أقل يظهر باللون الأحمر.</p>
  </div>
</template>
