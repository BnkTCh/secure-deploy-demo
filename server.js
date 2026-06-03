const express = require('express')
const path = require('path')
const app = express()
const PORT = process.env.PORT || 3000

// Este secret viene de una variable de entorno — NUNCA del código
const SECRET_MESSAGE = process.env.SECRET_MESSAGE || 'No secret configured'
const APP_ENV = process.env.APP_ENV || 'local'

// Serve static HTML
app.get('/', (req, res) => {
  res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Secure Deploy Demo</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #0f172a;
      color: #e2e8f0;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 2rem;
    }
    .container {
      max-width: 700px;
      width: 100%;
    }
    .header {
      text-align: center;
      margin-bottom: 2rem;
    }
    .header h1 {
      font-size: 2rem;
      background: linear-gradient(135deg, #60a5fa, #a78bfa);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      margin-bottom: 0.5rem;
    }
    .header p {
      color: #94a3b8;
      font-size: 0.9rem;
    }
    .card {
      background: #1e293b;
      border: 1px solid #334155;
      border-radius: 12px;
      padding: 1.5rem;
      margin-bottom: 1rem;
    }
    .card.secret {
      border-color: #7c3aed;
      background: linear-gradient(135deg, #1e1b4b, #1e293b);
    }
    .card.info {
      border-color: #2563eb;
    }
    .card h2 {
      font-size: 1rem;
      color: #94a3b8;
      margin-bottom: 0.75rem;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    .card .value {
      font-size: 1.1rem;
      color: #f1f5f9;
      font-weight: 500;
    }
    .card.secret .value {
      color: #a78bfa;
      font-family: monospace;
      background: #0f172a;
      padding: 1rem;
      border-radius: 8px;
      border: 1px solid #374151;
    }
    .badge {
      display: inline-block;
      padding: 0.25rem 0.75rem;
      border-radius: 9999px;
      font-size: 0.75rem;
      font-weight: 600;
    }
    .badge.green { background: #064e3b; color: #6ee7b7; }
    .badge.blue { background: #1e3a5f; color: #93c5fd; }
    .badge.purple { background: #2e1065; color: #c4b5fd; }
    .grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 1rem;
    }
    .flow {
      margin-top: 2rem;
      padding: 1.5rem;
      background: #1e293b;
      border: 1px solid #334155;
      border-radius: 12px;
    }
    .flow h3 {
      color: #94a3b8;
      font-size: 0.85rem;
      margin-bottom: 1rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    .flow-steps {
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 0.5rem;
    }
    .flow-step {
      text-align: center;
      font-size: 0.75rem;
      color: #cbd5e1;
    }
    .flow-step .icon {
      font-size: 1.5rem;
      margin-bottom: 0.25rem;
    }
    .flow-arrow {
      color: #475569;
      font-size: 1.2rem;
    }
    .footer {
      text-align: center;
      margin-top: 2rem;
      color: #475569;
      font-size: 0.75rem;
    }
    .footer a {
      color: #60a5fa;
      text-decoration: none;
    }
    @media (max-width: 600px) {
      .grid { grid-template-columns: 1fr; }
      .flow-steps { flex-direction: column; }
      .flow-arrow { transform: rotate(90deg); }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🔐 Secure Deploy Demo</h1>
      <p>This app demonstrates zero-credential deployments with GitHub + AWS</p>
    </div>

    <div class="card secret">
      <h2>🔑 Secret Message (from environment variable)</h2>
      <div class="value">${SECRET_MESSAGE}</div>
    </div>

    <div class="grid">
      <div class="card info">
        <h2>🌍 Environment</h2>
        <div class="value"><span class="badge green">${APP_ENV}</span></div>
      </div>
      <div class="card info">
        <h2>🔐 Secret Loaded</h2>
        <div class="value"><span class="badge ${SECRET_MESSAGE !== 'No secret configured' ? 'green' : 'purple'}">${SECRET_MESSAGE !== 'No secret configured' ? 'YES ✓' : 'NO ✗'}</span></div>
      </div>
    </div>

    <div class="card">
      <h2>📋 How this works</h2>
      <div class="value" style="font-size: 0.85rem; line-height: 1.6; color: #94a3b8;">
        This secret was <strong style="color: #a78bfa;">never hardcoded</strong> in the source code.<br>
        It was injected at runtime via:<br>
        <span class="badge blue" style="margin-top: 0.5rem; display: inline-block;">GitHub Secrets → GitHub Actions → ECS Task Definition → Container</span>
      </div>
    </div>

    <div class="flow">
      <h3>🚀 Deployment Flow (Zero Credentials)</h3>
      <div class="flow-steps">
        <div class="flow-step">
          <div class="icon">📝</div>
          GitHub Secret
        </div>
        <div class="flow-arrow">→</div>
        <div class="flow-step">
          <div class="icon">⚡</div>
          Actions (OIDC)
        </div>
        <div class="flow-arrow">→</div>
        <div class="flow-step">
          <div class="icon">🐳</div>
          Build + ECR
        </div>
        <div class="flow-arrow">→</div>
        <div class="flow-step">
          <div class="icon">☁️</div>
          ECS Fargate
        </div>
        <div class="flow-arrow">→</div>
        <div class="flow-step">
          <div class="icon">✅</div>
          Running!
        </div>
      </div>
    </div>

    <div class="footer">
      <p>GitHub Community Day — Bianca Torres</p>
      <p><a href="https://github.com/BnkTCh/secure-deploy-demo">github.com/BnkTCh/secure-deploy-demo</a></p>
    </div>
  </div>
</body>
</html>
  `)
})

// API endpoints (JSON)
app.get('/secret', (req, res) => {
  res.json({
    message: SECRET_MESSAGE,
    source: 'Variable de entorno SECRET_MESSAGE',
    note: 'Este valor fue inyectado a través de GitHub Secrets → ECS Task Definition. Nunca existió en el código fuente.',
  })
})

app.get('/info', (req, res) => {
  res.json({
    app: 'secure-demo-app',
    environment: APP_ENV,
    secretLoaded: SECRET_MESSAGE !== 'No secret configured',
    timestamp: new Date().toISOString(),
  })
})

app.get('/api/secret', (req, res) => {
  res.json({
    message: SECRET_MESSAGE,
    source: 'Variable de entorno SECRET_MESSAGE',
    note: 'Este valor fue inyectado a través de GitHub Secrets → ECS Task Definition. Nunca existió en el código fuente.',
  })
})

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' })
})

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`)
  console.log(`🔐 Secret loaded: ${SECRET_MESSAGE !== 'No secret configured' ? 'YES' : 'NO'}`)
  console.log(`🌍 Environment: ${APP_ENV}`)
})
