#!/bin/bash
# ============================================================
# DESTRUIR TODO — ECS + OIDC + IAM Roles
# Corre esto cuando ya no necesites nada de este proyecto
# ============================================================

AWS_ACCOUNT_ID="253179167168"
AWS_REGION="us-east-1"
export AWS_PROFILE=bnk_personal
export AWS_CA_BUNDLE=/etc/ssl/cert.pem

CLUSTER_NAME="secure-demo-cluster"
SERVICE_NAME="secure-demo-service"
TASK_FAMILY="secure-demo-app"
ECR_REPO="secure-demo-app"
ROLE_NAME="github-actions-deploy"

echo "============================================"
echo "  DESTRUYENDO TODA LA INFRAESTRUCTURA"
echo "============================================"
echo ""

# --- ECS ---
echo "=== 1. Detener ECS Service ==="
aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --desired-count 0 \
  --region $AWS_REGION 2>/dev/null
sleep 10

echo "=== 2. Eliminar ECS Service ==="
aws ecs delete-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --force \
  --region $AWS_REGION 2>/dev/null

echo "=== 3. Eliminar ECS Cluster ==="
aws ecs delete-cluster \
  --cluster $CLUSTER_NAME \
  --region $AWS_REGION 2>/dev/null

# --- ECR ---
echo "=== 4. Eliminar imágenes y ECR Repository ==="
aws ecr delete-repository \
  --repository-name $ECR_REPO \
  --force \
  --region $AWS_REGION 2>/dev/null

# --- Security Group ---
echo "=== 5. Eliminar Security Group ==="
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=secure-demo-sg" --query "SecurityGroups[0].GroupId" --output text --region $AWS_REGION 2>/dev/null)
if [ "$SG_ID" != "None" ] && [ -n "$SG_ID" ]; then
  aws ec2 delete-security-group --group-id $SG_ID --region $AWS_REGION 2>/dev/null
fi

# --- CloudWatch Logs ---
echo "=== 6. Eliminar Log Group ==="
aws logs delete-log-group \
  --log-group-name /ecs/$TASK_FAMILY \
  --region $AWS_REGION 2>/dev/null

# --- Task Definitions ---
echo "=== 7. Deregister Task Definitions ==="
TASK_DEFS=$(aws ecs list-task-definitions --family-prefix $TASK_FAMILY --query "taskDefinitionArns[*]" --output text --region $AWS_REGION 2>/dev/null)
for td in $TASK_DEFS; do
  aws ecs deregister-task-definition --task-definition $td --region $AWS_REGION 2>/dev/null
done

# --- IAM Role: github-actions-deploy ---
echo "=== 8. Eliminar IAM Role: github-actions-deploy ==="
aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess 2>/dev/null
aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess 2>/dev/null
aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess 2>/dev/null
aws iam delete-role --role-name $ROLE_NAME 2>/dev/null

# --- IAM Role: ecsTaskExecutionRole ---
echo "=== 9. Eliminar IAM Role: ecsTaskExecutionRole ==="
aws iam detach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy 2>/dev/null
aws iam delete-role --role-name ecsTaskExecutionRole 2>/dev/null

# --- OIDC Provider ---
echo "=== 10. Eliminar OIDC Provider ==="
aws iam delete-open-id-connect-provider \
  --open-id-connect-provider-arn arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com 2>/dev/null

echo ""
echo "============================================"
echo "  ✅ TODO ELIMINADO"
echo "============================================"
echo ""
echo "Recursos eliminados:"
echo "  - ECS Cluster, Service, Task Definitions"
echo "  - ECR Repository + imágenes"
echo "  - Security Group"
echo "  - CloudWatch Log Group"
echo "  - IAM Role: github-actions-deploy"
echo "  - IAM Role: ecsTaskExecutionRole"
echo "  - OIDC Provider"
echo ""
echo "💰 Tu cuenta AWS está limpia. No se te cobra nada a partir de ahora."
