function latticestrainMultiplePeaksNoCorr, x, A
common fitinfo, npeaks, npsi, offsetangle, costheta, countnan, nan
;
step = 0
d = fltarr(N_ELEMENTS(x))
; print, A
;print, N_ELEMENTS(x), N_ELEMENTS(ximageplate)
for i=0, npeaks-1 do begin
	d0 = A[2*i]
	Q = A[2*i+1]
	;print, i, t0, Q
	for j=0, npsi-1 do begin
		; in system properly centered
		cospsi = costheta*cos(x[step]-offsetangle)
		d[step] = d0*(1.+Q*(1.-3.*cospsi*cospsi))
		step += 1
	endfor
endfor
if (countnan gt 0) then d[nan] = 0. ; Setting d-spacings to 0 where there is no data...
return, d
end
