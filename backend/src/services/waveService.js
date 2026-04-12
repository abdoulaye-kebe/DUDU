const axios = require('axios');
const crypto = require('crypto');
const paymentConfig = require('../../config/payment.config');

/**
 * Service d'intégration Wave API
 * Documentation: https://developer.wave.com/
 */
class WaveService {
  constructor() {
    const mode = paymentConfig.wave.mode;
    this.config = paymentConfig.wave[mode];
    this.currency = paymentConfig.wave.currency;
    this.country = paymentConfig.wave.country;
  }

  /**
   * Créer les headers d'authentification
   * Wave utilise simplement Bearer token, pas de signature HMAC
   */
  getAuthHeaders() {
    return {
      'Authorization': `Bearer ${this.config.apiKey}`,
      'Content-Type': 'application/json',
    };
  }

  /**
   * Initier un paiement Wave
   * @param {Object} params - Paramètres du paiement
   * @param {string} params.orderId - ID unique de la commande
   * @param {number} params.amount - Montant en FCFA
   * @param {string} params.phone - Numéro de téléphone du client (+221XXXXXXXXX)
   * @param {string} params.description - Description du paiement
   */
  async initiatePayment({ orderId, amount, phone, description }) {
    try {
      // Validation
      if (amount < paymentConfig.general.minAmount || amount > paymentConfig.general.maxAmount) {
        throw new Error(`Le montant doit être entre ${paymentConfig.general.minAmount} et ${paymentConfig.general.maxAmount} FCFA`);
      }

      // Normaliser le numéro de téléphone
      const normalizedPhone = this.normalizePhoneNumber(phone);

      // Préparer les données de paiement
      const paymentData = {
        amount: amount,
        currency: this.currency,
        business_id: this.config.businessId,
        client_reference: orderId,
        customer_phone_number: normalizedPhone,
        description: description || `Paiement DUDU - ${orderId}`,
        callback_url: this.config.callbackUrl,
        metadata: {
          order_id: orderId,
          platform: 'DUDU',
          country: this.country,
        },
      };

      // Créer la requête de paiement
      const response = await axios.post(
        `${this.config.apiUrl}/checkout/sessions`,
        paymentData,
        {
          headers: this.getAuthHeaders(),
          timeout: paymentConfig.general.transactionTimeout * 1000,
        }
      );

      return {
        success: true,
        sessionId: response.data.id,
        checkoutUrl: response.data.wave_launch_url,
        orderId: orderId,
        amount: amount,
        currency: this.currency,
        status: 'pending',
        expiresAt: new Date(Date.now() + paymentConfig.general.transactionTimeout * 1000),
      };
    } catch (error) {
      console.error('Erreur lors de l\'initiation du paiement Wave:', error.response?.data || error.message);
      throw new Error(error.response?.data?.message || 'Erreur lors de l\'initiation du paiement Wave');
    }
  }

  /**
   * Vérifier le statut d'un paiement
   * @param {string} sessionId - ID de la session de paiement
   */
  async checkPaymentStatus(sessionId) {
    try {
      const response = await axios.get(
        `${this.config.apiUrl}/checkout/sessions/${sessionId}`,
        {
          headers: this.getAuthHeaders(),
          timeout: paymentConfig.general.transactionTimeout * 1000,
        }
      );

      const data = response.data;
      const status = this.mapStatus(data.status);

      return {
        success: true,
        sessionId: sessionId,
        status: status,
        transactionId: data.transaction_id,
        amount: data.amount,
        currency: data.currency,
        orderId: data.client_reference,
        paidAt: data.completed_at ? new Date(data.completed_at) : null,
        customerPhone: data.customer_phone_number,
        rawData: data,
      };
    } catch (error) {
      console.error('Erreur lors de la vérification du paiement Wave:', error.response?.data || error.message);
      throw new Error('Erreur lors de la vérification du statut du paiement');
    }
  }

