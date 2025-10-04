# Spatial Transcriptomics Analysis Pipeline

A comprehensive Nextflow DSL2 pipeline for integrated spatial transcriptomics analysis combining image processing, cell segmentation, scRNA-seq analysis, and spatial data integration.

## Pipeline Overview

This pipeline processes tissue imaging data (TIFF) and single-cell RNA-seq data (H5) through the following workflow:

### Image Processing Branch
1. **PREPROCESS_IMAGE** - Image preprocessing and hole filling
2. **CELLPOSE_SEGMENT** - Deep learning-based cell segmentation using Cellpose
3. **AI_ROI_CROP** - AI-guided region of interest extraction with coordinate tracking

### scRNA-seq Analysis Branch
4. **SCRNA_QC** - Quality control metrics calculation
5. **SCRNA_MAD_FILTER** - MAD (Median Absolute Deviation) filtering
6. **SCRNA_DIM_REDUCTION** - Dimensionality reduction (PCA/UMAP)
7. **SCRNA_CLUSTER** - Cell clustering analysis
8. **SCRNA_ANNOTATE** - Automated cell type annotation using CellTypist

### Spatial Integration
9. **SPATIAL_REFINE** - Spatial refinement of cell type annotations
10. **SPATIAL_INTEGRATION** - Integration of image and scRNA-seq data

### Visualization
11. **SCRNA_PLOTS** - Cell type and clustering visualizations
12. **SPATIAL_PLOTS** - Spatial distribution plots
13. **REPORT** - Comprehensive markdown report generation

## Quick Start

### Prerequisites
- Nextflow ≥ 25.04.7
- Docker or AWS Batch access
- Input data:
  - TIFF image file (tissue imaging)
  - H5 file (scRNA-seq feature matrix)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd my-spatial-project

# Test the pipeline locally (with Docker)
nextflow run main.nf -profile docker \
    --tiff data/image.tif \
    --h5 data/matrix.h5 \
    --outdir results/
```

### AWS Batch Execution

The pipeline is pre-configured for AWS Batch execution in the `ap-south-1` region.

```bash
nextflow run main.nf \
    --tiff s3://your-bucket/path/to/image.tif \
    --h5 s3://your-bucket/path/to/matrix.h5 \
    --outdir s3://your-bucket/results/
```

## Configuration

### Input Parameters

Edit `nextflow.config` or provide via command line:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--tiff` | Path to TIFF image file | `s3://tiffimage/tiffimage/lungstiff.tif` |
| `--h5` | Path to H5 scRNA-seq data | `s3://tiffimage/tiffimage/lungsfeaturematrix.h5` |
| `--outdir` | Output directory path | `s3://tiffimage/results/` |

### Resource Configuration

Process-specific resources are defined in `nextflow.config`:

- **CELLPOSE_SEGMENT**: 4 CPUs, 16 GB RAM, 4h timeout (most resource-intensive)
- **SCRNA_ANNOTATE**: 2 CPUs, 8 GB RAM, 3h timeout
- **Dimensionality reduction & clustering**: 2 CPUs, 8 GB RAM
- **Default processes**: 2 CPUs, 4 GB RAM, 2h timeout

Adjust these based on your data size and computational resources.

### Container Management

The pipeline uses **Wave** to automatically build and cache optimized containers with all dependencies:

```
Container: community.wave.seqera.io/library/anndata_cellpose_celltypist_matplotlib_pruned:1b8489838d4f0190
```

**Included packages:**
- Python 3.10
- Image processing: numpy, scikit-image, pillow
- Deep learning: cellpose
- scRNA-seq: scanpy, anndata, celltypist
- Visualization: matplotlib, seaborn

Wave is enabled by default. To disable and use a custom container:

```groovy
wave {
    enabled = false
}

process {
    container = 'your-dockerhub/custom-image:tag'
}
```

## AWS Setup

### 1. S3 Bucket Configuration

```bash
# Create bucket for data and results
aws s3 mb s3://your-pipeline-bucket --region ap-south-1

# Upload input data
aws s3 cp image.tif s3://your-pipeline-bucket/data/
aws s3 cp matrix.h5 s3://your-pipeline-bucket/data/
```

### 2. AWS Batch Configuration

Required AWS Batch resources (create via AWS Console or CloudFormation):

