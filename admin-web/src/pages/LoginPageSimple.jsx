import React, { useState } from 'react';

function LoginPageSimple({ onLoginSuccess }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!email.trim() || !password.trim() || isLoading) return;

    setIsLoading(true);
    setError(null);

    try {
      // Utiliser fetch natif au lieu d'axios
      const response = await fetch('/api/v1/auth/admin/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: email.trim(), password })
      });

      const data = await response.json();
      
      if (!response.ok || !data.success) {
        setError(data.message || 'Erreur de connexion');
        return;
      }

      const token = data?.data?.token;
      if (!token) {
        setError('Connexion impossible. Réponse serveur invalide.');
        return;
      }

      localStorage.setItem('admin_token', token);
      onLoginSuccess?.();
    } catch (err) {
      setError(err.message || 'Erreur de connexion');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: '100vh',
      display: 'grid',
      placeItems: 'center',
      padding: 24,
      background: 'linear-gradient(135deg, #f9fafb 0%, #f3f4f6 100%)'
    }}>
      <div style={{
        width: '100%',
        maxWidth: 420,
        background: '#fff',
        borderRadius: 18,
        border: '1px solid rgba(0,0,0,0.06)',
        boxShadow: '0 18px 60px rgba(0,0,0,0.08)',
        padding: 22
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
          <div style={{
            width: 44,
            height: 44,
            borderRadius: 14,
            display: 'grid',
            placeItems: 'center',
            color: '#fff',
            fontWeight: 900,
            background: 'linear-gradient(135deg, #0d5d36 0%, #10b981 100%)'
          }}>D</div>
          <div>
            <div style={{ fontWeight: 900, fontSize: 18, lineHeight: 1.1 }}>DUDU Admin</div>
            <div style={{ color: '#6b7280', fontSize: 13 }}>Connexion administrateur</div>
          </div>
        </div>

        {error ? (
          <div style={{
            background: 'rgba(239, 68, 68, 0.08)',
            border: '1px solid rgba(239, 68, 68, 0.18)',
            color: '#b91c1c',
            padding: '10px 12px',
            borderRadius: 12,
            fontSize: 13,
            marginBottom: 12
          }}>{error}</div>
        ) : null}

        <form onSubmit={handleSubmit}>
          <label style={{ display: 'block', fontSize: 13, fontWeight: 700, marginBottom: 6, color: '#374151' }}>
            Email
          </label>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="admin@dudugroup.sn"
            autoComplete="username"
            style={{
              width: '100%',
              padding: '12px 12px',
              borderRadius: 12,
              border: '1px solid rgba(0,0,0,0.12)',
              outline: 'none',
              marginBottom: 12
            }}
          />

          <label style={{ display: 'block', fontSize: 13, fontWeight: 700, marginBottom: 6, color: '#374151' }}>
            Mot de passe
          </label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="********"
            autoComplete="current-password"
            style={{
              width: '100%',
              padding: '12px 12px',
              borderRadius: 12,
              border: '1px solid rgba(0,0,0,0.12)',
              outline: 'none',
              marginBottom: 14
            }}
          />

          <button
            type="submit"
            disabled={!email.trim() || !password.trim() || isLoading}
            style={{
              width: '100%',
              padding: '12px 14px',
              borderRadius: 14,
              border: '1px solid rgba(16, 185, 129, 0.35)',
              background: 'linear-gradient(135deg, #0d5d36 0%, #10b981 100%)',
              color: '#fff',
              fontWeight: 900,
              cursor: (!email.trim() || !password.trim() || isLoading) ? 'not-allowed' : 'pointer',
              opacity: (!email.trim() || !password.trim() || isLoading) ? 0.65 : 1
            }}
          >
            {isLoading ? 'Connexion…' : 'Se connecter'}
          </button>
        </form>
      </div>
    </div>
  );
}

export default LoginPageSimple;
