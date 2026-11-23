* Main Results : Figure 1 (Panel B)
do "C:\Users\Salar\Desktop\Seminar paper\Codes\Figure 1(Panel A).do"
use "C:\Users\Salar\Desktop\CPS\synth_CPS_coal_gas_share.dta", clear
* Create the treatment effect series (vertical distance)
gen gap_in_outcome = _Y_treated - _Y_synthetic

***Figure 1 (Panel(b))***

* Plot the gap
twoway line gap_in_outcome _time, ///
    yline(0) ///
    xline(2013, lpattern(dash) lcolor(gs8)) ///
    ylabel(-40(10)40) ///
    ytitle("Treated − Synthetic") ///
    xtitle("Year")

