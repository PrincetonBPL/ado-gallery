** Desc: Salivette tracket sheet for one lab cohort (session). Randomizes seat assignment per lab day and treatment assignment per subject.
** Input: Empty dataset
** Output: .csv tracking sheet for for 1 HC cohort
** Options: 

capture program drop cortsheet
program define cortsheet, rclass
syntax anything, [subjects(real 0)] [startid(real 0)] [study(real 0)] [year(real 0)] [month(real 0)] [day(real 0)] [session(real 0)] [groups(real 0)] [samples(real 0)] [seed(string)] [replace]

/* Initialize macros */

preserve
clear

if `subjects' < 1 | `subjects' > 25 | `samples' < 1 | `groups' < 1 {
	di as error "Invalid argument for subjects(), samples(), or groups()."
	exit 
}

if "`year'" == "" | "`month'" == "" | "`day'" == "" {
	di as error "Must enter starting date for cohort."
	exit 
}

if "`subjects'" == "" loc subjects = 25
if "`startid'" == "" loc startid = 1
if "`study'" == "" loc study = 1
if "`session'" == "" loc study = 1
if "`groups'" == "" loc groups = 4
if "`samples'" == "" loc samples = 7
if "`seed'" != "" set seed `seed'

/* Populate lab days */

set obs 25

gen subject = _n + `startid' - 1 if _n <= `subjects'
gen study = `study' if ~mi(subject)
gen date = mdy(`month', `day', `year') if ~mi(subject)
gen session = `session' if ~mi(subject)
gen day = 1 if ~mi(subject)

gen randtreat = runiform() if ~mi(subject)
egen treatment = cut(randtreat) if ~mi(subject), group(`groups')
qui replace treatment = treatment + 1

gen randseat1 = runiform()
gen randseat2 = runiform()
sort randseat1
gen seat = _n

qui expand 2, gen(last_day)
qui replace date = date + 7 if last_day & ~mi(subject)
qui replace day = 7 if last_day & ~mi(subject)

sort day randseat2
qui replace seat = _n - 25 if last_day

drop if mi(subject)

/* Populate in-between days */

forval i = 1/5 {

	qui expand 2 if day == 1, gen(dup_day)
	qui replace date = date + `i' if dup_day
	qui replace day = `i' + 1 if dup_day
	drop dup_day

}

/* Generate salivette samples */

gen salivette = 1

if `samples' > 1 {
	
	forval i = 2/`samples' {

		qui expand 2 if (day == 1 | day == 7) & salivette == 1, gen(dup_cort)
		qui replace salivette = `i' if dup_cort
		drop dup_cort

	}

}

/* Generate barcodes */

gen datestr = substr(string(year(date)), 3, .) + string(month(date), "%02.0f") + string(day(date), "%02.0f")

drop date
qui destring datestr, gen(date)

gen codestr = string(seat, "%02.0f") + string(subject, "%03.0f") + string(study) + datestr + string(session) + string(day) + string(treatment) + string(salivette)
qui destring codestr, gen(barcode)

/* Save tracking sheet */

keep seat subject study date session day treatment salivette barcode codestr
order seat subject study date session day treatment salivette barcode codestr
sort study session date subject salivette

if `anything' != "" {

	if "`replace'" == "" export delim `anything'
	else export delim `anything', replace
	di as error "<3"

} 

else {

	di as error "Invalid filepath."
	exit

}

restore

end
