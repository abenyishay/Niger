********************************************************************************
* RANDOMIZATION OF NIGER USAID PRG PHASE 2 ASSIGNMENT

/* This do-file runs code to:
  	+ randomly assign the phase 2 treatment, stratifying on region, urban, and phase 1 intervention status

- This do-file uses the following datasets:
	+ 'List of PRG-PA Communes for Randomization Sept 2016-KNnotes.xlsx'
	
- This do-file produces:
	+ 'Niger PRG Randomization.dta'
	+ 'Niger PRG Randomization.csv'
	
- v1 9-15-16 [ab]: Produce randomization 
*/
********************************************************************************
****************************************

clear all
set more off

set seed 082380

global file_path "C:\Users\Ariel\Dropbox\AidData\Niger\Randomization"
global logpath "${file_path}\logs"
global tablepath "${file_path}\tables"

cap mkdir "${logpath}"
cap mkdir "${tablepath}"

********************************************************************************
cap log close
log using "${logpath}\Niger PRG Randomization ($S_DATE)", replace

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


* Randomize within cell
gsample cell_count_draw, str(cell) wor gen(Treatment)

export excel Region Commune Treatment using "${tablepath}\Randomized list - $S_DATE.xls", firstrow(variables) replace


log close
