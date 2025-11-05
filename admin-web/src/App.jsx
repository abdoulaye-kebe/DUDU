import { useState } from 'react'
import DashboardNew from './pages/DashboardNew'
import DriversNew from './pages/DriversNew'
import Clients from './pages/Clients'
import Rides from './pages/Rides'
import './App.css'

function App() {
  const [currentPage, setCurrentPage] = useState('dashboard')

  const renderPage = () => {
    switch (currentPage) {
      case 'dashboard':
        return <DashboardNew />
      case 'drivers':
        return <DriversNew />
      case 'clients':
        return <Clients />
      case 'rides':
        return <Rides />
      default:
        return <DashboardNew />
    }
  }

  return (
    <div className="app">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-header">
          <h1>🚗 DUDU</h1>
          <p>Admin Dashboard</p>
        </div>
        
        <nav className="sidebar-nav">
          <button 
            className={currentPage === 'dashboard' ? 'active' : ''}
            onClick={() => setCurrentPage('dashboard')}
          >
            📊 Tableau de bord
          </button>
          <button 
            className={currentPage === 'drivers' ? 'active' : ''}
            onClick={() => setCurrentPage('drivers')}
          >
            🚕 Chauffeurs
          </button>
          <button 
            className={currentPage === 'clients' ? 'active' : ''}
            onClick={() => setCurrentPage('clients')}
          >
            👥 Clients
          </button>
          <button 
            className={currentPage === 'rides' ? 'active' : ''}
            onClick={() => setCurrentPage('rides')}
          >
            🗺️ Courses
          </button>
        </nav>
        
        <div className="sidebar-footer">
          <p>v1.0.0</p>
          <button className="logout-btn">Déconnexion</button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="main-content">
        {renderPage()}
      </main>
    </div>
  )
}

export default App

