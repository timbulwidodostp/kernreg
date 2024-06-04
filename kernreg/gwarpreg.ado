*! version 2.00 94/11/14                                        (STB-30: snp9)
program define gwarpreg
  version 3.1
*Authors: Isaias H. Salgado-Ugarte, Makoto Shimizu
*and Toru Taniuchi.
*First written 94/11/14; Last revised 95/03/04
*This program recall the Adjusted Prediction Error for the
*Haerdle WARPing approximation of the NADARAYA-WATSON regression
*estimate using the results of the TurboPascal program gwarpreg.pas
*which utilizes modified algorithms and C programs from Haerdle (1991)
*"Smoothing Techniques with Implementations in S", Springer-Verlag
*Series in Statistics, New York.
local varlist "req ex min(2) max(2)"
local if "opt"
local in "opt"
#delimit ;
local options "Delta(real 0) Select(integer 0) Kercode(integer 0)
       MStart(integer 5) MEnd(integer 0) Bound(real 0.1) Gen(string)";
#delimit cr
parse "`*'"
parse "`varlist'", parse(" ")
quietly {
preserve
if "`gen'"~="" {
   tempfile _data
   save `_data'
   }
  local delta=`delta'
  if "`mstart'"~="" {
    local ms=`mstart'
  }
  if "`mend'"~="" {
    local me=`mend'
  }
  if "`bound'"~="" {
    local bou=`bound'
  }
tempvar yvar xvar
gen `yvar'=`1' `if' `in'
gen `xvar'=`2' `if' `in'
replace `xvar'=. if `yvar'==.
if `xvar'[1]==. {
   di in red "no observations"
   exit}
summ `xvar'
sort `xvar'
outfile `yvar' `xvar' using _data2, replace
tempvar dval sval kc msv mev bouv
gen `dval'=`delta'
gen `sval'=`select'

if `dval'==0 {
     di in red "you must provide delta (small bin width)"
     exit}
if `sval'==0 {
     di in red "you must provide the selector function code"
     exit}

if `sval'<1 | `sval'>5 {
   di in red "invalid selector code"
   exit}
gen `kc'=`kercode'

if `kc'==0 {
     di in red "you must provide the kernel code"
     exit}

if `kc'<1 | `kc'>6 {
   di in red "invalid kernel code"
   exit}
gen `msv'=`ms'
if `msv'<5 {
   di in red "you must use a Mstart > 5"
   exit}
gen `mev'=`me'
replace `mev'=int(0.33*((_result(6)-_result(5))/`delta')) if `me'==0
gen `bouv'=`bou'
keep `dval' `sval' `kc' `msv' `mev' `bouv'
drop if _n>1
set obs 1
outfile using _inpval, replace
drop _all
!gwarpren
!del _data2.raw
!del _inpval.raw 
tempvar mval score hval
infile `mval' `score' `hval' using resfile.
label variable `mval' "M-value"
label variable `score' "Score value"
label variable `hval' "Bandwidth"
graph `score' `mval', xlab c(l) s(.)
graph `score' `hval', xlab c(l) s(.)
sort `score'
local i = 1
noi di _newline _dup(70) "-"
noi di "Adjusted Prediction error G(M) for WARPing Nadaraya-Watson regression"
noi di _dup(70) "-"
while `i'<6 {
noi di "M-value = " `mval'[`i'] _column(20) "Score value = " `score'[`i'] _column(50) "Bandwidth = " %8.4f `hval'[`i']
      local i = `i'+1
   }
!del resfile
if "`gen'"~="" {
   restore, not
   merge using `_data'
   drop _merge
   parse "`gen'", parse(" ")  
   gen `1'=`score'
   gen `2'=`mval'
   gen `3'= `hval'
   }
}
end
