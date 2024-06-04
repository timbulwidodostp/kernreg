*! version 2.00 94/11/14                                        (STB-30: snp9)
program define warpreg
  version 3.1
*Authors: Isaias H. Salgado-Ugarte, Makoto Shimizu
*and Toru Taniuchi
*First written 94/11/14; Last revised 94/03/04
*This program calculates Haerdle WARPing approximation for
*NADARAYA-WATSON regression estimate
*using a TurboPascal program which utilizes modified algorithms and
*C programs from Haerdle (1991) "Smoothing Techniques with 
*Implementations in S", Springer-Verlag Series in Statistics, New York.
local varlist "req ex min(2) max(2)"
local if "opt"
local in "opt"
#delimit ;
local options "Bwidth(real 0) Mval(integer 0) Kercode(integer 0) SOrt
       Gen(string) noGraph T1title(string) Symbol(string) Connect(string) *";
#delimit cr
parse "`*'"
parse "`varlist'", parse(" ")
quietly {
preserve
if "`gen'"~="" {
   tempfile _data
   save `_data'
   }
tempvar yvar xvar
gen `yvar'=`1' `if' `in'
gen `xvar'=`2' `if' `in'
replace `xvar'=. if `yvar'==.
if `xvar'[1]==. {
   di in red "no observations"
   exit}
if "`sort'"=="" { sort `xvar'}
outfile `yvar' `xvar' using _data2, replace
local hval=`bwidth'
local mva=`mval'
local kco=`kercode'
tempvar hv mv kc
gen `hv'=`hval'
gen `mv'=`mva'
gen `kc'=`kco'
if `hv'==0 {
     di in red "you must provide the bandwidth"
     exit}
if `mv'==0 {
     di in red "you must provide the number of shifted histograms"
     exit}
if `kc'==0 {
     di in red "you must provide the kernel code"
     exit}
if `kc'>7 {
     di in red "invalid choice of kernel"
     exit} 
keep `hv' `mv' `kc'
drop if _n>1
set obs 1
outfile using _inpval, replace
drop _all
!warpregf
!del _data2.raw
!del _inpval.raw 
tempvar midpoi mmval
infile `mmval' `midpoi' using resfile.
label var `midpoi'  "Midpoints"
label var `mmval'  "Conditional mean"
if "`graph'" ~= "nograph"  {
   if "`t1title'" ==""{
         local t1title "Nadaraya-Watson regression (WARP)"
         local t1title "`t1title', bw = `hval', M = `mva', Kernel = `kco'"
         }
   if "`symbol'"=="" { local symbol "i" }
   if "`connect'"=="" { local connect "l" }
   graph `mmval' `midpoi', `options' t1("`t1title'") /*
                          */ s(`symbol') c(`connect')
}
!del resfile
if "`gen'"~="" {
   restore, not
   merge using `_data'
   drop _merge
   parse "`gen'", parse(" ")  
   gen `1'=`mmval'
   gen `2'=`midpoi'
   }

}
end
