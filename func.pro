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

; ****************************************** intformat *********************************

function intformat, n, ndigits
case ndigits of
	'1': s = string(n,format='(I1.1)')
	'2': s = string(n,format='(I2.2)')
	'3': s = string(n,format='(I3.3)')
	'4': s = string(n,format='(I4.4)')
	'5': s = string(n,format='(I5.5)')
	'6': s = string(n,format='(I6.6)')
	'7': s = string(n,format='(I7.7)')
	'8': s = string(n,format='(I8.8)')
	'9': s = string(n,format='(I9.9)')
	'10': s = string(n,format='(I10.10)')
endcase
return, s
end


; ****************************************** fltformat *********************************

function fltformatA, f
if (abs(f) lt 10.) then s = string(f,format='(F8.5)') else s = string(f,format='(e9.2)')
; print, f, s
return, s
end

function fltformatB, f
s = string(f,format='(F8.2)')
return, s
end

function fltformatC, f
s = string(f,format='(e8.1)')
return, s
end

function fltformatD, f
s = string(f,format='(e10.3)')
return, s
end

; ****************************************** readascii **************
; readascii: 
; reads a line out of an ascii file, but skips lines that start with a
; given comment character

function readascii, lun, com=com
IF N_Elements(com) EQ 0 THEN com = ''
test = 1
while (test) do begin
	if (EOF(lun)) then return, 'EOF'
	row = STRARR(1)
	READF, lun, row
	if (strmid(row,0,1) ne com) then return, row
endwhile
end

PRO printascii, lun, txt
row = strsplit(txt, '\\n', /extract, /REGEX, /PRESERVE_NULL)
for i=0, N_ELEMENTS(row)-1 do begin
	col = strsplit(row[i], '\\t', /extract, /REGEX, /PRESERVE_NULL )
	text = ""
	for j=0, N_ELEMENTS(col)-1 do begin
		text += col[j]
		if (j lt N_ELEMENTS(col)-1) then text += "    "
	endfor
	printf, lun, text
endfor
END


function dhklortho, x, A
	d =1./sqrt(x.h*x.h/(A[0]* A[0]) + x.k*x.k/(A[1]* A[1]) +x.l*x.l/(A[2]* A[2]))
	return, d
end
function dhklhexa, x, A
	d = A[0]/sqrt(4.*(x.h*x.h+x.k*x.k+x.h*x.k)/3.+A[0]*A[0]*x.l*x.l/(A[1]*A[1]))
	return, d
end

function dhklcubic, x, A
	d = A[0]/sqrt(x.h*x.h + x.k*x.k +x.l*x.l)
	return, d
end