'use strict';

/**
 * PM2 — même nom de process que les logs (`dudu-bac`).
 * Depuis le dossier `backend/` :
 *   pm2 start ecosystem.config.cjs
 *   pm2 reload ecosystem.config.cjs --update-env
 */

module.exports = {
  apps: [
    {
      name: 'dudu-bac',
      cwd: __dirname,
      script: 'src/server.js',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '512M',
      env: {
        NODE_ENV: 'production',
      },
    },
  ],
};
