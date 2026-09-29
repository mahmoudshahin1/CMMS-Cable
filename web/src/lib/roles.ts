export const SUPERVISOR_ROLES = [
  'ADMIN',
  'PLANT_MANAGER',
  'SUPERVISOR',
  'MAINTENANCE_SUPERVISOR',
  'PRODUCTION_SUPERVISOR',
] as const

export const TECHNICIAN_ROLES = ['TECHNICIAN', 'MAINTENANCE_TECH'] as const

// Roles explicitly authorized to use the web dashboard. Keep this aligned
// with the factory role catalog; it also lets known roles in when the catalog
// row is not readable yet.
export const WEB_ACCESS_ROLES = [
  'ADMIN',
  'PLANT_MANAGER',
  'SUPERVISOR',
  'MAINTENANCE_SUPERVISOR',
  'PRODUCTION_SUPERVISOR',
] as const

export const WEB_ROLE_LABELS: Record<string, string> = {
  ADMIN: 'مدير النظام',
  PLANT_MANAGER: 'مدير المصنع',
  SUPERVISOR: 'مشرف',
  MAINTENANCE_SUPERVISOR: 'مشرف الصيانة',
  PRODUCTION_SUPERVISOR: 'مشرف الإنتاج',
}

// These match the roles enforced by rpc_assign_work_order in PostgreSQL.
export const WORK_ORDER_ASSIGN_ROLES = [
  'ADMIN',
  'PLANT_MANAGER',
  'SUPERVISOR',
  'MAINTENANCE_SUPERVISOR',
] as const

export const WORK_ORDER_CLOSE_ROLES = SUPERVISOR_ROLES
