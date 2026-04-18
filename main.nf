nextflow.enable.dsl=2

workflow {

    tiff_ch = Channel.fromPath(params.tiff)
    h5_ch   = Channel.fromPath(params.h5)

    // IMAGE
    filled = PREPROCESS_IMAGE(tiff_ch)
    mask   = CELLPOSE_SEGMENT(filled)
    roi    = AI_ROI_CROP(filled, mask)

    // scRNA
    qc       = SCRNA_QC(h5_ch)
    filtered = SCRNA_MAD_FILTER(qc)
    reduced  = SCRNA_DIM_REDUCTION(filtered)
    cluster  = SCRNA_CLUSTER(reduced)
    annot    = SCRNA_ANNOTATE(cluster)

    // Spatial refinement
    refined  = SPATIAL_REFINE(annot, roi)

    // Integration
    integrated = SPATIAL_INTEGRATION(roi, refined)

    SCRNA_PLOTS(refined)
    SPATIAL_PLOTS(integrated)

    REPORT(integrated)
}