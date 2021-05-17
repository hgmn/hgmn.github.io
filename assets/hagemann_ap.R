ApAlphaBar <- function(q1, q0, alpha, local = FALSE, q0max = 20) {
  if(local == TRUE) {
  balphas <- read.csv("hagemann_ap.csv", header = FALSE)
  } else {
  balphas <- read.csv('https://hgmn.github.io/assets/hagemann_ap.csv', header = FALSE)
  }
  if(alpha == .1) {
    j <- 0
  } else if(alpha == .05) {
    j <- 1
  } else if(alpha == .025) {
	j <- 2
  } else if(alpha == .01) {
  	j <- 3
  } else if(alpha == .005) {
    j <- 4
  } else stop("Nonstandard alpha selected.")
  balpha <- balphas[max(q1, q0) - 3 + (q0max - 3)*j, min(q1, q0) - 3]
  return(ifelse(balpha == "max", "max", as.numeric(balphas[max(q1, q0) - 3 + (q0max - 3)*j, min(q1, q0) - 3])))
}

ApTest <- function(x1, x0, alpha = .05, alphabar = NULL, random = TRUE, verbose = TRUE, index = NULL, ...) {
  stats <- c(x1, x0)
  q1 <- length(x1)
  q0 <- length(x0)
  q <- q1 + q0
  if(is.null(index)) {
  	if(random == TRUE & choose(q, q1) > 10^4) {
	  index <- MakeRandIndex(q1, q0)
  	} else {
      index <- MakeIndex(q1, q0)
    }
  }
  M <- nrow(index)
  r.stats <- matrix(stats[index[1:M, ]], M, q)
  perm.stats <- rowMeans(r.stats[, 1:q1]) - rowMeans(r.stats[, (q1+1):q])
  orig.stat <- perm.stats[1]
  perm.stats <- sort(perm.stats)
  if(is.null(alphabar)) alphabar <- ApAlphaBar(q1, q0, alpha, ...)
  k <- ifelse(alphabar == "max", M-1, ceiling(round((1-alphabar)*M, 4)))
  dec <- orig.stat > perm.stats[k]
  if (verbose == TRUE) {
    cat(paste("One-sided (>), alpha=", alpha, ".\n", sep=""))
    cat(paste("Decision:", ifelse(dec == TRUE, "reject.", "do not reject.")))
  } else {
  return(as.numeric(dec))
  }	
}

MakeIndex <- function(q1, q0) {
  count.stats <- 1:(q1  + q0)
  index.treat <- combn(count.stats, q1)
  index.cont <- sapply(1:ncol(index.treat), function(j) count.stats[! count.stats %in% index.treat[, j]])	
  index <- cbind(t(index.treat), t(index.cont))
  return(index)
}

MakeRandIndex <- function(q1, q0, n.greps = 9999) {
  q <- q1 + q0
  index <- t(cbind(1:q, replicate(n.greps, sample(1:q, q))))
  return(index)
}