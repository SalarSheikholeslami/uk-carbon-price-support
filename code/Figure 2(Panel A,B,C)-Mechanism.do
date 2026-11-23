*Figure 2 (Panel a,b,c) : Mechanism plots

* ==== main data ====

* Import electricity generation shares
clear
import delimited "C:\Users\Salar\Desktop\CPS\share-electricity-source-facet3.csv", ///
    varnames(1) clear

* Rename variables
rename entity              country
rename coalelectricity     coal_share
rename gaselectricity      gas_share
rename nuclearelectricity  nuclear_share
rename hydroelectricity    hydro_share
rename solarelectricity    solar_share
rename windelectricity     wind_share

* Replace missing values with zeros
replace wind_share    = 0 if missing(wind_share)
replace solar_share   = 0 if missing(solar_share)
replace nuclear_share = 0 if missing(nuclear_share)

* Construct renewable energy shares
gen renew_basic_share = hydro_share + wind_share + solar_share
replace renew_basic_share = 0 if missing(renew_basic_share)
gen coal_gas_share = coal_share + gas_share
label var coal_gas_share "Coal + Gas share (% of electricity)"

* Keep treated + donors and 2001–2019 window
keep if inlist(country,"United Kingdom","France","Germany","Italy","Spain","Netherlands","Hungary","Slovakia") | ///
        inlist(country,"Austria","Finland","Sweden","Denmark","Portugal","Greece","Ireland","Poland","Czechia") | ///
		inlist(country,"United States","Canada","Japan","New Zealand")

keep if inrange(year,2001,2019)

* Ensure balanced panel
bys country: assert _N==19
sort country year

*  Panel setup
encode country, gen(id)
tsset id year

* Define treated unit and donor units
summarize id if country=="United Kingdom", meanonly
global uk_id = r(min)

levelsof id if id != $uk_id, local(tmp_donors)
global donors "`tmp_donors'"

display "UK id = $uk_id"
display "Donors = $donors"



*Figure 2 (Panel (a))
* =====================================================
* Coal share (UK vs Average Donors)


local tr_year 2013

preserve

gen coal_uk    = coal_share if id == $uk_id
gen coal_donor = coal_share if id != $uk_id

bys year: egen uk_series    = mean(coal_uk)
bys year: egen donors_mean  = mean(coal_donor)

* keep one obs per year for plotting
keep year uk_series donors_mean
duplicates drop
sort year

label var uk_series   "UK"
label var donors_mean "Average donors"

twoway ///
    (line uk_series year, lcolor(black) lwidth(thick) sort) ///
    (line donors_mean year, lcolor(gs10) lwidth(vthin) sort) ///
    , ///
    xline(`tr_year', lpattern(dash) lcolor(gs8)) ///
    xtitle("Year") ///
    ytitle("Coal share (% of electricity)") ///
    title("Coal share — UK vs Average donors") ///
    legend(order(1 "UK" 2 "Average donors") rows(1))

restore


*Figure 2 (Panel (b))
* =====================================================
* Gas share (UK vs Average Donors)
* =====================================================

local tr_year 2013

preserve

* Create UK series and donors series
gen gas_uk    = gas_share if id == $uk_id
gen gas_donor = gas_share if id != $uk_id

* Collapse to year-level series (mean over units)
bys year: egen uk_series   = mean(gas_uk)
bys year: egen donors_mean = mean(gas_donor)

* Keep one observation per year for plotting
keep year uk_series donors_mean
duplicates drop
sort year

label var uk_series   "UK"
label var donors_mean "Average donors"

twoway ///
    (line uk_series year, lcolor(black) lwidth(thick) sort) ///
    (line donors_mean year, lcolor(gs10) lwidth(vthin) sort) ///
    , ///
    xline(`tr_year', lpattern(dash) lcolor(gs8)) ///
    xtitle("Year") ///
    ytitle("Gas share (% of electricity)") ///
    title("Gas share — UK vs Average donors") ///
    legend(order(1 "UK" 2 "Average donors") rows(1))

restore

*Figure 2 (Panel (c))
* =====================================================
* Renewable share of electricity generation

local tr_year 2013



* Renewable share 
gen renew_share = solar_share + wind_share + hydro_share
label var renew_share "Renewable share (solar+wind+hydro) (% of electricity)"

* --- UK series
preserve
keep if country=="United Kingdom"
keep year renew_share
rename renew_share ren_uk
tempfile uk
save `uk'
restore

* --- Average donors (exclude UK)
preserve
keep if country!="United Kingdom"
collapse (mean) ren_donors=renew_share, by(year)
tempfile donors
save `donors'
restore

* Merge
use `uk', clear
merge 1:1 year using `donors', nogen

* Plot
twoway ///
    (line ren_uk year, lcolor(black) lwidth(thick)) ///
    (line ren_donors year, lcolor(gs10) lwidth(medthin)), ///
    xline(2013, lpattern(dash) lcolor(gs8)) ///
    xtitle("Year") ///
    ytitle("Renewable share (% of electricity)") ///
    title("Renewable share — UK vs Average donors") ///
    legend(order(1 "UK" 2 "Average donors") rows(1))