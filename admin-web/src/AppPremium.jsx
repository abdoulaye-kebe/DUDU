import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import Navbar from './components/Navbar';
import Login from './pages/Login';
import DashboardPremium from './pages/DashboardPremium';
import DriversPremium from './pages/DriversPremium';
import ClientsPremium from './pages/ClientsPremium';
import RidesPremium from './pages/RidesPremium';
import PaymentsPremium from './pages/PaymentsPremium';
import PromotionsPremium from './pages/PromotionsPremium';
import './styles/admin-premium.css';

function AppPremium() {
  const [currentPage, setCurrentPage] = useState('dashboard');
  const [navbarSearch, setNavbarSearch] = useState('');
  const [isAuthenticated, setIsAuthenticated] = useState(() => {
    return Boolean(localStorage.getItem('admin_token'));
  });

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminUser');
    setIsAuthenticated(false);
    setCurrentPage('dashboard');
  };

  const renderPage = () => {
    switch (currentPage) {
      case 'dashboard':
        return <DashboardPremium />;
      case 'drivers':
        return <DriversPremium navbarSearch={navbarSearch} />;
      case 'clients':
        return <ClientsPremium navbarSearch={navbarSearch} />;
      case 'rides':
        return <RidesPremium navbarSearch={navbarSearch} />;
      case 'payments':
        return <PaymentsPremium navbarSearch={navbarSearch} />;
      case 'promotions':
        return <PromotionsPremium />;
      default:
        return <DashboardPremium />;
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
