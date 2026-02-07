/**
 * Configuration des services de paiement mobile
 * Orange Money et Wave API
 */

module.exports = {
  // Configuration Orange Money
  orangeMoney: {
    // Mode: 'sandbox' pour les tests, 'production' pour la prod
    mode: process.env.ORANGE_MONEY_MODE || 'production',
    
    // Sandbox (Test)
    sandbox: {
      apiUrl: 'https://api.orange.com/orange-money-webpay/dev/v1',
      merchantKey: process.env.ORANGE_MONEY_SANDBOX_MERCHANT_KEY || '',
      merchantSecret: process.env.ORANGE_MONEY_SANDBOX_MERCHANT_SECRET || '',
      merchantId: process.env.ORANGE_MONEY_SANDBOX_MERCHANT_ID || '',
      returnUrl: process.env.ORANGE_MONEY_SANDBOX_RETURN_URL || 'http://localhost:3000/api/v1/payments/orange-money/callback',
      cancelUrl: process.env.ORANGE_MONEY_SANDBOX_CANCEL_URL || 'http://localhost:3000/api/v1/payments/orange-money/cancel',
      notifyUrl: process.env.ORANGE_MONEY_SANDBOX_NOTIFY_URL || 'http://localhost:3000/api/v1/payments/orange-money/notify',
    },
    
    // Production
    production: {
      apiUrl: 'https://api.orange.com/orange-money-webpay/v1',
      merchantKey: process.env.ORANGE_MONEY_MERCHANT_KEY || 'c98da064-dd7e-4aae-9a80-6bbe4360b8e3',
      merchantSecret: process.env.ORANGE_MONEY_MERCHANT_SECRET || 'de8266ac-2a46-42a1-ae26-aa162b5ceafd',
      merchantId: process.env.ORANGE_MONEY_MERCHANT_ID || 'DuDu',
      returnUrl: process.env.ORANGE_MONEY_RETURN_URL || 'https://www.dudugroup.sn/api/v1/mobile-payments/orange-money/callback',
      cancelUrl: process.env.ORANGE_MONEY_CANCEL_URL || 'https://www.dudugroup.sn/api/v1/mobile-payments/orange-money/cancel',
      notifyUrl: process.env.ORANGE_MONEY_NOTIFY_URL || 'https://www.dudugroup.sn/api/v1/mobile-payments/orange-money/notify',
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
      callbackUrl: process.env.WAVE_SANDBOX_CALLBACK_URL || 'http://localhost:3000/api/v1/mobile-payments/wave/webhook',
      businessPhone: process.env.WAVE_SANDBOX_BUSINESS_PHONE || '',
    },
    
    // Production
    production: {
      apiUrl: 'https://api.wave.com/v1',
      apiKey: process.env.WAVE_API_KEY || 'wave_sn_prod_LHmeNrQE-TNw9iVm-M67APOgIsn-A9pfHClPSuOgyu3ojK8g-ABa83rBkAyVo6Hz_tEUfD45Vj5M4i7tAyI3tp3ycr5bIsanGQ',
      webhookSecret: process.env.WAVE_WEBHOOK_SECRET || 'wave_sn_WHS_pxdrk8vqcvt6nvxgsc74d54vfp7dy1nbdbnhapsbkfbdzz1mgg3g',
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
