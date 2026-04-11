#!/usr/bin/env python3
import sys
import tifffile as tf
import numpy as np
import matplotlib.pyplot as plt

def process_scrna_tiff(input_path, output_tiff, output_png):
    # Load 16-bit image
    img = tf.imread(input_path)
    
    # 1. Lossless Crop
    if img.ndim == 3:
        cropped = img[:, 0:2000, 0:2000]
        # For preview, use first channel or mean of channels
        preview_data = cropped[0] if cropped.shape[0] > 0 else cropped
    else:
        cropped = img[0:2000, 0:2000]
        preview_data = cropped
        
    # 2. Save Analysis-Ready TIFF (Compressed)
    tf.imwrite(output_tiff, cropped, compression='zlib', photometric='minisblack')

    # 3. Save Quick Preview PNG (Normalized)
    # Scale intensities to 0-1 for standard viewing
    if preview_data.max() > preview_data.min():
        norm = (preview_data - preview_data.min()) / (preview_data.max() - preview_data.min())
    else:
        norm = preview_data
    
    # 'viridis' or 'magma' colormaps help visualize low-signal spatial data
    plt.imsave(output_png, norm, cmap='viridis')

if __name__ == "__main__":
    # Nextflow now sends three arguments
    process_scrna_tiff(sys.argv[1], sys.argv[2], sys.argv[3])
