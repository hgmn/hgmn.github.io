*************************************
********** program ******************
*************************************

// minimization objective
mata void f0(todo, b, y, g, H) {
	q = strtoreal(st_local("q"))
	w = strtoreal(st_local("w"))
	y = normal(w*sqrt(q)*b)^q - normal(-1*w*sqrt(q)*b)^q + 2*normal(-1*b*q)
}

// integration objective
mata real scalar f1(real scalar y, real scalar rho, real scalar w, real scalar q) {
	q = strtoreal(st_local("q"))
	w = strtoreal(st_local("w"))
	rho = strtoreal(st_local("rho"))
	return(normal((1-w)*rho*y)^q * normalden(y))
}

program define determine_cluster_size, rclass
	/* arguments */
	args varname
	
	/* figure out control cluster size */
	quiet summarize `varname'
	local q0 = r(N)
	return local q0 `q0'
end

program define stc_weight2, rclass 
	/* arguments */
	syntax [, q_num(real 1) conf_level(real 1) het_level(real 1) steps(real 1)]
	
	local w = 1/`steps'
	local q = `q_num'
	local rho = `het_level'
	local alpha = `conf_level'
		
	forvalues i=1/`steps' {
		di "current weight = `w'"
		
		// numerical optimization of f0
		mata: S = optimize_init()
		mata: optimize_init_evaluator(S, &f0())
		mata: optimize_init_params(S, 2)
		mata: optimize_init_which(S,"min")
		mata: optimize(S)
		mata: b = optimize_result_value(S)
		mata: st_numscalar("r(f0_min)", b)
		
		// numerical integration of f1
		mata: q = Quadrature()
		mata: q.setEvaluator(&f1())
		mata: q.setLimits((0, .))
		mata: q.setArgument(1, `rho')
		mata: q.setArgument(2, `w')
		mata: q.setArgument(3, `q')
		mata: q_int = q.integrate()
		mata: st_numscalar("r(f1_int)", q_int)
		
		// determine objective value
		local wres = 2^(-`q'-1) + r(f0_min) + r(f1_int)
		di `wres' " and " `alpha'
		
		// break loop if objective value is below confidence level specified
		if (`wres' <= `conf_level') {
			di "yes, weight = `w'"
			continue, break
		} 
		
		local w = `w' + (1/`steps')
		mata: mata drop S q
	}
	
	// error messages
	if `w' >= 1 {
		di "No optimal weights found. Decrease rho, increase alpha."
		return local w 0
	}
	
	if `w' < 1 {
		return local w `w'
	}
	
end
