#' Generate personograph plots from data
#'
#' A personograph (Kuiper-Marshall plot) is a pictographic
#' representation of relative harm and benefit from an intervention. It is
#' similar to
#' \href{http://www.nntonline.net/visualrx/examples/}{Visual Rx (Cates
#' Plots)}. Each icon on the grid is colored to indicate whether that
#' percentage of people is harmed by the intervention, would benefit from the
#' intervention, has good outcome regardless of intervention, or bad outcome regardless of
#' intervention.
#' This terminology is similar to that of Uplift Modelling.
#'
#' The plot function \code{\link{personograph}} is implemented in such
#' a way that it's easy to just pass a named list of percentages,
#' colors, and an icon. Making it potentially useful for other use
#' cases as well.
#'
#' \if{html}{
#' The example code will generate the following graph if \code{higher_is_better=F}:
#'
#' \figure{green.png}{}
#'
#' }
#' \if{latex}{
#' The example code will generate the following graph if \code{higher_is_better=F}:
#'
#' \figure{green.pdf}{options: width=5in}
#' }
#'
#' \subsection{Funding & Acknowledgments}{
#' This software was commissioned and sponsored by \href{http://www.doctorevidence.com/}{Doctor Evidence}.
#' The Doctor Evidence mission is to improve clinical outcomes by
#' finding and delivering medical evidence to healthcare
#' professionals, medical associations, policy makers and
#' manufacturers through revolutionary solutions that enable anyone to
#' make informed decisions and policies using medical data that is
#' more accessible, relevant and readable.}
#'
#' @docType package
#' @name personograph-package
#' @seealso \code{\link{personograph}}
#' @seealso \code{\link{uplift}}
#' @import grid
#' @import grImport
#' @examples
#' # Example data from rMeta
#' data <- read.table(textConnection('
#'           name ev.trt n.trt ev.ctrl n.ctrl
#' 1     Auckland     36   532      60    538
#' 2        Block      1    69       5     61
#' 3        Doran      4    81      11     63
#' 4        Gamsu     14   131      20    137
#' 5     Morrison      3    67       7     59
#' 6 Papageorgiou      1    71       7     75
#' 7      Tauesch      8    56      10     71
#' '
#' ), header=TRUE)
#'
#' sm <- "RR" # The outcome measure (either Relative Risk or Odds Ratio)
#' if (requireNamespace("meta", quietly = TRUE)) { # use meta if available
#'     ## Calculate the pooled OR or RR point estimate
#'     m <- with(data,
#'            meta::metabin(ev.trt, n.trt, ev.ctrl, n.ctrl, sm=sm))
#'     point <- exp(m$TE.random) # meta returns random effects estimate on the log scale
#' } else {
#'     # Calculated Random Effects RR, using the meta package
#'     point <- 0.5710092
#' }
#'
#' # Approximate the Control Event Rates using a weighed median
#' cer <- w.approx.cer(data[["ev.ctrl"]], data[["n.ctrl"]])
#'
#' # Calculate the Intervention Event Rates (IER) from the CER and point estimate
#' ier <- calc.ier(cer, point, sm)
#'
#' # Calcaulte the "uplift" statistics
#' # Note that this depends on the direction of the outcome effect (higher_is_better)
#' u <- uplift(ier, cer, higher_is_better=FALSE)
#' plot(u, fig.title="Example", fig.cap="Example from rMeta")
NULL

w.median <- function(x, w) {
    ## Lifted from cwhmisc, http://www.inside-r.org/packages/cran/cwhmisc/docs/w.median
    if (missing(w)) w <- rep(1,length(x))
    ok <- complete.cases(x, w)
    x <- x[ok]
    w <- w[ok]
    ind <- sort.list(x)
    x <- x[ind]
    w <- w[ind]
    ind1 <- min(which(cumsum(w) / sum(w) >= 0.5))
    ind2 <- if((w[1] / sum(w)) > 0.5) {
        1
    } else {
        max(which(cumsum(w) / sum(w) <= 0.5))
    }
    max(x[ind1], x[ind2])
}

