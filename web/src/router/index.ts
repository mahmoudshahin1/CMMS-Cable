import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import LoginView from '../views/LoginView.vue'
import AppShell from '../components/AppShell.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/login', component: LoginView, meta: { public: true } },
    { path: '/', redirect: '/plant-floor' },
    { path: '/', component: AppShell, children: [
      { path: 'plant-floor', component: () => import('../views/LivePlantView.vue') },
      { path: 'work-orders', component: () => import('../views/WorkOrdersView.vue') },
      { path: 'analytics', component: () => import('../views/AnalyticsView.vue') },
    ] },
    { path: '/:pathMatch(.*)*', redirect: '/plant-floor' },
  ],
})

router.beforeEach(async (to) => {
  const auth = useAuthStore()
  await auth.initialize()
  if (to.meta.public) return auth.isAuthenticated ? '/plant-floor' : true
  if (!auth.isAuthenticated) return { path: '/login', query: { redirect: to.fullPath } }
  return true
})

export default router
