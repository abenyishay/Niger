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
*/
********************************************************************************
****************************************

clear all
set more off

set seed 082380

global project_path "C:\Users\Ariel\Dropbox\AidData\Niger"
global file_path "${project_path}\Analysis\Main analysis"
global logpath "${file_path}\logs"
global tablepath "${file_path}\tables"

cap mkdir "${logpath}"
cap mkdir "${tablepath}"

********************************************************************************

* Specify parameters

*global inter_round_sd 1		// Specify standard deviation of mean for same HH across rds (as share of SD of mean across HH within EA for same round)

loc num_reps 10000		// Set how many repetitions 

********************************************************************************
cap log close
log using "${logpath}\Niger PRG Main Analysis ($S_DATE)", replace

********************************************************************************
*** Set up Randomization
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

save "${file_path}\HH_w_Randomization.dta", replace

* Merge into Leader file


********************************************************************************
*** Make index for Anderson (2008) multiple hypothesis test
use "${file_path}\HH_w_Randomization.dta", clear

keep if post

/*
4.   Multi-stakeholder dialogues will increase the perceived legitimacy of the government among citizens in the commune.
•	Citizen perceptions of government legitimacy (e.g., government has the right to make citizens pay taxes) (survey questions 41, 42, 43, 46)
*/

/*  
5. 	Multi-stakeholder dialogues will strengthen citizen perceptions that the government is responsive to their needs and demands.
•	Citizen perceptions of local government responsiveness (e.g., in your opinion, how responsive do you think the local government has been to addressing citizens' developmental needs and wants) 
	(survey questions Q49  Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2 Q58_3 Q58_4)

Q34_1 Q34_2 Q34_3 Q33 Q39 Q44 Q45_1 Q45_2 Q46_1 Q46_2 Q46_3 Q47_1 Q47_2 Q47_3 Q47_4 Q47_5 Q48_1 Q48_2 ///
	Q50_1 Q50_2 Q50_3 Q50_4 Q50_5 Q50_6 Q50_7 Q50_8 Q50_9 Q50_10 Q50_11 Q50_12 Q50_13 
*/
cap gen wgt = 1
local H5_outcomes "Q49  Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2"  // Add variable names here

make_index H5 wgt `H5_outcomes' 

save "${file_path}\HH_w_Randomization_Indices_Endline.dta", replace

*************************
* Redo with baseline data
use "${file_path}\HH_w_Randomization.dta", clear

keep if !post

cap gen wgt = 1
local H5_outcomes "Q49  Q51_1 Q51_2 Q55A Q55B Q55C Q58_1 Q58_2"  // Add variable names here

make_index H5_base wgt `H5_outcomes' 

keep index* Commune_n
collapse index*, by(Commune_n)

save "${file_path}\HH_indices_base.dta", replace
************************
* Merge back into endline

use "${file_path}\HH_w_Randomization_Indices_Endline.dta", clear
mmerge Commune_n using "${file_path}\HH_indices_base.dta"

***********************
* Keep only analysis vars for now
keep index* Commune_n Commune Village cell Treatment cell_count_draw

save "${file_path}\HH_w_Randomization_Indices.dta", replace

********************************************************************************

********************************************************************************
*** Set up RI
cap prog drop permme

 program permme // define the program
            syntax, ///
            resampvar(varname) /// name of the permutation variable
            cell(varname) /// name of the strata variable
            commune(varname) /// name of the cluster variable
            * // ritest also passes other things to the permutation procedure (for example, run(#))
            gsample cell_count_draw, str(`cell') wor gen(`resampvar')
	end


 
*** Analysis

loc num_reps 1000

*g	D_a = 0
ritest Treatment _b[Treatment], reps(`num_reps') samplingprogram(permme) samplingprogramoptions("cell(cell) Commune(Commune)"):  areg index_H5 Treatment index_H5_base , absorb(cell) vce(cluster Commune)
*ritest Treatment _b[Treatment], reps(`num_reps') strata(cell) cluster(Commune):  areg index_H5 Treatment index_H5_base , absorb(cell) vce(cluster Commune)

/*
Elite-level hypotheses include:

1.	Multi-stakeholder dialogues will improve coordination and strategic ties between community elites.
2.	Multi-stakeholder dialogues will strengthen the representativeness of development processes. 
3.	Multi-stakeholder dialogues will increase the resources local and regional governments devote to local service delivery.

Elite-level measures for above hypotheses:
•	Elite expectations about the dependability and commitment of other elites to address citizen priorities (survey questions GV1, GV2, PD9, PD10, PD12).
•	Elites more likely to identify a diverse set of agents (beyond state authorities) to be important for community-level development (e.g., Who are the most important actors to engage for bringing about development in your commune?) (survey questions GV3, PD2, PD3, PD4, PD5, PD6, PD7, PD8, PD11, PD12, PD13, PD14).
•	Multi-stakeholder dialogues will increase the likelihood that community leaders prioritize projects matching citizen preferences.
 
Government performance and legitimacy hypotheses include:

6. 	Multi-stakeholder dialogues will increase citizen perceptions that their government is democratic.
7.  	Multi-stakeholder dialogues will reduce citizen perceptions that the local government is corrupt. 
  
Measures for government performance and legitimacy:
•	Citizen perceptions of democracy (e.g., In your opinion how much of a democracy is Niger today?  Overall, how satisfied are you with the way democracy works in Niger?)
Citizen perceptions of corruption (survey questions 31, 33, 39, 40, 44) 
 

Collective Action hypotheses:
 
8.	Multi-stakeholder dialogues will increase citizen political participation.
9.	Multi-stakeholder dialogues will increase likelihood citizens sign a petition to ensure the government invests in public priorities.
10.	Multi-stakeholder dialogues will increase the likelihood citizens send an SMS to commune government to insist they address citizen priorities
 
Measures:
•	Citizen participation (e.g., voting in local elections, attending rally, participating in demonstration, reaching out to government official) (survey questions 32, 34, 35, 36, 37)
•	Citizens sign petition at end of survey we administer
•	Citizens respond to SMS solicitation to voice opinion to local government 

*/




log close
end
