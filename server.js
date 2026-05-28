const express = require('express')
const app = express()
const PORT = process.env.PORT || 3000

// Este secret viene de una variable de entorno — NUNCA del código
const SECRET_MESSAGE = process.env.SECRET_MESSAGE || 'No secret configured'
const APP_ENV = process.env.APP_ENV || 'local'

app.get('/', (req, res) => {
  res.json({
    app: 'secure-demo-app',
    message: '🔐 This app reads secrets from environment variables — never from code',
    environment: APP_ENV,
    secretLoaded: SECRET_MESSAGE !== 'No secret configured',
    timestamp: new Date().toISOString(),
  })
})

app.get('/secret', (req, res) => {
  res.json({
    message: SECRET_MESSAGE,
    source: 'Environment variable SECRET_MESSAGE',
    note: 'This value was injected via GitHub Secrets → ECS Task Definition. It never existed in the source code.',
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
