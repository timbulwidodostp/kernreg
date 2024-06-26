*! kernreg2 1.0.1 NJC 26 March 1999
* kernreg 2.00 94/10/03 (STB-30: snp9)
* Isaias H. Salgado-Ugarte, Makoto Shimizu and Toru Taniuchi.
program define kernreg2
        version 6.0

        #delimit ;
        syntax varlist(min=2 max=2) [if] [in]
        , Bwidth(real) Kercode(int) NPoint(int)
        [ Gen(str) noGraph T1title(str) Symbol(str) Connect(str) * ] ;
        #delimit cr

        if `kercode' < 1 | `kercode' > 7 {
                di in r "kernel code should be between 1 and 7"
                exit 198 
        }
        local kc `kercode'
        local hv `bwidth'
        local np `npoint'

        tokenize `varlist'
        args yvar xvar
        marksample touse
        qui count if `touse'
        if r(N) == 0 { error 2000 }

        tempvar fh rh mh z kz kzy gridp
        quietly  {
                if `np' >_N { 
			preserve
			set obs `np' 
		}

                gen `fh' = 0
                gen `rh' = 0
                gen `z' = 0 if `touse' 
                gen `kz' = 0
                gen `kzy' = 0
		
                su `xvar' if `touse', meanonly
                local nuobs = r(N)
                local maxval = r(max)
                local minval = r(min)
                local range = `maxval' - `minval'
                local inter = `range' / (`np' - 1)
	        gen `gridp' = sum(`inter') + `minval' - `inter' if _n <= `np'

                local count = 1
                while `count' <= `np' {
                        local xo = `gridp'[`count']
                        replace `z' = (`xo' - `xvar') / `hv'
                        if `kc' == 1 {
                                replace `kz' = 0.5 if (abs(`z') <= 1)
                        }
                        else if `kc' == 2 {
                                replace `kz' = (1 - abs(`z')) if (abs(`z') <= 1)
                        }
                        else if `kc' == 3 {
                                replace `kz' = /* 
				*/ 0.75 * (1 - `z'^2) if (abs(`z') <= 1)
                        }
                        else if `kc' == 4 {
                                replace `kz' = /*
				*/ (15/16) * ((1 - `z'^2))^2 if (abs(`z') <= 1)
                        }
                        else if `kc' == 5 {
                                replace `kz' = /*
				*/ (35/32) * (1 - `z'^2)^3 if (abs(`z') <= 1)

                        }
                        else if `kc' == 6 {
                                replace `kz' = /*
                */ (1 / (sqrt(2 * _pi))) * exp(-0.5 * `z'^2) if (abs(`z') <= 3)
                        }
                        else {
                                replace `kz' = /*
                */ (_pi /4 ) * cos((_pi / 2) * `z') if (abs(`z') <= 1)
                        }

                        if `kc' == 6 {
                                replace `kzy' = `kz' * `yvar' if (abs(`z') <= 3)
                        }
                        else replace `kzy' = `kz' * `yvar' if (abs(`z') <= 1)

                        su `kz', meanonly 
                        replace `fh' = /*
		*/ (1 / (`nuobs' * `hv')) * `r(sum)' in `count'
                        su `kzy', meanonly 
                        replace `rh' = /*
		*/ (1 / (`nuobs' * `hv')) * `r(sum)' in `count'

			replace `kz' = 0 
			replace `kzy' = 0 
                        local count = `count' + 1
                }

                gen `mh' = `rh'/`fh' if _n <= `np'

                label var `mh' "Conditional mean"
                label var `gridp' "Grid points"

                if "`graph'" ~= "nograph"  {
                        if "`t1title'" =="" {
                                local t1title "Kernel regression"
                                local t1title "`t1title', bw = `hv', k = `kc'"
                        }
                        if "`symbol'" == "" { local symbol "i" }
                        if "`connect'" == "" { local connect "l" }
                        graph `mh' `gridp', `options' /*
                        */ t1("`t1title'") s(`symbol') c(`connect')
                }

                if "`gen'" ~= "" {
			capture restore, not 
                        tokenize `gen'
                        gen `1' = `mh'
                        gen `2' = `gridp'
                }
        }
end
