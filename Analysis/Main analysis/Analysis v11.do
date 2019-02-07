********************************************************************************
* Main Analysis for NIGER USAID PRG

/* This do-file runs code to:
  	+ Main analysis of treatment effects

- This do-file uses the following datasets:
	+ 'List of PRG-PA Communes for Randomization Sept 2016-KNnotes.xlsx'
	
- This do-file produces:
	+ 
	
- v1 1-3-19 [ab]: Initial
- v2 1-10-19 [ab]
- v3 1-10-19 [ab]: adding actual data
- v4 1-18-19 [ab]: running variable-specific outcomes 
- v5 1-18-19 [ab]: adding commune-level HH data analysis
- v6 1-18-19 [ab]: adding leader analysis 
- v7 1-23-19 [ab]: cleaning up
- v8 1-29-19 [ab]: 
- v9 1-30-19 [ab]: checking MSD participation and awareness
*/
********************************************************************************
****************************************

clear all
set more off

set seed 082380

global project_path "C:\Users\Ariel\Dropbox\AidData\Niger" 		// User-specific file path.  Add your own in next row to run on your own filepath
*global project_path XXX										// Add your own filepath and uncomment this line.
*global project_path "C:\Users\lisamueller\Dropbox\Niger"		// Lisa's filepath

global file_path "${project_path}\Analysis\Main analysis"
global logpath "${file_path}\logs"
global tablepath "${file_path}\tables"

cap mkdir "${logpath}"
cap mkdir "${tablepath}"

*******************************************************************************
global esttab_settings		"csv wrap label mtitle collab(none)   varwidth(6)"	//  cells(b(fmt(a3) star) se(fmt(a3) par)) Settings for esttab command
							

********************************************************************************
cap log close
log using "${logpath}\Niger PRG Main Analysis ($S_DATE)", replace


********************************************************************************
* Macros governing which modules to run

global HH		01		// Set to 1 if want to run, 0 otherwise
global HH_import 01
global HH_index_and_merge 01
global leader	0		// Set to 1 if want to run, 0 otherwise

