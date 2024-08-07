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

program define stc_estimate_robust, rclass

	syntax varlist [, alpha_level(real 1) rho_start(real 1) inc(real 1) option(real 1)]
	
	// start rho iteration
	local rho_level = `rho_start'
	
	// estimate rho_start
	stc_estimate `varlist', alpha_level(`alpha_level') rho_level(`rho_level') option(`option')
	local fin_result = r(result)
	di `fin_result'
	
	// if failing to reject, nothing else to do
	if `fin_result'==0 {
		di "NA. Test fails to reject at the level of rho specified."
	}
	
	// if rejected, then proceed with updating rho_start
	if `fin_result'==1 {
		local rho_updated = `rho_level'
		while `fin_result'==1 {
			local rho_updated = (`rho_updated' + 1)
			stc_estimate `varlist', alpha_level(`alpha_level') rho_level(`rho_updated')
			local fin_result `r(result)'
		}
	}
	
	// if rejected, then obtain rho_updated, then see where to keep searching "upwards"
	local rho_final = max(`rho_updated'-1, `rho_start')
	di `rho_final'
	
	// final loop to land on smallest, largest rho such that we fail to reject H0
	local final_decision = 1
	
	// go up the rho value by inc, where inc = increments to go upwards by
	while `final_decision' == 1 {
		stc_estimate `varlist', alpha_level(`alpha_level') rho_level(`rho_final')
		local final_decision = `r(result)'
		local rho_final = `rho_final' + `inc'
	}
	
	// show the final rho such that we fail to reject H0
	local incr_final = `rho_final' - `inc'
	local incr_final_disp = round(`incr_final', 0.0001)
	
	// final rho
	di "H0 at alpha = `alpha_level' can no longer be rejected at rho = `incr_final_disp'."
	return local rho_max = round(`incr_final_disp', 0.0001)
end
