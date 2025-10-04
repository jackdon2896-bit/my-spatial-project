#!/bin/bash
set -e

# Configuration
AWS_REGION="ap-south-1"
ECR_REPO_NAME="spatial-transcriptomics-pipeline"
WAVE_IMAGE="community.wave.seqera.io/library/anndata_cellpose_celltypist_matplotlib_pruned:1b8489838d4f0190"
VERSION="v1.0.0"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get AWS Account ID
echo -e "${BLUE}🔍 Getting AWS Account ID...${NC}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✅ Account ID: ${AWS_ACCOUNT_ID}${NC}"

# ECR Repository URI
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

echo -e "\n${BLUE}🚀 Starting ECR push process...${NC}"
echo -e "${YELLOW}Wave Image: ${WAVE_IMAGE}${NC}"
echo -e "${YELLOW}Target ECR: ${ECR_URI}${NC}\n"

# Create repository (ignore if exists)
echo -e "${BLUE}📦 Creating ECR repository...${NC}"
if aws ecr create-repository \
    --repository-name ${ECR_REPO_NAME} \
    --region ${AWS_REGION} \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256 2>/dev/null; then
    echo -e "${GREEN}✅ Repository created successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Repository already exists (this is fine)${NC}"
fi

# Login to ECR
echo -e "\n${BLUE}🔐 Authenticating with ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${ECR_URI}
echo -e "${GREEN}✅ Authentication successful${NC}"

# Pull Wave container
echo -e "\n${BLUE}⬇️  Pulling Wave container...${NC}"
docker pull ${WAVE_IMAGE}
echo -e "${GREEN}✅ Container pulled successfully${NC}"

# Tag for ECR
echo -e "\n${BLUE}🏷️  Tagging container...${NC}"
docker tag ${WAVE_IMAGE} ${ECR_URI}:latest
docker tag ${WAVE_IMAGE} ${ECR_URI}:${VERSION}
echo -e "${GREEN}✅ Tags created: latest, ${VERSION}${NC}"

# Push to ECR
echo -e "\n${BLUE}⬆️  Pushing to ECR (this may take a few minutes)...${NC}"
docker push ${ECR_URI}:latest
docker push ${ECR_URI}:${VERSION}

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Container successfully pushed to ECR!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${BLUE}📍 ECR Repository URI:${NC}"
echo -e "   ${ECR_URI}:latest"
echo -e "   ${ECR_URI}:${VERSION}\n"

echo -e "${YELLOW}📝 Update your nextflow.config with:${NC}"
echo -e "${BLUE}process {${NC}"
echo -e "${BLUE}    container = '${ECR_URI}:latest'${NC}"
echo -e "${BLUE}}${NC}\n"

# List images in ECR
echo -e "${BLUE}🔍 Verifying images in ECR...${NC}"
aws ecr describe-images \
    --repository-name ${ECR_REPO_NAME} \
    --region ${AWS_REGION} \
    --output table

echo -e "\n${GREEN}✅ All done! Your container is ready to use in AWS Batch.${NC}"
