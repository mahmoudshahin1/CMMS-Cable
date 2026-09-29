import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import LoginView from '../views/LoginView.vue'
import NoAccessView from '../views/NoAccessView.vue'
import AppShell from '../components/AppShell.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/login', component: LoginView, meta: { public: true } },
    { path: '/no-access', component: NoAccessView, meta: { public: true, noWebAccess: true } },
    { path: '/', redirect: '/plant-floor' },
    { path: '/', component: AppShell, children: [
      { path: 'plant-floor', component: () => import('../views/LivePlantView.vue') },
      { path: 'machines/:id', component: () => import('../views/MachineDetailView.vue') },
      { path: 'downtime', component: () => import('../views/DowntimeView.vue') },
      { path: 'spare-parts', component: () => import('../views/SparePartsView.vue') },
      { path: 'work-orders', component: () => import('../views/WorkOrdersView.vue') },
      { path: 'work-orders/:id', component: () => import('../views/WorkOrderDetailView.vue') },
      { path: 'analytics', component: () => import('../views/AnalyticsView.vue') },
    ] },
    { path: '/:pathMatch(.*)*', redirect: '/plant-floor' },
  ],
})

router.beforeEach(async (to) => {
  const auth = useAuthStore()
  await auth.initialize()

  if (to.path === '/login') {
    if (!auth.isAuthenticated) return true
    return auth.webAccess ? '/plant-floor' : '/no-access'
  }

  if (!auth.isAuthenticated) return { path: '/login', query: { redirect: to.fullPath } }
  if (!auth.webAccess && to.path !== '/no-access') return '/no-access'
  if (auth.webAccess && (to.path === '/no-access' || to.path === '/login')) return '/plant-floor'
  return true
})

export default router
