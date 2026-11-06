module.exports = {
  content: ['./index.html', './src/**/*.{vue,ts,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT: '#0C4595', // Energya primary blue
          light: '#2563EB',
          dark: '#093777',    // Energya secondary deep blue
          navy: '#082957',    // Energya deep navy (sidebar / hero)
          50: '#EEF3FB',
          100: '#E1E8F2',
        },
        accent: {
          DEFAULT: '#F04E37', // Energya signature orange
          light: '#FF7A5C',
          dark: '#D53B26',
          50: '#FEF0ED',
        },
        status: {
          running: '#10B981',
          idle: '#F59E0B',
          downProcess: '#F97316',
          downMaintenance: '#EF4444',
          underRepair: '#8B5CF6',
          offline: '#64748B',
        },
      },
      boxShadow: {
        brand: '0 10px 30px -10px rgba(12,69,149,.35)',
        accent: '0 10px 26px -8px rgba(240,78,55,.45)',
      },
      backgroundImage: {
        'brand-grid': 'linear-gradient(rgba(255,255,255,.06) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,.06) 1px, transparent 1px)',
      },
      keyframes: {
        'flow': { '0%': { backgroundPosition: '0% 50%' }, '100%': { backgroundPosition: '200% 50%' } },
        'spark': { '0%,100%': { opacity: 0, transform: 'translateX(-6px)' }, '50%': { opacity: 1, transform: 'translateX(6px)' } },
      },
      animation: {
        flow: 'flow 6s linear infinite',
        spark: 'spark 2.2s ease-in-out infinite',
      },
    },
  },
  plugins: [],
}
