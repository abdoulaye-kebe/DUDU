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

      // URLs de redirection (Wave Checkout API exige https://…)
      const baseUrl = process.env.PUBLIC_BASE_URL || 'https://www.dudugroup.sn';
      const successUrl = process.env.WAVE_SUCCESS_URL || `${baseUrl}/payment/success?ref=${encodeURIComponent(orderId)}`;
      const errorUrl = process.env.WAVE_ERROR_URL || `${baseUrl}/payment/error?ref=${encodeURIComponent(orderId)}`;

      // Préparer les données de paiement
      const paymentData = {
        amount: amount,
        currency: this.currency,
        client_reference: orderId,
        description: description || `Paiement DUDU - ${orderId}`,
        // Checkout API fields (docs.wave.com/checkout)
        success_url: successUrl,
        error_url: errorUrl,
        // Optionnel : si fourni, Wave affiche des instructions à ce numéro
        // (ne bloque pas si absent / non supporté selon régions)
        customer_phone_number: normalizedPhone,
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
   * Normalise un événement Wave (format actuel : { id, type, data }) ou ancien corps plat.
   * @param {Object} webhookData - JSON parsé du webhook
   */
  async handleWebhook(webhookData) {
    try {
      const eventType = webhookData.type || webhookData.event;

      if (eventType === 'test.test_event' || (typeof eventType === 'string' && eventType.startsWith('test.'))) {
        return {
          success: true,
          skipProcessing: true,
          sessionId: null,
          orderId: null,
          transactionId: null,
          status: 'noop',
          amount: null,
          currency: null,
          paidAt: null,
          customerPhone: null,
          event: eventType,
        };
      }

      // Nouveau format : envelope avec data (checkout.session.*, etc.)
      if (webhookData.data && typeof webhookData.data === 'object') {
        const d = webhookData.data;
        const status = this.mapWebhookEventStatus(eventType, d);
        const paidAt = d.when_completed
          ? new Date(d.when_completed)
          : (d.when_created ? new Date(d.when_created) : null);

        return {
          success: true,
          sessionId: d.id,
          orderId: d.client_reference != null ? String(d.client_reference) : null,
          transactionId: d.transaction_id != null ? String(d.transaction_id) : null,
          status,
          amount: d.amount != null ? parseFloat(String(d.amount), 10) : null,
          currency: d.currency,
          paidAt,
          customerPhone: d.sender_mobile || d.customer_phone_number,
          event: eventType,
        };
      }

      // Ancien format plat (rétrocompatibilité)
      const status = this.mapStatus(webhookData.status);
      return {
        success: true,
        sessionId: webhookData.id,
        orderId: webhookData.client_reference != null ? String(webhookData.client_reference) : null,
        transactionId: webhookData.transaction_id != null ? String(webhookData.transaction_id) : null,
        status,
        amount: webhookData.amount != null ? parseFloat(String(webhookData.amount), 10) : null,
        currency: webhookData.currency,
        paidAt: webhookData.completed_at ? new Date(webhookData.completed_at) : null,
        customerPhone: webhookData.customer_phone_number,
        event: eventType,
      };
    } catch (error) {
      console.error('Erreur lors du traitement du webhook Wave:', error.message);
      throw error;
    }
  }

  /**
   * Statut métier à partir d’un événement checkout Wave.
   */
  mapWebhookEventStatus(eventType, data) {
    const ps = (data.payment_status || '').toLowerCase();
    const cs = (data.checkout_status || '').toLowerCase();

    if (eventType === 'checkout.session.completed' && ps === 'succeeded' && cs === 'complete') {
      return 'completed';
    }
    if (eventType === 'checkout.session.payment_failed' || ps === 'failed') {
      return 'failed';
    }
    if (cs === 'expired' || ps === 'expired') {
      return 'failed';
    }
    if (ps === 'cancelled' || cs === 'cancelled') {
      return 'cancelled';
    }
    return 'processing';
  }

  /**
   * Vérifie l’en-tête Wave-Signature (t=timestamp,v1=hex) sur le corps brut UTF-8.
   * @see https://docs.wave.com/webhook
   */
  verifyWebhookSignature(rawBody, waveSignatureHeader) {
    try {
      const secret = this.config.webhookSecret;
      if (!waveSignatureHeader || !secret) {
        console.warn('⚠️ Wave-Signature ou WAVE_WEBHOOK_SECRET manquant');
        return false;
      }

      const raw =
        typeof rawBody === 'string'
          ? rawBody
          : Buffer.isBuffer(rawBody)
            ? rawBody.toString('utf8')
            : String(rawBody);

      const header = String(waveSignatureHeader).trim();

      // Format officiel : t=1639081943,v1=abc...
      if (header.includes('t=') && header.includes('v1=')) {
        const parts = header.split(',').map((p) => p.trim());
        const timestampPart = parts.find((p) => p.startsWith('t='));
        const v1Parts = parts.filter((p) => p.startsWith('v1='));
        if (!timestampPart || v1Parts.length === 0) return false;

        const timestamp = timestampPart.split('=').slice(1).join('=');
        const signatures = v1Parts.map((p) => p.split('=').slice(1).join('='));

        const tsNum = parseInt(timestamp, 10);
        if (!Number.isFinite(tsNum)) return false;
        const maxSkew = parseInt(process.env.WAVE_WEBHOOK_MAX_SKEW_SEC || '600', 10);
        const ageSec = Math.abs(Math.floor(Date.now() / 1000) - tsNum);
        if (ageSec > maxSkew) {
          console.warn('⚠️ Webhook Wave : timestamp hors fenêtre (replay ?)', ageSec, 's');
          return false;
        }

        const payload = timestamp + raw;
        const calculated = crypto
          .createHmac('sha256', secret)
          .update(payload, 'utf8')
          .digest('hex');

        return signatures.some((sig) => sig === calculated);
      }

      // Secours : ancien test avec signature = seul hex du corps (non documenté Wave)
      const expected = crypto.createHmac('sha256', secret).update(raw, 'utf8').digest('hex');
      if (header.length === expected.length) {
        try {
          return crypto.timingSafeEqual(Buffer.from(header, 'utf8'), Buffer.from(expected, 'utf8'));
        } catch (_) {
          return false;
        }
      }
      return false;
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
