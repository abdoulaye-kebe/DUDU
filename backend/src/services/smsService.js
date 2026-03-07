/**
 * Service d'envoi SMS (code de vérification)
 * En développement : log en console. En production : configurer Twilio ou autre via variables d'env.
 */
const axios = require('axios');

const SMS_PROVIDER = process.env.SMS_PROVIDER || 'log';
const TWILIO_ACCOUNT_SID = process.env.TWILIO_ACCOUNT_SID;
const TWILIO_AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN;
const TWILIO_FROM = process.env.TWILIO_PHONE_NUMBER;

/**
 * Envoie le code de vérification par SMS (ou log en dev)
 * @param {string} phone - Numéro au format +221XXXXXXXXX
 * @param {string} code - Code à 6 chiffres
 * @returns {Promise<boolean>} true si envoyé (ou simulé), false en cas d'erreur
 */
async function sendVerificationCode(phone, code) {
  const normalizedPhone = phone.startsWith('+') ? phone : `+221${phone.replace(/^221/, '')}`;
  const message = `Votre code DUDU : ${code}. Ne le partagez pas.`;

  if (SMS_PROVIDER === 'twilio' && TWILIO_ACCOUNT_SID && TWILIO_AUTH_TOKEN && TWILIO_FROM) {
    try {
      const auth = Buffer.from(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`).toString('base64');
      await axios.post(
        `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`,
        new URLSearchParams({
          To: normalizedPhone,
          From: TWILIO_FROM,
          Body: message,
        }),
        {
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            Authorization: `Basic ${auth}`,
          },
          timeout: 10000,
        }
      );
      console.log(`SMS envoyé à ${normalizedPhone} (Twilio)`);
      return true;
    } catch (err) {
      console.error('Erreur envoi SMS Twilio:', err.response?.data || err.message);
      return false;
    }
  }

  // Mode log (développement) : afficher le code en console
  console.log(`[SMS] Destinataire: ${normalizedPhone} | Code: ${code} | Message: ${message}`);
  return true;
}

module.exports = { sendVerificationCode };
