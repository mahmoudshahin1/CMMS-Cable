export const departmentLabels: Record<string, string> = {
  drawing: 'السحب',
  ccv: 'العزل والتكسية',
  stranding: 'الجدل',
  tapeArmour: 'التسليح',
  extrusion: 'الغلاف الخارجي',
  assembly: 'إعادة لف',
  screening: 'التجهيز',
}

export const workOrderStatuses = [
  { value: 'open', label: 'مفتوح' },
  { value: 'assigned', label: 'مُسند' },
  { value: 'inProgress', label: 'جاري العمل' },
  { value: 'pendingParts', label: 'بانتظار قطع غيار' },
  { value: 'completed', label: 'مكتمل' },
  { value: 'verified', label: 'تم التحقق' },
  { value: 'verifiedClosed', label: 'مغلق' },
] as const

export const workOrderPriorities = [
  { value: 'critical', label: 'حرج', className: 'bg-red-100 text-red-800' },
  { value: 'high', label: 'مرتفع', className: 'bg-orange-100 text-orange-800' },
  { value: 'medium', label: 'متوسط', className: 'bg-amber-100 text-amber-800' },
  { value: 'low', label: 'منخفض', className: 'bg-slate-100 text-slate-700' },
] as const

export const workOrderTypes = [
  { value: 'breakdown', label: 'عطل' },
  { value: 'preventive', label: 'صيانة وقائية' },
  { value: 'corrective', label: 'صيانة تصحيحية' },
  { value: 'inspection', label: 'فحص' },
] as const

export const eventTypeLabels: Record<string, string> = {
  REPORTED: 'تم تسجيل أمر الشغل',
  ASSIGNED: 'تم إسناد الفني',
  REPAIR_STARTED: 'بدأ الإصلاح',
  SPARE_PART_ADDED: 'تمت إضافة قطعة غيار',
  REPAIR_COMPLETED: 'اكتمل الإصلاح',
  TEST_RUN_PASSED: 'تم اجتياز التشغيل التجريبي',
  CLOSED: 'تم إغلاق أمر الشغل',
}

export function statusLabel(status: string | null | undefined): string {
  return workOrderStatuses.find((item) => item.value === status)?.label ?? status ?? 'غير محدد'
}

export function priorityInfo(priority: string | null | undefined) {
  return workOrderPriorities.find((item) => item.value === priority) ?? {
    value: priority ?? '',
    label: priority ?? 'غير محدد',
    className: 'bg-slate-100 text-slate-700',
  }
}

export function typeLabel(type: string | null | undefined): string {
  return workOrderTypes.find((item) => item.value === type)?.label ?? type ?? 'غير محدد'
}

export function statusClass(status: string | null | undefined): string {
  const styles: Record<string, string> = {
    open: 'bg-blue-100 text-blue-800',
    assigned: 'bg-indigo-100 text-indigo-800',
    inProgress: 'bg-amber-100 text-amber-800',
    pendingParts: 'bg-orange-100 text-orange-800',
    completed: 'bg-emerald-100 text-emerald-800',
    verified: 'bg-teal-100 text-teal-800',
    verifiedClosed: 'bg-slate-200 text-slate-800',
  }
  return styles[status ?? ''] ?? 'bg-slate-100 text-slate-700'
}

export function eventTypeLabel(eventType: string | null | undefined): string {
  if (!eventType) return 'تحديث'
  return eventTypeLabels[eventType.toUpperCase()] ?? eventType.replaceAll('_', ' ')
}

export function formatDateTime(value: string | null | undefined): string {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '—'
  return new Intl.DateTimeFormat('ar-EG', {
    dateStyle: 'medium',
    timeStyle: 'short',
    timeZone: 'Africa/Cairo',
  }).format(date)
}

export function relativeTime(value: string | null | undefined): string {
  if (!value) return '—'
  const timestamp = new Date(value).getTime()
  if (Number.isNaN(timestamp)) return '—'
  const seconds = Math.round((timestamp - Date.now()) / 1000)
  const units: [Intl.RelativeTimeFormatUnit, number][] = [
    ['year', 60 * 60 * 24 * 365],
    ['month', 60 * 60 * 24 * 30],
    ['day', 60 * 60 * 24],
    ['hour', 60 * 60],
    ['minute', 60],
  ]
  const [unit, divisor] = units.find(([, size]) => Math.abs(seconds) >= size) ?? ['second', 1]
  return new Intl.RelativeTimeFormat('ar', { numeric: 'auto' }).format(Math.round(seconds / divisor), unit)
}

export function shortId(value: string | null | undefined): string {
  return value ? value.slice(0, 8) : '—'
}
