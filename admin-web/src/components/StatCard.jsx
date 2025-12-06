import React from 'react';
import { motion } from 'framer-motion';
import { TrendingUp, TrendingDown } from 'lucide-react';

function StatCard({ 
  title, 
  value, 
  icon: Icon, 
  trend, 
  trendValue, 
  color = 'green',
  delay = 0 
}) {
  const colorClasses = {
    green: 'green',
    blue: 'blue',
    purple: 'purple',
    orange: 'orange',
    cyan: 'cyan'
  };

  const formatValue = (val) => {
    if (typeof val === 'number') {
      if (val >= 1000000) {
        return (val / 1000000).toFixed(1) + 'M';
      }
      if (val >= 1000) {
        return (val / 1000).toFixed(1) + 'K';
      }
      return val.toLocaleString('fr-FR');
    }
    return val;
  };

  return (
    <motion.div 
      className="stat-card"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay }}
      whileHover={{ y: -4 }}
    >
      <div className="stat-card-header">
        <motion.div 
          className={`stat-icon-wrapper ${colorClasses[color]}`}
          whileHover={{ scale: 1.1, rotate: -5 }}
          transition={{ type: "spring", stiffness: 400 }}
        >
          <Icon />
        </motion.div>
        
        {trend && (
          <div className={`stat-trend ${trend === 'up' ? 'positive' : 'negative'}`}>
            {trend === 'up' ? <TrendingUp /> : <TrendingDown />}
            <span>{trendValue}</span>
          </div>
        )}
      </div>
      
      <motion.div 
        className="stat-value"
        initial={{ opacity: 0, scale: 0.5 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.5, delay: delay + 0.2 }}
      >
        {formatValue(value)}
      </motion.div>
      
      <div className="stat-label">{title}</div>
    </motion.div>
  );
}

export default StatCard;
