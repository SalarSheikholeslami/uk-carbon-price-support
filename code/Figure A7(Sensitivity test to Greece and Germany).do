*Figure A7


* 0) CLEAN GDP PER CAPITA
****************************************************
clear
import delimited "C:\Users\Salar\Desktop\CPS\GDP per capita.csv", ///
    varnames(5) case(lower)

keep if inlist(countryname,"United Kingdom","France","Germany","Italy","Spain","Netherlands","Hungary","Slovakia" ) | ///
        inlist(countryname,"Austria","Finland","Sweden","Denmark","Portugal","Greece","Ireland","Poland","Czechia") | ///
        inlist(countryname,"United States","Canada","Japan","New Zealand")

keep countryname v46-v64

forvalues y = 2001/2019 {
    local v = 45 + (`y' - 2000)
    rename v`v' y`y'
}

reshape long y, i(countryname) j(year)

rename y gdp_pc
rename countryname country
label var gdp_pc "GDP per capita (current US dollars)"
gen lngdp_pc = log(gdp_pc)
sort country year

save "C:\Users\Salar\Desktop\CPS\gdp_clean.dta", replace


****************************************************
* 1) CLEAN ELECTRICITY CONSUMPTION PER CAPITA
****************************************************
clear
import delimited "C:\Users\Salar\Desktop\CPS\electric consumption per capita.csv", ///
    varnames(5) case(lower)

keep if inlist(countryname,"United Kingdom","France","Germany","Italy","Spain","Netherlands","Hungary","Slovakia") | ///
        inlist(countryname,"Austria","Finland","Sweden","Denmark","Portugal","Greece","Ireland","Poland","Czechia") | ///
        inlist(countryname,"United States","Canada","Japan","New Zealand")

keep countryname v46-v64

forvalues y = 2001/2019 {
    local v = 45 + (`y' - 2000)
    rename v`v' y`y'
}

reshape long y, i(countryname) j(year)

rename y elec_pc
rename countryname country
label var elec_pc "Electric power consumption (kWh per capita)"

sort country year
save "C:\Users\Salar\Desktop\CPS\elec_clean.dta", replace


****************************************************
* 2) CLEAN MANUFACTURING VALUE ADDED (% GDP)
****************************************************
clear
import delimited "C:\Users\Salar\Desktop\CPS\manufacturing-value-added-to-gdp.csv", ///
    varnames(1) clear

rename entity country
rename manufactur~p manufacturing_share

keep if inlist(country,"United Kingdom","France","Germany","Italy","Spain","Netherlands","Hungary","Slovakia") | ///
        inlist(country,"Austria","Finland","Sweden","Denmark","Portugal","Greece","Ireland","Poland","Czechia") | ///
        inlist(country,"United States","Canada","Japan","New Zealand")

keep if inrange(year,2001,2019)
label var manufacturing_share "Manufacturing value added (% of GDP)"

sort country year
save "C:\Users\Salar\Desktop\CPS\manuf_clean.dta", replace


****************************************************
* 3) MAIN DATA: ELECTRICITY GENERATION SHARES + MERGES
****************************************************
clear
import delimited "C:\Users\Salar\Desktop\CPS\share-electricity-source-facet3.csv", ///
    varnames(1) clear

rename entity              country
rename coalelectricity     coal_share
rename gaselectricity      gas_share
rename nuclearelectricity  nuclear_share
rename hydroelectricity    hydro_share
rename solarelectricity    solar_share
rename windelectricity     wind_share

replace wind_share    = 0 if missing(wind_share)
replace solar_share   = 0 if missing(solar_share)
replace nuclear_share = 0 if missing(nuclear_share)

gen renew_basic_share = hydro_share + wind_share + solar_share
replace renew_basic_share = 0 if missing(renew_basic_share)

gen coal_gas_share = coal_share + gas_share
label var coal_gas_share "Coal + Gas share (% of electricity)"

