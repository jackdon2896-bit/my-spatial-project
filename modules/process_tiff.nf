process CROP_AND_COMPRESS {
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path tiff_file

    output:
    path "cropped_${tiff_file.baseName}.tif", emit: cropped_tiff
    path "preview_${tiff_file.baseName}.png", emit: preview_png

    script:
    // We pass three arguments now: input, cropped output, and preview output
    """
    process_scrna.py \\
        ${tiff_file} \\
        "cropped_${tiff_file.baseName}.tif" \\
        "preview_${tiff_file.baseName}.png"
    """
}
