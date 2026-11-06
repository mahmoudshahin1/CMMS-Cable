<script setup lang="ts">
import type { Component } from 'vue'

// Shaded summary tile. With `interactive` it becomes a filter button.
withDefaults(defineProps<{
  label: string
  value: string | number
  tone?: 'brand' | 'red' | 'amber' | 'emerald' | 'violet'
  icon?: Component
  hint?: string
  active?: boolean
  interactive?: boolean
}>(), { tone: 'brand' })
defineEmits<{ select: [] }>()
</script>

<template>
  <component
    :is="interactive ? 'button' : 'div'"
    :type="interactive ? 'button' : undefined"
    class="stat-tile enter flex w-full items-center gap-3 text-start"
    :class="[`tone-${tone}`, { 'is-active': active, 'cursor-pointer': interactive }]"
    :aria-pressed="interactive ? Boolean(active) : undefined"
    @click="interactive && $emit('select')"
  >
    <span v-if="icon" class="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-[rgb(var(--tone)/.14)] text-[rgb(var(--tone))]"><component :is="icon" :size="18" /></span>
    <span class="min-w-0">
      <span class="block text-2xl font-extrabold tabular-nums text-brand-navy">{{ value }}</span>
      <span class="block truncate text-[11px] font-semibold text-slate-500">{{ label }}</span>
      <span v-if="hint" class="block truncate text-[10px] text-slate-400">{{ hint }}</span>
    </span>
  </component>
</template>
