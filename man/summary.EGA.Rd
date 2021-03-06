% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/summary.EGA.R
\name{summary.EGA}
\alias{summary.EGA}
\title{Summary method for EGA objects.}
\usage{
\method{summary}{EGA}(object)
}
\arguments{
\item{object}{An EGA object}
}
\description{
\code{summary} Returns a summary of the EGA results.
}
\examples{
ega.wmt <- EGA(data = wmt2[,7:24], plot.EGA = TRUE)
summary(ega.wmt)

\dontrun{
summary(EGA)
}
}
\seealso{
\code{\link{EGA}} to estimate the number of dimensions of an instrument using EGA and \code{\link{CFA}} to
verify the fit of the structure suggested by EGA using confirmatory factor analysis.
}
\author{
Hudson F. Golino <hfg9s at virginia.edu>
}
