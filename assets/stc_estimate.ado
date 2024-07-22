*************************************
********** program ******************
*************************************

// integration objective
mata real scalar f1(real scalar y, real scalar rho, real scalar w, real scalar q) {
	q = strtoreal(st_local("q"))
	w = strtoreal(st_local("w"))
	rho = strtoreal(st_local("rho"))
	return(normal((1-w)*rho*y)^(q-1) * normalden(y))
}

program define determine_cluster_size, rclass
	args varname
	
	/* figure out control cluster size */
	quiet summarize `varname'
	local q0 = r(N)
	return local q0 `q0'
end

program define stc_estimate, rclass
	/* arguments */
	syntax varlist [, alpha_level(real 1) rho_level(real 1) option(real 1)]
	
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
	if `option'==1 {
		stc_weight , q_num(`q0_size') conf_level(`alpha_level') het_level(`rho_level') steps(1000)
		local w 		= `r(w)'
		local f1_res	= `r(f1_res)'
		local alpha_l	= `alpha_level'
		local rho_l		= `rho_level'
	}
	
	if `option'==2 {
		stc_weight2 , q_num(`q0_size') conf_level(`alpha_level') het_level(`rho_level') steps(1000)
		local w 		= `r(w)'
		local f1_res	= `r(f1_res)'
		local alpha_l	= `alpha_level'
		local rho_l		= `rho_level'
	}
	
	if `option'>2 {
		di "Invalid option. Option takes either value 1 or 2. Option 1 is the default. Option 2 uses the upper bound assuming variances in control clusters are bounded away from zero."
		drop control treated
		exit
	}
		
	/* compute averages */
	quietly summarize treated if !missing(treated) /* treated */
	quietly summarize control if !missing(control) /* control */
	local mean_x0	= r(sum)/r(N)
	
	drop if missing(control) & missing(treated)
	
	preserve
		/* generate (1+w)*(treated-mean(control)), (1-w)*(treated-mean(control)), control-mean(control) */
		local x1_w1		= (1+`w')*(treated - `mean_x0')
		local x1_w2		= (1-`w')*(treated - `mean_x0')
		gen x0_w1		= (control - `mean_x0')
				
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

		quietly summarize x0_w1_placebo if _n > 2
		local mean_x0_w1_placebo = r(sum)/r(N)
	restore
		
	/* calculate decision */
	local decision_lhs = `mean_x1_w1_w2' - `mean_x0_w1'
	local decision_rhs = `mean_x1_w1_w2_placebo' - `mean_x0_w1_placebo'

	di "Decision (LHS) = " `decision_lhs' ", and Decision (RHS) = " `decision_rhs'
	
	/* drop created variables */
	drop control treated
	
	/* format decision and print; need to round due to STATA numerical issues */
	local result = (round(`decision_lhs',0.000001)==round(`decision_rhs',0.000001))
	if `result'==0 {
		di "Decision is do not reject at alpha = `alpha_level', with rho = `rho_l'"
		return local result `result'
	}
	else {
		di "Decision is reject at alpha = `alpha_level', with rho = `rho_l'. Try increasing alpha, decreasing rho."
		return local result `result'
	}
	
	if `w'==0 {
		di "w = 0, rho = `rho_level', alpha = `alpha_level', w = `w', q = `q0_size'."
		
		local boundalpha = round(5/(2^(`q0_size'+1)) + `f1_res', 0.000001)
		
		di "Caution: w=0. The test is valid but may have size less than `alpha_level'. The actual size is alpha=`boundalpha'. Increase rho or decrease alpha to remove Caution."
	}
	
end
