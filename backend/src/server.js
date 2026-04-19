const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { createServer } = require('http');
const { Server } = require('socket.io');
require('dotenv').config();
const path = require('path');

const app = express();

// Faire confiance au proxy (X-Forwarded-For) pour les IP clientes
// nécessaire quand l’app est derrière un reverse proxy (Nginx, etc.)
app.set('trust proxy', 1);

const server = createServer(app);

// Configuration Socket.io
const io = new Server(server, {
  cors: {
    origin: process.env.NODE_ENV === 'production'
      ? [
          'https://dudu.sn',
          'https://admin.dudu.sn',
          'https://dudugroup.sn',
          'http://dudugroup.sn',
          'https://www.dudugroup.sn',
          'http://www.dudugroup.sn',
          'https://admin.dudugroup.sn',
          'http://admin.dudugroup.sn',
          'https://www.admin.dudugroup.sn',
          'http://www.admin.dudugroup.sn',
        ]
      : true,
    methods: ["GET", "POST"],
    credentials: true
  }
});

// Middleware de sécurité
// Par défaut Helmet envoie Cross-Origin-Resource-Policy: same-origin, ce qui bloque
// les réponses XHR/fetch depuis un autre sous-domaine (ex. admin.dudugroup.sn → www.dudugroup.sn).
// CORS contrôle déjà les origines autorisées.
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));
app.use(compression());
app.use(morgan('combined'));

// Configuration CORS - Autoriser toutes les origines en développement
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? [
        'https://dudu.sn',
        'https://admin.dudu.sn',
        'https://dudugroup.sn',
        'http://dudugroup.sn',
        'https://www.dudugroup.sn',
        'http://www.dudugroup.sn',
        'https://admin.dudugroup.sn',
        'http://admin.dudugroup.sn',
        'https://www.admin.dudugroup.sn',
        'http://www.admin.dudugroup.sn',
      ] 
    : true, // Autoriser toutes les origines en dev
  credentials: true
}));

// Limitation du taux de requêtes (ne pas limiter le webhook Wave : IPs Wave + retries du portail)
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    error: 'Trop de requêtes depuis cette IP, veuillez réessayer plus tard.'
  },
  skip: (req) => {
    const u = req.originalUrl || req.url || '';
    return req.method === 'POST' && u.includes('/mobile-payments/wave/webhook');
  },
});
app.use('/api/', limiter);

// Webhook Wave : le corps doit rester brut pour HMAC (Wave-Signature = t=…,v1=…)
const mobilePaymentsRouter = require('./routes/mobile-payments');
app.post(
  '/api/v1/mobile-payments/wave/webhook',
  express.raw({
    // Wave envoie souvent `application/json; charset=utf-8` — matcher large pour ne pas perdre le corps brut.
    type: (req) => {
      const ct = req.headers['content-type'] || '';
      return /application\/json/i.test(ct);
    },
    limit: '1mb',
  }),
  mobilePaymentsRouter.handleWaveWebhook
);
// Health checks Wave/portail : ping en GET/HEAD (pas de signature)
app.get('/api/v1/mobile-payments/wave/webhook', (req, res) => {
  res.status(200).json({ success: true, message: 'Wave webhook endpoint OK' });
});
app.head('/api/v1/mobile-payments/wave/webhook', (req, res) => {
  res.sendStatus(200);
});

// Page publique « partage trajet » (lien dans l’app client) — avant express.static
app.get('/track/:rideKey', (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'public', 'track.html'));
});

// Retours Wave Checkout (success_url / error_url) — évite une erreur S3 « NoSuchKey »
// si le domaine public pointe vers un bucket sans ces chemins. Ces routes doivent être
// servies par ce serveur Node (ou reproduire les mêmes fichiers sur S3 / CloudFront).
const paymentSuccess = path.join(__dirname, '..', 'public', 'payment', 'success.html');
const paymentError = path.join(__dirname, '..', 'public', 'payment', 'error.html');
app.get(['/payment/success', '/payment/success.html'], (req, res) => {
  res.sendFile(paymentSuccess);
});
app.get(['/payment/error', '/payment/error.html'], (req, res) => {
  res.sendFile(paymentError);
});

// Middleware pour parser le JSON
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Servir les fichiers statiques (pages de téléchargement APK)
app.use(express.static('public'));

// Connexion à MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/dudu')
.then(() => {
  console.log('✅ Connexion à MongoDB réussie');
})
.catch((error) => {
  console.error('❌ Erreur de connexion à MongoDB:', error);
  process.exit(1);
});

// Routes principales
app.use('/api/v1/auth', require('./routes/auth'));
app.use('/api/v1/users', require('./routes/users'));
app.use('/api/v1/drivers', require('./routes/drivers'));
app.use('/api/v1/rides', require('./routes/rides'));
app.use('/api/v1/payments', require('./routes/payments'));
app.use('/api/v1/mobile-payments', mobilePaymentsRouter);
app.use('/api/v1/subscriptions', require('./routes/subscriptions'));
app.use('/api/v1/admin', require('./routes/admin'));
app.use('/api/v1/notifications', require('./routes/notifications'));
app.use('/api/v1/disputes', require('./routes/disputes'));
// Route de santé
app.get('/api/v1/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'DUDU API est opérationnelle',
    timestamp: new Date().toISOString(),
    version: process.env.API_VERSION || 'v1'
  });
});

// Gestion des erreurs 404
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Route non trouvée',
    message: 'La route demandée n\'existe pas'
  });
});

// Middleware de gestion d'erreurs global
app.use((error, req, res, next) => {
  console.error('Erreur:', error);
  
  res.status(error.status || 500).json({
    error: error.message || 'Erreur interne du serveur',
    ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
  });
});

// Rendre io accessible dans les routes
app.set('io', io);
const { setIO } = require('./socket/socketIO');
setIO(io);

// Configuration Socket.io
require('./socket/socketHandler')(io);

// Scheduler pour les courses planifiées
try {
  const startScheduledRidesDispatcher = require('./jobs/scheduledRidesDispatcher');
  startScheduledRidesDispatcher(io);
  console.log('⏰ Scheduler des courses planifiées initialisé');
} catch (err) {
  console.error('❌ Impossible d\'initialiser le scheduler des courses planifiées:', err);
}

// Service de rappel automatique (1h avant la course)
try {
  const startScheduledRidesReminder = require('./jobs/scheduledRidesReminder');
  startScheduledRidesReminder(io);
  console.log('🔔 Service de rappel automatique initialisé');
} catch (err) {
  console.error('❌ Impossible d\'initialiser le service de rappel:', err);
}

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0'; // Écouter sur toutes les interfaces

server.listen(PORT, HOST, () => {
  console.log(`🚀 Serveur DUDU démarré sur le port ${PORT}`);
  console.log(`🌐 Accessible sur: http://${HOST}:${PORT}`);
  console.log(`📱 Environnement: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🗺️  API Version: ${process.env.API_VERSION || 'v1'}`);
  console.log(`🔌 WebSocket activé pour synchro temps réel`);
});

module.exports = { app, io };

