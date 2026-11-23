*Figure A5 (Panel A & B)

clear all
set more off

local root "C:\Users\Salar\Desktop\CPS"
local TR 2013
local pre_end = `TR' - 1

cap which synth
if _rc ssc install synth, replace

* Load panel and ensure tsset
* -----------------------------------------------------
use "`root'\panel_ready.dta", clear

cap confirm variable id
if _rc encode country, gen(id)
tsset id year

summarize id if country=="United Kingdom", meanonly
global uk_id = r(min)

* Build predictors for pre-period 2001–2012 
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

* Fixed (kept) predictors
local P_fixed "cg_avg_early cg_avg_mid cg_avg_late"

* Auxiliary predictors subject to drop-one
local P_aux "lngdp_avg elec_avg manuf_avg"

* Baseline full predictor set
local P_base "`P_fixed' `P_aux'"

* -----------------------------------------------------
* 1) Baseline run (all predictors)
* -----------------------------------------------------
use `synth_ready', clear
tsset id year

synth coal_gas_share ///
      `P_base', ///
      trunit($uk_id) trperiod(`TR') ///
      unitnames(country) ///
      resultsperiod(2001(1)2019) ///
      keep("`root'\auxdrop_BASELINE.dta", replace)

use "`root'\auxdrop_BASELINE.dta", clear
keep _time _Y_treated _Y_synthetic
rename _time year
rename _Y_treated   uk
rename _Y_synthetic syn_base
tempfile base
save `base', replace

* -----------------------------------------------------
* 2) Drop-one runs only for auxiliary predictors
* -----------------------------------------------------
foreach dropvar of local P_aux {

    use `synth_ready', clear
    tsset id year

    local Pdrop : list P_aux - dropvar
    local Pspec "`P_fixed' `Pdrop'"

    synth coal_gas_share ///
          `Pspec', ///
          trunit($uk_id) trperiod(`TR') ///
          unitnames(country) ///
          resultsperiod(2001(1)2019) ///
          keep("`root'\auxdrop_drop_`dropvar'.dta", replace)

    use "`root'\auxdrop_drop_`dropvar'.dta", clear
    keep _time _Y_synthetic
    rename _time year
    rename _Y_synthetic syn_drop_`dropvar'
    tempfile s_`dropvar'
    save `s_`dropvar'', replace
}

* -----------------------------------------------------
* 3) Merge for plotting
* -----------------------------------------------------
use `base', clear
foreach dropvar of local P_aux {
    merge 1:1 year using `s_`dropvar'', nogen
}
sort year

* -----------------------------------------------------
* 4) Plot 1: UK vs Synthetic (baseline + drop-one auxiliary)
* =====================================================

*Panel A

twoway ///
    (line uk year, lcolor(black) lwidth(medthick) sort) ///
    (line syn_base year, lcolor(black) lwidth(medthin) sort) ///
    (line syn_drop_lngdp_avg year, lcolor(gs10) lpattern(dash) lwidth(medthin) sort) ///
    (line syn_drop_elec_avg  year, lcolor(gs10) lpattern(dash) lwidth(medthin) sort) ///
    (line syn_drop_manuf_avg year, lcolor(gs10) lpattern(dash) lwidth(medthin) sort) ///
    , ///
    xline(`TR', lpattern(dash) lcolor(gs8)) ///
    xtitle("Year") ///
    ytitle("Coal + Gas share (% of electricity)", size(small) margin(r+6)) ///
    title("Treated vs Synthetic: baseline vs dropping predictors") ///
    legend( ///
        order(1 "UK (treated)" ///
              2 "Baseline synthetic" ///
              3 "Drop-one predictor") ///
        rows(3) size(small) pos(6) ring(0) ///
    )

	
*Panel B

* =====================================================
*5) Plot 2: Gaps (baseline + drop-one auxiliary)
cap drop gap_base gap_drop_lngdp_avg gap_drop_elec_avg gap_drop_manuf_avg
gen gap_base = uk - syn_base
gen gap_drop_lngdp_avg = uk - syn_drop_lngdp_avg
gen gap_drop_elec_avg  = uk - syn_drop_elec_avg
gen gap_drop_manuf_avg = uk - syn_drop_manuf_avg

twoway ///
    (line gap_base year, lcolor(black) lwidth(medthick) sort) ///
    (line gap_drop_lngdp_avg year, lcolor(gs10) lpattern(dash) lwidth(medthin) sort) ///
    (line gap_drop_elec_avg  year, lcolor(gs10) lpattern(dash) lwidth(medthin) sort) ///
    (line gap_drop_manuf_avg year, lcolor(gs10) lpattern(dash) lwidth(medthin) sort) ///
    , ///
    yline(0) ///
    xline(`TR', lpattern(dash) lcolor(gs8)) ///
    ylabel(-50(10)50) ///
    yscale(range(-50 50)) ///
    xtitle("Year") ///
    ytitle("Gap (UK - Synthetic)", size(small) margin(r+6)) ///
    title("Gap sensitivity") ///
    legend( ///
        order(1 "Baseline gap" ///
              2 "Drop-one predictor") ///
        rows(2) size(small) pos(6) ring(0) ///
    )
