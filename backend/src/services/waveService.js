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

      // Préparer les données de paiement (docs Wave : amount souvent envoyé en chaîne)
      const paymentData = {
        amount: String(amount),
        currency: this.currency,
        client_reference: orderId,
        description: description || `Paiement DUDU - ${orderId}`,
        // Checkout API fields (docs.wave.com/checkout)
        success_url: successUrl,
        error_url: errorUrl,
      };
      const restrict = String(process.env.WAVE_RESTRICT_PAYER_MOBILE || '')
        .trim()
        .toLowerCase();
      if (restrict === '1' || restrict === 'true' || restrict === 'yes') {
        paymentData.restrict_payer_mobile = normalizedPhone;
      }

      // Créer la requête de paiement
      const response = await axios.post(
        `${this.config.apiUrl}/checkout/sessions`,
        paymentData,
        {
          headers: this.getAuthHeaders(),
          timeout: paymentConfig.general.transactionTimeout * 1000,
        }
      );

      const data = response.data || {};
      let checkoutUrl = data.wave_launch_url;
      if (
        (!checkoutUrl || typeof checkoutUrl !== 'string') &&
        typeof data.id === 'string' &&
        data.id.startsWith('cos-')
      ) {
        checkoutUrl = `https://pay.wave.com/c/${data.id}`;
      }
      if (!checkoutUrl) {
        console.error(
          'Wave checkout: réponse sans wave_launch_url, clés:',
          Object.keys(data).join(', ')
        );
        throw new Error('Réponse Wave invalide (pas d’URL de paiement)');
      }

      return {
        success: true,
        sessionId: data.id,
        checkoutUrl,
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
  _normalizeWebhookSecret(secret) {
    if (secret == null) return '';
    let s = String(secret).trim();
    if (
      (s.startsWith('"') && s.endsWith('"')) ||
      (s.startsWith("'") && s.endsWith("'"))
    ) {
      s = s.slice(1, -1).trim();
    }
    return s;
  }

  /** Signing secret présent (variable d’environnement alignée sur le portail Wave pour ce webhook). */
  isWebhookSecretConfigured() {
    return this._normalizeWebhookSecret(this.config.webhookSecret).length > 0;
  }

  /**
   * Secrets de signature (principal + rotation optionnelle, ex. après régénération sur le portail Wave).
   */
  _webhookSigningSecrets() {
    const primary = this._normalizeWebhookSecret(this.config.webhookSecret);
    const prev = this._normalizeWebhookSecret(
      process.env.WAVE_WEBHOOK_SECRET_PREVIOUS || ''
    );
    const list = [];
    if (primary) list.push(primary);
    if (prev && prev !== primary) list.push(prev);
    return list;
  }

  /**
   * @param {string|Buffer} rawBody - Corps exact reçu (Buffer recommandé, identique aux octets signés par Wave).
   * @returns {{ valid: boolean, code?: string, detail?: string }}
   */
  verifyWebhookSignatureDetailed(rawBody, waveSignatureHeader) {
    try {
      const secrets = this._webhookSigningSecrets();
      if (secrets.length === 0) {
        console.warn('⚠️ WAVE_WEBHOOK_SECRET (signing secret) non configuré');
        return { valid: false, code: 'NO_SECRET' };
      }
      if (!waveSignatureHeader) {
        console.warn('⚠️ En-tête Wave-Signature manquant');
        return { valid: false, code: 'NO_HEADER' };
      }

      const rawBuf = Buffer.isBuffer(rawBody)
        ? rawBody
        : Buffer.from(
            typeof rawBody === 'string' ? rawBody : String(rawBody),
            'utf8'
          );

      const header = String(waveSignatureHeader).trim();

      const hexTimingSafeEqual = (a, b) => {
        const ba = Buffer.from(String(a).toLowerCase(), 'utf8');
        const bb = Buffer.from(String(b).toLowerCase(), 'utf8');
        if (ba.length !== bb.length) return false;
        try {
          return crypto.timingSafeEqual(ba, bb);
        } catch (_) {
          return false;
        }
      };

      // Format officiel : t=1639081943,v1=abc...
      if (header.includes('t=') && header.includes('v1=')) {
        const parts = header.split(',').map((p) => p.trim());
        const timestampPart = parts.find((p) => p.startsWith('t='));
        const v1Parts = parts.filter((p) => p.startsWith('v1='));
        if (!timestampPart || v1Parts.length === 0) {
          return { valid: false, code: 'BAD_HEADER' };
        }

        const timestamp = timestampPart.split('=').slice(1).join('=');
        const signatures = v1Parts.map((p) => p.split('=').slice(1).join('='));

        const tsNumRaw = parseInt(timestamp, 10);
        if (!Number.isFinite(tsNumRaw)) {
          return { valid: false, code: 'BAD_TIMESTAMP' };
        }
        let tsSecForAge = tsNumRaw;
        if (tsNumRaw > 9999999999) {
          tsSecForAge = Math.floor(tsNumRaw / 1000);
        }
        // Défaut 1 h : les relivraisons Wave peuvent dépasser 10 min (ancien défaut 600 s).
        const maxSkew = parseInt(process.env.WAVE_WEBHOOK_MAX_SKEW_SEC || '3600', 10);
        const ageSec = Math.abs(Math.floor(Date.now() / 1000) - tsSecForAge);
        if (ageSec > maxSkew) {
          console.warn(
            '⚠️ Webhook Wave : timestamp hors fenêtre',
            ageSec,
            's (max',
            maxSkew,
            's — augmenter WAVE_WEBHOOK_MAX_SKEW_SEC si besoin)'
          );
          return {
            valid: false,
            code: 'TIMESTAMP_SKEW',
            detail: `${ageSec}s > ${maxSkew}s`,
          };
        }

        const tsBuf = Buffer.from(timestamp, 'utf8');
        const payloadBuf = Buffer.concat([tsBuf, rawBuf]);

        for (const secret of secrets) {
          const keyBuf = Buffer.from(secret, 'utf8');
          const calculated = crypto
            .createHmac('sha256', keyBuf)
            .update(payloadBuf)
            .digest('hex');
          const calculatedLower = calculated.toLowerCase();
          if (signatures.some((sig) => hexTimingSafeEqual(sig, calculatedLower))) {
            return { valid: true };
          }
        }

        return { valid: false, code: 'HMAC_MISMATCH' };
      }

      // Secours : ancien test avec signature = seul hex du corps (non documenté Wave)
      for (const secret of secrets) {
        const expected = crypto
          .createHmac('sha256', Buffer.from(secret, 'utf8'))
          .update(rawBuf)
          .digest('hex');
        if (header.length === expected.length) {
          try {
            if (crypto.timingSafeEqual(Buffer.from(header, 'utf8'), Buffer.from(expected, 'utf8'))) {
              return { valid: true };
            }
          } catch (_) {
            /* continue */
          }
        }
      }
      return { valid: false, code: 'HMAC_MISMATCH' };
    } catch (error) {
      console.error('❌ Erreur lors de la vérification de la signature webhook:', error.message);
      return { valid: false, code: 'ERROR', detail: error.message };
    }
  }

  /**
   * @param {string|Buffer} rawBody - Corps exact reçu (Buffer recommandé, identique aux octets signés par Wave).
   */
  verifyWebhookSignature(rawBody, waveSignatureHeader) {
    return this.verifyWebhookSignatureDetailed(rawBody, waveSignatureHeader).valid;
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
