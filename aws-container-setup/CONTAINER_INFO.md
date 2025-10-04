# Wave Container Information

## 🐳 Pre-Built Container (Ready to Use!)

Your pipeline uses a Wave-built container that's **already available** and optimized for your workflow.

### Container Image URL
```
community.wave.seqera.io/library/anndata_cellpose_celltypist_matplotlib_pruned:1b8489838d4f0190
```

### Container Details
- **Build ID**: `bd-1b8489838d4f0190_1`
- **Status**: ✅ COMPLETED
- **Platform**: linux/amd64
- **Format**: Docker
- **Digest**: `sha256:7776ecc1d45d152c5dcb5abb875b571942a04e1f70870df3a14880c7022bf5f3`

### Installed Packages
- **Python**: 3.10
- **Bioinformatics**: anndata, cellpose, celltypist, scanpy
- **Data Science**: numpy, pandas, matplotlib, seaborn
- **Image Processing**: pillow, scikit-image

---

## 📋 Container Configuration

This container is **already configured** in your `nextflow.config`:

```groovy
process {
    container = 'community.wave.seqera.io/library/anndata_cellpose_celltypist_matplotlib_pruned:1b8489838d4f0190'
}

wave {
    enabled = true
    strategy = ['conda']
}

docker {
    enabled = true
    registry = 'community.wave.seqera.io'
}
```

---

## 🚀 Using the Container

### Option 1: Direct Use with Wave (Recommended)
Wave automatically handles container distribution. No ECR setup needed!

```bash
# Run pipeline - Wave handles everything
nextflow run main.nf -profile awsbatch
```

### Option 2: Copy to AWS ECR (Optional)
If you want to host the container in your own AWS ECR, follow the instructions in `ECR_SETUP.md`.

---

## ✅ Advantages of Wave Container

1. **No Build Time**: Container is pre-built and cached
2. **Automatic Distribution**: Wave serves the container globally
3. **Optimized**: Includes only necessary dependencies
4. **Reproducible**: Locked versions ensure consistency
5. **Fast Pull**: Wave's CDN ensures quick downloads

---

## 🔍 Container Dockerfile

The container was built using this Dockerfile:

```dockerfile
FROM mambaorg/micromamba:1.5.10-noble
COPY --chown=$MAMBA_USER:$MAMBA_USER conda.yml /tmp/conda.yml
RUN micromamba install -y -n base -f /tmp/conda.yml \
    && micromamba install -y -n base conda-forge::procps-ng \
    && micromamba env export --name base --explicit > environment.lock \
    && echo ">> CONDA_LOCK_START" \
    && cat environment.lock \
    && echo "<< CONDA_LOCK_END" \
    && micromamba clean -a -y
USER root
ENV PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"
```

---

## 📦 Conda Environment

```yaml
channels:
- defaults
- conda-forge
- bioconda
dependencies:
- anndata
- cellpose
- celltypist
- matplotlib
- numpy
- pandas
- pillow
- python=3.10
- scanpy
- scikit-image
- seaborn
```

---

## 🆘 Troubleshooting

### Container Pull Fails
```bash
# Test container pull
docker pull community.wave.seqera.io/library/anndata_cellpose_celltypist_matplotlib_pruned:1b8489838d4f0190

# Check Wave service status
curl -I https://community.wave.seqera.io
```

### AWS Batch Can't Pull Container
- Ensure compute environment has internet access
- Check security groups allow outbound HTTPS (port 443)
- Verify NAT Gateway is configured for private subnets

### Need Different Packages?
Rebuild container with new packages:
```bash
# Use Wave to build with additional packages
wave --conda-package "your-package=version" \
     --conda-package "another-package" \
     community.wave.seqera.io
```
