workflow {
    Channel
        .fromPath("data/*.txt")
        .view()
}