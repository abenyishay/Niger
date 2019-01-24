********************************************************************************
* Main Analysis for NIGER USAID PRG

/* This do-file runs code to:
  	+ Main analysis of treatment effects

- This do-file uses the following datasets:
	+ 'List of PRG-PA Communes for Randomization Sept 2016-KNnotes.xlsx'
	
- This do-file produces:
	+ 
	
- v1 1-3-18 [ab]: Initial
- v2 1-10-18 [ab]
- v3 1-10-18 [ab]: adding actual data
- v4 1-18-18 [ab]: running variable-specific outcomes 
- v5 1-18-18 [ab]: adding commune-level HH data analysis
- v6 1-18-18 [ab]: adding leader analysis 
- v7 1-23-18 [ab]: cleaning up
*/
********************************************************************************
****************************************

clear all
set more off

set seed 082380

global project_path "C:\Users\Ariel\Dropbox\AidData\Niger" 		// User-specific file path.  Add your own in next row to run on your own filepath
*global project_path XXX										// Add your own filepath and uncomment this line.
global file_path "${project_path}\Analysis\Main analysis"
global logpath "${file_path}\logs"
global tablepath "${file_path}\tables"

cap mkdir "${logpath}"
cap mkdir "${tablepath}"

*******************************************************************************
global esttab_settings		"csv wrap label mtitle collab(none)  cells(b(fmt(a3) star) se(fmt(a3) par)) varwidth(6)"	// Settings for esttab command
							

********************************************************************************
cap log close
log using "${logpath}\Niger PRG Main Analysis ($S_DATE)", replace


********************************************************************************
* Macros governing which modules to run

global HH		1		// Set to 1 if want to run, 0 otherwise
global leader	1		// Set to 1 if want to run, 0 otherwise

