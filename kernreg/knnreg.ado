*! version 2.0 94/11/17                                         (STB-30: snp9)
program define knnreg
 version 3.1
*Authors: Isaias H. Salgado Ugarte, Makoto Shimizu
*and Toru Taniuchi.
*First written (version 1.0) 94/10/31; last revised 95/02/16
*First written (version 2.0) 94/11/17
*This program calculate k-Nearest Neighbor (k-NN) regression
*based on the algorithm of Haerdle (1991) and considering 
*additional adjustments quoted in XploRe Systems (1993)
*95/02/16: fixed the (incorrect) shifting of data.
local varlist "req ex min(2) max(2)"
local if "opt"
local in "opt"
#delimit ;
local options "Knum(integer 0) Gen(string) noGraph T1title(string) Symbol(string) 
      Connect(string) *";
#delimit cr
parse "`*'"
parse "`varlist'", parse(" ")
tempvar yvar xvar kv sumy mk dif difa sumd
quietly  {
    gen `yvar'=`1' `if' `in'
    gen `xvar'=`2' `if' `in'
    _crcslbl `yvar' `1'
    _crcslbl `xvar' `2'
    sort `xvar' `yvar'
    if `knum'==0 | `knum'>_N {
        di in red "the number of neighbors must be entered (0<k<n)"
        exit}
    local kv=`knum'
    local start=1+int(`kv'/2)
    gen `mk'=.
    gen `sumy'=sum(`yvar')
    replace `mk'=`sumy'[`kv']/`kv' if _n==`start'
    gen `dif'=(`yvar'[_n+`kv']-`yvar'[_n])/`kv'
    gen `difa'=`dif'[_n-1]
    replace `difa'=`mk'[`start'] if _n==1
    gen `sumd'=sum(`difa')

    replace `mk'=`sumd'[_n-`start'+1] if _n>=`start'+1 & _n<=_N-`start'+1

    if "`graph'" ~= "nograph"  {
       if "`t1title'" ==""{
          local t1title "k-NN regression"
          local t1title "`t1title', k = `kv'"
          }
       if "`symbol'"=="" { local symbol "oi" }
       if "`connect'"=="" { local connect ".l" }
       graph `yvar' `mk' `xvar', `options' /*
				*/ t1("`t1title'") /*
				*/ s(`symbol') c(`connect')
   } 
    if "`gen'"~="" {
       rename `mk' `gen'
       }
   }
end