keep if inlist(country,"United Kingdom","France","Germany","Italy","Spain","Netherlands","Hungary","Slovakia") | ///
        inlist(country,"Austria","Finland","Sweden","Denmark","Portugal","Greece","Ireland","Poland","Czechia") | ///
        inlist(country,"United States","Canada","Japan","New Zealand")

keep if inrange(year,2001,2019)

bys country: assert _N==19
sort country year

* Merge GDP
merge 1:1 country year using "C:\Users\Salar\Desktop\CPS\gdp_clean.dta"
keep if _merge==3
drop _merge

* Merge elec consumption
merge 1:1 country year using "C:\Users\Salar\Desktop\CPS\elec_clean.dta"
keep if _merge==3
drop _merge

* Merge manufacturing share
merge 1:1 country year using "C:\Users\Salar\Desktop\CPS\manuf_clean.dta"
keep if _merge==3
drop _merge


****************************************************
* 4) BUILD PRE-TREATMENT PREDICTORS (2001–2012)
****************************************************
sort country year
gen coal_early = coal_share if inrange(year,2001,2004)
by country: egen coal_avg_early = mean(coal_early)
drop coal_early

gen coal_mid = coal_share if inrange(year,2005,2008)
by country: egen coal_avg_mid = mean(coal_mid)
drop coal_mid

gen coal_late = coal_share if inrange(year,2009,2012)
by country: egen coal_avg_late = mean(coal_late)
drop coal_late

bys country: replace coal_avg_early = coal_avg_early[1]
bys country: replace coal_avg_mid   = coal_avg_mid[1]
bys country: replace coal_avg_late  = coal_avg_late[1]

* Block averages for coal+gas 
gen coal_gas_share_early = coal_gas_share if inrange(year,2001,2004)
by country: egen coal_gas_share_avg_early = mean(coal_gas_share_early)
drop coal_gas_share_early

gen coal_gas_share_mid = coal_gas_share if inrange(year,2005,2008)
by country: egen coal_gas_share_avg_mid = mean(coal_gas_share_mid)
drop coal_gas_share_mid

gen coal_gas_share_late = coal_gas_share if inrange(year,2009,2012)
by country: egen coal_gas_share_avg_late = mean(coal_gas_share_late)
drop coal_gas_share_late

bys country: replace coal_gas_share_avg_early = coal_gas_share_avg_early[1]
bys country: replace coal_gas_share_avg_mid   = coal_gas_share_avg_mid[1]
bys country: replace coal_gas_share_avg_late  = coal_gas_share_avg_late[1]


* Averages for GDP, elec_pc, manufacturing (2001–2012)
by country: egen lngdp_pc_avg  = mean(lngdp_pc)  if inrange(year,2001,2012)
by country: egen elec_pc_avg   = mean(elec_pc)   if inrange(year,2001,2012)
by country: egen manufacturing_share_avg = mean(manufacturing_share) if inrange(year,2001,2012)

bys country: replace lngdp_pc_avg  = lngdp_pc_avg[1]
bys country: replace elec_pc_avg   = elec_pc_avg[1]
bys country: replace manufacturing_share_avg = manufacturing_share_avg[1]

