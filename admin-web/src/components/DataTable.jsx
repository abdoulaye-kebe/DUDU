import React from 'react';
import { motion } from 'framer-motion';
import { 
  Search, 
  Download, 
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
  /** Panneau optionnel sous la barre d’outils (filtres métier), toujours visible si renseigné */
  filterSlot = null,
  /** (row) => string — recherche sur prénom, téléphone, véhicule, etc. */
  searchText,
  /** Recherche globale (ex. barre Navbar) — cumulée avec la recherche locale */
  navbarSearch = '',
  onExport,
  /** Nombre de lignes par page (0 = tout afficher) */
  pageSize = 10,
  onView,
  onEdit,
  onDelete,
  editLabel = "Modifier",
  editIcon: EditIcon = Edit,
  emptyMessage = "Aucune donnée disponible"
}) {
  const [searchTerm, setSearchTerm] = React.useState('');
  const [page, setPage] = React.useState(1);
  React.useEffect(() => {
    setPage(1);
  }, [data, searchTerm, navbarSearch]);

  const rowMatchesNav = (row) => {
    const q = (navbarSearch || '').trim().toLowerCase();
    if (!q) return true;
    const hay = typeof searchText === 'function'
      ? (searchText(row) || '')
      : columns.map((c) => {
          const v = row[c.key];
          return v != null && typeof v !== 'object' ? String(v) : '';
        }).join(' ');
    return hay.toLowerCase().includes(q);
  };

  const filteredData = data.filter(row => {
    if (!rowMatchesNav(row)) return false;
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

  const usePagination = pageSize > 0 && filteredData.length > pageSize;
  const totalPages = usePagination ? Math.max(1, Math.ceil(filteredData.length / pageSize)) : 1;
  const safePage = Math.min(page, totalPages);
  const paginatedData = usePagination
    ? filteredData.slice((safePage - 1) * pageSize, safePage * pageSize)
    : filteredData;

  const showFrom = filteredData.length === 0 ? 0 : (safePage - 1) * (usePagination ? pageSize : filteredData.length) + 1;
  const showTo = usePagination
    ? Math.min(safePage * pageSize, filteredData.length)
    : filteredData.length;

  return (
    <motion.div 
      className="table-container"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
    >
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

      {filterSlot && (
        <div style={{ padding: '0 0 16px', marginBottom: 8 }}>
          {filterSlot}
        </div>
      )}

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
          {paginatedData.length === 0 ? (
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
            paginatedData.map((row, index) => (
              <motion.tr 
                key={row._id || row.id || index}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.3, delay: index * 0.03 }}
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
                          type="button"
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
                          type="button"
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
                          type="button"
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

      {filteredData.length > 0 && (
        <div className="card-footer" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 8 }}>
          <span style={{ fontSize: '14px', color: 'var(--gray-500)' }}>
            {usePagination
              ? `Affichage ${showFrom}–${showTo} sur ${filteredData.length} résultat${filteredData.length > 1 ? 's' : ''}`
              : `Affichage de ${filteredData.length} résultat${filteredData.length > 1 ? 's' : ''}`}
          </span>
          {usePagination && (
            <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
              <motion.button 
                type="button"
                className="btn btn-ghost btn-sm"
                disabled={safePage <= 1}
                whileHover={{ scale: safePage <= 1 ? 1 : 1.05 }}
                whileTap={{ scale: safePage <= 1 ? 1 : 0.95 }}
                onClick={() => setPage((p) => Math.max(1, p - 1))}
              >
                <ChevronLeft size={16} />
                Précédent
              </motion.button>
              <span style={{ fontSize: 13, color: 'var(--gray-600)' }}>
                Page {safePage} / {totalPages}
              </span>
              <motion.button 
                type="button"
                className="btn btn-ghost btn-sm"
                disabled={safePage >= totalPages}
                whileHover={{ scale: safePage >= totalPages ? 1 : 1.05 }}
                whileTap={{ scale: safePage >= totalPages ? 1 : 0.95 }}
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              >
                Suivant
                <ChevronRight size={16} />
              </motion.button>
            </div>
          )}
        </div>
      )}
    </motion.div>
  );
}

export default DataTable;
