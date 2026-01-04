import React from 'react';
import { motion } from 'framer-motion';
import { 
  Car, 
  LayoutDashboard, 
  Users, 
  UserCheck, 
  MapPin, 
  Search,
  Bell,
  Settings,
  ChevronDown,
  LogOut
} from 'lucide-react';

const navItems = [
  { id: 'dashboard', label: 'Tableau de bord', icon: LayoutDashboard },
  { id: 'drivers', label: 'Chauffeurs', icon: UserCheck },
  { id: 'clients', label: 'Clients', icon: Users },
  { id: 'rides', label: 'Courses', icon: MapPin },
  { id: 'promotions', label: 'Promotions', icon: Bell },
];

function Navbar({ currentPage, onNavigate, onLogout }) {
  return (
    <nav className="navbar">
      <div className="navbar-container">
        {/* Logo */}
        <motion.a 
          href="#" 
          className="navbar-brand"
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
        >
          <div className="brand-logo">
            <Car />
          </div>
          <div className="brand-text">
            <span className="brand-name">DUDU</span>
            <span className="brand-subtitle">Administration</span>
          </div>
        </motion.a>

        {/* Navigation Links */}
        <div className="navbar-nav">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = currentPage === item.id;
            
            return (
              <motion.button
                key={item.id}
                className={`nav-link ${isActive ? 'active' : ''}`}
                onClick={() => onNavigate(item.id)}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                initial={false}
                animate={{
                  backgroundColor: isActive ? undefined : 'transparent'
                }}
              >
                <Icon />
                <span>{item.label}</span>
              </motion.button>
            );
          })}
        </div>

        {/* Actions */}
        <div className="navbar-actions">
          {/* Search */}
          <div className="navbar-search">
            <Search className="search-icon" />
            <input 
              type="text" 
              className="search-input" 
              placeholder="Rechercher..." 
            />
          </div>

          {/* Notifications */}
          <motion.button 
            className="icon-btn"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            <Bell />
            <span className="badge">3</span>
          </motion.button>

          {/* Settings */}
          <motion.button 
            className="icon-btn"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            <Settings />
          </motion.button>

          {/* Logout */}
          <motion.button
            className="icon-btn"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => {
              if (typeof onLogout === 'function') onLogout();
            }}
            title="Déconnexion"
          >
            <LogOut />
          </motion.button>

          {/* User Menu */}
          <motion.button 
            className="user-menu"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            <div className="user-avatar">AD</div>
            <div className="user-info">
              <span className="user-name">Admin DUDU</span>
              <span className="user-role">Super Admin</span>
            </div>
            <ChevronDown size={16} style={{ color: '#9ca3af' }} />
          </motion.button>
        </div>
      </div>
    </nav>
  );
}

export default Navbar;
