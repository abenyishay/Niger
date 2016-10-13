********************************************************************************
* Power Calculations OF NIGER USAID PRG PHASE 2 ASSIGNMENT

/* This do-file runs code to:
  	+ Determine the minimum detectable effect given our sample and randomization design

- This do-file uses the following datasets:
	+ 'List of PRG-PA Communes for Randomization Sept 2016-KNnotes.xlsx'
	+ 'Afrobarometer_Niger_Round6.dta'
	
- This do-file produces:
	+ 
	
- v1 10-11-16 [ab]: Initial 
*/
********************************************************************************
****************************************

clear all
set more off

set seed 082380

global project_path "C:\Users\Ariel\Dropbox\AidData\Niger"
global file_path "${project_path}\Sampling Design"
global logpath "${file_path}\logs"
global tablepath "${file_path}\tables"

cap mkdir "${logpath}"
cap mkdir "${tablepath}"

********************************************************************************

* Specify parameters

global inter_round_sd 1		// Specify standard deviation of mean for same HH across rds (as share of SD of mean across HH within EA for same round)

loc num_reps 10000	// Set how many repetitions 

********************************************************************************
cap log close
log using "${logpath}\Niger PRG Sampling Design ($S_DATE)", replace

* Import commune list
import excel "${file_path}\List of PRG-PA Communes for Randomization Sept 2016-KNnotes.xlsx", sheet("Input for Randomization") firstrow

* Confirm strata
egen cell=group(Region Urban Phase1)
tab cell 						// Agadez-urban-not phase 1 has only 1 commune (Bilma).  Combine cells for Agadez-urban by reassigning Bilma
recode cell (3 = 4)

* For cells with odd number of communes, randomly assign count
bys cell: egen cell_count = count(Commune)
ge			odd = mod(cell_count,2)
tempvar u
ge		`u' = runiform()
bys cell: replace `u'=`u'[1]
ge		cell_count_draw = cell_count/2
replace cell_count_draw = (cell_count + 1)/2 if odd & `u'>=0.5
replace cell_count_draw = (cell_count - 1)/2 if odd & `u'<0.5

* Confirm 24 Communes to be drawn:
tempvar z
bys cell: ge	`z' = cell_count_draw*(_n==1)
egen	total_draw = sum(`z')

* Save
save "${file_path}\Randomization Frame", replace


********************************************************************************
* Obtain outcome data from prior rounds of Afrobarometer, transfer/expand to our sample design
use "${project_path}\Secondary Data\Afrobarometer\r6\Afrobarometer_Niger_Round6.dta" , clear

// Afrobarometer sample design: sample commune, sample 1-2 EAs within, sample 8 respondents per EA
// Here, we will use all data from three of our four regions: NIAMEY (1107), ZINDER (1106), and AGADEZ (1100)
// DIFFA region was not included in AB R6

keep if REGION==1100 | REGION==1106 | REGION==1107

* Identify questions of interest
// Citizen perceptions of government responsiveness to their own needs: 41, 44, 47, 50, 52, 59, 66, 67
// Generate aggregate measure by standardizing each and then averaging

