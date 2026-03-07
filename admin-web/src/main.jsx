import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import AppPremium from './AppPremium.jsx'

// Afficher toute erreur à l'écran (au lieu d'une page blanche)
function showError(title, err) {
  const root = document.getElementById('root')
  if (!root) return
  const message = err?.message || String(err)
  const stack = err?.stack || ''
  root.innerHTML = `
    <div style="font-family: system-ui, sans-serif; padding: 24px; max-width: 600px; margin: 0 auto;">
      <h2 style="color: #c00;">${title}</h2>
      <pre style="background: #f5f5f5; padding: 16px; overflow: auto; font-size: 13px;">${message}</pre>
      ${stack ? `<details><summary>Stack</summary><pre style="font-size: 11px; overflow: auto;">${stack}</pre></details>` : ''}
    </div>
  `
}

window.addEventListener('error', (e) => {
  showError('Erreur chargement admin', e.error || e)
})
window.addEventListener('unhandledrejection', (e) => {
  showError('Erreur (promise)', e.reason)
})

class ErrorBoundary extends React.Component {
  state = { error: null }
  static getDerivedStateFromError(error) {
    return { error }
  }
  componentDidCatch(error, info) {
    console.error('ErrorBoundary', error, info)
  }
  render() {
    if (this.state.error) {
      return (
        <div style={{ fontFamily: 'system-ui, sans-serif', padding: 24 }}>
          <h2 style={{ color: '#c00' }}>Erreur dans l'application</h2>
          <pre style={{ background: '#f5f5f5', padding: 16, overflow: 'auto' }}>
            {this.state.error.message}
          </pre>
        </div>
      )
    }
    return this.props.children
  }
}

try {
  const root = ReactDOM.createRoot(document.getElementById('root'))
  root.render(
    <React.StrictMode>
      <ErrorBoundary>
        <BrowserRouter>
          <AppPremium />
        </BrowserRouter>
      </ErrorBoundary>
    </React.StrictMode>,
  )
} catch (err) {
  showError('Erreur au démarrage', err)
}
