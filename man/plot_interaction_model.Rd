% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot_interaction_model.R
\name{plot_interaction_model}
\alias{plot_interaction_model}
\title{Plot interaction model results}
\usage{
plot_interaction_model(
  triplet.results,
  dnam,
  exp,
  metadata,
  tf.activity.es = NULL,
  tf.dnam.classifier.pval.thld = 0.001,
  dnam.group.threshold = 0.25,
  label.dnam = "beta-value",
  label.exp = "expression",
  genome = "hg38",
  add.tf.vs.exp.scatter.plot = FALSE
)
}
\arguments{
\item{triplet.results}{Output from function interaction_model
with Region ID, TF  (column name: TF),  and target gene  (column name: target),
p-values and estimates of interaction}

\item{dnam}{DNA methylation matrix or SummarizedExperiment object
(columns: samples same order as met, rows: regions/probes)}

\item{exp}{gene expression matrix or a SummarizedExperiment object
(columns: samples same order as met, rows: genes)}

\item{metadata}{A data frame with samples as rownames and one columns that will be used to
color the samples}

\item{tf.activity.es}{A matrix with normalized enrichment scores for each TF across all samples
to be used in linear models instead of TF gene expression.}

\item{tf.dnam.classifier.pval.thld}{P-value threshold to consider
a linear model significant
of not. Default 0.001. This will be used to classify the TF role and DNAm
effect.}

\item{dnam.group.threshold}{DNA methylation threshold percentage to define samples 
in the low methylated group and high methylated group. For example, 
setting the threshold to 0.3 (30\%) will assign samples with the lowest 30\% 
methylation in the low group and the highest 30\% methylation in the high group. 
Default is 0.25 (25\%), accepted threshold range (0.0,0.5].}

\item{label.dnam}{Used for label text. Option "beta-value" and "residuals"}

\item{label.exp}{Used for label text. Option "expression" and "residuals"}

\item{genome}{Genome of reference to be added to the plot as text}

\item{add.tf.vs.exp.scatter.plot}{Add another row to the figure if the 
target gene expression vs TF expression stratified by DNA methylation groups
(DNAmLow - low quartile, DNAmHigh - high quartile)}
}
\value{
A ggplot object, includes a table with results from fitting interaction model,
and the the following scatter plots: 1) TF vs DNAm, 2) Target vs DNAm,
3) Target vs TF, 4) Target vs TF for samples in Q1 and Q4 for DNA methylation,
5) Target vs DNAm for samples in Q1 and Q4 for the TF
}
\description{
Create several plots to show interaction data
TF expression with target gene interaction using a linear model
\deqn{log2(RNA target) = log2(TF) + DNAm + log2(TF) * DNAm}

To consider covariates, RNA can also be the residuals.
\deqn{log2(RNA target residuals) = log2(TF residual) + DNAm + log2(TF residual) * DNAm}
}
\examples{
library(dplyr)
dnam <- runif(20,min = 0,max = 1) \%>\%
  matrix(ncol = 1) \%>\%  t
rownames(dnam) <- c("chr3:203727581-203728580")
colnames(dnam) <- paste0("Samples",1:20)

exp.target <-  runif(20,min = 0,max = 10) \%>\%
  matrix(ncol = 1) \%>\%  t
rownames(exp.target) <- c("ENSG00000252982")
colnames(exp.target) <- paste0("Samples",1:20)

exp.tf <- runif(20,min = 0,max = 10) \%>\%
  matrix(ncol = 1) \%>\%  t
rownames(exp.tf) <- c("ENSG00000083937")
colnames(exp.tf) <- paste0("Samples",1:20)

exp <- rbind(exp.tf, exp.target)

triplet <- data.frame(
   "regionID" =  c("chr3:203727581-203728580"),
   "target" = "ENSG00000252982",
   "TF" = "ENSG00000083937"
)
results <- interaction_model(
   triplet = triplet, 
   dnam = dnam, 
   exp = exp, 
    dnam.group.threshold = 0.25,
   stage.wise.analysis = FALSE, 
   sig.threshold = 1,
   filter.correlated.tf.exp.dnam = FALSE,
   filter.correlated.target.exp.dnam = FALSE,
   filter.triplet.by.sig.term = FALSE
)
plots <- plot_interaction_model(
    triplet.results = results,
    dnam = dnam,
    exp = exp
)
}
