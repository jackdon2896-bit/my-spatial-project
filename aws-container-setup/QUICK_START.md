# 🚀 Quick Start Guide

## Container is Ready!

Your Wave container is **already built and available**. No ECR setup needed to get started!

---

## ⚡ Run Pipeline Immediately (No Setup Required)

### Option 1: Use Wave Container (Recommended - Zero Setup!)

```bash
# Navigate to pipeline directory
cd my-spatial-project

# Run with test data
nextflow run main.nf \
    --input_image "s3://your-bucket/sample.tif" \
    --output_dir "s3://your-bucket/results" \
    -profile awsbatch \
    -work-dir "s3://your-bucket/work"
```

**That's it!** Wave automatically:
- ✅ Distributes the container to AWS Batch
- ✅ Handles authentication
- ✅ Caches for fast subsequent runs

---

## 📦 Option 2: Host in Your Own ECR (Optional)

If you prefer to host the container in AWS ECR:

### Quick ECR Push (3 commands)

```bash
# 1. Make script executable
chmod +x aws-container-setup/push-to-ecr.sh

# 2. Run the push script
./aws-container-setup/push-to-ecr.sh

# 3. Update nextflow.config with the ECR URI shown at the end
```

See `ECR_SETUP.md` for detailed instructions.

---

## 🧪 Test Pipeline Locally

Before running on AWS Batch, test locally with Docker:

```bash
# Test with Docker
nextflow run main.nf \
    --input_image "test_data/sample.tif" \
    --output_dir "results" \
    -profile docker

# Test specific process
nextflow run main.nf -entry SEGMENT_CELLS
```

---

## 🔍 Container Details

**Wave Container URI:**
```
community.wave.seqera.io/library/anndata_cellpose_celltypist_matplotlib_pruned:1b8489838d4f0190
```

**What's inside:**
- Python 3.10
- Cellpose (cell segmentation)
- CellTypist (cell type annotation)
- Scanpy (single-cell analysis)
- AnnData, NumPy, Pandas
- Matplotlib, Seaborn
- Pillow, scikit-image

---

## 📋 Pre-Flight Checklist

Before running on AWS Batch, ensure you have:

### AWS Resources
- [ ] S3 bucket for work directory (`s3://your-bucket/work/`)
- [ ] AWS Batch compute environment (configured)
- [ ] AWS Batch job queue (active)
- [ ] IAM roles with proper permissions

### Pipeline Configuration
- [ ] Updated `nextflow.config` with your AWS settings
- [ ] Set correct AWS region (`ap-south-1` or your region)
- [ ] Configured S3 bucket paths
- [ ] Set appropriate compute resources

### Input Data
- [ ] Input images in S3 or accessible location
- [ ] Sample sheet prepared (if using batch processing)
- [ ] Output directory specified

---

## 🎯 Example Run Commands

### Single Image Processing
```bash
nextflow run main.nf \
    --input_image "s3://my-bucket/images/sample.tif" \
    --output_dir "s3://my-bucket/results/run1" \
    --cellpose_model "cyto2" \
    --cellpose_diameter 30 \
    -profile awsbatch \
    -work-dir "s3://my-bucket/work" \
    -resume
```

### Batch Processing with Sample Sheet
```bash
nextflow run main.nf \
    --samplesheet "s3://my-bucket/samplesheet.csv" \
    --output_dir "s3://my-bucket/results/batch1" \
    -profile awsbatch \
    -work-dir "s3://my-bucket/work" \
    -resume
```

### Test Run with Small Dataset
```bash
nextflow run main.nf \
    --input_image "s3://my-bucket/test/small.tif" \
    --output_dir "s3://my-bucket/test-results" \
    --cellpose_diameter 20 \
    -profile awsbatch \
    -work-dir "s3://my-bucket/work" \
    -with-report report.html \
    -with-timeline timeline.html
```

---

## 📊 Monitoring Your Run

### View Progress
```bash
# Nextflow shows real-time progress
[12/25] SEGMENT_CELLS (sample1) [100%] 1 of 1 ✔
[13/25] EXTRACT_FEATURES (sample1) [100%] 1 of 1 ✔
[14/25] CLUSTER_CELLS (sample1) [  0%] 0 of 1
```

### Check AWS Batch Console
1. Go to AWS Batch Console: https://console.aws.amazon.com/batch/
2. Select region: `ap-south-1`
3. View Jobs → See your pipeline tasks
4. Click job ID → View logs in CloudWatch

### Access Reports
After completion, Nextflow generates:
- `report.html` - Execution report with metrics
- `timeline.html` - Timeline of task execution
- `trace.txt` - Detailed execution trace

---

## 🛠️ Troubleshooting

### Container Issues
```bash
# Test container pull locally
docker pull community.wave.seqera.io/library/anndata_cellpose_celltypist_matplotlib_pruned:1b8489838d4f0190

# Run container interactively
docker run -it --rm \
    community.wave.seqera.io/library/anndata_cellpose_celltypist_matplotlib_pruned:1b8489838d4f0190 \
    /bin/bash

# Test Python packages
python -c "import cellpose; import scanpy; print('OK')"
```

### Pipeline Syntax Check
```bash
# Validate Nextflow syntax
nextflow run main.nf -preview

# Dry run (no execution)
nextflow run main.nf -profile docker -dump-channels
```

### AWS Batch Issues
See the main `README.md` troubleshooting section for:
- Compute environment stuck in INVALID state
- Jobs stuck in RUNNABLE state
- Permission errors
- S3 access issues

---

## 📈 Performance Tips

### Optimize Costs
1. **Use Spot Instances**: Configure in AWS Batch compute environment
2. **Right-size Resources**: Adjust CPU/memory in `nextflow.config`
3. **Use -resume**: Restart from last successful step on failures
4. **Batch Processing**: Process multiple samples in parallel

### Speed Up Execution
1. **Increase Parallelism**: Set `maxParallelTransfers` in config
2. **Use Fusion**: Enable Fusion file system for faster S3 access
3. **Optimize Work Directory**: Use same region as compute
4. **Cache Wave Container**: First run caches for subsequent runs

---

## 🎓 Next Steps

1. **Test Locally**: Run with small dataset using Docker profile
2. **Configure AWS**: Set up Batch compute environment and IAM roles
3. **Pilot Run**: Test with 1-2 samples on AWS Batch
4. **Scale Up**: Process full dataset after validation
5. **Optimize**: Tune resources based on metrics from pilot run

---

## 📚 Documentation

- **Container Details**: `CONTAINER_INFO.md`
- **ECR Setup**: `ECR_SETUP.md` (optional)
- **Pipeline Documentation**: `../README.md`
- **Nextflow Docs**: https://www.nextflow.io/docs/latest/

---

## ✅ Summary

✨ **Your container is ready to use right now!**

**To run immediately:**
```bash
nextflow run main.nf --input_image <path> --output_dir <path> -profile awsbatch
```

**No additional setup required** - Wave handles everything automatically!

For ECR hosting (optional), run:
```bash
./aws-container-setup/push-to-ecr.sh
```

---

**Questions?** Check the documentation files in this folder or the main `README.md`.

**Ready to go? Let's run the pipeline!** 🚀
