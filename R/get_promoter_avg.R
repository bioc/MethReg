#' @title Summarize promoter DNA methylation beta values by mean.
#' @description
#' First, identify gene promoter regions (default +-2Kkb around TSS).
#' Then, for each promoter region calculate the mean DNA methylation of probes
#' overlapping the region.
#' @return A RangedSummarizedExperiment with promoter region and
#' mean beta-values of CpGs within it.
#' Metadata will provide the promoter gene region and gene informations.
#' @export
#' @importFrom GenomicRanges reduce
#' @examples
#' \dontrun{
#'   data("dna.met.chr21")
#'   promoter.avg <- get_promoter_avg(
#'      dnam = dna.met.chr21,
#'      genome = "hg19",
#'      arrayType = "450k"
#' )
#' }
#' @param dnam A DNA methylation matrix or a SummarizedExperiment object
#' @param genome Human genome of reference hg38 or hg19
#' @param arrayType DNA methylation array type (450k or EPIC)
#' @param cores A integer number to use multiple cores. Default 1 core.
#' @param upstream.dist.tss Number of base pairs (bp) upstream of TSS
#' to consider as promoter regions
#' @param downstream.dist.tss Number of base pairs (bp) downstream of TSS
#' to consider as promoter regions
#' @param verbose A logical argument indicating if
#' messages output should be provided.
get_promoter_avg <- function(
    dnam,
    genome,
    arrayType,
    cores = 1,
    upstream.dist.tss = 2000,
    downstream.dist.tss = 2000,
    verbose = FALSE
) {
    
    if(is(dnam,"SummarizedExperiment")){
        dnam <- assay(dnam)
    }
    if(!is(dnam,"matrix")){
        stop("dnam input is wrong")
    }
    
    # We will start by defining the promoter regions
    if(verbose) message("o Get promoter regions for ", genome)
    promoter.gr <- get_promoter_regions(
        genome = genome,
        upstream = upstream.dist.tss,
        downstream = downstream.dist.tss
    )
    if(verbose) message("oo Number of promoter regions in ", genome, ": ", length(promoter.gr))
    
    # For each promoter region we will then
    # take the mean DNA methylation beta-values of all
    # probes within it
    
    # Get probes regions for mapping the motifs
    if(verbose) message("o Get DNA methylation regions overlapping promoter regions")
    
    # If input are probes, we need to map to regions
    if(any(grepl("cg", rownames(dnam)))){
        dnam <- map_probes_to_regions(dnam, genome = genome, arrayType = arrayType)
    }
    
    probes.gr <- make_granges_from_names(rownames(dnam))
    
    # Find which probes overlap with the regions
    hits <- findOverlaps(promoter.gr, probes.gr, ignore.strand = TRUE) %>% as.data.frame()
    if(nrow(hits) == 0) stop("No overlap found between promoter regions and DNA methylation array found")
    
    region.with.more.than.one.probe <- unique(hits$queryHits[duplicated(hits$queryHits)])
    unique.hits <- hits[!hits$queryHits %in% region.with.more.than.one.probe,]
    
    promoter.matrix <- NULL
    unique.promoter.genes <- NULL
    non.unique.promoter.genes <- NULL
    # Do we have probes mapped to unique promoter regions, if so copy probes and rename
    # probes to regions
    
    if(nrow(unique.hits) > 0){
        promoter.matrix <- dnam[unique.hits$subjectHits,, drop = FALSE] %>% as.matrix()
        rownames(promoter.matrix) <- make_names_from_granges(promoter.gr[unique.hits$queryHits])
        unique.promoter.genes <- values(promoter.gr[unique(unique.hits$queryHits)])
    }
    
    if(verbose) message("o Get mean DNA methylation of regions overlapping each promoter region")
    parallel <- register_cores(cores)
    
    # Do we have regions overlapping with multiple probes ?
    if(length(region.with.more.than.one.probe) > 0){
        non.unique.hits <- hits[hits$queryHits %in% region.with.more.than.one.probe,]
        
        non.unique.promoter <- plyr::adply(
            unique(non.unique.hits$queryHits),
            .margins = 1,
            function(x){
                idx <- hits %>% filter(queryHits == x) %>% pull(subjectHits)
                rows <- make_names_from_granges(probes.gr[idx])
                Matrix::colMeans(dnam[rows,,drop = FALSE],na.rm = TRUE)
            }, .id = NULL,
            .parallel = parallel ,
            .progress = "time",
            .inform = TRUE
        )
        
        non.unique.promoter.genes <- values(promoter.gr[unique(non.unique.hits$queryHits)])
        
        rownames(non.unique.promoter) <-
            promoter.gr[unique(non.unique.hits$queryHits)] %>%
            make_names_from_granges
        
        if(is.null(promoter.matrix)) {
            promoter.matrix <- non.unique.promoter
        } else {
            promoter.matrix <- rbind(promoter.matrix, non.unique.promoter)
        }
    }
    se <- promoter.matrix %>% as.matrix %>% make_dnam_se()
    values(se) <- cbind(
        rownames(se),
        rbind(
            unique.promoter.genes %>% as.data.frame, 
            non.unique.promoter.genes  %>% as.data.frame
        )
    )
    colnames(values(se)) <- c("promtoer_region","gene","gene_symbol")
    
    return(se)
}
