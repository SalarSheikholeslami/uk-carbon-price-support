*Table 1 : Predictor Balance and Table B3 : Unit weights

*-------------------------------------------------------
*Table 1
do "C:\Users\Salar\Desktop\Seminar paper\Codes\Figure 1(Panel A).do"
*---------------------------------------------------
* Table 1: UK / Synth UK / AVG Donor pool (Predictor Balance)


* --- Predictor list (same as in synth; same order)
local predvars ///
    coal_gas_share_avg_early coal_gas_share_avg_mid coal_gas_share_avg_late ///
    lngdp_pc_avg elec_pc_avg manufacturing_share_avg

* 1) Save a country-level predictor dataset (1 row per country)
preserve
keep id country `predvars'
bys id: keep if _n==1
tempfile pred_country
save `pred_country', replace
restore

* 2) Extract UK predictor values
preserve
use `pred_country', clear
keep if id == $uk_id
tempfile uk_row
save `uk_row', replace
restore

* 3) Get donor weights from synth (20x2: donor id + weight)
capture matrix Wm = e(W_weights)
if _rc matrix Wm = e(W)

preserve
clear
svmat double Wm, names(col)

* If Wm has 2 columns, first is donor id, second is weight
ds
local v1 : word 1 of `r(varlist)'
local v2 : word 2 of `r(varlist)'
rename `v1' id
rename `v2' w
keep id w
tempfile wts
save `wts', replace
restore

* 4) Merge weights onto donor predictor data
use `pred_country', clear
drop if id == $uk_id

merge 1:1 id using `wts', keep(match) nogen
replace w = 0 if missing(w)   // safety

* 5) Compute Synthetic and Avg Donor for each predictor
tempfile T1
postfile hh str50 Variable double UK Synth_UK Avg_DonorPool using `T1', replace

foreach p of local predvars {

    * UK value
    quietly use `uk_row', clear
    quietly summarize `p', meanonly
    local ukv = r(mean)

    * Avg donor pool (unweighted)
    quietly use `pred_country', clear
    drop if id == $uk_id
    quietly summarize `p', meanonly
    local avg = r(mean)

    * Synthetic UK (weighted)
    quietly use `pred_country', clear
    drop if id == $uk_id
    merge 1:1 id using `wts', keep(match) nogen
    replace w = 0 if missing(w)
    gen wp = w * `p'
    quietly summarize wp, meanonly
    local syn = r(sum)

    post hh ("`p'") (`ukv') (`syn') (`avg')
}

postclose hh
use `T1', clear

* 6) Make labels nicer (optional, but good for slides/paper)
replace Variable = "Coal+Gas share avg (2001–2004)" in 1
replace Variable = "Coal+Gas share avg (2005–2008)" in 2
replace Variable = "Coal+Gas share avg (2009–2012)" in 3
replace Variable = "ln GDP per capita avg (2001–2012)" in 4
replace Variable = "Electricity consumption per capita avg (2001–2012)" in 5
replace Variable = "Manufacturing share avg (2001–2012)" in 6

format UK Synth_UK Avg_DonorPool %9.3f
list, noobs

* 7) Export to Excel
export excel using "C:\Users\Salar\Desktop\CPS\Table4_predictors_balance.xlsx", ///
    firstrow(variables) replace
save "C:\Users\Salar\Desktop\CPS\Table4_predictors_balance.dta", replace
format UK Synth_UK Avg_DonorPool %9.2f
list Variable UK Synth_UK Avg_DonorPool, noobs abbreviate(28)

format UK Synth_UK Avg_DonorPool %9.2f
list Variable UK Synth_UK Avg_DonorPool, noobs abbreviate(28)


* Export Predictor Balance Table to Word (article-style)
*=========================================================
capture confirm variable PredictorBalance
if _rc {
    capture confirm variable Variable
    if !_rc rename Variable PredictorBalance
    else {
        ds, has(type string)
        local s = word("`r(varlist)'", 1)
        rename `s' PredictorBalance
    }
}

format PredictorBalance %45s
format UK Synth_UK Avg_DonorPool %9.2f
putdocx clear
putdocx begin
putdocx paragraph, style(Heading3)
putdocx text ("Table 1 : Predictors' values for the UK, synthetic UK and average of the donor pool")
putdocx table T1 = data(PredictorBalance UK Synth_UK Avg_DonorPool), varnames

* Header bold
putdocx table T1(1,.), bold

* Alignments: text left, numbers right
putdocx table T1(.,1), halign(left)
putdocx table T1(.,2), halign(right)
putdocx table T1(.,3), halign(right)
putdocx table T1(.,4), halign(right)

* Column widths
putdocx table T1(.,1), width(3.6)
putdocx table T1(.,2), width(1.1)
putdocx table T1(.,3), width(1.1)
putdocx table T1(.,4), width(1.3)

putdocx save "C:\Users\Salar\Desktop\CPS\Table1_PredictorBalance.docx", replace
