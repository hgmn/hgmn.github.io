---
permalink: /rea-stata/
title: ""
type: pages
layout: single
author_profile: true
redirect_from:
  - /rea-stata.html
---

# STATA Code for "Inference with a single treated cluster"

This page provides STATA code for Table 1, Algorithm 3.3, and a robustness check contained in my paper "Inference with a single treated cluster" [[PDF]](/assets/hagemann_rea.pdf).

### Download: [stc_weight.ado](/assets/stc_weight.ado)
### Download: [stc_estimate.ado](/assets/stc_estimate.R)
### Download: [stc_estimate_robust.ado](/assets/stc_estimate_robust.R)

## Installation Instructions

1. Download `.ado` files from above.
2. In STATA command window, execute `sysdir` and locate `personal` directory.
3. Place the `.ado` files from step 1 to the `personal` directory.
4. Restart STATA.

## Details

The `.ado` files supply three functions:

`stc_weight` calculates the weight *w* as in Table 1 of the paper. It has the following arguments:
  * `q_num` is the number of control clusters.
  * `het_level` is a measure of heterogeneity. No default is supplied.
  * `conf_level` is the level of the test. No default is supplied.
  * `steps` is the number of grid points on [0,1] to search over.
Syntax is: `stc_weight, q_num(.) het_level(.) conf_level(.) steps(.)`.

`stc_estimate` calculates the test decision as in Algorithm 3.3. It has the following arguments:
  * `varlist` contains both the cluster-level estimate from a treated cluster, and a vector of cluster-level estimates from control clusters.
  * `rho_level` is a measure of heterogeneity. No default is supplied.
  * `alpha_level` is the level of the test. No default is supplied.
  * Weight *w* is calculated based on the specified values of `rho_level` and `alpha_level`.
  * `steps` from `stc_estimate` is pre-specified to be 10,000.
Syntax is: `stc_estimate varlist, rho_level(.) alpha_level(.)`.

`stc_estimate_robust` computes the largest level of heterogeneity at which the null can no longer be rejected. It has the following arguments:
  * `varlist` and `alpha_level` have the same meaning as before.
  * `rho_start` is the initial value `rho_level` for the robustness check.
  * `inc` is the increment that is added to `rho_start` for the grid search. The output of the function is correct up to less than `inc`. No default is supplied.

## Replication Code for Table 2

### Download: [Table-2-Replication.do](/assets/Table_2_Replication.do)
