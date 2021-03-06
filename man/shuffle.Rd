% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/shuffle.R
\name{shuffle}
\alias{shuffle}
\title{Estimating the number of dimensions for n datasets with shuffled variables.}
\usage{
shuffle(data, n, ncores)
}
\arguments{
\item{data}{A data.frame object.}

\item{n}{Numeric. Number of estimates.}

\item{ncores}{Numeric. Number of cores to use in parallel.}
}
\description{
\code{shuffle} Apply EGA to n datasets with m shuffled variables. The number of
variables shuffled is defined as the square root of the total number of variables in the data.
}
\examples{
\dontrun{
wmt.surrogate <- shuffle(data = wmt2[,7:24], n = 100, ncores = 4)
}
}
\seealso{
\code{\link{subsamples}} to estimate the number of dimensions via EGA in n random subsamples of the original data and \code{\link{surrogate}}
to apply a surrogate method for EGA.
}
\author{
Hudson F. Golino <hfg9s at virginia.edu>
}