#' Calculate the CER (Control Event Rates)
#'
#' Calculates the CER from the data, this is a weighted approximation of absolute
#' risk with control (from 0 to 1)
#'
#' @export
#' @param ev.ctrl Vector of event rates in the control group (/arm)
#' @param n.ctrl A vector of sample sizes in the control group (/arm)
#' @return Approximated Control Event Rates (CER)
w.approx.cer <- function(ev.ctrl, n.ctrl) {
    study_cer <- ev.ctrl / n.ctrl
    w.median(study_cer, n.ctrl)
}

#' Calculate the IER (Intervention Event Rates)
#'
#' @export
#' @seealso \code{\link{w.approx.cer}}
#' @param cer Absolute risk with control (calculated; from 0 to 1)
#' @param point Relative risk with intervention (direct from meta-analysis)
#' @param sm The outcome measure, RR or OR as string
#' @return Absolute risk of intervention as Intervention Event Rates (IER)
calc.ier <- function(cer, point, sm) {
    if (sm == "RR") {
        return(cer * point)
    } else if(sm == "OR") {
        return(cer * (point / (1 - (cer * (1 - point)))))
    } else {
        stop("Sm need to be OR (Odds Ratios) or RR (Relative Risk)")
    }
}

#' "Uplift" from IER and CER
#'
#' Calculates the percentage (from 0 to 1) of people intervention benefit, intervention harm, bad, and good
#' from the Intervention Event Rates (IER) and Control Event Rates (CER).
#' Note that the result depends on the direction of the outcome measure,
#' e.g. \code{higher_is_better = T} (default) for intervention efficacy, \code{higher_is_better = F} for
#' adverse events.
#'
#' The adopted terminology is similar to that of Uplift modelling
#' \url{https://en.wikipedia.org/wiki/Uplift_modelling}
#'
#' @export
#' @param ier Intervention Event Rates
#' @param cer Control Event Rates
#' @param higher_is_better logical indicating the direction of the outcome measure, default TRUE
#' @return A list of S3 class \code{personograph.uplift} with the following elements:
#' \itemize{
#' \item{\code{good outcome}} {people who have a good outcome regardless of intervention}
#' \item{\code{bad outcome}} {people who have a bad outcome regradless of intervention}
#' \item{\code{intervention benefit}} {people who benefit from intervention}
#' \item{\code{intervention harm}} {people who are harmed by intervention}
#' }
#'
#' Can be plotted as a personograph with the S3 generic \code{plot}.
#' @examples
#' ier <- 0.06368133
#' cer <- 0.1115242
#' u <- uplift(ier, cer, higher_is_better=TRUE)
#' plot(u)
uplift <- function(ier, cer, higher_is_better=NULL) {
    if(is.null(higher_is_better)) {
        higher_is_better <- T
        warning("Setting higher_is_better as outcome direction to TRUE")
    }
    if (higher_is_better == F) {
        ## Always orient the numbers so that higher events represents a good outcome
        ier <- 1 - ier
        cer <- 1 - cer
    }

    ## [good outcome] people who are good no matter what intervention
    good <- min(ier, cer)

    ## [bad outcome] people who are bad no matter what intervention
    bad <- 1-max(ier, cer)

    ## [intervention benefit] people who would be benefit from the intervention
    benefit <- max(ier-cer, 0)

    ## [intervention harm] people who would harmed by intervention
    harm <- max(cer-ier, 0)

    if(higher_is_better) {
        result <- list("good outcome"=good, "intervention harm"=harm, "bad outcome"=bad)
    } else {
        result <- list("good outcome"=good, "intervention benefit"=benefit, "bad outcome"=bad)
    }

    class(result) <- "personograph.uplift"
    result
}

as.colors <- function(lst, palette=gray.colors) {
    n <- names(lst)
    colors <- palette(length(n))
    sapply(n, function(name) { colors[[which(n == name)]]}, simplify = FALSE, USE.NAMES = TRUE)
}

round.standard <- function(x) {
    # rounds numbers conventionally
    # so that round.standard(0.5)==1
    return(floor(x+0.5))
}

