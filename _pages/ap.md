---
permalink: /ap/
title: ""
type: pages
layout: single
author_profile: true
redirect_from:
  - /ap.html
---

# R code for "Permutation inference with a finite number of heterogeneous clusters"
This page provides R code for  "Permutation inference with a finite number of heterogeneous clusters" [[PDF]](/assets/hagemann_rperm.pdf). 

### Download: [hagemann_ap.R](/assets/hagemann_ap.R) 

Include this file in R with `include('hagemann_ap.R')`. Alternatively, load it into R directly with  

`include('https://hgmn.github.io/assets/hagemann_ap.R')`  

The code supplies two functions:

`ApAlphaBar` returns *&alpha;&#773;* as in Table 1 of the paper for combinations of *q*<sub>1</sub> and *q*<sub>0</sub> up to 32 by accessing [this list](https://github.com/hgmn/hgmn.github.io/blob/master/assets/hagemann_ap.csv). It has the following arguments:
  * `q1` is the number of treated clusters.
  * `q0` is the number of control clusters.
  * `alpha` is the desired level of the test. Default is `alpha=.05`.
  * `local=TRUE` looks for critial value tables in the working directory if set to `TRUE`. Default is `FALSE`. 

`ApTest` calculates the test decision as in Algorithm 3.3. It has the following arguments:
  * `x1` is a vector of cluster-level estimates from control clusters.
  * `x0` is a vector of cluster-level estimates from control clusters.
  * `alpha` is the desired level of the test. 
  * `alphabar` will be calculated automatically if `alpha` is supplied as argument. If `alphabar` is supplied, then `alpha` will be ignored.
  * `random=TRUE` computes 10<sup>4</sup> random permutations if the set of all permutations is larger than 10<sup>4</sup>. Default is `TRUE`.
  * `verbose=TRUE` provides a verbal summary of the test decision. Otherwise the value is a 1/0 decision. Default is `TRUE`.

The code also contains two auxiliary functions for generating permutations.
