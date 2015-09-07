library(grImport)

## Demo
data <- read.table(textConnection('
          name ev.trt n.trt ev.ctrl n.ctrl
1     Auckland     36   532      60    538
2        Block      1    69       5     61
3        Doran      4    81      11     63
4        Gamsu     14   131      20    137
5     Morrison      3    67       7     59
6 Papageorgiou      1    71       7     75
7      Tauesch      8    56      10     71
'
), header=TRUE)

cer <- w.approx.cer(data[["ev.ctrl"]], data[["n.ctrl"]])

sm <- "RR"
if (requireNamespace("meta", quietly = TRUE)) {
    ## Calculate the OR or RR, we use meta package here
    m <- meta::metabin(data[, "ev.trt"], data[, "n.trt"], data[, "ev.ctrl"], data[, "n.ctrl"], sm=sm)
    point <- exp(m$TE.random) # meta returns outcomes on the log scale
} else {
    # Calculated Random Effects RR, using the meta package
    point <- 0.5710092
}

ier <- calc.ier(cer, point)
d <- uplift(ier, cer, T)

png("~/Desktop/foo.png", width=600, height=800)
personograph(d,
             fig.title="1980 of corticosteroid therapy",
             fig.cap="Some caption",
             colors=list(harmed="firebrick3", helped="olivedrab3", bad="azure4", good="azure3"))
dev.off()