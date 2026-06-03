#!/bin/bash
# Obtener la IP pública del task de ECS
export AWS_CA_BUNDLE=/etc/ssl/cert.pem
export AWS_PROFILE=bnk_personal

CLUSTER="secure-demo-cluster"
REGION="us-east-1"

# Obtener task ARN
TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER --region $REGION --query "taskArns[0]" --output text)

if [ "$TASK_ARN" == "None" ] || [ -z "$TASK_ARN" ]; then
  echo "❌ No hay tasks corriendo en el cluster"
  exit 1
fi

# Obtener ENI ID
ENI_ID=$(aws ecs describe-tasks --cluster $CLUSTER --tasks $TASK_ARN --region $REGION --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value" --output text)

# Obtener IP pública del ENI
PUBLIC_IP=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID --region $REGION --query "NetworkInterfaces[0].Association.PublicIp" --output text)

echo ""
echo "🚀 App corriendo en:"
echo "   http://$PUBLIC_IP:3000"
echo "   http://$PUBLIC_IP:3000/secret"
echo "   http://$PUBLIC_IP:3000/health"
echo ""
