import { BrowserRouter, Routes, Route, NavLink, Navigate } from 'react-router-dom'
import DashboardNew from './pages/DashboardNew'
import DriversNew from './pages/DriversNew'
import Clients from './pages/Clients'
import Rides from './pages/Rides'
import './App.css'

function App() {
  return (
    <BrowserRouter>
      <div className="app">
        {/* Sidebar */}
        <aside className="sidebar">
          <div className="sidebar-header">
            <h1>DUDU</h1>
            <p>Admin Dashboard</p>
          </div>
          
          <nav className="sidebar-nav">
            <NavLink 
              to="/"
              className={({ isActive }) => isActive ? 'active' : ''}
            >
              📊 Tableau de bord
            </NavLink>
            <NavLink 
              to="/chauffeurs"
              className={({ isActive }) => isActive ? 'active' : ''}
            >
              🚕 Chauffeurs
            </NavLink>
            <NavLink 
              to="/clients"
              className={({ isActive }) => isActive ? 'active' : ''}
            >
              👥 Clients
            </NavLink>
            <NavLink 
              to="/courses"
              className={({ isActive }) => isActive ? 'active' : ''}
            >
              🗺️ Courses
            </NavLink>
          </nav>
          
          <div className="sidebar-footer">
            <p>v1.0.0</p>
            <button className="logout-btn">Déconnexion</button>
          </div>
        </aside>

        {/* Main Content */}
        <main className="main-content">
          <Routes>
            <Route path="/" element={<DashboardNew />} />
            <Route path="/chauffeurs" element={<DriversNew />} />
            <Route path="/clients" element={<Clients />} />
            <Route path="/courses" element={<Rides />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  )
}

export default App

