*Table B3
do "C:\Users\Salar\Desktop\Seminar paper\Codes\Figure 1(Panel A).do"
	  
* Table B3: Donor pool weights (SCM) -> Word (article-style)
* 1) Create an id->country map (one row per country)

*********************************************************************
preserve
keep id country
bys id: keep if _n==1
tempfile idmap
save `idmap', replace
restore

* 2) Pull weights matrix (in your case it is 20 x 2: donor_id + weight)
capture matrix Wm = e(W_weights)
if _rc matrix Wm = e(W)

* 3) Convert weight matrix to a dataset and merge country names
preserve
clear
svmat double Wm, names(col)

* Rename first two columns robustly
ds
local c1 : word 1 of `r(varlist)'
local c2 : word 2 of `r(varlist)'
rename `c1' id
rename `c2' weight

merge 1:1 id using `idmap', nogen keep(match)

* 4) Clean + order
order country id weight
sort weight
format weight %9.3f


* Add percent column
gen weight_pct = 100*weight
format weight_pct %9.2f
order country weight weight_pct

* 5) Display in Stata
list country weight weight_pct, noobs abbreviate(24)

* 6) Export to Word
putdocx clear
putdocx begin

putdocx paragraph, style(Heading3)
putdocx text ("Table B3 : Unit Weights in the Construction of the Synthetic UK")

putdocx table W = data(country weight weight_pct), varnames

* Header formatting
putdocx table W(1,.), bold

* Alignment: country left, numbers right
putdocx table W(.,1), halign(left)
putdocx table W(.,2), halign(right)
putdocx table W(.,3), halign(right)

* Column widths
putdocx table W(.,1), width(3.2)
putdocx table W(.,2), width(1.2)
putdocx table W(.,3), width(1.2)

putdocx save "C:\Users\Salar\Desktop\CPS\TableB3_DonorWeights.docx", replace

restore