round.with.warn <- function(x, f=round.standard, name=NULL) {
    rounded <- f(x)
    if(x > 0 && rounded == 0) {
        warning(paste("truncating", ifelse(is.null(name), "a", name), "non-zero value of", x, "to 0"))
    }
    rounded
}

naturalfreq <- function(ar, denominator=100) {
    numerator <- ar * denominator
    if(numerator > 0 && numerator <0.5) {
        return(paste0("< 1/", denominator))
    } else {
        return(paste0(round.standard(numerator), "/", denominator))
    }
}

setColor <- function(icon, color) {
    for(i in seq_along(icon@paths)) { icon@paths[[i]]@rgb <- color}
    icon
}

#' Plots a personograph
#'
#' Plots a personograph from a named list with percentages (must sum to
#' 1). A personograph is a graphical represenation of relative benefit
#' or harm, using a grid of icons with different colors. Its intended
#' use is similar to that of Cates Plots (Visual Rx, Number Needed to
#' Treat visualization).
#' Although these could be seen as Kuiper-Marshall plots.
#'
#' @export personograph
#' @param data A list of names to percentages (from 0 to 1)
#' @param icon.style A numeric from 1-11 indicating which of the included icons to use
#' @param icon A \code{grImport} \code{Picture} for the icon, overwrites \code{icon.style}
#' @param icon.dim The dimensions of icon as a vector \code{c(width, height)} of \code{unit} or numerical. Calculated from the \code{dimensions} if not supplied
#' @param n.icons Number of icons to draw, defaults to 100
#' @param plot.width The percentage of width that the main plotting area should take (with respect to the frame)
#' @param dimensions A vector of \code{c(rows, columns)} for the dimensions of the grid
#' @param colors A vector of names to colors, must match the names in data. Uses \code{gray.colors} style if none supplied
#' @param fig.cap Figure caption
#' @param fig.title Figure title
#' @param draw.legend Logical if TRUE (default) draw the legend
#' @return None.
#' @examples
#' data <- list(first=0.9, second=0.1)
#' personograph(data)
#' # With colors
#' personograph(data, colors=list(first="red", second="blue"))
#' # Plot a thousand in a 20x50 grid
#' personograph(data, n.icons=1000, dimensions=c(20,50))
personograph <- function(data,
                 fig.title=NULL,
                 fig.cap=NULL,
                 draw.legend=T,
                 icon=NULL,
                 icon.dim=NULL,
                 icon.style=1,
                 n.icons=100,
                 plot.width=0.75,
                 dimensions=ceiling(sqrt(c(n.icons, n.icons))),
                 colors=as.colors(data)) {

    devAskNewPage(FALSE)
    grid.newpage()

    fontfamily <- c("Helvetica", "Arial")

    if(is.null(icon)) {
        icon <- readPicture(system.file(paste0(icon.style, ".ps.xml"), package="personograph"))
    }

    master.rows <- sum(draw.legend, !is.null(fig.cap))
    master.heights <- c(0.1,
                       0.9 - (master.rows * 0.1),
                       ifelse(draw.legend, .1, 0),
                       ifelse(!is.null(fig.cap) || !draw.legend, .1, 0))

    masterLayout <- grid.layout(
        nrow    = 4,
        ncol    = 1,
        heights = unit(master.heights, rep("null", 4)))

    vp1 <- viewport(layout.pos.row=1, layout.pos.col = 1, name="title")
    vp2 <- viewport(layout.pos.row=2, layout.pos.col = 1, name="plot")
    vp3 <- viewport(layout.pos.row=3, layout.pos.col = 1, name="legend")
    vp4 <- viewport(layout.pos.row=4, layout.pos.col = 1, name="caption", just=c("centre", "top"))

    pushViewport(vpTree(viewport(layout = masterLayout, name = "master"), vpList(vp1, vp2, vp3, vp4)))

    if(!is.null(fig.title)) {
        seekViewport("title")
        grid.text(fig.title,
                  gp = gpar(fontsize = 18, fontfamily=fontfamily, fontface="bold"))
        popViewport()
    }

    rows <- dimensions[1]
    cols <- dimensions[2]

    if(is.null(icon.dim)) {
        icon.height <- 1 / rows
        icon.width <- 1 / cols
    } else {
        icon.height <- icon.dim[1]
        icon.width <- icon.dim[2]
    }

    data.names <- names(data)
    counts <- sapply(data.names, function(name) {
        x <- data[[which(data.names == name)]]
        round.with.warn(x * n.icons, name=name)}, simplify = FALSE, USE.NAMES = TRUE)

    if(is.null(colors)) {
        colors <- as.colors(data)
    }

    flat <- unlist(lapply(data.names, function(name) { rep(name, counts[[name]])}))

    seekViewport("plot")
    pushViewport(viewport(width=unit(plot.width, "npc")))

    colorMatrix <- function(flat, colors) {
        m <- matrix(nrow=rows, ncol=cols)
        total <- 0
        for (i in rows:1) {
            for (j in 1:cols) {
                total <- total + 1
                if(total < length(flat) + 1) {
                    j_snake <- ifelse((i %% 2 == 1), j, cols - j + 1) # to group like icons together
                    m[i,j_snake] <- colors[[flat[[total]]]]
                }
            }
        }
        m
    }

    colorMask <- function(colorMatrix, color) {
        return(ifelse(colorMatrix == color, color, NA))
    }

    coordinates <- function(colorMask, width, height) {
        originalDim <- dim(colorMask)
        rows <- originalDim[1]
        cols <- originalDim[2]

        x <- matrix(seq((width/2), 1 - (width/2), by=width), nrow=rows, ncol=cols, byrow=T)
        y <- matrix(seq((height/2), 1 - (height/2), by=height), nrow=rows, ncol=cols, byrow=F)

        list(x=x[which(!is.na(colorMask), TRUE)], y=y[which(!is.na(colorMask), TRUE)])
    }

    colorM <- colorMatrix(flat, colors)

    for(name in data.names) {
        color <- colors[[name]]
        mask <- colorMask(colorM, color)
        coords <- coordinates(mask, icon.width, icon.height)
        if(length(coords$x) > 0 && length(coords$y) > 0) {
            icon <- setColor(icon, color)
            fudge <- 0.0075
            grid.symbols(icon, x=coords$x, y=coords$y, size=max(icon.height, icon.width) - fudge)
        }
    }
    popViewport(2)

    font <- gpar(fontsize=11, fontfamily)

    if(draw.legend) {
        seekViewport("legend")

        legendCols <- length(data.names)

        legendGrobs <- list()
        legendWidths <- list()
        for(name in data.names) {
            label <- paste(naturalfreq(data[[name]], denominator=n.icons), name)
            grob <- textGrob(label, gp=font, just="left", x=-0)
            legendGrobs[[name]] <- grob
            legendWidths[[name]] <- widthDetails(grob)
        }

        legendWidths <- c(rbind(rep(unit(0.25, "inches"), legendCols), unlist(legendWidths)))

        pushViewport(viewport(
            clip   = F,
            width  = unit(0.8, "npc"),
            layout = grid.layout(ncol=legendCols * 2,
                                 nrow=1,
                                 widths=unit(legendWidths, "inches"),
                                 heights=unit(0.25, "npc"))))


        idx <- 0
        for(name in data.names)  {
            idx <- idx + 1
            pushViewport(viewport(layout.pos.row=1, layout.pos.col=idx))
            grid.circle(x=0.4, r=0.35, gp=gpar(fill=colors[[name]], col=NA))
            popViewport()

            idx <- idx + 1
            pushViewport(viewport(layout.pos.row=1, layout.pos.col=idx))
            grid.draw(legendGrobs[[name]])
            popViewport()
        }

        popViewport(2)
    }

    if(!is.null(fig.cap)) {
        seekViewport("caption")
        grid.text(fig.cap, gp = font)
        popViewport()
    }

    dev.flush()
    return(invisible(NULL))
}

#' @export
#' @method plot personograph.uplift
#' @seealso \code{\link{personograph}}
plot.personograph.uplift <- function(x, ...) {
    colors <- list("intervention harm"="firebrick3", "intervention benefit"="olivedrab3", "bad outcome"="azure4", "good outcome"="azure2")
    personograph(x, colors=colors, ...)
}
