** Desc: Custom program for the aspirations project that creates a key to merge phases of the data by correcting spouse survey issue.
** Input: Dataset or tracking sheet.
** Output: .dta dataset with merge_key variable.
** Options: "data()" receives input data. "id()" receives the name of the ID to be transformed. "keep()" keeps only specified variables. drop" indicates whether to drop duplicates. "idonly" drops all variables from the using data except merge_key. Remaining options specify filetype of intput data.

capture program drop mergekey
program define mergekey, eclass
syntax anything(name = output_filename), data(string) id(string) [keep(string)] [drop] [idonly] [delim] [excel] [use13]

if "`delim'" != "" import delim "`data'", varnames(1) clear
else if "`excel'" != "" import excel "`data'", first clear
else if "`use13'" != "" use13 "`data'", clear
else use "`data'", clear


gen double merge_key = `id'
tostring merge_key, replace format(%15.0g)

replace merge_key = "" if merge_key == "."
replace merge_key = "" if strpos(merge_key, "+") > 0

gen flag_notresp = regexm(merge_key, "^90[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]?[0-9]?[0-9]?$")
la var flag_notresp "Not original respondent"

replace merge_key = regexr(merge_key, "^90", "") if regexm(merge_key, "^90[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]?[0-9]?[0-9]?$")
destring merge_key, replace
format %15.0g merge_key

if "`drop'" != "" {
	duplicates report merge_key
	duplicates drop merge_key, force
}

if "`idonly'" != "" keep merge_key flag_notresp
else if "`keep'" != "" keep merge_key flag_notresp `keep'

if `output_filename' != "" {

    di "Saving to "`output_filename'"."
    save `output_filename', replace

}

end
