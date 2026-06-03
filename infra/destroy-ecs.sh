#!/bin/bash
# ============================================================
# DESTRUIR solo ECS/ECR (para dejar de pagar)
# NO borra OIDC ni IAM roles (son gratis)
# ============================================================

AWS_REGION="us-east-1"
export AWS_PROFILE=bnk_personal
export AWS_CA_BUNDLE=/etc/ssl/cert.pem

CLUSTER_NAME="secure-demo-cluster"
SERVICE_NAME="secure-demo-service"
TASK_FAMILY="secure-demo-app"
ECR_REPO="secure-demo-app"

echo "=== 1. Detener ECS Service ==="
aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --desired-count 0 \
  --region $AWS_REGION 2>/dev/null

echo "Esperando que los tasks se detengan..."
sleep 10

echo ""
echo "=== 2. Eliminar ECS Service ==="
aws ecs delete-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --force \
  --region $AWS_REGION 2>/dev/null

echo ""
echo "=== 3. Eliminar ECS Cluster ==="
aws ecs delete-cluster \
  --cluster $CLUSTER_NAME \
  --region $AWS_REGION 2>/dev/null

echo ""
echo "=== 4. Eliminar ECR Repository ==="
aws ecr delete-repository \
  --repository-name $ECR_REPO \
  --force \
  --region $AWS_REGION 2>/dev/null

echo ""
echo "=== 5. Eliminar Security Group ==="
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=secure-demo-sg" --query "SecurityGroups[0].GroupId" --output text --region $AWS_REGION 2>/dev/null)
if [ "$SG_ID" != "None" ] && [ -n "$SG_ID" ]; then
  aws ec2 delete-security-group --group-id $SG_ID --region $AWS_REGION 2>/dev/null
fi

echo ""
echo "=== 6. Eliminar Log Group ==="
aws logs delete-log-group \
  --log-group-name /ecs/$TASK_FAMILY \
  --region $AWS_REGION 2>/dev/null

echo ""
echo "=== 7. Deregister Task Definitions ==="
TASK_DEFS=$(aws ecs list-task-definitions --family-prefix $TASK_FAMILY --query "taskDefinitionArns[*]" --output text --region $AWS_REGION 2>/dev/null)
for td in $TASK_DEFS; do
  aws ecs deregister-task-definition --task-definition $td --region $AWS_REGION 2>/dev/null
done

echo ""
echo "=== ✅ ECS DESTRUIDO ==="
echo ""
echo "Lo que NO se eliminó (es gratis y lo necesitas):"
echo "  - OIDC Provider"
echo "  - IAM Role: github-actions-deploy"
echo "  - IAM Role: ecsTaskExecutionRole"
echo ""
echo "Para recrear: bash create-ecs.sh"
echo "Para destruir TODO: bash destroy-all.sh"
