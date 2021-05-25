---
permalink: /rea/
title: ""
type: pages
layout: single
author_profile: true
redirect_from:
  - /rea.html
---

# R code for "Inference with a single treated cluster"

This page provides R code for Table 1, Algorithm 3.3, and a robustness check contained in my paper "Inference with a single treated cluster" [[PDF]](/assets/hagemann_rea.pdf).

### Download: [hagemann_rea.R](/assets/hagemann_rea.R)

Include this file in R with `include('hagemann_rea.R')`. Alternatively, load it into R directly with  

`include('https://hgmn.github.io/assets/hagemann_rea.R')`  

The code supplies three functions:

`stc.weight` calculates the weight *w* as in Table 1 of the paper. It has the following arguments:
  * `q` is the number of control clusters.
  * `rho` is a measure of heterogeneity. Default is `rho=2`.
  * `alpha` Level of the test. Default is `alpha=.05`.

`stc` calculates the test decision as in Algorithm 3.3. It has the following arguments:
  * `x1` is the cluster-level estimate from a treated cluster.
  * `x0` is a vector of cluster-level estimates from control clusters.
  * `w` is the weight. Will be calculated automatically if `alpha` and `rho` are supplied as arguments. If `w` is supplied, then `alpha` and `rho` arguments will be ignored.
  * `verbose=TRUE` provides a verbal summary of the test decision. Otherwise the value is a 1/0 decision. Default is `TRUE`.

`stc.robust` computes the largest level of heterogeneity at which the null can no longer be rejected. It has the following arguments:
  * `x1`, `x0`, `alpha`, `verbose` have the same meaning as before.
  * `rhostart` is the initial value `rho` for the robustness check.
  * `inc` is the increment that is added to `rho` for the grid search. The output of the function is correct up to less than `inc`. Default is `.001`.

### Raw code

```R
# Calculates w as in Table 1
stc.weight <- function(q, alpha=.05, rho=2, steps=10^4) {
  wgrid <- (1:steps)/steps
  bnd <- function(w) {
    minb <- function(b) pnorm(w*sqrt(q-1)*b)^(q-1) + 2*pnorm(-b*q)
    f0 <- function(y) pnorm((1-w)*rho*y)^(q-1) * dnorm(y)
    2^(-q-1) + integrate(f0, 0, Inf)$val + optimize(minb, c(0,2))$ob
  }
  wres <- sapply(wgrid, bnd)
  winf <- min(which(wres <= alpha))
  if(is.finite(winf)) wgrid[winf]
  else stop("Feasible w does not exist. Decrease rho, increase q, or increase alpha.")
}

# Calculates test decision as in Algorithm 3.3
stc <- function(x1, x0, alpha=.05, rho=2, steps=10^4, w=NULL, verbose = TRUE) {
  q <- length(x0)
  if(is.null(w))
    w <- stc.weight(q=q, alpha=alpha, rho=rho, steps = steps)
  S <- c( (1+w)*(x1-mean(x0)), (1-w)*(x1-mean(x0)), x0 - mean(x0) )
  dec <-  mean(S[1:2])-mean(S[3:(q+2)]) == mean(sort(S, T)[1:2])-mean(sort(S, T)[3:(q+2)])
  if (verbose == TRUE) {
  	cat(paste("One-sided (>), alpha=", alpha, ".\n", sep=""))
  	cat(paste("Decision:", ifelse(dec == TRUE, "reject.", "do not reject.")))
  } else {
  	dec
  }
}

# Robustness check
stc.robust <- function(x1, x0, alpha=.05, rhostart=0, steps=10^3, inc=.001, verbose=TRUE) {
  rho <- rhostart
  dec <- stc(x1=x1, x0=x0, alpha=alpha, rho=rho, steps=steps, verbose=FALSE)
  if (dec == FALSE) {
  	return(NA)
  } else {
    while (dec == TRUE) {
      rho <- rho + 1
      dec <- stc(x1=x1, x0=x0, alpha=alpha, rho=rho, steps=steps, verbose=FALSE)
    }
  }
  rho <- max(rho - 1, rhostart)
  dec <- TRUE
  while (dec == TRUE) {
    dec <- stc(x1=x1, x0=x0, alpha=alpha, rho=rho, steps=steps, verbose=FALSE)
    rho <- rho + inc
  }
  if (verbose == TRUE) {
    cat(paste("H0 at alpha=", alpha, " can no longer be rejected at rho=", rho - inc, ".", sep=""))
  } else {
    rho - inc
  }
}
```
