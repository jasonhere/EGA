#'  Investigates the stability of EGA's estimation via bootstrap.
#'
#' \code{bootEGA} Estimates the number of dimensions of n bootstraps from the empirical correlation matrix,
#'  and returns a typical network (i.e. the network formed by the median or mean pairwise correlations over the n bootstraps) and its dimensionality.
#'
#' @param data A dataframe with the variables to be used in the analysis
#' @param n An integer value representing the number of bootstraps
#' @param typicalStructure Logical. If true, returns the typical network of partial correlations (estimated via graphical lasso or via TMFG) and estimates its dimensions. The "typical network" is the median of all pairwise correlations over the n bootstraps.
#' @param plot.typicalStructure Logical. If true, returns a plot of the typical network (partial correlations), which is the median of all pairwise correlations over the n bootstraps, and its estimated dimensions.
#' @param model A string indicating the method to use. Current options are:
#' -\code{glasso}:
#' {Gaussian Markov random field estimation using graphical LASSO with extended Bayesian information criterion to select optimal regularization parameter. Using \code{\link[qgraph]{EBICglasso}} from the qgraph package version 1.4.4.}
#' \code{TMFG}:
#' {Estimates a Triangulated Maximally Filtered Graph, using the function \code{TMFG} of the NetworkToolbox package}
#' @param type A string indicating the type of bootstrap to use. Current options are:
#' -\code{parametric}:
#' {Generates n new datasets (multivariate normal random distributions) based on the
#' original dataset, via the \code{\link[mvtnorm]{rmvnorm}} function of the mvtnorm package}.
#' -\code{resampling}:
#' {Generates n random subsamples of the original data.}
#' @param ncores Number of cores to use in computing results. Set to 1 to not use parallel computing.
#' @author Hudson F. Golino <hfg9s at virginia.edu> and Alexander Christensen <alexpaulchristensen@gmail.com>
#' @examples
#' \dontrun{
#' boot.wmt <- bootEGA(data = wmt2[,7:24], n = 500, typicalStructure = TRUE,
#' plot.typicalStructure = TRUE, model = "glasso", type = "parametric", ncores = 4)
#' boot.intwl <- bootEGA(data = intelligenceBattery[,8:66], n = 500, typicalStructure = TRUE,
#' plot.typicalStructure = TRUE, model = "glasso", type = "parametric", ncores = 4)
#'}
#' @seealso \code{\link{EGA}} to estimate the number of dimensions of an instrument using EGA and \code{\link{CFA}} to
#' verify the fit of the structure suggested by EGA using confirmatory factor analysis.
#'
#' @importFrom foreach %dopar%
#' @importFrom stats cov median sd qt
#'
#' @export