ge mean = 0
foreach v in 41 44 47A 47B 50 /* 52 */ 59A 59B /* 66 */ 67A 67B {
	gen lnQ`v' = ln(Q`v' + 1)
	qui sum lnQ`v', det
	gen q`v' = (lnQ`v' - `r(mean)') /(`r(sd)')
	loc list "`list' + q`v'_st"
	replace mean = mean + q`v'
}

replace mean = 1/9*mean
su mean
global mean `r(mean)'


* Expand from 8-16 to 30 per commune
* Parameterize intra-EA correlation
loneway mean EANUMB

* Save parameters
global sd_w = `r(sd_w)'
global sd_b = `r(sd_b)'

qui su mean
global sd_y = `r(sd)'

 
********************************************************************************


* Use RI to get distribution of betas under sharp null
 
tempname simulation	// Create filename
postfile `simulation' tau using "${tablepath}\simulation.dta", replace	// Declare file for results
	

	forvalues rep = 1/`num_reps'  {		// Run the repetitions

		*Return to randomization frame
		use "${file_path}\Randomization Frame", clear 
		* Randomize within cell
		gsample cell_count_draw, str(cell) wor gen(D_a)
		
		* expand into village, then hh
		expand 3, gen(expand_village)
		gen village_id = _n
		expand 10, gen(expand_hh)
		gen hh_id = _n
		cap drop `z' `v' `t'
		tempvar z v t
		ge	`z'	= rnormal()*$sd_w
		ge  `v' = rnormal()*$sd_b
		bys village_id: replace `v'=`v'[1] 
		* expand into time series
		expand 2, gen(t)
		ge	`t' = rnormal()*$inter_round_sd*$sd_w
		gen mean = $mean + `z' + `v' + `t' 
		* implement beta
		gen y = mean

		reg y D_a##t				// Simple way to get mean 
		loc tau = _b[1.D_a#1.t]			// Save mean as local
		post `simulation' (`tau')		// Post it to your results file
		cap drop D_a			// Drop your random assignment
	  }

	  
 postclose `simulation'			// Close your results file

 
tempname betas
postfile `betas' beta pval using "${tablepath}\betas.dta", replace	// Declare file for results
 
 use "${tablepath}\simulation.dta", clear		// Open results file
 sum tau, det			// Summarize tau

 

forv b = 0.05(0.05)0.2 {
 count if abs(tau)>abs(`b')		// Count how many instances of simulated tau
									// generate values exceeding our ATE
 loc n = `r(N)'			// Save that value as local n 
 loc pval = round((`n'+1)/(`num_reps'+1),0.001)	// Compare it to the total number of values
									// (one per repetition)
 di "p-value at beta = `b': `pval'"
 post `betas' (`b') (`pval')

 loc beta_list "`beta_list' `b'"
 loc beta_p_list "`beta_p_list' `b' "p=`pval'" "
 }
 
tw (hist tau, percent xline(-0.2 0.2, lc(red) noextend) xline(-0.1 0.1, lc(blue) noextend) xline(-0.05 0.05, lc(green) noextend) ///
	xaxis(1 2) xla(-0.25(0.05)0.25, axis(1)) xlab(`beta_p_list', axis(2)) xti("", axis(2)) xti("Treatment effect (SD)", axis(1)) ///
	, saving("${tablepath}\Power", replace))

postclose `betas'	
 
/* 
* Loop over betas
forv b = 0.05(0.05)0.3 {

	* Loop over simulations of the data
	forv i = 1/`num_reps' {

		*Return to randomization frame
		use "${file_path}\Randomization Frame", clear 

		* Randomize within cell
		gsample cell_count_draw, str(cell) wor gen(Treatment)

		* expand into village, then hh
		expand 3, gen(expand_village)
		gen village_id = _n
		expand 10, gen(expand_hh)
		gen hh_id = _n
		cap drop `z' `v' `t'
		tempvar z v t
		ge	`z'	= rnormal()*$sd_w
		ge  `v' = rnormal()*$sd_b
		bys village_id: replace `v'=`v'[1] 

		* expand into time series
		expand 2, gen(t)
		ge	`t' = rnormal()*$inter_round_sd*$sd_w

		gen mean = $mean + `z' + `v' + `t' 

		di `b'
		
		* implement beta
		gen y = mean + `b'*Treatment*t

		* run RI
		reg y Treatment##t, cluster(Commune)
		loc ATE = _b[1.Treatment#1.t]
		
		* Compare to betas from sharp null

		  use "${tablepath}\simulation.dta", clear		// Open results file
		  sum tau, det			// Summarize tau
		  
		  count if abs(tau)>abs(`ATE')		// Count how many instances of simulated tau
						// generate values exceeding our ATE
		  loc n = `r(N)'			// Save that value as local n 
		  loc pval = (`n'+1)/(`num_reps'+1)	// Compare it to the total number of values
						// (one per repetition)
		  di "p-value = `pval'"
		  
		  post `betas' (`b') (`pval')

	}
}

postclose `betas'

log close
