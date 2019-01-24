********************************************************************************
* Main Analysis for NIGER USAID PRG

/* This do-file runs code to:
  	+ Main analysis of treatment effects

- This do-file uses the following datasets:
	+ 'List of PRG-PA Communes for Randomization Sept 2016-KNnotes.xlsx'
	
- This do-file produces:
	+ 
	
- v1 1-3-18 [ab]: Initial 
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
bys cell: ge `z' = cell_count_draw*(_n==1)
egen	total_draw = sum(`z')

* Save
save "${file_path}\Randomization Frame", replace


********************************************************************************
*** Set up RI
cap drop permme

 program permme // define the program
            syntax, ///
            resampvar(D_a) /// name of the permutation variable
            cell(cell) /// name of the strata variable
            commune(commune) /// name of the cluster variable
            * // ritest also passes other things to the permutation procedure (for example, run(#))
            gsample cell_count_draw, str(cell) wor gen(D_a)
	end


 
********************************************************************************
*** Make index for Anderson (2008) multiple hypothesis test

cap gen wgt = 1
local outcomes ""  // Add variable names here
local outcomes_base ""

make_index main_outcome wgt `outcomes'
make_index main_outcome_base wgt `outcomes_base'

********************************************************************************
*** Analysis


ritest treatment _b[treatment], reps(`num_reps') samplingprogram(permme) samplingprogramoptions("cell(cell) commune(commune)"):  areg main_outcome treatment main_outcome_base i.cell, vce(cluster commune)

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

4.   Multi-stakeholder dialogues will increase the perceived legitimacy of the government among citizens in the commune.
5. 	Multi-stakeholder dialogues will strengthen citizen perceptions that the government is responsive to their needs and demands.
6. 	Multi-stakeholder dialogues will increase citizen perceptions that their government is democratic.
7.  	Multi-stakeholder dialogues will reduce citizen perceptions that the local government is corrupt. 
  
Measures for government performance and legitimacy:
•	Citizen perceptions of government legitimacy (e.g., government has the right to make citizens pay taxes) (survey questions 41, 42, 43, 46)
•	Citizen perceptions of local government responsiveness (e.g., in your opinion, how responsive do you think the local government has been to addressing citizens' developmental needs and wants) (survey questions 45, 47, 49d, 49e, 49f, 53)
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
