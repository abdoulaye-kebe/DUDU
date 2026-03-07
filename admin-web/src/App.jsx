import { BrowserRouter, Routes, Route, NavLink, Navigate, useNavigate, useLocation } from 'react-router-dom'
import { useEffect, useState } from 'react'
import DashboardNew from './pages/DashboardNew'
import DriversNew from './pages/DriversNew'
import Clients from './pages/Clients'
import Rides from './pages/Rides'
import Login from './pages/Login'
import './App.css'

function ProtectedLayout() {
  const navigate = useNavigate();
  const location = useLocation();
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(false);

  useEffect(() => {
    const token = localStorage.getItem('adminToken');
    if (!token) {
      navigate('/login');
    } else {
      setIsAuthenticated(true);
    }
  }, [navigate]);

  useEffect(() => {
    setSidebarOpen(false);
  }, [location.pathname]);

  const handleLogout = () => {
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminUser');
    navigate('/login');
  };

  if (!isAuthenticated) {
    return null;
  }

  return (
    <div className="app">
      {/* Bouton hamburger mobile */}
      <button
        type="button"
        className="sidebar-toggle"
        onClick={() => setSidebarOpen(!sidebarOpen)}
        aria-label="Menu"
      >
        <span></span>
        <span></span>
        <span></span>
      </button>
      {/* Overlay quand sidebar ouverte sur mobile */}
      <div
        className={`sidebar-overlay ${sidebarOpen ? 'active' : ''}`}
        onClick={() => setSidebarOpen(false)}
        aria-hidden="true"
      />
      {/* Sidebar */}
      <aside className={`sidebar ${sidebarOpen ? 'open' : ''}`}>
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
          <button className="logout-btn" onClick={handleLogout}>Déconnexion</button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="main-content" onClick={() => setSidebarOpen(false)}>
        <Routes>
          <Route path="/" element={<DashboardNew />} />
          <Route path="/chauffeurs" element={<DriversNew />} />
          <Route path="/clients" element={<Clients />} />
          <Route path="/courses" element={<Rides />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
    </div>
  );
}

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/*" element={<ProtectedLayout />} />
      </Routes>
    </BrowserRouter>
  )
}

export default App

