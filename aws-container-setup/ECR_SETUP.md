# AWS ECR Setup Guide

## 📦 Push Wave Container to AWS ECR (Optional)

While Wave automatically distributes containers, you may want to host the container in your own AWS ECR for:
- **Air-gapped environments** (no internet access)
- **Corporate policies** requiring internal registries
- **Cost optimization** for large-scale runs
- **Full control** over container lifecycle

---

## 🔧 Prerequisites

1. **AWS CLI** installed and configured
2. **Docker** running locally
3. **IAM permissions** for ECR operations
4. **AWS Account ID** and **Region** (we'll use `ap-south-1`)

---

## 📋 Step-by-Step Instructions

### Step 1: Install AWS CLI (if not installed)

```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

### Step 2: Configure AWS Credentials

```bash
# Configure with your credentials
aws configure

# You'll be prompted for:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (use: ap-south-1)
# - Output format (use: json)
```

### Step 3: Create ECR Repository

```bash
# Set variables
export AWS_REGION="ap-south-1"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REPO_NAME="spatial-transcriptomics-pipeline"

# Create ECR repository
aws ecr create-repository \
    --repository-name ${ECR_REPO_NAME} \
    --region ${AWS_REGION} \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256

# Output will show:
# {
#     "repository": {
#         "repositoryArn": "arn:aws:ecr:ap-south-1:XXXXXXXXXXXX:repository/spatial-transcriptomics-pipeline",
#         "repositoryUri": "XXXXXXXXXXXX.dkr.ecr.ap-south-1.amazonaws.com/spatial-transcriptomics-pipeline"
#     }
# }
```

### Step 4: Authenticate Docker to ECR

```bash
# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin \
    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Expected output: Login Succeeded
```

### Step 5: Pull Wave Container

```bash
# Pull the Wave-built container
docker pull community.wave.seqera.io/library/anndata_cellpose_celltypist_matplotlib_pruned:1b8489838d4f0190

# Verify pull
docker images | grep wave
```

### Step 6: Tag Container for ECR

```bash
# Tag the Wave container for your ECR
docker tag \
    community.wave.seqera.io/library/anndata_cellpose_celltypist_matplotlib_pruned:1b8489838d4f0190 \
    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest

# Tag with version
docker tag \
    community.wave.seqera.io/library/anndata_cellpose_celltypist_matplotlib_pruned:1b8489838d4f0190 \
    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:v1.0.0
```

### Step 7: Push to ECR

```bash
# Push latest tag
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest

# Push version tag
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:v1.0.0

# This will take a few minutes depending on your internet speed
```

### Step 8: Verify Upload

```bash
# List images in ECR
aws ecr describe-images \
    --repository-name ${ECR_REPO_NAME} \
    --region ${AWS_REGION}

# Get repository URI
aws ecr describe-repositories \
    --repository-names ${ECR_REPO_NAME} \
    --region ${AWS_REGION} \
    --query 'repositories[0].repositoryUri' \
    --output text
```

---

## 🔄 Update Nextflow Config to Use ECR

Once pushed to ECR, update your `nextflow.config`:

```groovy
// Replace the Wave container with your ECR container
process {
    container = 'XXXXXXXXXXXX.dkr.ecr.ap-south-1.amazonaws.com/spatial-transcriptomics-pipeline:latest'
}

// Update AWS configuration
aws {
    region = 'ap-south-1'
    batch {
        cliPath = '/home/ec2-user/miniconda/bin/aws'
        jobRole = 'arn:aws:iam::XXXXXXXXXXXX:role/BatchJobRole'
        executionRole = 'arn:aws:iam::XXXXXXXXXXXX:role/BatchExecutionRole'
    }
}

docker {
    enabled = true
    // ECR authentication is handled automatically by AWS Batch
}
```

---

## 🔐 IAM Permissions Required

Your AWS Batch **Job Role** needs permission to pull from ECR:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage"
            ],
            "Resource": "*"
        }
    ]
}
```

### Apply Policy to Batch Job Role

```bash
# Create policy document
cat > ecr-pull-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage"
            ],
            "Resource": "*"
        }
    ]
}
EOF

# Create IAM policy
aws iam create-policy \
    --policy-name ECRPullPolicy \
    --policy-document file://ecr-pull-policy.json

# Attach to your Batch Job Role (replace with your role name)
aws iam attach-role-policy \
    --role-name BatchJobRole \
    --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/ECRPullPolicy
```

---

## 💰 Cost Considerations

### ECR Storage Costs (ap-south-1 region)
- **Storage**: ~$0.10 per GB/month
- **Data Transfer OUT**: $0.00 (within same region to AWS Batch)

### Example Cost Calculation
- Container size: ~2 GB
- Monthly storage cost: ~$0.20
- Data transfer to Batch: $0.00
- **Total monthly cost**: ~$0.20

### Wave Container (Free Alternative)
- No storage costs
- Free CDN distribution
- Automatic caching

---

## 🔄 Automated ECR Push Script

Save this as `push-to-ecr.sh`:

```bash
#!/bin/bash
set -e

# Configuration
AWS_REGION="ap-south-1"
ECR_REPO_NAME="spatial-transcriptomics-pipeline"
WAVE_IMAGE="community.wave.seqera.io/library/anndata_cellpose_celltypist_matplotlib_pruned:1b8489838d4f0190"
VERSION="v1.0.0"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# ECR Repository URI
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

echo "🚀 Starting ECR push process..."

# Create repository (ignore if exists)
echo "📦 Creating ECR repository..."
aws ecr create-repository \
    --repository-name ${ECR_REPO_NAME} \
    --region ${AWS_REGION} \
    --image-scanning-configuration scanOnPush=true 2>/dev/null || echo "Repository already exists"

# Login to ECR
echo "🔐 Authenticating with ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${ECR_URI}

# Pull Wave container
echo "⬇️  Pulling Wave container..."
docker pull ${WAVE_IMAGE}

# Tag for ECR
echo "🏷️  Tagging container..."
docker tag ${WAVE_IMAGE} ${ECR_URI}:latest
docker tag ${WAVE_IMAGE} ${ECR_URI}:${VERSION}

# Push to ECR
echo "⬆️  Pushing to ECR..."
docker push ${ECR_URI}:latest
docker push ${ECR_URI}:${VERSION}

echo "✅ Container successfully pushed to ECR!"
echo "📍 ECR URI: ${ECR_URI}:latest"
echo ""
echo "Update your nextflow.config with:"
echo "  container = '${ECR_URI}:latest'"
```

Make it executable and run:

```bash
chmod +x push-to-ecr.sh
./push-to-ecr.sh
```

---

## 🆘 Troubleshooting

### Error: "no basic auth credentials"
```bash
# Re-authenticate
aws ecr get-login-password --region ap-south-1 | \
    docker login --username AWS --password-stdin \
    ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com
```

### Error: "RepositoryAlreadyExistsException"
This is normal if the repository already exists. Continue with the push.

### Error: "denied: Your authorization token has expired"
```bash
# Tokens expire after 12 hours - re-login
aws ecr get-login-password --region ap-south-1 | \
    docker login --username AWS --password-stdin \
    ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com
```

### AWS Batch Can't Pull from ECR
1. Check Job Role has ECR permissions (see IAM section above)
2. Verify compute environment is in the same region (ap-south-1)
3. Check security groups allow outbound traffic

---

## 🔍 Verify Container Works

Test the container locally before using in AWS:

```bash
# Run container interactively
docker run -it --rm \
    ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/spatial-transcriptomics-pipeline:latest \
    /bin/bash

# Test Python packages
python -c "import cellpose; import scanpy; import celltypist; print('All packages loaded!')"

# Exit container
exit
```

---

## 📚 Additional Resources

- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [AWS Batch with ECR](https://docs.aws.amazon.com/batch/latest/userguide/ECR_URIs.html)
- [Wave Documentation](https://www.nextflow.io/docs/latest/wave.html)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
