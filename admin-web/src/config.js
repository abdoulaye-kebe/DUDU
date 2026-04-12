// Configuration centralisée de l'admin DUDU
// Détection automatique de l'environnement

// Détection automatique: localhost = développement, sinon = production
const isDevelopment = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';

// URL du backend API
const PROD_API_URL = 'https://www.dudugroup.sn/api/v1';
const DEV_API_URL = 'http://localhost:3000/api/v1';

/** Ignore VITE_* en http:// sur pages https (contenu mixte → « Erreur de connexion »). */
function resolveApiBaseUrl() {
  const v = import.meta.env.VITE_API_BASE_URL;
  if (!v || typeof v !== 'string') return null;
  const t = v.trim();
  if (t.startsWith('https://')) return t;
  if (t.startsWith('http://') && (t.includes('localhost') || t.includes('127.0.0.1'))) return t;
  return null;
}

export const API_BASE_URL =
    resolveApiBaseUrl() || (isDevelopment ? DEV_API_URL : PROD_API_URL);

// URL du serveur Socket.io (même que le backend)
const PROD_SOCKET_URL = 'https://www.dudugroup.sn';
const DEV_SOCKET_URL = 'http://localhost:3000';

export const SOCKET_URL = import.meta.env.VITE_SOCKET_URL || (isDevelopment ? DEV_SOCKET_URL : PROD_SOCKET_URL);

// Afficher la configuration dans la console
console.log('🌐 Admin DUDU Configuration:');
console.log('   Environment:', isDevelopment ? 'DEVELOPMENT' : 'PRODUCTION');
console.log('   API URL:', API_BASE_URL);
console.log('   Socket URL:', SOCKET_URL);
