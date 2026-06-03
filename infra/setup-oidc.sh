#!/bin/bash
# ============================================================
# Setup OIDC + IAM Roles (gratis, se corre una sola vez)
# ============================================================

AWS_ACCOUNT_ID="253179167168"
AWS_REGION="us-east-1"
GITHUB_REPO="BnkTCh/secure-deploy-demo"
ROLE_NAME="github-actions-deploy"

export AWS_PROFILE=bnk_personal
export AWS_CA_BUNDLE=/etc/ssl/cert.pem

echo "=== 1. Crear OIDC Identity Provider ==="
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 2>/dev/null || echo "  → OIDC Provider ya existe"

echo ""
echo "=== 2. Crear IAM Role: github-actions-deploy ==="
cat > /tmp/trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF

aws iam create-role \
  --role-name $ROLE_NAME \
  --assume-role-policy-document file:///tmp/trust-policy.json 2>/dev/null || echo "  → Role ya existe"

aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess 2>/dev/null
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess 2>/dev/null
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess 2>/dev/null

echo ""
echo "=== 3. Crear IAM Role: ecsTaskExecutionRole ==="
cat > /tmp/ecs-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file:///tmp/ecs-trust-policy.json 2>/dev/null || echo "  → Role ya existe"

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy 2>/dev/null

echo ""
echo "=== ✅ OIDC + IAM LISTO ==="
echo ""
echo "Role ARN: arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
echo ""
echo "Configura en GitHub:"
echo "  Settings → Variables → AWS_ROLE_ARN = arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
echo "  Settings → Secrets → SECRET_MESSAGE = (tu mensaje secreto)"
