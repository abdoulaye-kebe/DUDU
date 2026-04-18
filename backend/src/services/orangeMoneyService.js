const axios = require('axios');
const crypto = require('crypto');
const paymentConfig = require('../../config/payment.config');

/**
 * Message lisible à partir d'une erreur axios / API Orange (formats variables).
 */
function formatOrangeApiError(error, fallback) {
  if (error.response?.data != null) {
    const d = error.response.data;
    if (typeof d === 'string' && d.trim()) return d.trim().slice(0, 500);
    if (typeof d === 'object') {
      if (d.message) return String(d.message).slice(0, 500);
      if (d.error_description) return String(d.error_description).slice(0, 500);
      if (d.detail) return String(d.detail).slice(0, 500);
      if (d.title && d.detail) return `${d.title}: ${d.detail}`.slice(0, 500);
      if (d.title) return String(d.title).slice(0, 500);
      if (d.error && typeof d.error === 'string') return d.error.slice(0, 500);
      if (Array.isArray(d.errors) && d.errors.length) {
        const parts = d.errors.map((e) =>
          e && typeof e === 'object' ? e.message || e.code || JSON.stringify(e) : String(e)
        );
        return parts.join('; ').slice(0, 500);
      }
      try {
        const s = JSON.stringify(d);
        if (s && s !== '{}') return s.slice(0, 500);
      } catch (_) {}
    }
  }
  if (error.code === 'ECONNABORTED' || error.message?.includes('timeout')) {
    return 'Délai dépassé vers l’API Orange Money — réessayez.';
  }
  if (error.message) return error.message.slice(0, 500);
  return fallback;
}

/**
 * Service d'intégration Orange Money API (Orange Sonatel)
 * Documentation: https://developers.orange-sonatel.com
 * API Version: v1.0.0
 */
class OrangeMoneyService {
  constructor() {
    const mode = paymentConfig.orangeMoney.mode;
    this.config = paymentConfig.orangeMoney[mode];
    this.currency = paymentConfig.orangeMoney.currency;
    this.country = paymentConfig.orangeMoney.country;
    this.accessToken = null;
    this.tokenExpiry = null;
  }

  assertConfig() {
    if (!this.config.merchantKey || !this.config.merchantSecret) {
      throw new Error(
        'Configuration Orange Money : ORANGE_SONATEL_CLIENT_ID et ORANGE_SONATEL_CLIENT_SECRET sont requis sur le serveur.'
      );
    }
    if (!this.config.merchantCode) {
      throw new Error(
        'Configuration Orange Money : ORANGE_SONATEL_MERCODE (code marchand QR) est requis sur le serveur.'
      );
    }
  }

  /**
   * Obtenir un token d'accès OAuth 2.0
   */
  async getAccessToken() {
    try {
      this.assertConfig();
      // Vérifier si le token existe et n'est pas expiré
      if (this.accessToken && this.tokenExpiry && Date.now() < this.tokenExpiry) {
        return this.accessToken;
      }

      const params = new URLSearchParams();
      params.append('client_id', this.config.merchantKey);
      params.append('client_secret', this.config.merchantSecret);
      params.append('grant_type', 'client_credentials');

      const response = await axios.post(
        this.config.oauthUrl,
        params,
        {
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          timeout: paymentConfig.orangeMoney.timeout,
        }
      );

      this.accessToken = response.data.access_token;
      // Expiration à 80% de la durée (par sécurité)
      this.tokenExpiry = Date.now() + (response.data.expires_in * 0.8 * 1000);
      
      console.log('✅ Token OAuth Orange Money obtenu');
      return this.accessToken;
    } catch (error) {
      console.error('❌ Erreur lors de l\'obtention du token Orange Money:', error.response?.data || error.message);
      const msg = formatOrangeApiError(
        error,
        'Impossible d\'obtenir le token d\'accès Orange Money'
      );
      throw new Error(msg);
    }
  }

  /**
   * Initier un paiement Orange Money via QR Code
   * @param {Object} params - Paramètres du paiement
   * @param {string} params.orderId - ID unique de la commande
   * @param {number} params.amount - Montant en FCFA
   * @param {string} params.description - Description du paiement
   */
  async initiatePayment({ orderId, amount, description }) {
    try {
      this.assertConfig();
      // Validation
      if (amount < paymentConfig.general.minAmount || amount > paymentConfig.general.maxAmount) {
        throw new Error(`Le montant doit être entre ${paymentConfig.general.minAmount} et ${paymentConfig.general.maxAmount} FCFA`);
      }

      // Obtenir le token d'accès
      const accessToken = await this.getAccessToken();

      // Préparer les données pour générer le QR Code
      const qrData = {
        code: this.config.merchantCode,
        name: 'DUDU',
        amount: {
          value: amount,
          unit: this.currency
        },
        validity: 300, // 5 minutes
        callbackSuccessUrl: this.config.callbackUrl,
        callbackCancelUrl: this.config.callbackUrl,
        metadata: {
          orderId: orderId,
          description: description || `Paiement DUDU - ${orderId}`,
          reference: orderId,
        },
      };

      // Générer le QR Code
      const response = await axios.post(
        `${this.config.apiUrl}/api/eWallet/v4/qrcode`,
        qrData,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
            'X-Callback-Url': this.config.callbackUrl
          },
          timeout: paymentConfig.orangeMoney.timeout,
        }
      );

      console.log('✅ QR Code Orange Money généré');

      const rawDl = response.data.deeplinks || response.data.deepLinks || {};
      const deeplinks = {
        maxIt: rawDl.maxIt || rawDl.MAX_IT || rawDl.MAXIT || rawDl.maxit,
        orangeMoney: rawDl.om || rawDl.OM || rawDl.orangeMoney,
      };

