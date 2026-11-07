import { ref } from 'vue'

// "full" = ambient animations on, "lite" = all looping animations off.
// Lite is picked automatically on weak devices / when the OS asks for reduced
// motion, and the user can flip it from the header (choice is remembered).
type Mode = 'full' | 'lite'
const KEY = 'energya-motion'
export const motionMode = ref<Mode>('full')

function detect(): Mode {
  try {
    const saved = localStorage.getItem(KEY)
    if (saved === 'full' || saved === 'lite') return saved
  } catch { /* storage can be unavailable */ }
  const nav = navigator as Navigator & { deviceMemory?: number }
  const weak = (nav.hardwareConcurrency ?? 8) <= 4 || (nav.deviceMemory ?? 8) <= 4
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches
  return weak || reduce ? 'lite' : 'full'
}

function apply() { document.documentElement.dataset.motion = motionMode.value }

export function initMotion() { motionMode.value = detect(); apply() }

export function toggleMotion() {
  motionMode.value = motionMode.value === 'lite' ? 'full' : 'lite'
  try { localStorage.setItem(KEY, motionMode.value) } catch { /* ignore */ }
  apply()
}
