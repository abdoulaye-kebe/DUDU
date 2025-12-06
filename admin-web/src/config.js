// Configuration centralisée de l'admin DUDU
// Modifier ces valeurs selon l'environnement

// URL du backend API
// - Développement local: http://localhost:3000
// - Production AWS: http://213.154.90.11
export const API_BASE_URL = 'http://localhost:3000/api/v1';

// URL du serveur Socket.io (même que le backend)
export const SOCKET_URL = 'http://localhost:3000';

// Pour passer en production, changer les URLs ci-dessus en:
// export const API_BASE_URL = 'http://213.154.90.11/api/v1';
// export const SOCKET_URL = 'http://213.154.90.11';
