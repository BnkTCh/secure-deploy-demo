# 🔐 Secure Deploy Demo

Demo app para la charla **"Nunca más hardcodees un token: Seguridad en GitHub para DevOps"** — GitHub Community Day.

Esta aplicación demuestra cómo deployar a AWS **sin credenciales permanentes en el código**, usando las herramientas de seguridad gratuitas de GitHub.

## ¿Qué demuestra?

- **GitHub Secrets** → El secret de la app se guarda encriptado en GitHub, nunca en el código
- **OIDC con AWS** → El deploy a AWS se autentica sin access keys permanentes
- **Secret Scanning** → GitHub detecta tokens expuestos automáticamente
- **Push Protection** → GitHub bloquea pushes que contengan secrets
- **Dependabot** → Detecta vulnerabilidades en dependencias

## La app

Una API simple en Node.js/Express que lee un mensaje secreto desde una variable de entorno y lo muestra en una página web.

**Endpoints:**
- `/` → Página visual con el secret y el flujo de deploy
- `/secret` → JSON con el secret y su origen
- `/info` → JSON con info de la app
- `/health` → Health check

## Flujo de deploy

```
GitHub Secret (SECRET_MESSAGE)
       ↓
GitHub Actions (autenticación con OIDC — sin AWS keys)
       ↓
Build imagen Docker → Push a Amazon ECR
       ↓
Update Task Definition (inyecta el secret)
       ↓
Deploy a ECS Fargate
       ↓
App corriendo con el secret inyectado en runtime
```

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `server.js` | La aplicación — lee `process.env.SECRET_MESSAGE` |
| `package.json` | Dependencias (express, lodash) |
| `Dockerfile` | Imagen de Node.js Alpine |
| `.github/workflows/deploy.yml` | CI/CD con OIDC → ECR → ECS Fargate |
| `.github/dependabot.yml` | Configuración de Dependabot |
| `.dockerignore` | Archivos excluidos del build Docker |

## Configuración necesaria

### En GitHub (Settings del repo):

**Variables:**
- `AWS_ROLE_ARN` → ARN del IAM role con OIDC trust policy

**Secrets:**
- `SECRET_MESSAGE` → El mensaje secreto que la app muestra

### En AWS:
- OIDC Identity Provider (`token.actions.githubusercontent.com`)
- IAM Role con trust policy para este repo
- ECS Cluster + Service + Task Definition
- ECR Repository

## Correr localmente

```bash
npm install
SECRET_MESSAGE="Mi mensaje secreto" APP_ENV=local node server.js
```

Abrir http://localhost:3000

## Seguridad habilitada

- ✅ Secret Scanning — detecta tokens en cada push
- ✅ Push Protection — bloquea pushes con secrets antes de que lleguen al repo
- ✅ Dependabot — escanea vulnerabilidades en dependencias
- ✅ OIDC — zero AWS credentials permanentes

## Charla

**Título:** "Nunca más hardcodees un token: Seguridad en GitHub para DevOps"
**Speaker:** Bianca Torres — Devops Engineer
**Evento:** GitHub Community Day
