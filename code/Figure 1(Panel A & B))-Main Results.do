* Main Results : Figure 1 (Panel a and b) , Predictor Balance and Unit Weights 

* ==== cleaning GDP per capita data ====
clear
import delimited "C:\Users\Salar\Desktop\CPS\GDP per capita.csv", ///
    varnames(5) case(lower)

* Keep treated + donor countries
keep if inlist(countryname,"United Kingdom","France","Germany","Italy","Spain","Netherlands","Hungary","Slovakia" ) | ///
        inlist(countryname,"Austria","Finland","Sweden","Denmark","Portugal","Greece","Ireland","Poland","Czechia") | ///
		inlist(countryname,"United States","Canada","Japan","New Zealand")

* Keep only country + year columns (v46–v64 = 2001–2019)
keep countryname v46-v64

* Rename v46–v64 to y2001–y2019
forvalues y = 2001/2019 {
    local v = 45 + (`y' - 2000)
    rename v`v' y`y'
}

* Reshape wide → long (country-year panel)
reshape long y, i(countryname) j(year)

* Rename variables
rename y gdp_pc
rename countryname country
label var gdp_pc "GDP per capita (current US dollars)"
gen lngdp_pc = log(gdp_pc)
sort country year

* Save cleaned GDP panel
save "C:\Users\Salar\Desktop\CPS\gdp_clean.dta", replace


* ==== cleaning electricity consumption per capita data ====
clear
import delimited "C:\Users\Salar\Desktop\CPS\electric consumption per capita.csv", ///
    varnames(5) case(lower)

* Keep treated + donor countries
keep if inlist(countryname,"United Kingdom","France","Germany","Italy","Spain","Netherlands","Hungary","Slovakia") | ///
        inlist(countryname,"Austria","Finland","Sweden","Denmark","Portugal","Greece","Ireland","Poland","Czechia") | ///
		inlist(countryname,"United States","Canada","Japan","New Zealand")

* Keep only country + year columns (v46–v64 = 2001–2019)
keep countryname v46-v64

* Rename v46–v64 to y2001–y2019
forvalues y = 2001/2019 {
    local v = 45 + (`y' - 2000)
    rename v`v' y`y'
}

* Reshape wide → long
reshape long y, i(countryname) j(year)

* Rename variables
rename y elec_pc
rename countryname country
label var elec_pc "Electric power consumption (kWh per capita)"

sort country year

* Save cleaned electricity panel
save "C:\Users\Salar\Desktop\CPS\elec_clean.dta", replace

* =====================================================
* Clean Manufacturing share (% GDP) data
* =====================================================
clear
import delimited "C:\Users\Salar\Desktop\CPS\manufacturing-value-added-to-gdp.csv", ///
    varnames(1) clear
	
* 1) Rename variables
rename entity              country
rename manufactur~p        manufacturing_share

* Keep treated + donor countries
keep if inlist(country,"United Kingdom","France","Germany","Italy","Spain","Netherlands","Hungary","Slovakia") | ///
        inlist(country,"Austria","Finland","Sweden","Denmark","Portugal","Greece","Ireland","Poland","Czechia") | ///
        inlist(country,"United States","Canada","Japan","New Zealand")

keep if inrange(year,2001,2019)
label var manufacturing_share "Manufacturing value added (% of GDP)"

sort country year
save "C:\Users\Salar\Desktop\CPS\manuf_clean.dta", replace



* ==== Main data ====

* 0) Import electricity generation by source
clear
import delimited "C:\Users\Salar\Desktop\CPS\share-electricity-source-facet3.csv", ///
    varnames(1) clear

* 1) Rename variables
rename entity              country
rename coalelectricity     coal_share
rename gaselectricity      gas_share
rename nuclearelectricity  nuclear_share
rename hydroelectricity    hydro_share
rename solarelectricity    solar_share
rename windelectricity     wind_share

* 2) Replace missing values with zeros
replace wind_share    = 0 if missing(wind_share)
replace solar_share   = 0 if missing(solar_share)
replace nuclear_share = 0 if missing(nuclear_share)

