*! version 2.00 94/10/03                                        (STB-30: snp9)
program define kernreg
  version 3.1
*Authors: Isaias H. Salgado-Ugarte, Makoto Shimizu
*and Toru Taniuchi.
*First written (version 1.00,  94/10/03; version 2.00 94/12/27);
*Last revised: 95/03/06
*This program calculates nonparametric regression by means of
*the Nadaraya-Watson estimator using a Quartic (Biweight) kernel.
*It is based on the algorithm described by Haerdle (1991), 
*Chapter 5. This version considers a grid with the number of points
*specified by the user. 
*Kernel codes:
* 1: Uniform
* 2: Triangular
* 3: Epanechnikow
* 4: Quartic (biweight)
* 5: Triweight
* 6: Gaussian
* 7: Cosinus 
*If _N is less than `np' then the program sets the number of the 
*observations = `np' to obtain the full set of estimations.
*syntax: kernreg yvar xvar [if exp] [in range], Bwidth(#) Kercode(#) NPoint(#)
*        [Gen(mhvar gridvar) NOGraph graph_options]

local varlist "req ex min(2) max(2)"
local if "opt"
local in "opt"
#delimit ;
local options "Bwidth(real 0) Kercode(integer 0) NPoint(integer 0)
   Gen(string) noGraph T1title(string) Symbol(string) Connect(string) *";
#delimit cr
parse "`*'"
parse "`varlist'", parse(" ")
tempvar yvar xvar fh rh mh count xo z kz kzy sums sums2  nuobs npoi
quietly  {
preserve
if "`gen'"~="" {
   tempfile _data
   save `_data'
   }

gen `yvar'=`1' `if' `in'
gen `xvar'=`2' `if' `in'
replace `xvar'=. if `yvar'==.
if `xvar'[1]==. {
   di in red "no observations"
   exit}

local hv=`bwidth'
local kco=`kercode'
local np=`npoint'

if `np'>_N {
     set obs `np'
     }

tempvar h kc
gen `h'=`hv'
gen `kc'=`kco'
if `h'==0 {
     di in red "you must provide the bandwidth"
     exit}
if `kc'==0 {
     di in red "you must provide the kernel code"
     exit}
if `np'==0 {
     di in red "you must provide the number of grid points"
     exit}

if `kc'>7 {
     di in red "invalid choice of kernel"
     exit} 
  gen `fh'=0
  gen `rh'=0
  gen `mh'=0
  gen `count'=1
  gen `xo'=0
  gen `sums'=0
  gen `sums2'=0
  gen `z'=0
  gen `kz'=0
  gen `kzy'=0
  tempvar nuobs maxval minval range inter gridp
  summ `xvar'

  gen `nuobs'=_result(1)

  gen `maxval'=_result(6)
  gen `minval'=_result(5)
  gen `range'=`maxval'-`minval'
  gen `inter'=`range'/(`np'-1)
  gen `gridp'=sum(`inter')+`minval'-`inter' 
*  noi di "WORKING WITH EACH VALUE. PLEASE BE PATIENT"
*  set more 1

  while `count'<=`np' {
*    noi di "Calculating fh(x) and rh(x) number = " `count'
    replace `xo'=`gridp'[`count']
    replace `z'=(`xo'-`xvar')/`h'
    if `kc'==1 {
        replace `kz'=0.5 if abs(`z')<=1
    }
    else if `kc'==2 {
        replace `kz'=(1-abs(`z')) if abs(`z')<=1
    }
    else if `kc'==3 {
        replace `kz'=(3/4)*(1-`z'^2) if abs(`z')<=1
    }
    else if `kc'==4 {
        replace `kz'=(15/16)*((1-`z'^2))^2 if abs(`z')<=1
    }
    else if `kc'==5 {
        replace `kz'=(35/32)*(1-`z'^2)^3 if abs(`z')<=1
    }
    else if `kc'==6 {
        replace `kz'=(1/(sqrt(2*_pi)))*exp(-0.5*`z'^2) if abs(`z')<=3
    }
    else {
        replace `kz'=(_pi/4)*cos((_pi/2)*`z') if abs(`z')<=1
    }
    if `kc'==6 {
        replace `kzy'=`kz'*`yvar' if abs(`z')<=3
    }
    else {
        replace `kzy'=`kz'*`yvar' if abs(`z')<=1
    }
    replace `sums'= sum(`kz')
    replace `sums2'= sum(`kzy')
    replace `fh'=(1/(`nuobs'*`h'))*`sums'[_N] if _n==`count'
    replace `rh'=(1/(`nuobs'*`h'))*`sums2'[_N] if _n==`count'
    replace `kz'=0
    replace `kzy'=0
    replace `count'=`count'+1
  }

  if `rh'==0 {
          replace `mh'=0
  }
  else {
          replace `mh'=`rh'/`fh'
  }
  replace `mh'=. if _n>`np'
  replace `gridp'=. if _n>`np'

*  set more 0
  label var `mh' "Conditional mean"
  label var `gridp' "Grid points"

  if "`graph'" ~= "nograph"  {
     if "`t1title'" ==""{
        local t1title "Kernel regression"
        local t1title "`t1title', bw = `hv', k = `kco'"
        }
     if "`symbol'"=="" { local symbol "i" }
     if "`connect'"=="" { local connect "l" }
     graph `mh' `gridp', `options' /*
		*/ t1("`t1title'") /*
		*/ s(`symbol') c(`connect')
 } 

if "`gen'"~="" {
   restore, not
   parse "`gen'", parse(" ")  
   gen `1'=`mh'
   gen `2'=`gridp'
   }

  }
end
