// Tailwind CSS Configuration for OhMyDialogSystem Wiki
// This file is used by the Play CDN inline script
// Colors derived from the AI/Neural Network theme

tailwind.config = {
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Background colors - deep space/neural
        'bg-primary': '#0a0d12',
        'bg-secondary': '#0f1419',
        'bg-tertiary': '#161d26',
        'bg-card': '#121921',

        // AI Accent colors - Neural Network theme
        'ai-cyan': '#00d4ff',
        'ai-cyan-dim': '#0099cc',
        'ai-purple': '#a855f7',
        'ai-purple-dim': '#7c3aed',
        'ai-green': '#10b981',
        'ai-green-dim': '#059669',
        'ai-pink': '#ec4899',
        'ai-orange': '#f97316',

        // Semantic mapping
        'accent-primary': '#00d4ff',
        'accent-secondary': '#a855f7',
        'success': '#10b981',
        'warning': '#f97316',
        'error': '#ef4444',

        // Borders
        'border-default': '#21262d',
      },
      fontFamily: {
        'body': ['Inter', 'Segoe UI', 'system-ui', '-apple-system', 'sans-serif'],
        'heading': ['Inter', 'Segoe UI', 'system-ui', 'sans-serif'],
        'mono': ['JetBrains Mono', 'Fira Code', 'Consolas', 'monospace'],
      },
      boxShadow: {
        'glow-cyan': '0 0 20px rgba(0, 212, 255, 0.4)',
        'glow-purple': '0 0 20px rgba(168, 85, 247, 0.4)',
        'glow-green': '0 0 20px rgba(16, 185, 129, 0.3)',
        'card': '0 4px 20px rgba(0, 0, 0, 0.3)',
        'card-hover': '0 8px 30px rgba(0, 0, 0, 0.4), 0 0 20px rgba(0, 212, 255, 0.2)',
      },
      animation: {
        'glow': 'glow 2s ease-in-out infinite',
        'float': 'float 3s ease-in-out infinite',
        'pulse-ai': 'pulse-ai 4s ease-in-out infinite',
      },
      keyframes: {
        glow: {
          '0%, 100%': { boxShadow: '0 0 5px #00d4ff' },
          '50%': { boxShadow: '0 0 20px #00d4ff, 0 0 30px #a855f7' },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-10px)' },
        },
        'pulse-ai': {
          '0%, 100%': { opacity: '0.3', transform: 'scale(1)' },
          '50%': { opacity: '0.6', transform: 'scale(1.1)' },
        },
      },
      spacing: {
        'sidebar': '280px',
      },
    },
  },
}
