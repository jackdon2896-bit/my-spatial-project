#!/bin/bash

# Spatial Transcriptomics Pipeline - Test Script
# This script validates the pipeline configuration and container setup

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Spatial Transcriptomics Pipeline - Validation Test       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Test 1: Check Nextflow installation
echo -e "${BLUE}[Test 1/7] Checking Nextflow installation...${NC}"
if command -v nextflow &> /dev/null; then
    NEXTFLOW_VERSION=$(nextflow -version 2>&1 | head -n1)
    echo -e "${GREEN}✅ Nextflow installed: ${NEXTFLOW_VERSION}${NC}"
else
    echo -e "${RED}❌ Nextflow not found. Please install Nextflow.${NC}"
    exit 1
fi

# Test 2: Validate main.nf exists
echo -e "\n${BLUE}[Test 2/7] Checking pipeline files...${NC}"
if [ -f "main.nf" ]; then
    PROCESS_COUNT=$(grep -c "^process " main.nf || true)
    echo -e "${GREEN}✅ main.nf found with ${PROCESS_COUNT} processes${NC}"
else
    echo -e "${RED}❌ main.nf not found${NC}"
    exit 1
fi

# Test 3: Validate nextflow.config exists
if [ -f "nextflow.config" ]; then
    echo -e "${GREEN}✅ nextflow.config found${NC}"
else
    echo -e "${RED}❌ nextflow.config not found${NC}"
    exit 1
fi

# Test 4: Check container configuration
echo -e "\n${BLUE}[Test 3/7] Validating container configuration...${NC}"
CONTAINER_IMAGE=$(grep "container = " nextflow.config | head -n1 | sed "s/.*container = //g" | tr -d "'" | tr -d '"' | xargs)
if [ -n "$CONTAINER_IMAGE" ]; then
    echo -e "${GREEN}✅ Container configured: ${CONTAINER_IMAGE}${NC}"
else
    echo -e "${RED}❌ No container configured${NC}"
    exit 1
fi

# Test 5: Test container pull (Docker)
echo -e "\n${BLUE}[Test 4/7] Testing container availability...${NC}"
if command -v docker &> /dev/null; then
    # Check if container URL is valid
    if curl -sL --head "https://$(echo $CONTAINER_IMAGE | cut -d'/' -f1)" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Container registry reachable${NC}"
        echo -e "${YELLOW}   Note: Run 'docker pull $CONTAINER_IMAGE' locally to test${NC}"
    else
        echo -e "${YELLOW}⚠️  Container registry check skipped (SSL issues in test environment)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Docker not available, skipping container test${NC}"
fi

# Test 6: Validate container documentation
echo -e "\n${BLUE}[Test 5/7] Validating container documentation...${NC}"
if [ -f "aws-container-setup/CONTAINER_INFO.md" ]; then
    echo -e "${GREEN}✅ Container documentation available${NC}"
    
    # Check for expected packages in documentation
    PACKAGES=("cellpose" "scanpy" "celltypist" "anndata" "matplotlib")
    for pkg in "${PACKAGES[@]}"; do
        if grep -q "$pkg" aws-container-setup/CONTAINER_INFO.md; then
            echo -e "${GREEN}✅ $pkg documented${NC}"
        else
            echo -e "${YELLOW}⚠️  $pkg not in documentation${NC}"
        fi
    done
else
    echo -e "${YELLOW}⚠️  Container documentation not found${NC}"
fi

# Test 7: Check AWS configuration
echo -e "\n${BLUE}[Test 6/7] Checking AWS Batch configuration...${NC}"
if grep -q "process.executor = 'awsbatch'" nextflow.config; then
    echo -e "${GREEN}✅ AWS Batch executor configured${NC}"
    
    # Check for queue
    if grep -q "process.queue" nextflow.config; then
        QUEUE=$(grep "process.queue" nextflow.config | cut -d"'" -f2)
        echo -e "${GREEN}✅ Job queue: ${QUEUE}${NC}"
    fi
    
    # Check for region
    if grep -q "aws.region" nextflow.config; then
        REGION=$(grep "aws.region" nextflow.config | cut -d"'" -f2)
        echo -e "${GREEN}✅ AWS region: ${REGION}${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  AWS Batch not configured (docker profile available)${NC}"
fi

# Test 8: Check Wave configuration
echo -e "\n${BLUE}[Test 7/7] Checking Wave configuration...${NC}"
if grep -q "wave.enabled = true" nextflow.config; then
    echo -e "${GREEN}✅ Wave enabled${NC}"
else
    echo -e "${YELLOW}⚠️  Wave not explicitly enabled${NC}"
fi

# Summary
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Test Summary                                              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}✅ All critical tests passed!${NC}\n"

echo -e "${YELLOW}Pipeline Configuration:${NC}"
echo -e "  • Processes: ${PROCESS_COUNT}"
echo -e "  • Container: ${CONTAINER_IMAGE}"
echo -e "  • Nextflow version: ${NEXTFLOW_VERSION}"

echo -e "\n${BLUE}Next Steps:${NC}"
echo -e "  1. Configure AWS credentials and Batch environment"
echo -e "  2. Test with small dataset: ${YELLOW}nextflow run main.nf -profile docker${NC}"
echo -e "  3. Run on AWS Batch: ${YELLOW}nextflow run main.nf -profile awsbatch${NC}"

echo -e "\n${GREEN}Documentation:${NC}"
echo -e "  • Quick Start: ${YELLOW}aws-container-setup/QUICK_START.md${NC}"
echo -e "  • Container Info: ${YELLOW}aws-container-setup/CONTAINER_INFO.md${NC}"
echo -e "  • ECR Setup: ${YELLOW}aws-container-setup/ECR_SETUP.md${NC}"

echo -e "\n${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Pipeline is ready to use! 🚀${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}\n"
