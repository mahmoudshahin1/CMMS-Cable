import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import { initMotion } from './lib/motion'
import './style.css'

initMotion()
createApp(App).use(createPinia()).use(router).mount('#app')
