import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import Navbar from './components/Navbar';
import Login from './pages/Login';
import DashboardPremium from './pages/DashboardPremium';
import DriversPremium from './pages/DriversPremium';
import ClientsPremium from './pages/ClientsPremium';
import RidesPremium from './pages/RidesPremium';
import PromotionsPremium from './pages/PromotionsPremium';
import './styles/admin-premium.css';

function AppPremium() {
  const [currentPage, setCurrentPage] = useState('drivers');
  const [navbarSearch, setNavbarSearch] = useState('');
  const [isAuthenticated, setIsAuthenticated] = useState(() => {
    return Boolean(localStorage.getItem('admin_token'));
  });

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminUser');
    setIsAuthenticated(false);
    setCurrentPage('drivers');
  };

  const renderPage = () => {
    switch (currentPage) {
      case 'drivers':
        return <DriversPremium navbarSearch={navbarSearch} />;
      case 'clients':
        return <ClientsPremium navbarSearch={navbarSearch} />;
      case 'rides':
        return <RidesPremium navbarSearch={navbarSearch} />;
      case 'promotions':
        return <PromotionsPremium />;
      default:
        return <DriversPremium navbarSearch={navbarSearch} />;
    }
  };

  return (
    <div className="admin-app">
      {isAuthenticated ? (
        <>
          <Navbar
            currentPage={currentPage}
            onNavigate={setCurrentPage}
            onLogout={handleLogout}
            searchValue={navbarSearch}
            onSearchChange={setNavbarSearch}
          />
          
          <main className="main-content">
            <AnimatePresence mode="wait">
              <motion.div
                key={currentPage}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -20 }}
                transition={{ duration: 0.3 }}
              >
                {renderPage()}
              </motion.div>
            </AnimatePresence>
          </main>
        </>
      ) : (
        <Login onLoginSuccess={() => setIsAuthenticated(true)} />
      )}
    </div>
  );
}

export default AppPremium;
