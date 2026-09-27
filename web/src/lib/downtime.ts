export const downtimeCategories = [
  { value: 'processSetup', label: 'تجهيز وتشغيل / تغيير مقاس' },
  { value: 'processMaterialShortage', label: 'نقص مواد وخامات' },
  { value: 'processQualityHold', label: 'توقف جودة وفحص' },
  { value: 'mechanicalBreakdown', label: 'عطل ميكانيكي' },
  { value: 'electricalBreakdown', label: 'عطل كهربائي' },
  { value: 'utilityFailure', label: 'عطل مرافق (كهرباء/هواء/مياه)' },
  { value: 'plannedMaintenance', label: 'صيانة وقائية مخططة' },
] as const

const cairoParts = new Intl.DateTimeFormat('en-CA', {
  timeZone: 'Africa/Cairo', year: 'numeric', month: '2-digit', day: '2-digit',
  hour: '2-digit', minute: '2-digit', hourCycle: 'h23',
})

function cairoTime(date: Date) {
  const values = Object.fromEntries(cairoParts.formatToParts(date).map((part) => [part.type, part.value]))
  return { date: `${values.year}-${values.month}-${values.day}`, minute: Number(values.hour) * 60 + Number(values.minute) }
}

export function buildChronology(date = new Date()) {
  const local = cairoTime(date)
  const shift = local.minute >= 450 && local.minute < 930
    ? 'shift1_Morning'
    : local.minute >= 930 && local.minute < 1380 ? 'shift2_Evening' : 'shift3_Night'
  const productionDate = local.minute < 450
    ? new Date(new Date(`${local.date}T12:00:00Z`).getTime() - 86400000).toISOString().slice(0, 10)
    : local.date
  return {
    recordedAtUtc: date.toISOString(),
    plantTimeFormatted: new Intl.DateTimeFormat('ar-EG', { timeZone: 'Africa/Cairo', dateStyle: 'short', timeStyle: 'medium' }).format(date),
    productionDate,
    activeShift: shift,
    isOfflineGenerated: false,
    syncedAtUtc: date.toISOString(),
  }
}

export function calculateShiftMinutes(startValue: string, endDate = new Date()) {
  const start = new Date(startValue).getTime()
  const end = endDate.getTime()
  const minutes = { shift1_Morning: 0, shift2_Evening: 0, shift3_Night: 0 }
  if (!Number.isFinite(start) || end <= start) return minutes
  // Count each elapsed minute by its local Cairo shift; cap extreme historical intervals.
  const firstMinute = Math.ceil(start / 60000) * 60000
  const lastMinute = Math.floor(end / 60000) * 60000
  for (let timestamp = firstMinute; timestamp < lastMinute; timestamp += 60000) {
    const minute = cairoTime(new Date(timestamp)).minute
    if (minute >= 450 && minute < 930) minutes.shift1_Morning += 1
    else if (minute >= 930 && minute < 1380) minutes.shift2_Evening += 1
    else minutes.shift3_Night += 1
  }
  return minutes
}

export const downtimeCategoryLabel = (value: string | null | undefined) =>
  downtimeCategories.find((item) => item.value === value)?.label ?? value ?? 'غير محدد'

export const formatCairoDate = (value: string | null | undefined) => {
  if (!value) return '—'
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? '—' : new Intl.DateTimeFormat('ar-EG', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'Africa/Cairo' }).format(date)
}
