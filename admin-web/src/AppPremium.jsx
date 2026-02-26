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
  const [isAuthenticated, setIsAuthenticated] = useState(() => {
    return Boolean(localStorage.getItem('admin_token'));
  });

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    setIsAuthenticated(false);
    setCurrentPage('drivers');
  };

  const renderPage = () => {
    switch (currentPage) {
      case 'drivers':
        return <DriversPremium />;
      case 'clients':
        return <ClientsPremium />;
      case 'rides':
        return <RidesPremium />;
      case 'promotions':
        return <PromotionsPremium />;
      default:
        return <DriversPremium />;
    }
  };

  return (
    <div className="admin-app">
      {isAuthenticated ? (
        <>
          <Navbar currentPage={currentPage} onNavigate={setCurrentPage} onLogout={handleLogout} />
          
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
