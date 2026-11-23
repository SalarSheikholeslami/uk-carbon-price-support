*Figure A2(Panel a and b)
* =====================================================

*Figure A2(Panel (a))
* Carbon intensity of electricity (gCO2/kWh)
* UK vs Average donors (simple unweighted mean)

clear
import delimited "C:\Users\Salar\Desktop\CPS\carbon-intensity-electricity.csv", ///
    varnames(1) clear encoding(UTF-8)
cap rename Entity country
cap rename entity country
cap rename Year   year
cap rename year   year

* --- Robust rename for intensity column 
cap rename "Carbon intensity of electricity - gCO2/kWh" ci_elec
cap rename "Carbon intensity of electricity - gCOâ‚‚/kWh" ci_elec
cap rename carbonintensityofelectricitygco2kwh ci_elec
cap rename carbonintensityofelectricitygcoâ‚‚kwh ci_elec
cap confirm variable ci_elec
if _rc {
    ds *intens*, has(type numeric)
    local vlist `r(varlist)'
    if "`vlist'"=="" {
        ds *gco2*, has(type numeric)
        local vlist `r(varlist)'
    }
    di as text "Intensity-related numeric vars found: `vlist'"
    local v : word 1 of `vlist'
    capture confirm variable `v'
    if _rc {
        di as error "Could not find carbon intensity numeric variable. Run: describe"
        exit 198
    }
    rename `v' ci_elec
}

replace country = strtrim(country)

* --- Keep treated + donors
keep if inlist(country,"United Kingdom","France","Germany","Italy","Spain","Netherlands","Hungary","Slovakia") | ///
        inlist(country,"Austria","Finland","Sweden","Denmark","Portugal","Greece","Ireland","Poland","Czechia") | ///
        inlist(country,"United States","Canada","Japan","New Zealand")

* Window
keep if inrange(year,2001,2019)

label var ci_elec "Carbon intensity (gCO2/kWh)"

* --- UK series
preserve
keep if country=="United Kingdom"
keep year ci_elec
rename ci_elec ci_uk
tempfile uk
save `uk', replace
restore

* --- Average donors (exclude UK)
preserve
keep if country!="United Kingdom"
collapse (mean) ci_donors=ci_elec, by(year)
tempfile donors
save `donors', replace
restore

* Merge and plot
use `uk', clear
merge 1:1 year using `donors', nogen

local tr_year 2013

twoway ///
    (line ci_uk year, lcolor(black) lwidth(thick) sort) ///
    (line ci_donors year, lcolor(gs10) lwidth(vthin) sort), ///
    xline(`tr_year', lpattern(dash) lcolor(gs8)) ///
    xtitle("Year") ///
    ytitle("Carbon intensity (gCO2/kWh)", size(small) margin(r+6)) ///
    title("Carbon intensity of electricity — UK vs Average donors") ///
    legend(order(1 "UK" 2 "Average donors") rows(1))

	
*Figure A2(Panel (b))
* =====================================================
* CO2 emissions from coal: UK vs Average donors
* =====================================================

clear
import delimited "C:\Users\Salar\Desktop\CPS\annual-co2-coal.csv", ///
    varnames(1) clear encoding(UTF-8)

cap rename AnnualCOâ‚‚emissionsfromcoal co2_coal
cap rename AnnualCO2emissionsfromcoal  co2_coal
cap rename "Annual COâ‚‚ emissions from coal" co2_coal
cap rename "Annual CO2 emissions from coal"  co2_coal

cap confirm variable co2_coal
if _rc {
    ds *coal*, has(type numeric)
    local coalvars `r(varlist)'
    di as text "Coal-related numeric vars found: `coalvars'"
    local coalvar : word 1 of `coalvars'
    capture confirm variable `coalvar'
    if _rc {
        di as error "No numeric '*coal*' variable found. Run: describe"
        exit 198
    }
    rename `coalvar' co2_coal
}

rename entity country

keep if inlist(country,"United Kingdom","France","Germany","Italy","Spain","Netherlands","Hungary","Slovakia") | ///
        inlist(country,"Austria","Finland","Sweden","Denmark","Portugal","Greece","Ireland","Poland","Czechia") | ///
        inlist(country,"United States","Canada","Japan","New Zealand")

keep if inrange(year,2001,2019)

* --- UK series
preserve
keep if country=="United Kingdom"
keep year co2_coal
rename co2_coal co2_uk
tempfile uk
save `uk'
restore

* --- Average donors (exclude UK)
preserve
keep if country!="United Kingdom"
collapse (mean) co2_donors=co2_coal, by(year)
tempfile donors
save `donors'
restore

* Merge and plot
use `uk', clear
merge 1:1 year using `donors', nogen

local tr_year 2013

twoway ///
    (line co2_uk year, lcolor(black) lwidth(thick) sort) ///
    (line co2_donors year, lcolor(gs10) lwidth(vthin) sort), ///
    xline(`tr_year', lpattern(dash) lcolor(gs8)) ///
    xtitle("Year") ///
    ytitle("CO2 emissions from coal", size(small) margin(r+6)) ///
    title("CO2 emissions from coal — UK vs Average donors") ///
    legend(order(1 "UK" 2 "Average donors") rows(1))
