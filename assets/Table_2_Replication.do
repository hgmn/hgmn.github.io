**********************************************************
********** replication code for Table 2 ******************
**********************************************************

clear all
clear *

set type double

import delimited using "/Users/rexhsieh/Dropbox (University of Michigan)/Single Cluster Inference - STATA/application_check/all_results.csv", clear 

forvalues i=3/7 {
	
	preserve
	
		// get data to look like what we need for input
		gen x0 = .
		gen x1 = .
		
		replace x0 = v`i' in 1
		replace x1 = v`i'
		replace x1 = . in 1
		
		keep x0 x1
		replace x1 = x1[_n+1]
		drop if missing(x1)
		
		// robustness check #1
		stc_estimate_robust x0 x1, alpha_level(0.1) rho_start(0.98) inc(0.1)
		di r(rho_max)
		local outcome`i'_1 = r(rho_max)
		
		// robustness check #2
		stc_estimate_robust x0 x1, alpha_level(0.05) rho_start(0.98) inc(0.1)
		di r(rho_max)
		local outcome`i'_2 = r(rho_max)
		
	restore
	
	di "results are: rho_max = `outcome`i'_1' and `outcome`i'_2' at alpha = 0.1 and 0.05, respectively"
	
}

// only v2 
preserve
	
	// get data to look like what we need for input
	gen x0 = .
	gen x1 = .
	
	replace x0 = v2 in 1
	replace x1 = v2
	replace x1 = . in 1
	
	keep x0 x1
	replace x1 = x1[_n+1]
	drop if missing(x1)
	
	replace x0 = -x0
	replace x1 = -x1
	
	// robustness check #1
	stc_estimate_robust x0 x1, alpha_level(0.1) rho_start(0.98) inc(0.1)
	di r(rho_max)
	local outcome2_1 = r(rho_max)
	
	// robustness check #2
	stc_estimate_robust x0 x1, alpha_level(0.05) rho_start(0.98) inc(0.1)
	di r(rho_max)
	local outcome2_2 = r(rho_max)
	
	di "results are: rho_max = `outcome2_1' and `outcome2_2' at alpha = 0.1 and 0.05, respectively"

restore


