*Figure A6
*Leave-One-Donor-Out Test 


clear all
set more off

local root "C:\Users\Salar\Desktop\CPS"
local TR 2013
local pre_end = `TR' - 1

cap which synth
if _rc ssc install synth, replace


* 1) Load panel and ensure tsset
* -----------------------------------------------------
use "`root'\panel_ready.dta", clear

cap confirm variable id
if _rc encode country, gen(id)
tsset id year

summarize id if country=="United Kingdom", meanonly
global uk_id = r(min)

* 2) Build predictors for pre-period 2001–2012 (same as main)
* -----------------------------------------------------
preserve

gen cg_early = coal_gas_share if inrange(year,2001,2004)
bysort country: egen cg_avg_early = mean(cg_early)
drop cg_early

gen cg_mid = coal_gas_share if inrange(year,2005,2008)
bysort country: egen cg_avg_mid = mean(cg_mid)
drop cg_mid

gen cg_late = coal_gas_share if inrange(year,2009,`pre_end')
bysort country: egen cg_avg_late = mean(cg_late)
drop cg_late

bysort country: replace cg_avg_early = cg_avg_early[1]
bysort country: replace cg_avg_mid   = cg_avg_mid[1]
bysort country: replace cg_avg_late  = cg_avg_late[1]

bysort country: egen lngdp_avg = mean(lngdp_pc) if inrange(year,2001,`pre_end')
bysort country: egen elec_avg  = mean(elec_pc)  if inrange(year,2001,`pre_end')
bysort country: egen manuf_avg = mean(manufacturing_share) if inrange(year,2001,`pre_end')

bysort country: replace lngdp_avg = lngdp_avg[1]
bysort country: replace elec_avg  = elec_avg[1]
bysort country: replace manuf_avg = manuf_avg[1]

drop if missing(cg_avg_early) | missing(cg_avg_mid) | missing(cg_avg_late) | ///
        missing(lngdp_avg) | missing(elec_avg) | missing(manuf_avg)

tempfile synth_ready
save `synth_ready', replace
restore

local P "cg_avg_early cg_avg_mid cg_avg_late lngdp_avg elec_avg manuf_avg"

* 3) Baseline synth (full donor pool)
* -----------------------------------------------------
use `synth_ready', clear
tsset id year

synth coal_gas_share ///
      `P', ///
      trunit($uk_id) trperiod(`TR') ///
      unitnames(country) ///
      resultsperiod(2001(1)2019) ///
      keep("`root'\loo_tbl_BASELINE.dta", replace)

use "`root'\loo_tbl_BASELINE.dta", clear
keep _time _Y_treated _Y_synthetic
rename _time year
rename _Y_treated   uk
rename _Y_synthetic syn_base
tempfile base
save `base', replace

* -----------------------------------------------------
* 4) Leave-one-out loop over the 5 positive-weight donors
* -----------------------------------------------------
local loo_countries "Denmark Greece Italy Netherlands Spain"

use `base', clear

capture ds syn_drop_*
if !_rc {
    drop `r(varlist)'
}

tempfile master
save `master', replace

foreach c of local loo_countries {

    use `synth_ready', clear
    tsset id year

    drop if country=="`c'"

    synth coal_gas_share ///
          `P', ///
          trunit($uk_id) trperiod(`TR') ///
          unitnames(country) ///
          resultsperiod(2001(1)2019) ///
          keep("`root'\loo_tbl_drop_`c'.dta", replace)

    use "`root'\loo_tbl_drop_`c'.dta", clear
    keep _time _Y_synthetic
    rename _time year
    rename _Y_synthetic syn_drop_`c'
    tempfile syn_`c'
    save `syn_`c'', replace

    use `master', clear
    merge 1:1 year using `syn_`c'', nogen
    save `master', replace
}

use `master', clear
sort year



* 5) Plot: Gap (baseline + LOO)
* -----------------------------------------------------
cap drop gap_base
gen gap_base = uk - syn_base

cap drop gap_drop_*
gen gap_drop_Denmark     = uk - syn_drop_Denmark
gen gap_drop_Greece      = uk - syn_drop_Greece
gen gap_drop_Italy       = uk - syn_drop_Italy
gen gap_drop_Netherlands = uk - syn_drop_Netherlands
gen gap_drop_Spain       = uk - syn_drop_Spain

twoway ///
    (line gap_base year, lcolor(black) lwidth(medthick) sort) ///
    (line gap_drop_Denmark     year, lcolor(gs12) lpattern(dash) lwidth(medthin) sort) ///
    (line gap_drop_Greece      year, lcolor(gs12) lpattern(dash) lwidth(medthin) sort) ///
    (line gap_drop_Italy       year, lcolor(gs12) lpattern(dash) lwidth(medthin) sort) ///
    (line gap_drop_Netherlands year, lcolor(gs12) lpattern(dash) lwidth(medthin) sort) ///
    (line gap_drop_Spain       year, lcolor(gs12) lpattern(dash) lwidth(medthin) sort) ///
    , ///
    yline(0) ///
    xline(`TR', lpattern(dash) lcolor(gs8)) ///
    ylabel(-50(10)50) ///
    yscale(range(-50 50)) ///
    xtitle("Year") ///
    ytitle("Gap (UK - Synthetic)", size(small) margin(r+6)) ///
    title("Leave-one-out (positive-weight donors): Gap sensitivity") ///
    legend(order(1 "Baseline gap" 2 "LOO gaps") ///
           rows(2) size(small) pos(6) ring(0))