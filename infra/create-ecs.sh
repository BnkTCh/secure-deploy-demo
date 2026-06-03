#!/bin/bash
# ============================================================
# CREAR infraestructura de ECS (lo que cuesta dinero)
# Corre esto cuando quieras ensayar o el día de la charla
# Prerequisito: haber corrido setup-oidc.sh al menos una vez
# ============================================================

AWS_ACCOUNT_ID="253179167168"
AWS_REGION="us-east-1"
export AWS_PROFILE=bnk_personal
export AWS_CA_BUNDLE=/etc/ssl/cert.pem

CLUSTER_NAME="secure-demo-cluster"
SERVICE_NAME="secure-demo-service"
TASK_FAMILY="secure-demo-app"
ECR_REPO="secure-demo-app"
CONTAINER_NAME="secure-demo-app"
SECRET_MESSAGE="Hola desde GitHub Community Day! Este secreto nunca estuvo en el codigo 🔐"

echo "=== 1. Crear ECR Repository ==="
aws ecr create-repository \
  --repository-name $ECR_REPO \
  --region $AWS_REGION 2>/dev/null || echo "  → ECR repo ya existe"

echo ""
echo "=== 2. Crear ECS Cluster ==="
aws ecs create-cluster \
  --cluster-name $CLUSTER_NAME \
  --region $AWS_REGION

echo ""
echo "=== 3. Crear CloudWatch Log Group ==="
aws logs create-log-group \
  --log-group-name /ecs/$TASK_FAMILY \
  --region $AWS_REGION 2>/dev/null || echo "  → Log group ya existe"

echo ""
echo "=== 4. Registrar Task Definition ==="
cat > /tmp/task-definition.json << EOF
{
  "family": "$TASK_FAMILY",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "$CONTAINER_NAME",
      "image": "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {"name": "APP_ENV", "value": "production"},
        {"name": "SECRET_MESSAGE", "value": "$SECRET_MESSAGE"},
        {"name": "PORT", "value": "3000"}
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/$TASK_FAMILY",
          "awslogs-region": "$AWS_REGION",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
EOF

aws ecs register-task-definition \
  --cli-input-json file:///tmp/task-definition.json \
  --region $AWS_REGION

echo ""
echo "=== 5. Configurar Networking ==="
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text --region $AWS_REGION)
SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text --region $AWS_REGION | tr '\t' ',')
echo "  VPC: $VPC_ID"
echo "  Subnets: $SUBNETS"

SG_ID=$(aws ec2 create-security-group \
  --group-name secure-demo-sg \
  --description "Security group for secure-demo-app" \
  --vpc-id $VPC_ID \
  --query "GroupId" --output text \
  --region $AWS_REGION 2>/dev/null || aws ec2 describe-security-groups --filters "Name=group-name,Values=secure-demo-sg" --query "SecurityGroups[0].GroupId" --output text --region $AWS_REGION)

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 3000 \
  --cidr 0.0.0.0/0 \
  --region $AWS_REGION 2>/dev/null || echo "  → Ingress rule ya existe"

echo "  Security Group: $SG_ID"

echo ""
echo "=== 6. Crear ECS Service ==="
SUBNET_1=$(echo $SUBNETS | cut -d',' -f1)
SUBNET_2=$(echo $SUBNETS | cut -d',' -f2)

aws ecs create-service \
  --cluster $CLUSTER_NAME \
  --service-name $SERVICE_NAME \
  --task-definition $TASK_FAMILY \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
  --region $AWS_REGION

echo ""
echo "=== ✅ ECS CREADO ==="
echo ""
echo "Cluster: $CLUSTER_NAME"
echo "Service: $SERVICE_NAME"
echo "ECR: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"
echo ""
echo "⚠️  El service va a fallar hasta que pushees una imagen a ECR."
echo "    Corre el workflow de GitHub Actions para hacer el primer deploy."
echo ""
echo "Después usa: bash get-ip.sh para obtener la URL de la app."
