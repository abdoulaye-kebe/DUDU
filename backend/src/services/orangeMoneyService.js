const axios = require('axios');
const crypto = require('crypto');
const paymentConfig = require('../../config/payment.config');

/**
 * Service d'intégration Orange Money API
 * Documentation: https://developer.orange.com/apis/orange-money-webpay/
 */
class OrangeMoneyService {
  constructor() {
    const mode = paymentConfig.orangeMoney.mode;
    this.config = paymentConfig.orangeMoney[mode];
    this.currency = paymentConfig.orangeMoney.currency;
    this.country = paymentConfig.orangeMoney.country;
  }

  /**
   * Obtenir un token d'accès OAuth
   */
  async getAccessToken() {
    try {
      const auth = Buffer.from(
        `${this.config.merchantKey}:${this.config.merchantSecret}`
      ).toString('base64');

      const response = await axios.post(
        `${this.config.apiUrl}/oauth/token`,
        'grant_type=client_credentials',
        {
          headers: {
            'Authorization': `Basic ${auth}`,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          timeout: paymentConfig.general.transactionTimeout * 1000,
        }
      );

      return response.data.access_token;
    } catch (error) {
      console.error('Erreur lors de l\'obtention du token Orange Money:', error.response?.data || error.message);
      throw new Error('Impossible d\'obtenir le token d\'accès Orange Money');
    }
  }

  /**
   * Initier un paiement Orange Money
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

      // Obtenir le token d'accès
      const accessToken = await this.getAccessToken();

      // Préparer les données de paiement
      const paymentData = {
        merchant_key: this.config.merchantKey,
        currency: this.currency,
        order_id: orderId,
        amount: amount,
        return_url: this.config.returnUrl,
        cancel_url: this.config.cancelUrl,
        notif_url: this.config.notifyUrl,
        lang: paymentConfig.orangeMoney.language,
        reference: `DUDU-${orderId}`,
        customer_phone: normalizedPhone,
        customer_country: this.country,
        description: description || `Paiement DUDU - ${orderId}`,
      };

      // Créer la requête de paiement
      const response = await axios.post(
        `${this.config.apiUrl}/webpayment`,
        paymentData,
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
        paymentToken: response.data.payment_token,
        paymentUrl: response.data.payment_url,
        orderId: orderId,
        amount: amount,
        currency: this.currency,
        expiresAt: new Date(Date.now() + paymentConfig.general.transactionTimeout * 1000),
      };
    } catch (error) {
      console.error('Erreur lors de l\'initiation du paiement Orange Money:', error.response?.data || error.message);
      throw new Error(error.response?.data?.message || 'Erreur lors de l\'initiation du paiement Orange Money');
    }
  }

  /**
   * Vérifier le statut d'un paiement
   * @param {string} paymentToken - Token du paiement
   */
  async checkPaymentStatus(paymentToken) {
    try {
      const accessToken = await this.getAccessToken();

      const response = await axios.get(
        `${this.config.apiUrl}/webpayment/${paymentToken}`,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
          },
          timeout: paymentConfig.general.transactionTimeout * 1000,
        }
      );

      const status = response.data.status;
      const transactionId = response.data.txnid;

      return {
        success: true,
        status: this.mapStatus(status),
        transactionId: transactionId,
        amount: response.data.amount,
        currency: response.data.currency,
        orderId: response.data.order_id,
        paidAt: response.data.pay_date ? new Date(response.data.pay_date) : null,
        rawData: response.data,
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
      // Vérifier la signature si nécessaire
      // const isValid = this.verifySignature(callbackData);
      // if (!isValid) {
      //   throw new Error('Signature invalide');
      // }

      const status = this.mapStatus(callbackData.status);
      
      return {
        success: true,
        orderId: callbackData.order_id,
        transactionId: callbackData.txnid,
        status: status,
        amount: parseFloat(callbackData.amount),
        currency: callbackData.currency,
        paidAt: callbackData.pay_date ? new Date(callbackData.pay_date) : null,
        message: callbackData.message,
      };
    } catch (error) {
      console.error('Erreur lors du traitement du callback Orange Money:', error.message);
      throw error;
    }
  }

  /**
   * Mapper le statut Orange Money vers notre système
   */
  mapStatus(orangeStatus) {
    const statusMap = {
      'INITIATED': 'pending',
      'PENDING': 'processing',
      'SUCCESS': 'completed',
      'FAILED': 'failed',
      'EXPIRED': 'failed',
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