if ${HH}==1 {
********************************************************************************
*** Household Data Files, Setting up
********************************************************************************

global H4_outcomes "Q45_a Q46_1 Q46_2 Q46_3 Q47_1_a Q47_2_a Q47_3_a Q47_4_a Q47_5_a Q50_1 Q50_2 Q50_3 Q50_4 Q50_5 Q50_6 Q50_7 Q50_8 Q50_9 Q50_10 Q50_11 Q50_12 Q50_13"
global H5_outcomes "Q49  Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2" 
global H4a_outcomes "Q45_a Q46_1 Q46_2 Q46_3"
global H4b_outcomes "Q47_1_a Q47_2_a Q47_3_a Q47_4_a Q47_5_a"
global H4c_outcomes "Q50_1 Q50_2 Q50_3 Q50_4 Q50_5 Q50_6 Q50_7 Q50_8 Q50_9 Q50_10 Q50_11 Q50_12 Q50_13"
global H5_outcomes "Q49  Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2" 
global H6_outcomes "Q34_1 Q34_2 Q34_3 Q43 Q44 Q48_1 Q48_2"
global H6a_outcomes "Q34_1 Q34_2 Q34_3 Q43 Q44"					// Q48_1 Q48_2

global H8_1  "Q35_1 Q35_2 Q35_3 Q35_4 Q35_5 Q35_6 Q36A_1 Q36A_2 Q36A_3 Q36A_4 Q36A_5 Q36A_6 Q36A_7 Q36A_8 Q36A_9 Q36A_10 Q36A_11" 
global H8_2	"Q37A_1 Q37A_2 Q37A_3 Q37A_4 Q37A_5 Q37A_6 Q37A_7 Q37A_8 Q37A_9 Q37A_10 Q37A_11 Q38A_1 Q38A_2 Q38A_3 Q38A_4 Q38A_5 Q38A_6 Q38A_7 Q38A_8 Q38A_9 Q38A_10 Q38A_11"
global H8_3 	"Q39A_1 Q39A_2 Q39A_3 Q39A_4 Q39A_5 Q39A_6 Q39A_7 Q39A_8 Q39A_9 Q39A_10 Q39A_11 Q39A_12 Q39A_13 Q39A_14 Q39A_15"
global H8_4  "Q39B_1 Q39B_2 Q39B_3 Q39B_4 Q39B_5 Q39B_6 Q39B_7 Q39B_8 Q39B_9 Q39B_10 Q39B_11 Q39B_12 Q39B_13 Q39C_1 Q39C_2 Q39C_3 Q39C_4 Q39C_5 Q39C_6 Q39C_7 Q39C_8 Q39C_9 Q39C_10 Q39C_11 Q39C_12 Q39C_13 Q39C_14 Q40_1_1 Q40_1_2 Q40_1_3 Q40_1_5"
global H8_outcomes "${H8_1} ${H8_2} ${H8_3} ${H8_4}"

global HH_outcomes "${H4_outcomes} ${H5_outcomes} ${H6_outcomes} ${H8_outcomes}"

if ${HH_import}==1 {
clear
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


*local H4_outcomes "Q45_a Q46_1 Q46_2 Q46_3 Q47_1 Q47_2 Q47_3 Q47_4 Q47_5 Q50_1 Q50_2 Q50_3 Q50_4 Q50_5 Q50_6 Q50_7 Q50_8 Q50_9 Q50_10 Q50_11 Q50_12 Q50_13"

foreach v of global H4_outcomes {
	recode `v' (8/. = .)
}

* Q45, 47 are negative, so need to re-orient to positive
replace Q45_a = 5-Q45_a
forv i = 1/5 {
	g Q47_`i'_a = 4 - Q47_`i'
}

/*  
5. 	Multi-stakeholder dialogues will strengthen citizen perceptions that the government is responsive to their needs and demands.
•	Citizen perceptions of local government responsiveness (e.g., in your opinion, how responsive do you think the local government has been to addressing citizens' developmental needs and wants) 
	(survey questions Q49  Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2 Q58_3 Q58_4) 
	*/
*local H5_outcomes "Q49  Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2" 
foreach v of global H5_outcomes {
	recode `v' (8/. = .)
}

*local H5_no_Q49 "Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2"

/*
6. 	Multi-stakeholder dialogues will increase citizen perceptions that their government is democratic.
•	Citizen perceptions of democracy (e.g., In your opinion how much of a democracy is Niger today?  Overall, how satisfied are you with the way democracy works in Niger?) Q34, Q43, Q44, Q48_1, Q48_2
*/
*local H6_outcomes "Q34_1 Q34_2 Q34_3 Q43 Q44 Q48_1 Q48_2"
foreach v of global H6_outcomes {
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

/*
local H8_1  "Q35_1 Q35_2 Q35_3 Q35_4 Q35_5 Q35_6 Q36A_1 Q36A_2 Q36A_3 Q36A_4 Q36A_5 Q36A_6 Q36A_7 Q36A_8 Q36A_9 Q36A_10 Q36A_11" 
local H8_2	"Q37A_1 Q37A_2 Q37A_3 Q37A_4 Q37A_5 Q37A_6 Q37A_7 Q37A_8 Q37A_9 Q37A_10 Q37A_11 Q38A_1 Q38A_2 Q38A_3 Q38A_4 Q38A_5 Q38A_6 Q38A_7 Q38A_8 Q38A_9 Q38A_10 Q38A_11"
local H8_3 	"Q39A_1 Q39A_2 Q39A_3 Q39A_4 Q39A_5 Q39A_6 Q39A_7 Q39A_8 Q39A_9 Q39A_10 Q39A_11 Q39A_12 Q39A_13 Q39A_14 Q39A_15"
local H8_4  "Q39B_1 Q39B_2 Q39B_3 Q39B_4 Q39B_5 Q39B_6 Q39B_7 Q39B_8 Q39B_9 Q39B_10 Q39B_11 Q39B_12 Q39B_13 Q39C_1 Q39C_2 Q39C_3 Q39C_4 Q39C_5 Q39C_6 Q39C_7 Q39C_8 Q39C_9 Q39C_10 Q39C_11 Q39C_12 Q39C_13 Q39C_14 Q40_1_1 Q40_1_2 Q40_1_3 Q40_1_5"

loc H8_outcomes "`H8_1' `H8_2' `H8_3' `H8_4'"
*/

foreach v of global H8_outcomes {
	recode `v' (8/. = .)
}


save "${file_path}\HH_w_Randomization.dta", replace

}


********************************************************************************
*** Make index for Anderson (2008) multiple hypothesis test

if ${HH_index_and_merge}==1 {
use "${file_path}\HH_w_Randomization.dta", clear

keep if post

cap gen wgt = 1
/*
local H4_outcomes "Q45_a Q46_1 Q46_2 Q46_3  Q50_1 Q50_2 Q50_3 Q50_4 Q50_5 Q50_6 Q50_7 Q50_8 Q50_9 Q50_10 Q50_11 Q50_12 Q50_13" 	
local H4a_outcomes "Q45_a Q46_1 Q46_2 Q46_3 Q50_1 Q50_2 Q50_3 Q50_4 Q50_5 Q50_6 Q50_7 Q50_8 Q50_9 Q50_10 Q50_11 Q50_12 Q50_13" 									// Q47_1 Q47_2 Q47_3 Q47_4 Q47_5 
local H5_outcomes "Q49  Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2" 
local H6_outcomes "Q34_1 Q34_2 Q34_3 Q43 Q44 Q48_1 Q48_2"
local H6a_outcomes "Q34_1 Q34_2 Q34_3 Q43 Q44"					// Q48_1 Q48_2

local H8_1  "Q35_1 Q35_2 Q35_3 Q35_4 Q35_5 Q35_6 Q36A_1 Q36A_2 Q36A_3 Q36A_4 Q36A_5 Q36A_6 Q36A_7 Q36A_8 Q36A_9 Q36A_10 Q36A_11" 
local H8_2	"Q37A_1 Q37A_2 Q37A_3 Q37A_4 Q37A_5 Q37A_6 Q37A_7 Q37A_8 Q37A_9 Q37A_10 Q37A_11 Q38A_1 Q38A_2 Q38A_3 Q38A_4 Q38A_5 Q38A_6 Q38A_7 Q38A_8 Q38A_9 Q38A_10 Q38A_11"
local H8_3 	"Q39A_1 Q39A_2 Q39A_3 Q39A_4 Q39A_5 Q39A_6 Q39A_7 Q39A_8 Q39A_9 Q39A_10 Q39A_11 Q39A_12 Q39A_13 Q39A_14 Q39A_15"
local H8_4  "Q39B_1 Q39B_2 Q39B_3 Q39B_4 Q39B_5 Q39B_6 Q39B_7 Q39B_8 Q39B_9 Q39B_10 Q39B_11 Q39B_12 Q39B_13 Q39C_1 Q39C_2 Q39C_3 Q39C_4 Q39C_5 Q39C_6 Q39C_7 Q39C_8 Q39C_9 Q39C_10 Q39C_11 Q39C_12 Q39C_13 Q39C_14 Q40_1_1 Q40_1_2 Q40_1_3 Q40_1_5"
loc H8_outcomes "`H8_1' `H8_2' `H8_3' `H8_4'"
*/

foreach v in 4 4a 4b 4c 5 6 6a 8 {
	local H`v'_outcomes "${H`v'_outcomes}"
	make_index H`v' wgt `H`v'_outcomes'
}
/*	
make_index H4 wgt `H4_outcomes'
make_index H4a wgt `H4a_outcomes'
make_index H5 wgt `H5_outcomes'
make_index H6 wgt `H6_outcomes'
make_index H6a wgt `H6a_outcomes'
make_index H8 wgt `H8_outcomes'
*/


save "${file_path}\HH_w_Randomization_Indices_Endline.dta", replace

*************************
* Redo with baseline data
use "${file_path}\HH_w_Randomization.dta", clear

/*
local H4_outcomes "Q45_a Q46_1 Q46_2 Q46_3 Q47_1 Q47_2 Q47_3 Q47_4 Q47_5 Q50_1 Q50_2 Q50_3 Q50_4 Q50_5 Q50_6 Q50_7 Q50_8 Q50_9 Q50_10 Q50_11 Q50_12 Q50_13"
local H4a_outcomes "Q45_a Q46_1 Q46_2 Q46_3 Q50_1 Q50_2 Q50_3 Q50_4 Q50_5 Q50_6 Q50_7 Q50_8 Q50_9 Q50_10 Q50_11 Q50_12 Q50_13" 									// Q47_1 Q47_2 Q47_3 Q47_4 Q47_5 
local H5_outcomes "Q49  Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2" 
local H6_outcomes "Q34_1 Q34_2 Q34_3 Q43 Q44 Q48_1 Q48_2"
local H6a_outcomes "Q34_1 Q34_2 Q34_3 Q43 Q44"					// Q48_1 Q48_2

local H8_1  "Q35_1 Q35_2 Q35_3 Q35_4 Q35_5 Q35_6 Q36A_1 Q36A_2 Q36A_3 Q36A_4 Q36A_5 Q36A_6 Q36A_7 Q36A_8 Q36A_9 Q36A_10 Q36A_11" 
local H8_2	"Q37A_1 Q37A_2 Q37A_3 Q37A_4 Q37A_5 Q37A_6 Q37A_7 Q37A_8 Q37A_9 Q37A_10 Q37A_11 Q38A_1 Q38A_2 Q38A_3 Q38A_4 Q38A_5 Q38A_6 Q38A_7 Q38A_8 Q38A_9 Q38A_10 Q38A_11"
local H8_3 	"Q39A_1 Q39A_2 Q39A_3 Q39A_4 Q39A_5 Q39A_6 Q39A_7 Q39A_8 Q39A_9 Q39A_10 Q39A_11 Q39A_12 Q39A_13 Q39A_14 Q39A_15"
local H8_4  "Q39B_1 Q39B_2 Q39B_3 Q39B_4 Q39B_5 Q39B_6 Q39B_7 Q39B_8 Q39B_9 Q39B_10 Q39B_11 Q39B_12 Q39B_13 Q39C_1 Q39C_2 Q39C_3 Q39C_4 Q39C_5 Q39C_6 Q39C_7 Q39C_8 Q39C_9 Q39C_10 Q39C_11 Q39C_12 Q39C_13 Q39C_14 Q40_1_1 Q40_1_2 Q40_1_3 Q40_1_5"
loc H8_outcomes "`H8_1' `H8_2' `H8_3' `H8_4'"
*/

keep if !post

cap gen wgt = 1
foreach v in 4 4a 4b 4c 5 6 6a {
	local H`v'_outcomes "${H`v'_outcomes}"
	make_index H`v' wgt `H`v'_outcomes'
}

/*
make_index H4 wgt `H4_outcomes'
make_index H4a wgt `H4a_outcomes'
make_index H5 wgt `H5_outcomes'
make_index H6 wgt `H6_outcomes'
make_index H6a wgt `H6a_outcomes'
make_index H8 wgt `H8_outcomes'
*/

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
/*
local H4_outcomes "Q45_a Q46_1 Q46_2 Q46_3  Q50_1 Q50_2 Q50_3 Q50_4 Q50_5 Q50_6 Q50_7 Q50_8 Q50_9 Q50_10 Q50_11 Q50_12 Q50_13" 	
local H4a_outcomes "Q45_a Q46_1 Q46_2 Q46_3 Q50_1 Q50_2 Q50_3 Q50_4 Q50_5 Q50_6 Q50_7 Q50_8 Q50_9 Q50_10 Q50_11 Q50_12 Q50_13" 									// Q47_1 Q47_2 Q47_3 Q47_4 Q47_5 
local H5_outcomes "Q49  Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2" 
local H6_outcomes "Q34_1 Q34_2 Q34_3 Q43 Q44 Q48_1 Q48_2"
local H6a_outcomes "Q34_1 Q34_2 Q34_3 Q43 Q44 "					// Q48_1 Q48_2

local H8_1  "Q35_1 Q35_2 Q35_3 Q35_4 Q35_5 Q35_6 Q36A_1 Q36A_2 Q36A_3 Q36A_4 Q36A_5 Q36A_6 Q36A_7 Q36A_8 Q36A_9 Q36A_10 Q36A_11" 
local H8_2	"Q37A_1 Q37A_2 Q37A_3 Q37A_4 Q37A_5 Q37A_6 Q37A_7 Q37A_8 Q37A_9 Q37A_10 Q37A_11 Q38A_1 Q38A_2 Q38A_3 Q38A_4 Q38A_5 Q38A_6 Q38A_7 Q38A_8 Q38A_9 Q38A_10 Q38A_11"
local H8_3 	"Q39A_1 Q39A_2 Q39A_3 Q39A_4 Q39A_5 Q39A_6 Q39A_7 Q39A_8 Q39A_9 Q39A_10 Q39A_11 Q39A_12 Q39A_13 Q39A_14 Q39A_15"
local H8_4  "Q39B_1 Q39B_2 Q39B_3 Q39B_4 Q39B_5 Q39B_6 Q39B_7 Q39B_8 Q39B_9 Q39B_10 Q39B_11 Q39B_12 Q39B_13 Q39C_1 Q39C_2 Q39C_3 Q39C_4 Q39C_5 Q39C_6 Q39C_7 Q39C_8 Q39C_9 Q39C_10 Q39C_11 Q39C_12 Q39C_13 Q39C_14 Q40_1_1 Q40_1_2 Q40_1_3 Q40_1_5"
loc H8_outcomes "`H8_1' `H8_2' `H8_3' `H8_4'"
*/


foreach v in 4 4a 4b 4c 5 6 6a 8 {
	local H`v'_outcomes "${H`v'_outcomes}"
	make_index H`v' wgt `H`v'_outcomes'
}
/*	
make_index H4 wgt `H4_outcomes'
make_index H4a wgt `H4a_outcomes'
make_index H5 wgt `H5_outcomes'
make_index H6 wgt `H6_outcomes'
make_index H6a wgt `H6a_outcomes'
make_index H8 wgt `H8_outcomes'

global HH_outcomes "`H4_outcomes' `H5_outcomes' `H6_outcomes' `H8_outcomes'"
*/

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


}



********************************************************************************
*** Household Analysis

**********************
* Summary tables by group
use "${file_path}\HH_w_Randomization_Indices_Full.dta", clear

/*
local H4_outcomes "Q45_a Q46_1 Q46_2 Q46_3 Q47_1 Q47_2 Q47_3 Q47_4 Q47_5 Q50_1 Q50_2 Q50_3 Q50_4 Q50_5 Q50_6 Q50_7 Q50_8 Q50_9 Q50_10 Q50_11 Q50_12 Q50_13"
local H4a_outcomes "Q45_a Q46_1 Q46_2 Q46_3 Q50_1 Q50_2 Q50_3 Q50_4 Q50_5 Q50_6 Q50_7 Q50_8 Q50_9 Q50_10 Q50_11 Q50_12 Q50_13" 									// Q47_1 Q47_2 Q47_3 Q47_4 Q47_5 
local H5_outcomes "Q49  Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2" 
local H6_outcomes "Q34_1 Q34_2 Q34_3 Q43 Q44 Q48_1 Q48_2"
local H6a_outcomes "Q34_1 Q34_2 Q34_3 Q43 Q44 "					// Q48_1 Q48_2

local H8_1  "Q35_1 Q35_2 Q35_3 Q35_4 Q35_5 Q35_6 Q36A_1 Q36A_2 Q36A_3 Q36A_4 Q36A_5 Q36A_6 Q36A_7 Q36A_8 Q36A_9 Q36A_10 Q36A_11" 
local H8_2	"Q37A_1 Q37A_2 Q37A_3 Q37A_4 Q37A_5 Q37A_6 Q37A_7 Q37A_8 Q37A_9 Q37A_10 Q37A_11 Q38A_1 Q38A_2 Q38A_3 Q38A_4 Q38A_5 Q38A_6 Q38A_7 Q38A_8 Q38A_9 Q38A_10 Q38A_11"
local H8_3 	"Q39A_1 Q39A_2 Q39A_3 Q39A_4 Q39A_5 Q39A_6 Q39A_7 Q39A_8 Q39A_9 Q39A_10 Q39A_11 Q39A_12 Q39A_13 Q39A_14 Q39A_15"
local H8_4  "Q39B_1 Q39B_2 Q39B_3 Q39B_4 Q39B_5 Q39B_6 Q39B_7 Q39B_8 Q39B_9 Q39B_10 Q39B_11 Q39B_12 Q39B_13 Q39C_1 Q39C_2 Q39C_3 Q39C_4 Q39C_5 Q39C_6 Q39C_7 Q39C_8 Q39C_9 Q39C_10 Q39C_11 Q39C_12 Q39C_13 Q39C_14 Q40_1_1 Q40_1_2 Q40_1_3 Q40_1_5"
loc H8_outcomes "`H8_1' `H8_2' `H8_3' `H8_4'"
*/

cap drop baseline_outcome
g baseline_outcome = .
foreach h in 4 5 6 8 {
	eststo clear
	foreach v of global H`h'_outcomes {
		replace baseline_outcome = .
		eststo `v': areg `v' Treatment , absorb(cell) vce(cluster Commune)
		cap replace baseline_outcome = base_`v'
		su `v' baseline_outcome
		cap eststo `v'_base: areg `v' Treatment baseline_outcome, absorb(cell) vce(cluster Commune)
	}
	esttab * using "${tablepath}\HH - `h'", replace ${esttab_settings} nocons
}

**********************
* Regressions with RI

use "${file_path}\HH_w_Randomization_Indices_Full.dta", clear

eststo clear

global num_reps 1000


* Loop over indices
foreach v in 4 4a 4b 4c 5 6 6a 8 {
	areg index_H`v' Treatment base_index_H`v' , absorb(cell) vce(cluster Commune)
	eststo H`v'
	ritest Treatment _b[Treatment], reps($num_reps) strata(cell) cluster(Commune):  areg index_H`v' Treatment base_index_H`v' , absorb(cell) vce(cluster Commune)
	matrix pvalues = r(p)
	mat colnames pvalues = Treatment
	est restore H`v'
	estadd matrix pvalues = pvalues
	/*
	estadd scalar pval = pvalues[1,1]
	esttab * using "${tablepath}\HH indices RI", replace ${esttab_settings} stats(pval)
	*/
}

esttab * using "${tablepath}\HH indices RI", replace cells(b(fmt(a3)) p(par) pvalues(par([ ]))) ${esttab_settings} nocons

/*
* H4
areg index_H4 Treatment base_index_H4 , absorb(cell) vce(cluster Commune)


* H5
areg index_H5 Treatment base_index_H5 , absorb(cell) vce(cluster Commune)
eststo H5
ritest Treatment _b[Treatment], reps($num_reps) strata(cell) cluster(Commune):  areg index_H5 Treatment base_index_H5 , absorb(cell) vce(cluster Commune)
estadd scalar pval = pvalues[1,1]

* H6
areg index_H6 Treatment base_index_H6 , absorb(cell) vce(cluster Commune)
eststo H6
ritest Treatment _b[Treatment], reps($num_reps) strata(cell) cluster(Commune):  areg index_H6 Treatment base_index_H6 , absorb(cell) vce(cluster Commune)
estadd scalar pval = pvalues[1,1]

* H8
areg index_H8 Treatment base_index_H8 , absorb(cell) vce(cluster Commune)
eststo H8
ritest Treatment _b[Treatment], reps($num_reps) strata(cell) cluster(Commune):  areg index_H8 Treatment base_index_H8 , absorb(cell) vce(cluster Commune)
estadd scalar pval = pvalues[1,1]
*/


**** Redo with commune-level data
use "${file_path}\HH_w_Randomization_Indices_Commune.dta", clear

eststo clear

* Loop over indices
foreach v in 4 4a 4b 4c 5 6 6a 8 {
	areg index_H`v' Treatment base_index_H`v' , absorb(cell) vce(cluster Commune)
	eststo H`v'
	ritest Treatment _b[Treatment], reps($num_reps) strata(cell) cluster(Commune):  areg index_H`v' Treatment base_index_H`v' , absorb(cell) vce(cluster Commune)
	matrix pvalues = r(p)
	mat colnames pvalues = Treatment
	est restore H`v'
	estadd matrix pvalues = pvalues
	/*
	estadd scalar pval = pvalues[1,1]
	esttab * using "${tablepath}\HH indices RI", replace ${esttab_settings} stats(pval)
	*/
}

esttab * using "${tablepath}\HH indices RI - commune", replace cells(b(fmt(a3)) p(par) pvalues(par([ ]))) ${esttab_settings} nocons


/*
* H4
ritest Treatment _b[Treatment], reps($num_reps) strata(cell) cluster(Commune):  areg index_H4 Treatment base_index_H4 , absorb(cell) vce(cluster Commune)

* H5
ritest Treatment _b[Treatment], reps($num_reps) strata(cell) cluster(Commune):  areg index_H5 Treatment base_index_H5 , absorb(cell) vce(cluster Commune)

* H6
ritest Treatment _b[Treatment], reps($num_reps) strata(cell) cluster(Commune):  areg index_H6 Treatment base_index_H6 , absorb(cell) vce(cluster Commune)

* H8
ritest Treatment _b[Treatment], reps($num_reps) strata(cell) cluster(Commune):  areg index_H8 Treatment base_index_H8 , absorb(cell) vce(cluster Commune)

*esttab * using "${tablepath}\HH indices RI - Commune", replace ${esttab_settings}

*/

}


******************
* MSD Treatment Checks
use "${file_path}\HH_w_Randomization.dta", clear

foreach v in 60 61A 62 63A 63B_1 63B_2 {
	tab Q`v' Tre, col
}

tab Q42 Treat if post, col
recode Q42 (10/. = .)
replace Q42 = 5 - Q42

areg Q42 post##Treat, absorb(cell) vce(cluster Commune)

tab Q66 Treat
forv v = 1/11 {
	tab Q67_`v' Treat, col
}

tab Q68 Treat if post, col
recode Q68 (10/. = .)
replace Q68 = 5 - Q68






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


* Frequency and number consulted combined
forv v = 1/5{
	replace PD9c_`v' = 4 - PD9c_`v'			// Recoding so larger values are better
	}
egen PD9c_mean = rowmean(PD9c_1 PD9c_2 PD9c_3 PD9c_4 PD9c_5)	
gen PD9b_c_combined = PD9b_count*PD9c_mean

* Type of actors consulted
forv v = 1/5 {
	g 	PD9_`v'_comm_leader = inlist(PD9b_`v',2,3,4,5,12,13,17,18,19,20,25)
	g	PD9_`v'_formal_org =  inlist(PD9b_`v',7,8,11,15,16,24)
	g	PD9_`v'_informal_unorg =  inlist(PD9b_`v',1,6,9,10,14,21,22,23,26)
	g 	PD9_`v'_comm_leader_freq = PD9_`v'_comm_leader*PD9c_`v'
	g	PD9_`v'_formal_org_freq =  PD9_`v'_formal_org*PD9c_`v'
	g	PD9_`v'_informal_unorg_freq =  PD9_`v'_informal_unorg*PD9c_`v'
}
egen PD9_comm_leader_freq = rowtotal(PD9_1_comm_leader_freq PD9_2_comm_leader_freq PD9_3_comm_leader_freq PD9_4_comm_leader_freq PD9_5_comm_leader_freq)
egen PD9_formal_org_freq = rowtotal(PD9_1_formal_org_freq PD9_2_formal_org_freq PD9_3_formal_org_freq PD9_4_formal_org_freq PD9_5_formal_org_freq)
egen PD9_informal_unorg_freq = rowtotal(PD9_1_informal_unorg_freq PD9_2_informal_unorg_freq PD9_3_informal_unorg_freq PD9_4_informal_unorg_freq PD9_5_informal_unorg_freq)

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

*GV4B and GV5B recode non-responses
recode GV4B (5/100 = .)
recode GV5B (5/100 = .)
* reorient so larger numbers are positive
foreach v in 4 5 {
	replace GV`v'B = 4 - GV`v'B
}


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
local H1_outcomes "GV1_2 PD12 PD9b_count PD9c_mean PD9b_c_combined PD9d_mean PD9b_d_combined" 		// GV1_3 GV1_1 GV1_3 GV1_4 PD2E PD2H PD3E PD3H	 PD9B_1-5 - PDE_1-5
local H2_outcomes "GV3_1 GV3_2 GV3_4 GV4B GV5B PD10b_count PD10c_mean PD10b_c_combined PD10d_mean PD10b_d_combined "	// GV3_7 GV3_11 GV3_12  PD6H PD6E PD2H PD3H PD2E, PD3E,  Removing variables not asked at baseline or for which responses very infrequent
local H3_outcomes "GV8"																						// Removing variables not asked at baseline or for which responses very infrequent

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

collapse ${Leader_outcomes}, by(Commune_n)

cap gen wgt = 1

local H1_outcomes_base "GV1_2 PD12 PD9b_count PD9c_mean PD9b_c_combined PD9d_mean PD9b_d_combined" 		// GV1_1 GV1_3 GV1_4 PD2E PD2H PD3E PD3H	 PD9B_1-5 - PDE_1-5
local H2_outcomes_base "GV3_1 GV3_2 GV3_4 GV4B GV5B PD10b_count PD10c_mean PD10b_c_combined PD10d_mean PD10b_d_combined "	// GV3_7 GV3_11 GV3_12  PD6H PD6E PD2H PD3H PD2E, PD3E,  Removing variables not asked at baseline or for which responses very infrequent
local H3_outcomes_base "GV8"																						// Removing variables not asked at baseline or for which responses very infrequent

make_index H1 wgt `H1_outcomes_base'
make_index H2 wgt `H2_outcomes_base' 
make_index H3 wgt `H3_outcomes_base'

keep index* Commune_n ${Leader_outcomes}


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

**********************
* Summary tables by group

local H1_outcomes "GV1_2 PD12 PD9b_count PD9c_mean PD9b_c_combined PD9d_mean PD9b_d_combined" 		// GV1_3 GV1_1 GV1_3 GV1_4 PD2E PD2H PD3E PD3H	 PD9B_1-5 - PDE_1-5
local H2_outcomes "GV3_1 GV3_2 GV3_4 GV4B GV5B PD10b_count PD10c_mean PD10b_c_combined PD10d_mean PD10b_d_combined "	// GV3_7 GV3_11 GV3_12  PD6H PD6E PD2H PD3H PD2E, PD3E,  Removing variables not asked at baseline or for which responses very infrequent
local H3_outcomes "GV8"																						// Removing variables not asked at baseline or for which responses very infrequent

cap g baseline_outcome = .
foreach h in 1 2 3 {
	eststo clear
	foreach v of local H`h'_outcomes {
		eststo `v': areg `v' Treatment , absorb(cell) vce(cluster Commune_n)
		replace baseline_outcome = base_`v'
		cap eststo `v'_base: areg `v' Treatment baseline_outcome , absorb(cell) vce(cluster Commune_n)
	}
	esttab * using "${tablepath}\Leader - `h'", replace ${esttab_settings}
}


*******
* RI

global num_reps 1000

* H1
* without baseline
ritest Treatment _b[Treatment], reps($num_reps) strata(cell):  areg index_H1 Treatment , absorb(cell) vce(cluster Commune_n)
* with bl
ritest Treatment _b[Treatment], reps($num_reps) strata(cell):  areg index_H1 Treatment base_index_H1 , absorb(cell) vce(cluster Commune_n)


* H2
* without baseline
ritest Treatment _b[Treatment], reps($num_reps) strata(cell):  areg index_H2 Treatment , absorb(cell) vce(cluster Commune_n)
* with
ritest Treatment _b[Treatment], reps($num_reps) strata(cell):  areg index_H2 Treatment base_index_H2 , absorb(cell) vce(cluster Commune_n)

* H3
* without baseline
ritest Treatment _b[Treatment], reps($num_reps) strata(cell):  areg index_H3 Treatment , absorb(cell) vce(cluster Commune_n)
* with
ritest Treatment _b[Treatment], reps($num_reps) strata(cell):  areg index_H3 Treatment base_index_H3 , absorb(cell) vce(cluster Commune_n)



******************
* MSD Treatment Checks

use "${file_path}\Leader_w_Randomization.dta", clear

* From MSD section of Leader survey
tab MSD1 treatment

* From PD section
forv v = 1/5 {
	tab PD9e_`v' treatment, col
}

forv v = 1/5 {
	tab PD10e_`v' treatment, col
}



******************
* Committee Treatment Checks
cap ssc install catplot

eststo clear
foreach v in CP14 CP15A /* CP15B */	 HTH18 CP1H_1 CP1H_2 CP1E_1 CP1E_2 CP1E_3 CP1E_4 { 
	catplot treatment `v' if Base==2, percent(treatment) asyvars intensity(25) saving("${tablepath}\Leader - `v'", replace)
	eststo `v': estpost tab `v' treatment
	
}

esttab * using "${tablepath}\Leader - Committees", replace ${esttab_settings}

***************
*** Ed Outcomes
use "${file_path}\Leader_w_Randomization.dta", clear

* Staffing
eststo clear

foreach v in 2 3 {
	recode EDF1_`v' (99 = .) (-99 = .) (-98 = .)
	recode EDF2_`v' (99 = .) (-99 = .) (-98 = .)
	recode EDF3C_`v'  ( 10 / . = .)
	recode EDF3C_`v' (-99/0 = .) (4/100 = .) (3 = -1) (2 = 0)
}	

foreach v in 2 3 {
	
	g students_per_school_`v' = EDF2_`v' / EDF1_`v'
	bys Commune_n: egen b_students_per_school_`v' = mean(students_per_school_`v') if !post
	bys Commune_n: egen base_students_per_school_`v' = max(b_students_per_school_`v')
	
	catplot treatment EDF3C_`v' if Base==2, percent(treatment) asyvars intensity(25) saving("${tablepath}\Leader - EDF3C_`v'", replace)
	eststo EDF3C_`v': estpost tab EDF3C_`v' treatment

	eststo EDF3C_`v'_r1: areg EDF3C_`v' treatment if post, absorb(cell) vce(cluster Commune_n)
	eststo EDF3C_`v'_r2: areg EDF3C_`v' treatment##c.base_students_per_school_`v' if post, absorb(cell) vce(cluster Commune_n)
}

	
	recode EDF3D_* EDF3E_* (-1000/0 = .) 
	
	g 		Teachers_2_continuous = EDF3C_2 if EDF3C_2==0
	replace Teachers_2_continuous = EDF3D_3 if   EDF3C_2==1 & EDF3D_3!=.
	replace Teachers_2_continuous = EDF3D_3 + EDF3D_4  if   EDF3C_2==1 & EDF3D_4!=.
	replace Teachers_2_continuous = -EDF3E_2 if   EDF3C_2==-1 & EDF3E_2!=.
		
	g 		Teachers_3_continuous = EDF3C_3 if EDF3C_3==0
	replace Teachers_3_continuous = EDF3D_5 if   EDF3C_3==1 & EDF3D_5!=.
	replace Teachers_3_continuous = EDF3D_5 + EDF3D_6  if   EDF3C_3==1 & EDF3D_6!=.
	replace Teachers_3_continuous = -EDF3E_3 if   EDF3C_3==-1 & EDF3E_3!=.
	

****************
*** Health Outcomes

* Staffing
eststo clear
foreach v in HTH1 HTH2 HTH3A HTH4A HTH5A HTH7A HTH8A  { 
	catplot treatment `v' if Base==2, percent(treatment) asyvars intensity(25) saving("${tablepath}\Leader - `v'", replace)
	eststo `v': estpost tab `v' treatment
	
}

esttab * using "${tablepath}\Leader - Health Staffing", replace ${esttab_settings}

foreach v in HTH2B HTH6_1 HTH6_2 HTH9  { 
	recode `v' (-1000/-1 = .)
	eststo `v': reg `v' ibn.treatment, nocons
	
}

* Quality
	catplot treatment HTH10 if Base==2, percent(treatment) asyvars intensity(25) saving("${tablepath}\Leader - HTH10", replace)

* Supplies
eststo clear 

foreach i in 1 6 9 {
	foreach v in HTH14 HTH15 HTH16  {
		recode `v'_`i' (-1000/-1 = .)
		eststo `v'_`i': reg `v'_`i' ibn.treatment if post, nocons
	}
	ritest treatment _b[treatment], reps(100) strata(cell):  areg HTH16_`i' treatment if post, absorb(cell) vce(cluster Commune_n)
}

esttab * using "${tablepath}\Leader - HTH14-16", replace ${esttab_settings}


* Wait times
foreach v in HTH11_1 HTH11_2  { 
	recode `v' (-1000/-1 = .)
}
g wait_times = HTH11_1*60 + HTH11_2
eststo wait: reg wait_times ibn.treatment, nocons
ritest treatment _b[treatment], reps(100) strata(cell):  areg wait_times treatment, absorb(cell) vce(cluster Commune_n)


* Mortality
g infant_mort = HTH12A / HTH12B
la var infant_mort "Infant mortality"

g u5_mort = HTH13A / HTH13B
la var u5_mort "U5 mortality"

areg infant_mort treatment , absorb(cell) vce(cluster Commune_n)
areg u5_mort treatment , absorb(cell) vce(cluster Commune_n)


*graph bar , over(treatment) over(CP14)


}




log close
end
