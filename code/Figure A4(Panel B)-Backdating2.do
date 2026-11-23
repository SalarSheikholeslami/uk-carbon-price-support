*Figure A4 (Panel(b)
clear all
set more off

local root "C:\Users\Salar\Desktop\CPS"

* =====================================================
* 1) Clean GDP per capita (2001–2019)
* =====================================================
clear
import delimited "`root'\GDP per capita.csv", varnames(5) case(lower) clear

keep if inlist(countryname,"United Kingdom","France","Germany","Italy","Spain","Netherlands","Hungary","Slovakia") | ///
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
gen lngdp_pc = log(gdp_pc)

sort country year
save "`root'\gdp_clean.dta", replace


* =====================================================
* 2) Clean electricity consumption per capita (2001–2019)
* =====================================================
clear
import delimited "`root'\electric consumption per capita.csv", varnames(5) case(lower) clear

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

sort country year
save "`root'\elec_clean.dta", replace


* =====================================================
* 3) Clean manufacturing value added (% GDP)
* =====================================================
clear
import delimited "`root'\manufacturing-value-added-to-gdp.csv", varnames(1) clear

rename entity country
rename manufactur~p manufacturing_share

keep if inlist(country,"United Kingdom","France","Germany","Italy","Spain","Netherlands","Hungary","Slovakia") | ///
        inlist(country,"Austria","Finland","Sweden","Denmark","Portugal","Greece","Ireland","Poland","Czechia") | ///
        inlist(country,"United States","Canada","Japan","New Zealand")

keep if inrange(year,2001,2019)

sort country year
save "`root'\manuf_clean.dta", replace


* =====================================================
* 4) Main panel: electricity generation shares
* =====================================================
clear
import delimited "`root'\share-electricity-source-facet3.csv", varnames(1) clear

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

keep if inlist(country,"United Kingdom","France","Germany","Italy","Spain","Netherlands","Hungary","Slovakia") | ///
        inlist(country,"Austria","Finland","Sweden","Denmark","Portugal","Greece","Ireland","Poland","Czechia") | ///
        inlist(country,"United States","Canada","Japan","New Zealand")

keep if inrange(year,2001,2019)

bys country: assert _N==19
sort country year

merge 1:1 country year using "`root'\gdp_clean.dta", nogen keep(3)
merge 1:1 country year using "`root'\elec_clean.dta", nogen keep(3)
merge 1:1 country year using "`root'\manuf_clean.dta", nogen keep(3)

encode country, gen(id)
tsset id year

summarize id if country=="United Kingdom", meanonly
global uk_id = r(min)

cap which synth
if _rc ssc install synth, replace

* Save analysis-ready dataset
save "`root'\panel_ready.dta", replace


* 5) Scenario A: Placebo TR = 2011 (pre_end = 2008)
* =====================================================
use "`root'\panel_ready.dta", clear
local TR 2011
local pre_end = `TR' - 1   // 2008

preserve
sort country year

* Outcome blocks (example split; adjust if you want)
gen cg_early = coal_gas_share if inrange(year,2001,2004)
by country: egen cg_avg_early = mean(cg_early)
drop cg_early

gen cg_mid = coal_gas_share if inrange(year,2005,2008)
by country: egen cg_avg_mid = mean(cg_mid)
drop cg_mid

gen cg_late = coal_gas_share if inrange(year,2009,`pre_end')
by country: egen cg_avg_late = mean(cg_late)
drop cg_late

bys country: replace cg_avg_early = cg_avg_early[1]
bys country: replace cg_avg_mid   = cg_avg_mid[1]
bys country: replace cg_avg_late  = cg_avg_late[1]