* Check missing predictors
foreach v in coal_gas_share_avg_early coal_gas_share_avg_mid coal_gas_share_avg_late ///
            lngdp_pc_avg elec_pc_avg manufacturing_share_avg {
    di "Missing count for `v':"
    count if missing(`v')
}

* Drop units with missing predictors
drop if missing(coal_gas_share_avg_early) | missing(coal_gas_share_avg_mid) | missing(coal_gas_share_avg_late) | ///
        missing(lngdp_pc_avg) | missing(elec_pc_avg) | missing(manufacturing_share_avg)

* Ensure remaining panel is balanced (important for synth)
bys country: assert _N==19


****************************************************
* 5) PANEL SETUP
****************************************************
encode country, gen(id)
tsset id year


****************************************************
* 6) SENSITIVITY (BULLETPROOF): drop Greece / Germany / both
****************************************************
tempfile master
save `master', replace

cap which synth
if _rc ssc install synth, replace

local outdir "C:\Users\Salar\Desktop\CPS"

foreach s in base nogr node nogrde {

    use `master', clear

    * physically drop donors by NAME
    if "`s'"=="nogr"   drop if country=="Greece"
    if "`s'"=="node"   drop if country=="Germany"
    if "`s'"=="nogrde" drop if inlist(country,"Greece","Germany")

    * hard checks (if not dropped -> stop here)
    if "`s'"=="nogr" {
        count if country=="Greece"
        assert r(N)==0
    }
    if "`s'"=="node" {
        count if country=="Germany"
        assert r(N)==0
    }
    if "`s'"=="nogrde" {
        count if inlist(country,"Greece","Germany")
        assert r(N)==0
    }

    * re-encode AFTER dropping (ids must match this scenario)
    capture drop id
    encode country, gen(id)
    tsset id year

    * treated id in THIS scenario
    summarize id if country=="United Kingdom", meanonly
    local uk_id = r(min)

    * donors in THIS scenario
    levelsof id if id != `uk_id', local(controls)

    di "=== scenario: `s' ==="
    di "UK id = `uk_id'"

    synth coal_gas_share ///
        coal_gas_share_avg_early coal_gas_share_avg_mid coal_gas_share_avg_late ///
        lngdp_pc_avg elec_pc_avg manufacturing_share_avg, ///
        trunit(`uk_id') trperiod(2013) controls(`controls') ///
        unitnames(country) nograph ///
        keep("`outdir'\synth_CPS_coal_gas_share_`s'.dta", replace)
}


****************************************************
* 7) BUILD ONE DATASET: UK + ALL SYNTHETICS + GAPS
****************************************************
use "`outdir'\synth_CPS_coal_gas_share_base.dta", clear
keep if !missing(_time)
keep _time _Y_treated _Y_synthetic
rename _Y_treated   uk
rename _Y_synthetic syn_base

foreach s in nogr node nogrde {
    preserve
    use "`outdir'\synth_CPS_coal_gas_share_`s'.dta", clear
    keep if !missing(_time)
    keep _time _Y_synthetic
    tempfile t`s'
    save `t`s'', replace
    restore

    merge 1:1 _time using `t`s'', nogen
    rename _Y_synthetic syn_`s'
}

foreach s in base nogr node nogrde {
    gen gap_`s' = uk - syn_`s'
}

label var uk         "UK"
label var syn_base   "Synthetic (all donors)"
label var syn_nogr   "Synthetic (drop Greece)"
label var syn_node   "Synthetic (drop Germany)"
label var syn_nogrde "Synthetic (drop Greece+Germany)"

label var gap_base   "Gap (all donors)"
label var gap_nogr   "Gap (drop Greece)"
label var gap_node   "Gap (drop Germany)"
label var gap_nogrde "Gap (drop Greece+Germany)"

save "`outdir'\synth_sensitivity_merged.dta", replace


	
*Figure A7	
twoway ///
    (line gap_base _time,    lwidth(medthick) lpattern(solid)    lcolor(black)) ///
    (line gap_nogr _time,    lwidth(medthick) lpattern(dash)     lcolor(gs8)) ///
    (line gap_node _time,    lwidth(medthick) lpattern(dot)      lcolor(gs10)) ///
    (line gap_nogrde _time,  lwidth(medthick) lpattern(longdash) lcolor(gs12)), ///
    yline(0) ///
    xline(2013, lpattern(dash) lcolor(gs8)) ///
    ylabel(-40(10)40) ///
    xtitle("Year") ///
    ytitle("Treated − Synthetic") ///
    title("Sensitivity: Gaps under donor exclusions") ///
    legend(order(1 "All donors" 2 "No Greece" 3 "No Germany" 4 "No Greece+Germany") cols(1)) ///
    name(gr_gap, replace)