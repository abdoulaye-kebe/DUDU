/**
 * Configuration des services de paiement mobile
 * Orange Money et Wave API
 */

module.exports = {
  // Configuration Orange Money
  orangeMoney: {
    // Mode: 'sandbox' pour les tests, 'production' pour la prod
    mode: process.env.ORANGE_MONEY_MODE || 'sandbox',
    
    // Sandbox (Test) — OAuth: client_id / client_secret (portail développeur) ; Mercode = code marchand QR
    sandbox: {
      apiUrl: process.env.ORANGE_SONATEL_API_BASE || 'https://api.sandbox.orange-sonatel.com',
      oauthUrl: process.env.ORANGE_SONATEL_OAUTH_URL || 'https://api.sandbox.orange-sonatel.com/oauth/v1/token',
      merchantKey: process.env.ORANGE_SONATEL_CLIENT_ID || process.env.ORANGE_MONEY_SANDBOX_MERCHANT_KEY || '',
      merchantSecret: process.env.ORANGE_SONATEL_CLIENT_SECRET || process.env.ORANGE_MONEY_SANDBOX_MERCHANT_SECRET || '',
      merchantCode: process.env.ORANGE_SONATEL_MERCODE || process.env.ORANGE_MONEY_SANDBOX_MERCHANT_CODE || '599242',
      callbackUrl: process.env.ORANGE_MONEY_SANDBOX_CALLBACK_URL || 'http://localhost:3000/api/v1/mobile-payments/orange-money/callback',
    },
    
    production: {
      apiUrl: process.env.ORANGE_SONATEL_API_BASE || 'https://api.orange-sonatel.com',
      oauthUrl: process.env.ORANGE_SONATEL_OAUTH_URL || 'https://api.orange-sonatel.com/oauth/v1/token',
      merchantKey: process.env.ORANGE_SONATEL_CLIENT_ID || process.env.ORANGE_MONEY_MERCHANT_KEY || '',
      merchantSecret: process.env.ORANGE_SONATEL_CLIENT_SECRET || process.env.ORANGE_MONEY_MERCHANT_SECRET || '',
      merchantCode: process.env.ORANGE_SONATEL_MERCODE || process.env.ORANGE_MONEY_MERCHANT_CODE || '',
      merchantPhone: process.env.ORANGE_SONATEL_MSISDN || process.env.ORANGE_MONEY_MERCHANT_PHONE || '',
      callbackUrl: process.env.ORANGE_MONEY_CALLBACK_URL || 'https://www.dudugroup.sn/api/v1/mobile-payments/orange-money/callback',
    },
    
    // Paramètres communs
    currency: 'XOF',
    country: 'SN', // Sénégal
    language: 'fr',
    timeout: 30000, // 30 secondes
  },

  // Configuration Wave
  wave: {
    // Mode: 'sandbox' pour les tests, 'production' pour la prod
    mode: process.env.WAVE_MODE || 'production',
    
    // Sandbox (Test)
    sandbox: {
      apiUrl: 'https://api.wave.com/v1',
      apiKey: process.env.WAVE_SANDBOX_API_KEY || '',
      webhookSecret:
        process.env.WAVE_SANDBOX_WEBHOOK_SECRET || process.env.WAVE_WEBHOOK_SECRET || '',
      callbackUrl: process.env.WAVE_SANDBOX_CALLBACK_URL || 'http://localhost:3000/api/v1/mobile-payments/wave/webhook',
      businessPhone: process.env.WAVE_SANDBOX_BUSINESS_PHONE || '',
    },
    
    // Production
    production: {
      apiUrl: 'https://api.wave.com/v1',
      // Ne jamais committer de clés : uniquement variables d’environnement (portail Wave).
      apiKey: process.env.WAVE_API_KEY || '',
      webhookSecret: process.env.WAVE_WEBHOOK_SECRET || '',
      callbackUrl: process.env.WAVE_CALLBACK_URL || 'https://www.dudugroup.sn/api/v1/mobile-payments/wave/webhook',
      businessPhone: process.env.WAVE_BUSINESS_PHONE || '+221771491330',
    },
    
    // Paramètres communs
    currency: 'XOF',
    country: 'SN',
    timeout: 30000,
  },

  // Configuration générale
  general: {
    // Montants minimum et maximum
    minAmount: 100, // 100 FCFA
    maxAmount: 1000000, // 1 000 000 FCFA
    
    // Frais de transaction
    fees: {
      orangeMoney: 0.01, // 1%
      wave: 0.015, // 1.5%
    },
    
    // Délai d'expiration des transactions (en secondes)
    transactionTimeout: 300, // 5 minutes
    
    // Nombre de tentatives de vérification
    maxVerificationAttempts: 10,
    verificationInterval: 3000, // 3 secondes
  }
};
