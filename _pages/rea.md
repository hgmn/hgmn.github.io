---
permalink: /rea/
title: ""
type: pages
layout: single
author_profile: true
redirect_from:
  - /rea.html
---

# Code for "Inference with a single treated cluster"
This page provides R and Stata code for Table 1, Algorithm 3.3, and a robustness check contained in my paper "Inference with a single treated cluster" [[PDF]](/assets/hagemann_rea.pdf).

## Stata code

#### Download: [stc_weight.ado](/assets/stc_weight.ado), [stc_weight2.ado](/assets/stc_weight2.ado), [stc_estimate.ado](/assets/stc_estimate.ado), [stc_estimate_robust.ado](/assets/stc_estimate_robust.ado)

#### Installation Instructions

1. Download `.ado` files from above.
2. In Stata command window, execute `sysdir` and locate `personal` directory.
3. Place the `.ado` files from step 1 to the `personal` directory.
4. Restart Stata.

#### Details

The `.ado` files supply three functions:

`stc_weight` calculates the weight *w* as in Table 1 of the paper. It has the following arguments:
  * `q_num` is the number of control clusters.
  * `het_level` is a measure of heterogeneity. No default is supplied.
  * `conf_level` is the level of the test. No default is supplied.
  * `steps` is the number of grid points on [0,1] to search over.

Syntax is: `stc_weight, q_num(.) het_level(.) conf_level(.) steps(.)`.

`stc_weight2` calculates the weight *w*, assuming the variance of all control clusters are bounded away zero. It takes the same arguments as `stc_weight`. The syntax is also identical to that of `stc_weight`: `stc_weight2, q_num(.) het_level(.) conf_level(.) steps(.)`.

`stc_estimate` calculates the test decision as in Algorithm 3.3. It has the following arguments:
  * `varlist` contains both the cluster-level estimate from a treated cluster, and a vector of cluster-level estimates from control clusters.
  * `rho_level` is a measure of heterogeneity. No default is supplied.
  * `alpha_level` is the level of the test. No default is supplied.
  * `steps` from `stc_estimate` is pre-specified to be 10,000.
  * Weight *w* is calculated based on the specified values of `rho_level` and `alpha_level`.
  * `option` specifies the weights computed. This takes two values. `Option = 1` computes the weights assuming the variances of all but one control cluster are bounded away from zero. `Option = 2` computes the weights assuming the variances of all control clusters are bounded away from zero. Puttingin any value other than `1` or `2` returns with an error message.

Syntax is: `stc_estimate varlist, rho_level(.) alpha_level(.) option(.)`.

`stc_estimate_robust` computes the largest level of heterogeneity at which the null can no longer be rejected. It has the following arguments:
  * `varlist`, `alpha_level`, and `option` have the same meaning as before.
  * `rho_start` is the initial value `rho_level` for the robustness check.
  * `inc` is the increment that is added to `rho_start` for the grid search. The output of the function is correct up to less than `inc`. No default is supplied.

Syntax is: `stc_estimate_robust varlist, rho_start(.) alpha_level(.) inc(.) option(.)`.

#### Replication Code for Table 3: [Table-3-Replication.do](/assets/Table_3_Replication.do), [Replication_Data.csv](/assets/all_results.csv)

## R code

#### Download: [hagemann_rea.R](/assets/hagemann_rea.R)

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

#### Raw code

```R
# Calculates w as in Table 1
stc.weight <- function(q, alpha=.05, rho=2, steps=10^4) {
  wgrid <- (0:steps)/steps
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
  	if(w == 0) {
  		f0 <- function(y) pnorm(rho*y)^(q-1) * dnorm(y)
		bnd0 <- round(5/2^(q+1) + integrate(f0, 0, Inf)$val, 6)
  		cat(paste("\n", "Caution: w=0, test is valid but may have size less than ", alpha, ". ", 
  			"Actual size is alpha=", bnd0, ". ", "Increase rho or decrease alpha to remove Caution.", sep=""))
  	}
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
    while (dec == TRUE)
      rho <- rho + 1
      dec <- stc(x1=x1, x0=x0, alpha=alpha, rho=rho, steps=steps, verbose=FALSE)
    }
    rho <- max(rho - 1, rhostart)
    dec <- TRUE
    while (dec == TRUE) {
      dec <- stc(x1=x1, x0=x0, alpha=alpha, rho=rho, steps=steps, verbose=FALSE)
      rho <- rho + inc
    }
    if (verbose == TRUE) {
      cat(paste("H0 at alpha=", alpha, " can no longer be rejected at w=", rho - inc, ".", sep=""))
    } else {
      rho - inc
}
```