if ${HH}==1 {
********************************************************************************
*** Household Data Files, Setting up
********************************************************************************

import excel "${file_path}\Randomized list - 16 Sep 2016 - Final.xls", sheet("Sheet1") firstrow
save "${file_path}\Randomized Assignment", replace

use "${file_path}\Randomization Frame", clear
drop _*
mmerge Region Commune using "${file_path}\Randomized Assignment"

rename *, lower

save "${file_path}\Randomization Frame and Assignment", replace 

* Merge into HH file
use "${file_path}\Niger_EndlineBaseline_Combined.dta", clear
mmerge Commune using "${file_path}\Commune codes", umatch(Commune_n)
mmerge Commune_randomization using "${file_path}\Randomization Frame and Assignment", _merge(_m_random) umatch(commune)
drop if _m_random<3

g		post = (Base==2)

* Q45 split into two --> re-join here
g 		Q45_a = Q45_1
replace Q45_a = Q45_2 if Q45_1==.

/*
4.   Multi-stakeholder dialogues will increase the perceived legitimacy of the government among citizens in the commune.
•	Citizen perceptions of government legitimacy (e.g., government has the right to make citizens pay taxes) (survey questions 41, 42, 43, 46)
*/


local H4_outcomes "Q45_a Q46_1 Q46_2 Q46_3 Q47_1 Q47_2 Q47_3 Q47_4 Q47_5 Q50_1 Q50_2 Q50_3 Q50_4 Q50_5 Q50_6 Q50_7 Q50_8 Q50_9 Q50_10 Q50_11 Q50_12 Q50_13"
foreach v of local H4_outcomes {
	recode `v' (8/. = .)
}

* Q45, 47 are negative, so need to re-orient to positive
replace Q45_a = -Q45_a
forv i = 1/5 {
	g Q47_`i'_a = - Q47_`i'
}

/*  
5. 	Multi-stakeholder dialogues will strengthen citizen perceptions that the government is responsive to their needs and demands.
•	Citizen perceptions of local government responsiveness (e.g., in your opinion, how responsive do you think the local government has been to addressing citizens' developmental needs and wants) 
	(survey questions Q49  Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2 Q58_3 Q58_4) 
	*/
local H5_outcomes "Q49  Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2" 
foreach v of local H5_outcomes {
	recode `v' (8/. = .)
}

local H5_no_Q49 "Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2"

/*
6. 	Multi-stakeholder dialogues will increase citizen perceptions that their government is democratic.
•	Citizen perceptions of democracy (e.g., In your opinion how much of a democracy is Niger today?  Overall, how satisfied are you with the way democracy works in Niger?) Q34, Q43, Q44, Q48_1, Q48_2
*/
local H6_outcomes "Q34_1 Q34_2 Q34_3 Q43 Q44 Q48_1 Q48_2"
foreach v of local H6_outcomes {
	recode `v' (8/. = .)
}

/* 
8.	Multi-stakeholder dialogues will increase citizen political participation.
•	Citizen participation (e.g., voting in local elections, attending rally, participating in demonstration, reaching out to government official) 
							(survey questions Q35_1 Q35_2 Q35_3 Q35_4 Q35_5 Q35_6 
							Q36_1 Q36_2 Q36_3 Q36_4 Q36_5 Q36_6 Q36_7 Q36_8 Q36_9 Q36_10 Q36_15 Q36_16 Q36_18-21 Q36A_97Text,
							Q37_1 Q37_2 Q37_3 Q37_4 Q37_5 Q37_6 Q37_7 Q37_8 Q37_9 Q37_10 Q37_15 Q37_16 Q37_18-21 Q37A_97Text,
							Q38_1 Q38_2 Q38_3 Q38_4 Q38_5 Q38_6 Q38_7 Q38_8 Q38_9 Q38_10 Q38_15 Q38_16 Q38_18-21 Q38A_97Text,
							Q39A_1 Q39A_2 Q39A_3 Q39A_4 Q39A_5 Q39A_6 Q39A_7 Q39A_8 Q39A_9 Q39A_10 Q39A_11 Q39A_12 Q39A_13 Q39A_14 Q39A_15,
							Q39B_1 Q39B_2 Q39B_3 Q39B_4 Q39B_5 Q39B_6 Q39B_7 Q39B_8 Q39B_9 Q39B_10 Q39B_11 Q39B_12 Q39B_13,
							Q39C_1 Q39C_2 Q39C_3 Q39C_4 Q39C_5 Q39C_6 Q39C_7 Q39C_8 Q39C_9 Q39C_10 Q39C_11 Q39C_12 Q39C_13 Q39C_14
							Q40_1_1 Q40_1_2 Q40_1_3 Q40_1_5
*/

local H8_1  "Q35_1 Q35_2 Q35_3 Q35_4 Q35_5 Q35_6 Q36A_1 Q36A_2 Q36A_3 Q36A_4 Q36A_5 Q36A_6 Q36A_7 Q36A_8 Q36A_9 Q36A_10 Q36A_11" 
local H8_2	"Q37A_1 Q37A_2 Q37A_3 Q37A_4 Q37A_5 Q37A_6 Q37A_7 Q37A_8 Q37A_9 Q37A_10 Q37A_11 Q38A_1 Q38A_2 Q38A_3 Q38A_4 Q38A_5 Q38A_6 Q38A_7 Q38A_8 Q38A_9 Q38A_10 Q38A_11"
local H8_3 	"Q39A_1 Q39A_2 Q39A_3 Q39A_4 Q39A_5 Q39A_6 Q39A_7 Q39A_8 Q39A_9 Q39A_10 Q39A_11 Q39A_12 Q39A_13 Q39A_14 Q39A_15"
local H8_4  "Q39B_1 Q39B_2 Q39B_3 Q39B_4 Q39B_5 Q39B_6 Q39B_7 Q39B_8 Q39B_9 Q39B_10 Q39B_11 Q39B_12 Q39B_13 Q39C_1 Q39C_2 Q39C_3 Q39C_4 Q39C_5 Q39C_6 Q39C_7 Q39C_8 Q39C_9 Q39C_10 Q39C_11 Q39C_12 Q39C_13 Q39C_14 Q40_1_1 Q40_1_2 Q40_1_3 Q40_1_5"

loc H8_outcomes "`H8_1' `H8_2' `H8_3' `H8_4'"
foreach v of local H8_outcomes {
	recode `v' (8/. = .)
}


save "${file_path}\HH_w_Randomization.dta", replace



********************************************************************************
*** Make index for Anderson (2008) multiple hypothesis test

use "${file_path}\HH_w_Randomization.dta", clear

keep if post

cap gen wgt = 1
local H4_outcomes "Q45_a Q46_1 Q46_2 Q46_3  Q50_1 Q50_2 Q50_3 Q50_4 Q50_5 Q50_6 Q50_7 Q50_8 Q50_9 Q50_10 Q50_11 Q50_12 Q50_13" 	
local H5_outcomes "Q49  Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2" 
local H6_outcomes "Q34_1 Q34_2 Q34_3 Q43 Q44 Q48_1 Q48_2"

local H8_1  "Q35_1 Q35_2 Q35_3 Q35_4 Q35_5 Q35_6 Q36A_1 Q36A_2 Q36A_3 Q36A_4 Q36A_5 Q36A_6 Q36A_7 Q36A_8 Q36A_9 Q36A_10 Q36A_11" 
local H8_2	"Q37A_1 Q37A_2 Q37A_3 Q37A_4 Q37A_5 Q37A_6 Q37A_7 Q37A_8 Q37A_9 Q37A_10 Q37A_11 Q38A_1 Q38A_2 Q38A_3 Q38A_4 Q38A_5 Q38A_6 Q38A_7 Q38A_8 Q38A_9 Q38A_10 Q38A_11"
local H8_3 	"Q39A_1 Q39A_2 Q39A_3 Q39A_4 Q39A_5 Q39A_6 Q39A_7 Q39A_8 Q39A_9 Q39A_10 Q39A_11 Q39A_12 Q39A_13 Q39A_14 Q39A_15"
local H8_4  "Q39B_1 Q39B_2 Q39B_3 Q39B_4 Q39B_5 Q39B_6 Q39B_7 Q39B_8 Q39B_9 Q39B_10 Q39B_11 Q39B_12 Q39B_13 Q39C_1 Q39C_2 Q39C_3 Q39C_4 Q39C_5 Q39C_6 Q39C_7 Q39C_8 Q39C_9 Q39C_10 Q39C_11 Q39C_12 Q39C_13 Q39C_14 Q40_1_1 Q40_1_2 Q40_1_3 Q40_1_5"
loc H8_outcomes "`H8_1' `H8_2' `H8_3' `H8_4'"

	
make_index H4 wgt `H4_outcomes'
make_index H5 wgt `H5_outcomes'
make_index H6 wgt `H6_outcomes'
make_index H8 wgt `H8_outcomes'

global HH_outcomes "`H4_outcomes' `H5_outcomes' `H6_outcomes' `H8_outcomes'"

save "${file_path}\HH_w_Randomization_Indices_Endline.dta", replace

*************************
* Redo with baseline data
use "${file_path}\HH_w_Randomization.dta", clear

local H4_outcomes "Q45_a Q46_1 Q46_2 Q46_3 Q47_1 Q47_2 Q47_3 Q47_4 Q47_5 Q50_1 Q50_2 Q50_3 Q50_4 Q50_5 Q50_6 Q50_7 Q50_8 Q50_9 Q50_10 Q50_11 Q50_12 Q50_13"
local H5_outcomes "Q49  Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2" 
local H6_outcomes "Q34_1 Q34_2 Q34_3 Q43 Q44 Q48_1 Q48_2"

local H8_1  "Q35_1 Q35_2 Q35_3 Q35_4 Q35_5 Q35_6 Q36A_1 Q36A_2 Q36A_3 Q36A_4 Q36A_5 Q36A_6 Q36A_7 Q36A_8 Q36A_9 Q36A_10 Q36A_11" 
local H8_2	"Q37A_1 Q37A_2 Q37A_3 Q37A_4 Q37A_5 Q37A_6 Q37A_7 Q37A_8 Q37A_9 Q37A_10 Q37A_11 Q38A_1 Q38A_2 Q38A_3 Q38A_4 Q38A_5 Q38A_6 Q38A_7 Q38A_8 Q38A_9 Q38A_10 Q38A_11"
local H8_3 	"Q39A_1 Q39A_2 Q39A_3 Q39A_4 Q39A_5 Q39A_6 Q39A_7 Q39A_8 Q39A_9 Q39A_10 Q39A_11 Q39A_12 Q39A_13 Q39A_14 Q39A_15"
local H8_4  "Q39B_1 Q39B_2 Q39B_3 Q39B_4 Q39B_5 Q39B_6 Q39B_7 Q39B_8 Q39B_9 Q39B_10 Q39B_11 Q39B_12 Q39B_13 Q39C_1 Q39C_2 Q39C_3 Q39C_4 Q39C_5 Q39C_6 Q39C_7 Q39C_8 Q39C_9 Q39C_10 Q39C_11 Q39C_12 Q39C_13 Q39C_14 Q40_1_1 Q40_1_2 Q40_1_3 Q40_1_5"
loc H8_outcomes "`H8_1' `H8_2' `H8_3' `H8_4'"

keep if !post

cap gen wgt = 1
make_index H4 wgt `H4_outcomes'
make_index H5 wgt `H5_outcomes' 
make_index H6 wgt `H6_outcomes'

local H8_outcomes  "Q35_1 Q35_2 Q35_3 Q35_4 Q35_5 Q35_6 Q40_1_1 Q40_1_2 Q40_1_3 Q40_1_5"

su `H8_outcomes'
make_index H8 wgt `H8_outcomes'

keep index* Commune_n ${HH_outcomes}
collapse index* ${HH_outcomes}, by(Commune_n)		// Because our sample is largely rolled over between rounds, we are only linking rounds at commune level.  So we take means of baseline values for each commune, and below, merge them into endline

save "${file_path}\HH_indices_base.dta", replace

************************
* Merge back into endline

use "${file_path}\HH_w_Randomization_Indices_Endline.dta", clear
mmerge Commune_n using "${file_path}\HH_indices_base.dta", uname(base_)

save "${file_path}\HH_w_Randomization_Indices_Full.dta", replace

***********************
* Keep only analysis vars for now
keep index* Commune_n Commune Village cell Treatment cell_count_draw ${HH_outcomes} base*

save "${file_path}\HH_w_Randomization_Indices.dta", replace

********************************************************************************
*** Redo at commune scale to preserve sample size, because indexing based on Anderson requires balanced observations across variables
use "${file_path}\HH_w_Randomization.dta", clear
keep if post

collapse ${HH_outcomes} Commune cell Treatment cell_count_draw , by(Commune_n)

cap gen wgt = 1
local H4_outcomes "Q45_a Q46_1 Q46_2 Q46_3  Q50_1 Q50_2 Q50_3 Q50_4 Q50_5 Q50_6 Q50_7 Q50_8 Q50_9 Q50_10 Q50_11 Q50_12 Q50_13" 	
local H5_outcomes "Q49  Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2" 
local H6_outcomes "Q34_1 Q34_2 Q34_3 Q43 Q44 Q48_1 Q48_2"

local H8_1  "Q35_1 Q35_2 Q35_3 Q35_4 Q35_5 Q35_6 Q36A_1 Q36A_2 Q36A_3 Q36A_4 Q36A_5 Q36A_6 Q36A_7 Q36A_8 Q36A_9 Q36A_10 Q36A_11" 
local H8_2	"Q37A_1 Q37A_2 Q37A_3 Q37A_4 Q37A_5 Q37A_6 Q37A_7 Q37A_8 Q37A_9 Q37A_10 Q37A_11 Q38A_1 Q38A_2 Q38A_3 Q38A_4 Q38A_5 Q38A_6 Q38A_7 Q38A_8 Q38A_9 Q38A_10 Q38A_11"
local H8_3 	"Q39A_1 Q39A_2 Q39A_3 Q39A_4 Q39A_5 Q39A_6 Q39A_7 Q39A_8 Q39A_9 Q39A_10 Q39A_11 Q39A_12 Q39A_13 Q39A_14 Q39A_15"
local H8_4  "Q39B_1 Q39B_2 Q39B_3 Q39B_4 Q39B_5 Q39B_6 Q39B_7 Q39B_8 Q39B_9 Q39B_10 Q39B_11 Q39B_12 Q39B_13 Q39C_1 Q39C_2 Q39C_3 Q39C_4 Q39C_5 Q39C_6 Q39C_7 Q39C_8 Q39C_9 Q39C_10 Q39C_11 Q39C_12 Q39C_13 Q39C_14 Q40_1_1 Q40_1_2 Q40_1_3 Q40_1_5"
loc H8_outcomes "`H8_1' `H8_2' `H8_3' `H8_4'"

	
make_index H4 wgt `H4_outcomes'
make_index H5 wgt `H5_outcomes'
make_index H6 wgt `H6_outcomes'
make_index H8 wgt `H8_outcomes'

global HH_outcomes "`H4_outcomes' `H5_outcomes' `H6_outcomes' `H8_outcomes'"

save "${file_path}\HH_w_Randomization_Indices_Endline_Commune.dta", replace

************************
* Merge back into endline 

use "${file_path}\HH_w_Randomization_Indices_Endline_Commune.dta", clear
mmerge Commune_n using "${file_path}\HH_indices_base.dta", uname(base_)

save "${file_path}\HH_w_Randomization_Indices_Full_Commune.dta", replace
***********************
* Keep only analysis vars for now
keep index* Commune_n Commune cell Treatment cell_count_draw ${HH_outcomes} base*

save "${file_path}\HH_w_Randomization_Indices_Commune.dta", replace

********************************************************************************
*** Household Analysis

**********************
* Summary tables by group
use "${file_path}\HH_w_Randomization_Indices_Full.dta", clear

local H4_outcomes "Q45_a Q46_1 Q46_2 Q46_3 Q47_1 Q47_2 Q47_3 Q47_4 Q47_5 Q50_1 Q50_2 Q50_3 Q50_4 Q50_5 Q50_6 Q50_7 Q50_8 Q50_9 Q50_10 Q50_11 Q50_12 Q50_13"
local H5_outcomes "Q49  Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2" 
local H6_outcomes "Q34_1 Q34_2 Q34_3 Q43 Q44 Q48_1 Q48_2"

local H8_1  "Q35_1 Q35_2 Q35_3 Q35_4 Q35_5 Q35_6 Q36A_1 Q36A_2 Q36A_3 Q36A_4 Q36A_5 Q36A_6 Q36A_7 Q36A_8 Q36A_9 Q36A_10 Q36A_11" 
local H8_2	"Q37A_1 Q37A_2 Q37A_3 Q37A_4 Q37A_5 Q37A_6 Q37A_7 Q37A_8 Q37A_9 Q37A_10 Q37A_11 Q38A_1 Q38A_2 Q38A_3 Q38A_4 Q38A_5 Q38A_6 Q38A_7 Q38A_8 Q38A_9 Q38A_10 Q38A_11"
local H8_3 	"Q39A_1 Q39A_2 Q39A_3 Q39A_4 Q39A_5 Q39A_6 Q39A_7 Q39A_8 Q39A_9 Q39A_10 Q39A_11 Q39A_12 Q39A_13 Q39A_14 Q39A_15"
local H8_4  "Q39B_1 Q39B_2 Q39B_3 Q39B_4 Q39B_5 Q39B_6 Q39B_7 Q39B_8 Q39B_9 Q39B_10 Q39B_11 Q39B_12 Q39B_13 Q39C_1 Q39C_2 Q39C_3 Q39C_4 Q39C_5 Q39C_6 Q39C_7 Q39C_8 Q39C_9 Q39C_10 Q39C_11 Q39C_12 Q39C_13 Q39C_14 Q40_1_1 Q40_1_2 Q40_1_3 Q40_1_5"
loc H8_outcomes "`H8_1' `H8_2' `H8_3' `H8_4'"

cap g baseline_outcome = .
foreach h in 4 5 6 8 {
	eststo clear
	foreach v of local H`h'_outcomes {
		eststo `v': areg `v' Treatment , absorb(cell) vce(cluster Commune)
		replace base = base_`v'
		cap eststo `v'_base: areg `v' Treatment baseline_outcome , absorb(cell) vce(cluster Commune)
	}
	esttab * using "${tablepath}\HH - `h'", replace ${esttab_settings}
}

**********************
* Regressions with RI

use "${file_path}\HH_w_Randomization_Indices_Full.dta", clear

eststo clear

loc num_reps 1000


* H4
ritest Treatment _b[Treatment], reps(`num_reps') strata(cell) cluster(Commune):  areg index_H4 Treatment base_index_H4 , absorb(cell) vce(cluster Commune)

* H5
ritest Treatment _b[Treatment], reps(`num_reps') strata(cell) cluster(Commune):  areg index_H5 Treatment base_index_H5 , absorb(cell) vce(cluster Commune)

* H6
ritest Treatment _b[Treatment], reps(`num_reps') strata(cell) cluster(Commune):  areg index_H6 Treatment base_index_H6 , absorb(cell) vce(cluster Commune)

* H8
ritest Treatment _b[Treatment], reps(`num_reps') strata(cell) cluster(Commune):  areg index_H8 Treatment base_index_H8 , absorb(cell) vce(cluster Commune)

*esttab * using "${tablepath}\HH indices RI", replace ${esttab_settings}


**** Redo with commune-level data
use "${file_path}\HH_w_Randomization_Indices_Commune.dta", clear

local num_reps 1000

* H4
ritest Treatment _b[Treatment], reps(`num_reps') strata(cell) cluster(Commune):  areg index_H4 Treatment base_index_H4 , absorb(cell) vce(cluster Commune)

* H5
ritest Treatment _b[Treatment], reps(`num_reps') strata(cell) cluster(Commune):  areg index_H5 Treatment base_index_H5 , absorb(cell) vce(cluster Commune)

* H6
ritest Treatment _b[Treatment], reps(`num_reps') strata(cell) cluster(Commune):  areg index_H6 Treatment base_index_H6 , absorb(cell) vce(cluster Commune)

* H8
ritest Treatment _b[Treatment], reps(`num_reps') strata(cell) cluster(Commune):  areg index_H8 Treatment base_index_H8 , absorb(cell) vce(cluster Commune)

*esttab * using "${tablepath}\HH indices RI - Commune", replace ${esttab_settings}
}


*****************************************************************
*****************************************************************
*** Leader Data

if ${leader}==1 {
*****************************************************************

use "${file_path}\Niger_Leader_EndlineBaseline_Combined.dta", clear
mmerge LK2 using "${file_path}\Commune codes_leader", umatch(lk2_n)
drop if _merge==2
destring commune_n, force replace
g		Commune_n = LK2
replace Commune_n = Commune if LK2==.


g		post = (Base==2)

*** PD9 generate new outcomes
* Number of actors consulted
egen PD9b_count = rownonmiss(PD9b_1 PD9b_2 PD9b_3 PD9b_4 PD9b_5)

* Official vs. citizen actors consulted

* Frequency and number consulted combined
forv v = 1/5{
	replace PD9c_`v' = 5 - PD9c_`v'			// Recoding so larger values are better
	}
egen PD9c_mean = rowmean(PD9c_1 PD9c_2 PD9c_3 PD9c_4 PD9c_5)	
gen PD9b_c_combined = PD9b_count*PD9c_mean

* Last time consulted
forv v = 1/5{
	recode PD9d_`v' (2016 = 542) (2017 = 182) 			// Recoding a few year answers to be 1/2 way through the year * number of days past
	replace PD9d_`v' = 655 - PD9d_`v'					// Recoding so larger values are better by subtracting from max in data
	}
egen PD9d_mean = rowmean(PD9d_1 PD9d_2 PD9d_3 PD9d_4 PD9d_5)
*Combine with number consulted
gen PD9b_d_combined = PD9b_count*PD9d_mean

*** PD10 new outcomes
* Number of actors consulted
egen PD10b_count = rownonmiss(PD10b_1 PD10b_2 PD10b_3 PD10b_4 PD10b_5)

* Official vs. citizen actors consulted

* Frequency and number consulted combined
forv v = 1/5{
	replace PD10c_`v' = 5 - PD10c_`v'			// Recoding so larger values are better
	}
egen PD10c_mean = rowmean(PD10c_1 PD10c_2 PD10c_3 PD10c_4 PD10c_5)	
gen PD10b_c_combined = PD10b_count*PD10c_mean

* Last time consulted
forv v = 1/5{
	recode PD10d_`v' (2016 = 542) (2017 = 182) 			// Recoding a few year answers to be 1/2 way through the year * number of days past
	replace PD10d_`v' = 655 - PD10d_`v'					// Recoding so larger values are better by subtracting from max in data
	}
egen PD10d_mean = rowmean(PD10d_1 PD10d_2 PD10d_3 PD10d_4 PD10d_5)
*Combine with number consulted
gen PD10b_d_combined = PD10b_count*PD10d_mean


*PD11
*recode so larger values better
replace PD11 = 3 - PD11

*PD12
*recode to deal with outliers
recode PD12 (300/10000 = 300)

*GV7 and GV8
foreach v in 7A 7B 8 {
	replace GV`v' = 4 - GV`v'
}

mmerge Commune_n using "${file_path}\Commune codes", umatch(Commune_n)
mmerge Commune_randomization using "${file_path}\Randomization Frame and Assignment", _merge(_m_random) umatch(commune)
drop if _m_random==2

save "${file_path}\Leader_w_Randomization.dta", replace

* Locals
local H1_outcomes "GV1_1 GV1_2 PD9b_count PD9c_mean PD9b_c_combined PD9d_mean PD9b_d_combined" 		// GV1_3 GV1_4 PD2E PD2H PD3E PD3H	 PD9B_1-5 - PDE_1-5
local H2_outcomes "GV3_1 GV3_2 GV3_4 GV3_5 GV3_6  PD10b_count PD10c_mean PD10b_c_combined PD10d_mean PD10b_d_combined"   			// GV3_7 GV3_8 GV3_9 GV3_10 GV3_11 GV3_12 GV3_3  PD4, PD5, PD6, PD7, PD8
local H3_outcomes "GV7A GV7B GV8"		// NEED to ADD MORE
global Leader_outcomes "`H1_outcomes' `H2_outcomes' `H3_outcomes'"

*************************
* Collapse at commune scale to preserve sample size
use "${file_path}\Leader_w_Randomization.dta", clear
keep if post

collapse ${Leader_outcomes} Commune cell treatment cell_count_draw, by(Commune_n)

cap gen wgt = 1

make_index H1 wgt `H1_outcomes'
make_index H2 wgt `H2_outcomes' 
make_index H3 wgt `H3_outcomes'


save "${file_path}\Leader_w_Randomization_Indices_Endline.dta", replace

*************************
* Redo with baseline data
use "${file_path}\Leader_w_Randomization.dta", clear

keep if !post

cap gen wgt = 1

local H1_outcomes "GV1_1 GV1_2 PD9b_count PD9c_mean PD9b_c_combined PD9d_mean PD9b_d_combined" 		// GV1_3 GV1_4 PD2E PD2H PD3E PD3H	 PD9B_1-5 - PDE_1-5
local H2_outcomes_base "GV3_1 GV3_2 GV3_4 PD10b_count PD10c_mean PD10b_c_combined PD10d_mean PD10b_d_combined"		// Removing variables not asked at baseline or for which responses very infrequent
local H3_outcomes_base "GV8"																						// Removing variables not asked at baseline or for which responses very infrequent

make_index H1 wgt `H1_outcomes'
make_index H2 wgt `H2_outcomes_base' 
make_index H3 wgt `H3_outcomes_base'

keep index* Commune_n ${Leader_outcomes}
collapse index* ${Leader_outcomes}, by(Commune_n)

save "${file_path}\Leader_indices_base.dta", replace

************************
* Merge back into endline

use "${file_path}\Leader_w_Randomization_Indices_Endline.dta", clear
mmerge Commune_n using "${file_path}\Leader_indices_base.dta", uname(base_)

save "${file_path}\Leader_w_Randomization_Indices_Full.dta", replace

***********************
* Keep only analysis vars for now
keep index* Commune_n Commune cell treatment cell_count_draw ${Leader_outcomes} base*
rename treatment Treatment

save "${file_path}\Leader_w_Randomization_Indices.dta", replace

********************************************************************************
*** ANALYSIS

use "${file_path}\Leader_w_Randomization_Indices.dta", clear

local num_reps 1000

* H1
ritest Treatment _b[Treatment], reps(`num_reps') strata(cell):  areg index_H1 Treatment base_index_H1 , absorb(cell) vce(cluster Commune_n)

* H2
ritest Treatment _b[Treatment], reps(`num_reps') strata(cell):  areg index_H2 Treatment base_index_H2 , absorb(cell) vce(cluster Commune_n)

* H3
ritest Treatment _b[Treatment], reps(`num_reps') strata(cell):  areg index_H3 Treatment base_index_H3 , absorb(cell) vce(cluster Commune_n)



/*
Elite-level hypotheses include:

1.	Multi-stakeholder dialogues will improve coordination and strategic ties between community elites.
2.	Multi-stakeholder dialogues will strengthen the representativeness of development processes. 
3.	Multi-stakeholder dialogues will increase the resources local and regional governments devote to local service delivery.

Elite-level measures for above hypotheses:
•	Elite expectations about the dependability and commitment of other elites to address citizen priorities (survey questions GV1, GV2, PD9, PD10, PD12).
•	Elites more likely to identify a diverse set of agents (beyond state authorities) to be important for community-level development (e.g., Who are the most important actors to engage for bringing about development in your commune?) (survey questions GV3, PD2, PD3, PD4, PD5, PD6, PD7, PD8, PD11, PD12, PD13, PD14).
•	Multi-stakeholder dialogues will increase the likelihood that community leaders prioritize projects matching citizen preferences.

*/

}




log close
end
