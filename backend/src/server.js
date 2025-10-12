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

const app = express();
const server = createServer(app);

// Configuration Socket.io
const io = new Server(server, {
  cors: {
    origin: process.env.SOCKET_CORS_ORIGIN || "http://localhost:3000",
    methods: ["GET", "POST"]
  }
});

// Middleware de sécurité
app.use(helmet());
app.use(compression());
app.use(morgan('combined'));

// Configuration CORS
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://dudu.sn', 'https://admin.dudu.sn'] 
    : ['http://localhost:3000', 'http://localhost:3001'],
  credentials: true
}));

// Limitation du taux de requêtes
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    error: 'Trop de requêtes depuis cette IP, veuillez réessayer plus tard.'
  }
});
app.use('/api/', limiter);

// Middleware pour parser le JSON
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Connexion à MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/dudu', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
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
app.use('/api/v1/subscriptions', require('./routes/subscriptions'));
app.use('/api/v1/admin', require('./routes/admin'));
app.use('/api/v1/carpool', require('./routes/carpool'));

// Route de santé
app.get('/api/health', (req, res) => {
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

// Configuration Socket.io
require('./socket/socketHandler')(io);

const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log(`🚀 Serveur DUDU démarré sur le port ${PORT}`);
  console.log(`📱 Environnement: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🗺️  API Version: ${process.env.API_VERSION || 'v1'}`);
});

module.exports = { app, io };

