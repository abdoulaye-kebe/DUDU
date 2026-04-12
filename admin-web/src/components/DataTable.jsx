import React from 'react';
import { motion } from 'framer-motion';
import { 
  Search, 
  Filter, 
  Download, 
  MoreVertical,
  ChevronLeft,
  ChevronRight,
  Eye,
  Edit,
  Trash2
} from 'lucide-react';

function DataTable({ 
  title, 
  icon: TitleIcon,
  columns, 
  data, 
  actions = true,
  searchable = true,
  filterable = true,
  /** (row) => string — recherche sur prénom, téléphone, véhicule, etc. */
  searchText,
  onExport,
  onView,
  onEdit,
  onDelete,
  editLabel = "Modifier",
  editIcon: EditIcon = Edit,
  emptyMessage = "Aucune donnée disponible"
}) {
  const [searchTerm, setSearchTerm] = React.useState('');

  const filteredData = data.filter(row => {
    if (!searchTerm) return true;
    const q = searchTerm.toLowerCase();
    if (typeof searchText === 'function') {
      return (searchText(row) || '').toLowerCase().includes(q);
    }
    return columns.some(col => {
      const value = row[col.key];
      if (typeof value === 'string') {
        return value.toLowerCase().includes(q);
      }
      return false;
    });
  });

  return (
    <motion.div 
      className="table-container"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
    >
      {/* Header */}
      <div className="table-header">
        <div className="table-title">
          {TitleIcon && <TitleIcon />}
          {title}
        </div>
        <div className="table-actions">
          {searchable && (
            <div className="search-box">
              <Search />
              <input 
                type="text" 
                placeholder="Rechercher..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          )}
          {filterable && (
            <motion.button 
              type="button"
              className="btn btn-secondary btn-sm"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <Filter size={16} />
              Filtrer
            </motion.button>
          )}
          {onExport && (
            <motion.button 
              type="button"
              className="btn btn-secondary btn-sm"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={onExport}
            >
              <Download size={16} />
              Exporter
            </motion.button>
          )}
        </div>
      </div>

      {/* Table */}
      <table className="table">
        <thead>
          <tr>
            {columns.map((col) => (
              <th key={col.key}>{col.label}</th>
            ))}
            {actions && <th style={{ width: '120px' }}>Actions</th>}
          </tr>
        </thead>
        <tbody>
          {filteredData.length === 0 ? (
            <tr>
              <td colSpan={columns.length + (actions ? 1 : 0)}>
                <div className="empty-state">
                  <div className="empty-state-icon">
                    <Search />
                  </div>
                  <div className="empty-state-title">{emptyMessage}</div>
                </div>
              </td>
            </tr>
          ) : (
            filteredData.map((row, index) => (
              <motion.tr 
                key={row._id || row.id || index}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.3, delay: index * 0.05 }}
              >
                {columns.map((col) => (
                  <td key={col.key}>
                    {col.render ? col.render(row[col.key], row) : row[col.key]}
                  </td>
                ))}
                {actions && (
                  <td>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      {onView && (
                        <motion.button 
                          className="btn btn-ghost btn-icon btn-sm"
                          onClick={() => onView(row)}
                          whileHover={{ scale: 1.1 }}
                          whileTap={{ scale: 0.9 }}
                          title="Voir détails"
                        >
                          <Eye size={16} />
                        </motion.button>
                      )}
                      {onEdit && (
                        <motion.button 
                          className="btn btn-ghost btn-icon btn-sm"
                          onClick={() => onEdit(row)}
                          whileHover={{ scale: 1.1 }}
                          whileTap={{ scale: 0.9 }}
                          title={editLabel}
                        >
                          <EditIcon size={16} />
                        </motion.button>
                      )}
                      {onDelete && (
                        <motion.button 
                          className="btn btn-ghost btn-icon btn-sm"
                          onClick={() => onDelete(row)}
                          whileHover={{ scale: 1.1 }}
                          whileTap={{ scale: 0.9 }}
                          title="Supprimer"
                          style={{ color: 'var(--accent-red)' }}
                        >
                          <Trash2 size={16} />
                        </motion.button>
                      )}
                    </div>
                  </td>
                )}
              </motion.tr>
            ))
          )}
        </tbody>
      </table>

      {/* Pagination */}
      {filteredData.length > 0 && (
        <div className="card-footer" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span style={{ fontSize: '14px', color: 'var(--gray-500)' }}>
            Affichage de {filteredData.length} résultat{filteredData.length > 1 ? 's' : ''}
          </span>
          <div style={{ display: 'flex', gap: '8px' }}>
            <motion.button 
              className="btn btn-ghost btn-sm"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              <ChevronLeft size={16} />
              Précédent
            </motion.button>
            <motion.button 
              className="btn btn-ghost btn-sm"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              Suivant
              <ChevronRight size={16} />
            </motion.button>
          </div>
        </div>
      )}
    </motion.div>
  );
}

export default DataTable;