  /**
   * Traite le JSON du webhook après vérification HMAC sur le corps brut (route HTTP).
   * @param {Object} webhookData - Données parsées du webhook
   */
  async handleWebhook(webhookData) {
    try {
      const status = this.mapStatus(webhookData.status);
      
      return {
        success: true,
        sessionId: webhookData.id,
        orderId: webhookData.client_reference,
        transactionId: webhookData.transaction_id,
        status: status,
        amount: parseFloat(webhookData.amount),
        currency: webhookData.currency,
        paidAt: webhookData.completed_at ? new Date(webhookData.completed_at) : null,
        customerPhone: webhookData.customer_phone_number,
        event: webhookData.event,
      };
    } catch (error) {
      console.error('Erreur lors du traitement du webhook Wave:', error.message);
      throw error;
    }
  }

  /**
   * Vérifier la signature du webhook Wave
   * Wave utilise HMAC SHA-256 avec le Signing Secret
   */
  verifyWebhookSignature(payload, signature) {
    try {
      if (!signature || !this.config.webhookSecret) {
        console.warn('⚠️ Signature ou secret webhook manquant');
        return false;
      }

      // Générer la signature attendue avec HMAC SHA-256
      const expectedSignature = crypto
        .createHmac('sha256', this.config.webhookSecret)
        .update(payload)
        .digest('hex');

      // Comparer de manière sécurisée (timing-safe)
      return crypto.timingSafeEqual(
        Buffer.from(signature),
        Buffer.from(expectedSignature)
      );
    } catch (error) {
      console.error('❌ Erreur lors de la vérification de la signature webhook:', error.message);
      return false;
    }
  }

  /**
   * Mapper le statut Wave vers notre système
   */
  mapStatus(waveStatus) {
    const statusMap = {
      'pending': 'pending',
      'processing': 'processing',
      'success': 'completed',
      'completed': 'completed',
      'failed': 'failed',
      'expired': 'failed',
      'cancelled': 'cancelled',
    };

    return statusMap[waveStatus?.toLowerCase()] || 'pending';
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
   * Calculer les frais de transaction
   */
  calculateFees(amount) {
    const feePercentage = paymentConfig.general.fees.wave;
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
   * @param {string} reason - Raison du remboursement
   */
  async initiateRefund(transactionId, amount, reason) {
    try {
      const refundData = {
        transaction_id: transactionId,
        amount: amount,
        currency: this.currency,
        reason: reason || 'Remboursement demandé',
      };

      const response = await axios.post(
        `${this.config.apiUrl}/refunds`,
        refundData,
        {
          headers: this.getAuthHeaders(),
          timeout: paymentConfig.general.transactionTimeout * 1000,
        }
      );

      return {
        success: true,
        refundId: response.data.id,
        status: response.data.status,
        amount: amount,
        transactionId: transactionId,
        message: 'Remboursement initié avec succès',
      };
    } catch (error) {
      console.error('Erreur lors du remboursement Wave:', error.response?.data || error.message);
      throw new Error('Erreur lors de l\'initiation du remboursement');
    }
  }

  /**
   * Obtenir les détails d'un remboursement
   * @param {string} refundId - ID du remboursement
   */
  async getRefundStatus(refundId) {
    try {
      const response = await axios.get(
        `${this.config.apiUrl}/refunds/${refundId}`,
        {
          headers: this.getAuthHeaders(),
          timeout: paymentConfig.general.transactionTimeout * 1000,
        }
      );

      return {
        success: true,
        refundId: refundId,
        status: response.data.status,
        amount: response.data.amount,
        transactionId: response.data.transaction_id,
        processedAt: response.data.processed_at ? new Date(response.data.processed_at) : null,
      };
    } catch (error) {
      console.error('Erreur lors de la récupération du statut du remboursement:', error.response?.data || error.message);
      throw new Error('Erreur lors de la récupération du statut du remboursement');
    }
  }

  /**
   * Annuler un paiement en attente
   * @param {string} sessionId - ID de la session à annuler
   */
  async cancelPayment(sessionId) {
    try {
      const response = await axios.post(
        `${this.config.apiUrl}/checkout/sessions/${sessionId}/cancel`,
        {},
        {
          headers: this.getAuthHeaders(),
          timeout: paymentConfig.general.transactionTimeout * 1000,
        }
      );

      return {
        success: true,
        sessionId: sessionId,
        status: 'cancelled',
        message: 'Paiement annulé avec succès',
      };
    } catch (error) {
      console.error('Erreur lors de l\'annulation du paiement Wave:', error.response?.data || error.message);
      throw new Error('Erreur lors de l\'annulation du paiement');
    }
  }
}

module.exports = new WaveService();
