test_that("make_granges_from_names works", {
     regions.gr <- data.frame(
                   chrom = c("chr22", "chr22", "chr22", "chr22", "chr22"),
                   start = c("39377790", "50987294", "19746156", "42470063", "43817258"),
                   end   = c("39377930", "50987527", "19746368", "42470223", "43817384"),
                   stringsAsFactors = FALSE)  %>%
          makeGRangesFromDataFrame

      # map to closest gene
      region.closest <- get_region_target_gene(
                           regions.gr = regions.gr,
                           genome = "hg19",
                           method = "closest.gene")

      # map to all gene within region +- 250kbp
      region.window <- get_region_target_gene(
                           regions.gr = regions.gr,
                           genome = "hg19",
                           method = "window")

      testthat::is_true("target" %in% colnames(region.window))
      testthat::is_true("target" %in% colnames(region.closest))
      testthat::is_true("regionID" %in% colnames(region.window))
      testthat::is_true("regionID" %in% colnames(region.closest))

})