# Bootstrap EGA:
bootEGA <- function(data, n, typicalStructure = TRUE, plot.typicalStructure = TRUE, ncores = 4,
                    model = c("glasso", "TMFG"), type = c("parametric", "resampling")) {

    #mode function for item confirm
    mode <- function(v)
    {
        uniqv <- unique(v)
        uniqv[which.max(tabulate(match(v, uniqv)))]
    }

    #Parallel processing
    cl <- parallel::makeCluster(ncores)
    doParallel::registerDoParallel(cl)

    #progress bar
    #pb <- txtProgressBar(max=n, style = 3)
    #progress <- function(num) setTxtProgressBar(pb, num)
    #opts <- list(progress = progress)

    boots <- list()

    #nets
    boots <-foreach::foreach(i=1:n,
                             .packages = c("NetworkToolbox","psych","qgraph")
                             )%dopar%
                             #.options.snow = opts)
                             {
                                 if(model=="glasso")
                                 {
                                     if(type=="parametric")  # Use a parametric approach:
                                     {
                                         g <- -EBICglasso.qgraph(cov(data), n = nrow(data), lambda.min.ratio = 0.1, returnAllResults = FALSE)
                                         diag(g) <- 1
                                         bootData <- mvtnorm::rmvnorm(nrow(data), sigma = corpcor::pseudoinverse(g))
                                         net <- EBICglasso.qgraph(cov(bootData), n = nrow(data), lambda.min.ratio = 0.1, returnAllResults = FALSE)
                                     }else if(type=="resampling") # Random subsample with replace
                                     {
                                         mat <- data[sample(1:nrow(data), replace=TRUE),]
                                         net <- EBICglasso.qgraph(cov(mat), n=nrow(data), lambda.min.ratio = 0.1, returnAllResults = FALSE)
                                     }

                                 }else if(model=="TMFG")
                                 {
                                     if(type=="parametric"){
                                         g <- -NetworkToolbox::LoGo(data, partial=TRUE)
                                         diag(g) <- 1
                                         bootData <- mvtnorm::rmvnorm(nrow(data), sigma = corpcor::pseudoinverse(g))
                                         net <- NetworkToolbox::TMFG(bootData)$A
                                     } else if(type=="resampling"){
                                         mat <- data[sample(1:nrow(data), replace=TRUE),]
                                         net <- NetworkToolbox::TMFG(mat)$A
                                     }

                                 }
                             }

    parallel::stopCluster(cl)

    bootGraphs <- vector("list", n)
    for (i in 1:n) {
        bootGraphs[[i]] <- boots[[i]]
        colnames(bootGraphs[[i]]) <- colnames(data)
        rownames(bootGraphs[[i]]) <- colnames(data)
    }
    boot.igraph <- vector("list", n)
    for (l in 1:n) {
        boot.igraph[[l]] <- NetworkToolbox::convert2igraph(abs(bootGraphs[[l]]))
    }
    boot.wc <- vector("list", n)
    for (m in 1:n) {
        boot.wc[[m]] <- igraph::walktrap.community(boot.igraph[[m]])
    }
    boot.ndim <- matrix(NA, nrow = n, ncol = 2)
    for (m in 1:n) {
        boot.ndim[m, 2] <- max(boot.wc[[m]]$membership)
    }

    colnames(boot.ndim) <- c("Boot.Number", "N.Dim")

    boot.ndim[, 1] <- seq_len(n)
    if (typicalStructure == TRUE) {
        if(model=="glasso")
        {typical.Structure <- apply(simplify2array(bootGraphs),1:2, median)
        }else if(model=="TMFG")
        {typical.Structure <- apply(simplify2array(bootGraphs),1:2, mean)}
        typical.igraph <- NetworkToolbox::convert2igraph(abs(typical.Structure))
        typical.wc <- igraph::walktrap.community(typical.igraph)
        typical.ndim <- max(typical.wc$membership)
        dim.variables <- data.frame(items = colnames(data), dimension = typical.wc$membership)
    }
    if (plot.typicalStructure == TRUE) {
        plot.typical.ega <- qgraph::qgraph(typical.Structure, layout = "spring",
                                   vsize = 6, groups = as.factor(typical.wc$membership))
    }
    Median <- median(boot.ndim[, 2])
    sd.boot <- sd(boot.ndim[, 2])
    se.boot <- (1.253 * sd.boot)/sqrt(nrow(boot.ndim))
    ciMult <- qt(0.95/2 + 0.5, nrow(boot.ndim) - 1)
    ci <- se.boot * ciMult
    summary.table <- data.frame(n.Boots = n, median.dim = Median,
                                SD.dim = sd.boot, SE.dim = se.boot, CI.dim = ci, Lower = Median -
                                    ci, Upper = Median + ci)

    #compute likelihood
    dim.range <- range(boot.ndim[,2])
    lik <- matrix(0, nrow = diff(dim.range)+1, ncol = 2)
    colnames(lik) <- c("# of Factors", "Likelihood")
    count <- 0

    for(i in seq(from=min(dim.range),to=max(dim.range),by=1))
    {
        count <- count + 1
        lik[count,1] <- i
        lik[count,2] <- length(which(boot.ndim[,2]==i))/n
    }

    result <- list()
    result$n <- n
    result$boot.ndim <- boot.ndim
    result$boot.wc <- boot.wc
    result$bootGraphs <- bootGraphs
    result$summary.table <- summary.table
    result$likelihood <- lik
    result$EGA <- suppressMessages(suppressWarnings(EGA(data = data, model = model, plot.EGA = FALSE)))
    typicalGraph <- list()
    typicalGraph$graph <- typical.Structure
    typicalGraph$typical.dim.variables <- dim.variables[order(dim.variables[,2]), ]
    typicalGraph$wc <- typical.wc$membership
    result$typicalGraph <- typicalGraph
    class(result) <- "bootEGA"
    return(result)
}
