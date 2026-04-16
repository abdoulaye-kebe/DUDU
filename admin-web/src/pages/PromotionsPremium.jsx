import React, { useMemo, useState } from 'react';
import { motion } from 'framer-motion';
import { Bell, Send, KeyRound, AlertCircle, CheckCircle2 } from 'lucide-react';
import api from '../services/api';

function PromotionsPremium() {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [image, setImage] = useState('');
  const [dataJson, setDataJson] = useState(`{
  "screen": "promo",
  "promoId": ""
}`);

  const [sending, setSending] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const parsedData = useMemo(() => {
    try {
      const obj = JSON.parse(dataJson);
      if (obj && typeof obj === 'object' && !Array.isArray(obj)) {
        return obj;
      }
      return null;
    } catch {
      return null;
    }
  }, [dataJson]);

  const canSend = Boolean(title.trim()) && Boolean(body.trim());

  const handleSend = async () => {
    setError('');
    setSuccess('');

    if (!title.trim() || !body.trim()) {
      setError('Titre et message sont requis.');
      return;
    }

    if (dataJson.trim() && !parsedData) {
      setError('Le champ Data JSON est invalide (JSON attendu).');
      return;
    }

    const payload = {
      title: title.trim(),
      body: body.trim(),
      image: image.trim() ? image.trim() : undefined,
      data: parsedData || undefined
    };

    const session = localStorage.getItem('admin_token');
    if (!session?.trim()) {
      setError('Session expirée : reconnectez-vous à l’admin.');
      return;
    }

    setSending(true);
    try {
      const res = await api.post('/notifications/promo', payload);
      const messageId = res?.data?.result;

      if (res?.data?.success) {
        setSuccess(messageId ? `Notification envoyée (messageId: ${messageId}).` : 'Notification envoyée.');
      } else {
        setError(res?.data?.message || 'Erreur lors de l\'envoi.');
      }
    } catch (e) {
      setError(e?.response?.data?.message || e?.message || 'Erreur lors de l\'envoi.');
    } finally {
      setSending(false);
    }
  };

  return (
    <div>
      <motion.div
        className="page-header"
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
      >
        <div className="page-header-content">
          <div className="page-title-section">
            <h1 className="page-title">Promotions</h1>
            <p className="page-subtitle">
              Paramétrez et envoyez une notification push à tous les utilisateurs abonnés au topic <b>promos</b>.
            </p>
          </div>
        </div>
      </motion.div>

      {error && (
        <motion.div
          className="card"
          style={{
            padding: '16px 24px',
            marginBottom: '24px',
            background: '#fef2f2',
            borderColor: 'var(--accent-red)',
            display: 'flex',
            alignItems: 'center',
            gap: '12px'
          }}
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <AlertCircle size={20} style={{ color: 'var(--accent-red)' }} />
          <span style={{ color: 'var(--accent-red)', fontWeight: 500 }}>{error}</span>
        </motion.div>
      )}

      {success && (
        <motion.div
          className="card"
          style={{
            padding: '16px 24px',
            marginBottom: '24px',
            background: '#ecfdf5',
            borderColor: 'var(--primary-500)',
            display: 'flex',
            alignItems: 'center',
            gap: '12px'
          }}
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <CheckCircle2 size={20} style={{ color: 'var(--primary-600)' }} />
          <span style={{ color: 'var(--primary-700)', fontWeight: 600 }}>{success}</span>
        </motion.div>
      )}

      <div className="stats-grid" style={{ gridTemplateColumns: '1.1fr 0.9fr' }}>
        <div className="card" style={{ padding: '24px' }}>
          <div className="section-header" style={{ marginBottom: '16px' }}>
            <div className="section-title">
              <Bell />
              Envoyer une promo
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '14px' }}>
            <div>
              <div className="modal-label">Titre</div>
              <input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Ex: Promo de Noël"
                style={{
                  marginTop: 8,
                  width: '100%',
                  padding: '12px 14px',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--gray-200)',
                  outline: 'none'
                }}
              />
            </div>

            <div>
              <div className="modal-label">Message</div>
              <textarea
                value={body}
                onChange={(e) => setBody(e.target.value)}
                placeholder="Ex: -20% sur toutes les courses aujourd'hui"
                rows={4}
                style={{
                  marginTop: 8,
                  width: '100%',
                  padding: '12px 14px',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--gray-200)',
                  outline: 'none',
                  resize: 'vertical'
                }}
              />
            </div>

            <div>
              <div className="modal-label">Image URL (optionnel)</div>
              <input
                value={image}
                onChange={(e) => setImage(e.target.value)}
                placeholder="https://..."
                style={{
                  marginTop: 8,
                  width: '100%',
                  padding: '12px 14px',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--gray-200)',
                  outline: 'none'
                }}
              />
              <div style={{ marginTop: 8, fontSize: 13, color: 'var(--gray-500)' }}>
                Laisse vide si tu ne veux pas d'image.
              </div>
            </div>

            <div>
              <div className="modal-label">Data (JSON optionnel)</div>
              <textarea
                value={dataJson}
                onChange={(e) => setDataJson(e.target.value)}
                rows={7}
                style={{
                  marginTop: 8,
                  width: '100%',
                  padding: '12px 14px',
                  borderRadius: 'var(--radius-md)',
                  border: `1px solid ${parsedData ? 'var(--gray-200)' : 'var(--accent-red)'}`,
                  outline: 'none',
                  resize: 'vertical',
                  fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace',
                  fontSize: 13
                }}
              />
              <div style={{ marginTop: 8, fontSize: 13, color: parsedData ? 'var(--gray-500)' : 'var(--accent-red)' }}>
                {parsedData ? 'JSON valide.' : 'JSON invalide.'}
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 12 }}>
              <motion.button
                className="btn btn-primary"
                onClick={handleSend}
                disabled={!canSend || sending}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                <Send size={18} />
                {sending ? 'Envoi...' : 'Envoyer'}
              </motion.button>
            </div>
          </div>
        </div>

        <div className="card" style={{ padding: '24px' }}>
          <div className="section-header" style={{ marginBottom: '16px' }}>
            <div className="section-title">
              <KeyRound />
              Accès
            </div>
          </div>

          <div style={{ display: 'grid', gap: 14 }}>
            <p style={{ margin: 0, fontSize: 14, color: 'var(--gray-600)', lineHeight: 1.5 }}>
              L’envoi utilise automatiquement votre session admin (token après connexion). Seuls les comptes administrateur peuvent appeler cette API.
            </p>
            <div>
              <div className="modal-label">Endpoint</div>
              <div className="modal-value" style={{ marginTop: 8 }}>
                POST /api/v1/notifications/promo
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default PromotionsPremium;
