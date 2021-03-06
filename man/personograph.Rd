% Generated by roxygen2 (4.1.1.9000): do not edit by hand
% Please edit documentation in R/personograph.R
\name{personograph}
\alias{personograph}
\title{Plots a personograph}
\usage{
personograph(data, fig.title = NULL, fig.cap = NULL, draw.legend = T,
  icon = NULL, icon.dim = NULL, icon.style = 1, n.icons = 100,
  plot.width = 0.75, dimensions = ceiling(sqrt(c(n.icons, n.icons))),
  colors = as.colors(data))
}
\arguments{
\item{data}{A list of names to percentages (from 0 to 1)}

\item{fig.title}{Figure title}

\item{fig.cap}{Figure caption}

\item{draw.legend}{Logical if TRUE (default) draw the legend}

\item{icon}{A \code{grImport} \code{Picture} for the icon, overwrites \code{icon.style}}

\item{icon.dim}{The dimensions of icon as a vector \code{c(width, height)} of \code{unit} or numerical. Calculated from the \code{dimensions} if not supplied}

\item{icon.style}{A numeric from 1-11 indicating which of the included icons to use}

\item{n.icons}{Number of icons to draw, defaults to 100}

\item{plot.width}{The percentage of width that the main plotting area should take (with respect to the frame)}

\item{dimensions}{A vector of \code{c(rows, columns)} for the dimensions of the grid}

\item{colors}{A vector of names to colors, must match the names in data. Uses \code{gray.colors} style if none supplied}
}
\value{
None.
}
\description{
Plots a personograph from a named list with percentages (must sum to
1). A personograph is a graphical represenation of relative benefit
or harm, using a grid of icons with different colors. Its intended
use is similar to that of Cates Plots (Visual Rx, Number Needed to
Treat visualization).
Although these could be seen as Kuiper-Marshall plots.
}
\examples{
data <- list(first=0.9, second=0.1)
personograph(data)
# With colors
personograph(data, colors=list(first="red", second="blue"))
# Plot a thousand in a 20x50 grid
personograph(data, n.icons=1000, dimensions=c(20,50))
}

