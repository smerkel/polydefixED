; *******************************************************************
; PolydefixED stress, strain, and texture analysis for experiment in 
; energy dispersive geometry
; Copyright (C) 2000-2011 S. Merkel, Universite Lille 1
; http://merkel.zoneo.net/Multifit/
; 
; This program is free software; you can redistribute it and/or
; modify it under the terms of the GNU General Public License
; as published by the Free Software Foundation; either version 2
; of the License, or (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
;
; *******************************************************************

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
