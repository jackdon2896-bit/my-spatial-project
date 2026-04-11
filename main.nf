#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Import the module
include { CROP_AND_COMPRESS } from './modules/process_tiff.nf'

workflow {
    // Create a channel from the S3 path defined in your config
    // Note: checkIfExists: true sometimes struggles with S3; remove if you hit connection issues
    tiff_ch = Channel.fromPath(params.input_s3, checkIfExists: true)

    // Run the process
    CROP_AND_COMPRESS(tiff_ch)
}

/* 
   Note: The 'script:' block below usually lives inside 
   ./modules/process_tiff.nf. If you are keeping it in this 
   main file, it must be wrapped in a 'process' block.
*/