1. **Compute Environment**
   - Type: EC2 or Fargate
   - Instance types: c5.xlarge, r5.xlarge (or larger for big datasets)
   - Min vCPUs: 0, Max vCPUs: 256 (adjust based on needs)

2. **Job Queue**
   - Connect to your compute environment
   - Priority: 1

3. **IAM Roles**
   - Batch service role with S3 access
   - EC2 instance role with ECR and S3 permissions

### 3. Update Configuration

Edit `nextflow.config`:

```groovy
aws {
    region = 'ap-south-1'  // Change to your region
    batch {
        cliPath = '/home/ec2-user/miniconda/bin/aws'
        jobRole = 'arn:aws:iam::ACCOUNT:role/your-batch-job-role'
        volumes = '/docker_scratch'
    }
}

params {
    tiff = "s3://your-pipeline-bucket/data/image.tif"
    h5 = "s3://your-pipeline-bucket/data/matrix.h5"
    outdir = "s3://your-pipeline-bucket/results/"
}
```

### 4. Launch Pipeline

```bash
nextflow run main.nf \
    -work-dir s3://your-pipeline-bucket/work \
    -bucket-dir s3://your-pipeline-bucket/nextflow
```

## Output Structure

```
results/
├── preprocessed/          # Filled images
│   └── filled.tif
├── segmentation/          # Cell masks
│   └── mask.png
├── roi/                   # Region of interest data
│   ├── roi.tif
│   └── coords.csv
├── qc/                    # QC metrics
│   └── qc.h5ad
├── filtered/              # Filtered cells
│   └── filtered.h5ad
├── dimred/                # Dimensionality reduction
│   └── reduced.h5ad
├── clusters/              # Clustering results
│   └── clustered.h5ad
├── annotated/             # Cell type annotations
│   └── annotated.h5ad
├── refined/               # Spatially refined annotations
│   └── refined.h5ad
├── integrated/            # Final integrated data
│   └── integrated.h5ad
├── plots/                 # scRNA-seq visualizations
│   ├── celltype.png
│   ├── refined.png
│   └── heatmap.png
├── spatial_plots/         # Spatial visualizations
│   └── spatial_*.png
└── report/                # Final report
    └── report.md
```

## Troubleshooting

### Common Issues

**1. Out of Memory Errors**
- Increase memory for specific processes in `nextflow.config`
- Use larger EC2 instance types in AWS Batch

**2. Cellpose Segmentation Fails**
- Ensure sufficient CPUs (4+) and memory (16 GB+)
- Check input image format and quality

**3. AWS Batch Job Stuck in RUNNABLE**
- Verify compute environment has sufficient max vCPUs
- Check instance availability in your region
- Review IAM permissions

**4. S3 Access Denied**
- Verify IAM role has S3 read/write permissions
- Check bucket policies and CORS settings

### Monitoring

```bash
# View pipeline execution
nextflow log

# View specific run details
nextflow log <run-name> -f name,status,duration,realtime

# Check AWS Batch jobs
aws batch list-jobs --job-queue <queue-name> --region ap-south-1
```

## Development

### Adding New Processes

1. Create Python script in `bin/` directory
2. Add process definition in `main.nf`
3. Configure resources in `nextflow.config`
4. Update workflow to include new process

### Testing

```bash
# Test with small dataset
nextflow run main.nf -profile test

# Resume failed runs
nextflow run main.nf -resume

# Clean work directory
nextflow clean -f
```

## Citations

If you use this pipeline, please cite:

- **Nextflow**: Di Tommaso, P., et al. (2017). Nextflow enables reproducible computational workflows. Nature Biotechnology.
- **Cellpose**: Stringer, C., et al. (2021). Cellpose: a generalist algorithm for cellular segmentation. Nature Methods.
- **Scanpy**: Wolf, F.A., et al. (2018). SCANPY: large-scale single-cell gene expression data analysis. Genome Biology.
- **CellTypist**: Domínguez Conde, C., et al. (2022). Cross-tissue immune cell analysis reveals tissue-specific features in humans. Science.

## License

[Specify your license here]

## Contact

[Your contact information or team details]

## Acknowledgments

Built with Nextflow DSL2 and optimized for AWS Batch execution with Wave container integration.
