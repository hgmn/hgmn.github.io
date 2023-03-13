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

program define stc_estimate_robust, rclass

	syntax varlist [, alpha_level(real 1) rho_start(real 1) inc(real 1)]
	
	// start rho iteration
	local rho_level = `rho_start'
	
	// estimate rho_start
	stc_estimate `varlist', alpha_level(`alpha_level') rho_level(`rho_level')
	local fin_result = r(result)
	di `fin_result'
	
	// if failing to reject, nothing else to do
	if `fin_result'==0 {
		di "NA. Test fails to reject at the level of rho specified."
		exit
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
	
	// inc = increments to go upwards by
	while `final_decision' == 1 {
		stc_estimate `varlist', alpha_level(`alpha_level') rho_level(`rho_final')
		local final_decision = `r(result)'
		local rho_final = `rho_final' + `inc'
	}
	
	di `rho_final'
	
	local incr_final = `rho_final' - `inc'
	
	di "H0 at alpha = `alpha_level' can no longer be rejected at rho = `incr_final'."
	return local rho_max `incr_final'
end
