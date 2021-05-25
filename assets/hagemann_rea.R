# Calculates w as in Table 1
stc.weight <- function(q, alpha=.05, rho=5, steps=10^4) {
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