      const providerRef =
        response.data.transactionId ||
        response.data.id ||
        response.data.reference ||
        response.data.shortCode ||
        (typeof response.data.qrCode === 'string' ? response.data.qrCode.substring(0, 80) : null);

      return {
        success: true,
        qrCode: response.data.qrCode,
        qrCodeUrl: response.data.qrCodeUrl,
        deeplinks,
        providerReference: providerRef,
        orderId: orderId,
        amount: amount,
        currency: this.currency,
        expiresAt: new Date(Date.now() + paymentConfig.general.transactionTimeout * 1000),
      };
    } catch (error) {
      console.error('Erreur lors de l\'initiation du paiement Orange Money:', error.response?.data || error.message);
      const msg = formatOrangeApiError(
        error,
        'Erreur lors de l\'initiation du paiement Orange Money'
      );
      throw new Error(msg);
    }
  }

  /**
   * Vérifier le statut d'un paiement via l'API de recherche de transactions
   * @param {string} transactionId - ID de la transaction Orange Money
   */
  async checkPaymentStatus(transactionId) {
    try {
      const accessToken = await this.getAccessToken();

      const response = await axios.get(
        `${this.config.apiUrl}/api/eWallet/v1/transactions/${transactionId}/status`,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
          },
          timeout: paymentConfig.orangeMoney.timeout,
        }
      );

      return {
        success: true,
        status: this.mapStatus(response.data.status),
        transactionId: transactionId,
      };
    } catch (error) {
      console.error('Erreur lors de la vérification du paiement Orange Money:', error.response?.data || error.message);
      throw new Error('Erreur lors de la vérification du statut du paiement');
    }
  }

  /**
   * Traiter la notification de callback
   * @param {Object} callbackData - Données du callback
   */
  async handleCallback(callbackData) {
    try {
      console.log('📥 Callback Orange Money reçu:', callbackData);

      // Extraire les données du callback
      const orderId =
        callbackData.metadata?.orderId ||
        callbackData.orderId ||
        callbackData.paymentId ||
        (typeof callbackData.reference === 'string' && callbackData.reference.startsWith('PAY')
          ? callbackData.reference
          : null) ||
        callbackData.metadata?.reference ||
        callbackData.reference;
      const status = this.mapStatus(callbackData.status);
      const transactionId = callbackData.transactionId || callbackData.transaction_id;
      const amount = callbackData.amount?.value || callbackData.amount;
      
      return {
        success: true,
        orderId: orderId,
        transactionId: transactionId,
        status: status,
        amount: amount,
        currency: callbackData.amount?.unit || this.currency,
        paidAt: new Date(),
        event: callbackData.type,
        message: callbackData.message || '',
      };
    } catch (error) {
      console.error('❌ Erreur lors du traitement du callback Orange Money:', error.message);
      throw error;
    }
  }

  /**
   * Mapper le statut Orange Money vers notre système
   */
  mapStatus(orangeStatus) {
    const statusMap = {
      'INITIATED': 'pending',
      'PRE_INITIATED': 'pending',
      'PENDING': 'processing',
      'ACCEPTED': 'processing',
      'SUCCESS': 'completed',
      'FAILED': 'failed',
      'REJECTED': 'failed',
      'CANCELLED': 'cancelled',
    };

    return statusMap[orangeStatus] || 'pending';
  }

  /**
   * Normaliser le numéro de téléphone au format international
   */
  normalizePhoneNumber(phone) {
    let normalized = phone.toString().trim().replace(/\s+/g, '');
    
    // Retirer le + si présent
    if (normalized.startsWith('+')) {
      normalized = normalized.substring(1);
    }
    
    // Ajouter 221 si nécessaire (Sénégal)
    if (normalized.length === 9) {
      normalized = `221${normalized}`;
    }
    
    // Ajouter le + au début
    if (!normalized.startsWith('+')) {
      normalized = `+${normalized}`;
    }
    
    return normalized;
  }

  /**
   * Vérifier la signature du callback (si implémenté par Orange Money)
   */
  verifySignature(data) {
    // Implémenter la vérification de signature selon la documentation Orange Money
    // Pour l'instant, on retourne true
    return true;
  }

  /**
   * Calculer les frais de transaction
   */
  calculateFees(amount) {
    const feePercentage = paymentConfig.general.fees.orangeMoney;
    const fees = Math.round(amount * feePercentage);
    const netAmount = amount - fees;
    
    return {
      amount: amount,
      fees: fees,
      netAmount: netAmount,
      feePercentage: feePercentage * 100,
    };
  }

  /**
   * Initier un remboursement
   * @param {string} transactionId - ID de la transaction à rembourser
   * @param {number} amount - Montant à rembourser
   */
  async initiateRefund(transactionId, amount) {
    try {
      const accessToken = await this.getAccessToken();

      const refundData = {
        transaction_id: transactionId,
        amount: amount,
        currency: this.currency,
      };

      const response = await axios.post(
        `${this.config.apiUrl}/refund`,
        refundData,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          timeout: paymentConfig.general.transactionTimeout * 1000,
        }
      );

      return {
        success: true,
        refundId: response.data.refund_id,
        status: response.data.status,
        amount: amount,
        message: 'Remboursement initié avec succès',
      };
    } catch (error) {
      console.error('Erreur lors du remboursement Orange Money:', error.response?.data || error.message);
      throw new Error('Erreur lors de l\'initiation du remboursement');
    }
  }
}

module.exports = new OrangeMoneyService();
