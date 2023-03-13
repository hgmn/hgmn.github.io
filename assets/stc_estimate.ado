*************************************
********** program ******************
*************************************

program define determine_cluster_size, rclass
	args varname
	
	/* figure out control cluster size */
	quiet summarize `varname'
	local q0 = r(N)
	return local q0 `q0'
end

program define stc_estimate, rclass
	/* arguments */
	syntax varlist [, alpha_level(real 1) rho_level(real 1)]
	
	foreach var of local varlist {
		quiet summarize `var'
		if `r(N)' > 1 {
			gen control = `var'
		}
		if `r(N)' == 1 {
			gen treated = `var'
		}
	}
	
	/* figure out control cluster size */
	determine_cluster_size control
	local q0_size = `r(q0)'
	
	/* determine the length of weights to search over */	
	stc_weight , q_num(`q0_size') conf_level(`alpha_level') het_level(`rho_level') steps(1000)
	local w 		= `r(w)'
	local alpha_l	= `alpha_level'
	local rho_l		= `rho_level'
	
	/* compute averages */
	quietly summarize treated if !missing(treated) /* treated */
	quietly summarize control if !missing(control) /* control */
	local mean_x0	= r(sum)/r(N)
	di "mean of control = `mean_x0'"
	
	drop if missing(control) & missing(treated)
	
	preserve
		/* generate (1+w)*(treated-mean(control)), (1-w)*(treated-mean(control)), control-mean(control) */
		local x1_w1		= (1+`w')*(treated - `mean_x0')
		local x1_w2		= (1-`w')*(treated - `mean_x0')
		gen x0_w1		= (control - `mean_x0')
		
		di `x1_w1' `x1_w2'
		
		/* first part of decision */
		/* mean of first two entries, mean(S[1:2]) */
		local mean_x1_w1_w2	= (`x1_w1' + `x1_w2')*(0.5) 
		quietly summarize x0_w1
		local mean_x0_w1 = r(sum)/r(N)
		local q			= r(N)

		/* second part of decision */
		/* placebo sort; q+2 observations */
		local q_2		= `q'+2
		set obs `q_2'
		
		gen x0_w1_placebo = x0_w1
		replace x0_w1_placebo = _n if missing(x0_w1)
		replace x0_w1_placebo = `x1_w1' if x0_w1_placebo == (`q_2'-1)
		replace x0_w1_placebo = `x1_w2' if x0_w1_placebo == `q_2'

		/* sort placebo descendingly */
		gsort -x0_w1_placebo

		/* ingredients for decision */
		local mean_x1_w1_w2_placebo = (x0_w1_placebo[1] + x0_w1_placebo[2])*(0.5)
		di `mean_x1_w1_w2_placebo'

		quietly summarize x0_w1_placebo if _n > 2
		local mean_x0_w1_placebo = r(sum)/r(N)
		di `mean_x0_w1_placebo'
	restore
		
	/* calculate decision */
	local decision_lhs = `mean_x1_w1_w2' - `mean_x0_w1'
	local decision_rhs = `mean_x1_w1_w2_placebo' - `mean_x0_w1_placebo'

	di "Decision (LHS) is " `decision_lhs'
	di "Decision (RHS) is " `decision_rhs'
	
	drop control treated
	
	/* format decision and print */
	local result = (round(`decision_lhs',0.000001)==round(`decision_rhs',0.000001))
	if `result'==0 {
		di "Decision is do not reject at alpha = `alpha_level', with rho = `rho_l'"
		return local result `result'
	}
	else {
		di "Decision is reject at alpha = `alpha_level', with rho = `rho_l'. Try increasing alpha, decreasing rho."
		return local result `result'
	}
end