* Macro averages over the placebo pre-period
by country: egen lngdp_avg = mean(lngdp_pc) if inrange(year,2001,`pre_end')
by country: egen elec_avg  = mean(elec_pc)  if inrange(year,2001,`pre_end')
by country: egen manuf_avg = mean(manufacturing_share) if inrange(year,2001,`pre_end')

bys country: replace lngdp_avg = lngdp_avg[1]
bys country: replace elec_avg  = elec_avg[1]
bys country: replace manuf_avg = manuf_avg[1]

drop if missing(cg_avg_early) | missing(cg_avg_mid) | missing(cg_avg_late) | ///
        missing(lngdp_avg) | missing(elec_avg) | missing(manuf_avg)

synth coal_gas_share ///
      cg_avg_early cg_avg_mid cg_avg_late ///
      lngdp_avg elec_avg manuf_avg, ///
      trunit($uk_id) trperiod(`TR') ///
      unitnames(country) ///
      fig ///
      resultsperiod(2001(1)2019) ///
      keep("`root'\synth_placebo_TR2011.dta", replace)


restore


* =====================================================
* 6) Scenario B: Main TR = 2013 (pre = 2001–2012)
* =====================================================
use "`root'\panel_ready.dta", clear
local TR 2013
local pre_end = `TR' - 1   // 2012

preserve
sort country year

gen cg_early = coal_gas_share if inrange(year,2001,2004)
by country: egen cg_avg_early = mean(cg_early)
drop cg_early

gen cg_mid = coal_gas_share if inrange(year,2005,2008)
by country: egen cg_avg_mid = mean(cg_mid)
drop cg_mid

gen cg_late = coal_gas_share if inrange(year,2009,`pre_end')
by country: egen cg_avg_late = mean(cg_late)
drop cg_late

bys country: replace cg_avg_early = cg_avg_early[1]
bys country: replace cg_avg_mid   = cg_avg_mid[1]
bys country: replace cg_avg_late  = cg_avg_late[1]

by country: egen lngdp_avg = mean(lngdp_pc) if inrange(year,2001,`pre_end')
by country: egen elec_avg  = mean(elec_pc)  if inrange(year,2001,`pre_end')
by country: egen manuf_avg = mean(manufacturing_share) if inrange(year,2001,`pre_end')

bys country: replace lngdp_avg = lngdp_avg[1]
bys country: replace elec_avg  = elec_avg[1]
bys country: replace manuf_avg = manuf_avg[1]

drop if missing(cg_avg_early) | missing(cg_avg_mid) | missing(cg_avg_late) | ///
        missing(lngdp_avg) | missing(elec_avg) | missing(manuf_avg)

* IMPORTANT: do NOT use controls()
synth coal_gas_share ///
      cg_avg_early cg_avg_mid cg_avg_late ///
      lngdp_avg elec_avg manuf_avg, ///
      trunit($uk_id) trperiod(`TR') ///
      unitnames(country) ///
      keep("`root'\synth_main_TR2013.dta", replace)

restore


* =====================================================
* 7) Compare gap(2011) vs gap(2013)
* =====================================================


use "`root'\synth_placebo_TR2011.dta", clear
gen gap2011 = _Y_treated - _Y_synthetic
keep _time gap2011
tempfile g2011
save `g2011', replace

use "`root'\synth_main_TR2013.dta", clear
gen gap2013 = _Y_treated - _Y_synthetic
keep _time gap2013
tempfile g2013
save `g2013', replace

* Merge by year
use `g2013', clear
merge 1:1 _time using `g2011', nogen
sort _time

* Common y-range (symmetric) across both series
gen absmax = max(abs(gap2011), abs(gap2013))
summ absmax, meanonly
local ymax = ceil(r(max))
local ymin = -`ymax'

* One overlay plot
twoway ///
    (line gap2013 _time, lcolor(black) lwidth(medthick) sort) ///
    (line gap2011 _time, lcolor(red%40) lwidth(medthin) sort) ///
    , ///
    yline(0) ///
	xline(2011, lpattern(dash) lcolor(gs8)) ///
    xline(2013, lpattern(dash) lcolor(gs8)) ///
    ylabel(-50(10)50) ///
    yscale(range(-50 50)) //////
    xtitle("Year") ///
    ytitle("Gap (Treated - Synthetic)", size(small) margin(r+6)) ///
    title("Gap comparison") ///
    legend( ///
        order(1 "Main: 2013" 2 "Placebo:2011") ///
        rows(2) size(small) ring(0) pos(3) ///
    )
