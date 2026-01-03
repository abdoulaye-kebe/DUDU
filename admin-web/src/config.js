// Configuration centralisée de l'admin DUDU
// Détection automatique de l'environnement

// Détection automatique: localhost = développement, sinon = production
const isDevelopment = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';

// URL du backend API
// - Développement local: http://localhost:3000
// - Production AWS: http://213.154.90.11
const PROD_API_URL = 'http://213.154.90.11:3000/api/v1';
const DEV_API_URL = 'http://localhost:3000/api/v1';

export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || (isDevelopment ? DEV_API_URL : PROD_API_URL);

// URL du serveur Socket.io (même que le backend)
const PROD_SOCKET_URL = 'http://213.154.90.11:3000';
const DEV_SOCKET_URL = 'http://localhost:3000';

export const SOCKET_URL = import.meta.env.VITE_SOCKET_URL || (isDevelopment ? DEV_SOCKET_URL : PROD_SOCKET_URL);

// Afficher la configuration dans la console
console.log('🌐 Admin DUDU Configuration:');
console.log('   Environment:', isDevelopment ? 'DEVELOPMENT' : 'PRODUCTION');
console.log('   API URL:', API_BASE_URL);
console.log('   Socket URL:', SOCKET_URL);