* 3) Construct outcome variable
gen coal_gas_share = coal_share + gas_share
label var coal_gas_share "Coal + Gas share (% of electricity)"

* 4) Keep treated + donors and 2001–2019 window
keep if inlist(country,"United Kingdom","France","Germany","Italy","Spain","Netherlands","Hungary","Slovakia") | ///
        inlist(country,"Austria","Finland","Sweden","Denmark","Portugal","Greece","Ireland","Poland","Czechia") | ///
		inlist(country,"United States","Canada","Japan","New Zealand")

keep if inrange(year,2001,2019)

* 5) Ensure balanced panel
bys country: assert _N==19
sort country year


* 6) Merge GDP per capita
merge 1:1 country year using "C:\Users\Salar\Desktop\CPS\gdp_clean.dta"
keep if _merge==3
drop _merge

* 7) Merge electricity consumption per capita
merge 1:1 country year using "C:\Users\Salar\Desktop\CPS\elec_clean.dta"
keep if _merge==3
drop _merge

* Merge manufactoring share
merge 1:1 country year using "C:\Users\Salar\Desktop\CPS\manuf_clean.dta"
keep if _merge==3
drop _merge

* 8) Create pre-treatment predictors (2001–2012)
sort country year

* Block averages for coal share
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

* Block averages for coal + gas share
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


* Averages for GDP per capita and electricity consumption
by country: egen lngdp_pc_avg  = mean(lngdp_pc)  if inrange(year,2001,2012)
by country: egen elec_pc_avg = mean(elec_pc) if inrange(year,2001,2012)
by country: egen manufacturing_share_avg = mean(manufacturing_share) if inrange(year,2001,2012)

bys country: replace lngdp_pc_avg  = lngdp_pc_avg[1]
bys country: replace elec_pc_avg = elec_pc_avg[1]
bys country: replace manufacturing_share_avg = manufacturing_share_avg[1]

* check missing predictors
foreach v in coal_gas_share_avg_early coal_gas_share_avg_mid coal_gas_share_avg_late lngdp_pc_avg elec_pc_avg {
    di "Missing count for `v':"
    count if missing(`v')
}

drop if missing(coal_gas_share_avg_early) | missing(coal_gas_share_avg_mid) | missing(coal_gas_share_avg_late) | ///
        missing(lngdp_pc_avg) | missing(elec_pc_avg) | missing(manufacturing_share_avg)

* 9) Panel setup
encode country, gen(id)
tsset id year

* 10) Define treated unit and donor units
summarize id if country=="United Kingdom", meanonly
global uk_id = r(min)

levelsof id if id != $uk_id, local(tmp_donors)
global donors "`tmp_donors'"

display "UK id = $uk_id"
display "Donors = $donors"

* 11) Install synth
cap which synth
if _rc ssc install synth, replace

***Figure 1 (Panel(a))***

* 12) Run Synthetic Control with extended predictors
synth coal_gas_share ///
      coal_gas_share_avg_early coal_gas_share_avg_mid coal_gas_share_avg_late ///
      lngdp_pc_avg elec_pc_avg manufacturing_share_avg, ///
      trunit($uk_id) trperiod(2013) controls($donors) ///
      unitnames(country) fig ///
      keep("C:\Users\Salar\Desktop\CPS\synth_CPS_coal_gas_share.dta", replace)

use "C:\Users\Salar\Desktop\CPS\synth_CPS_coal_gas_share.dta", clear


* Create the treatment effect series (vertical distance)
gen gap_in_outcome = _Y_treated - _Y_synthetic

***Figure 1 (Panel(b))***

* 13) Plot the gap over time with y-axis ticks every 10 units
twoway line gap_in_outcome _time, ///
    yline(0) ///
    xline(2013, lpattern(dash) lcolor(gs8)) ///
    ylabel(-40(10)40) ///
    ytitle("Treated − Synthetic") ///
    xtitle("Year")

