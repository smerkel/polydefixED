
; symmetry codes (numbers and letters, symmetry code in letters in the reference)
; - 0 cubic
; - 1 hexa for hexagonal
; - 2 otho for orthorhombic
; - 3 trig for trigonal
; Equation of state (Birch-Mur...)
; - V0: unit cell volume at zero pressure and ambient temperature
; - K0: bulk modulus at zero pressure and ambient temperature
; - dK0dP: first pressure derivative of bulk modulus at ambient temperature
; - dK0dPT: first temperature derivative of bulk modulus at ambient pressure
; - alphaA, alphaB, alphaC: coefficients of the thermal expansion
;     alpha = alphaA + alphaB*T - alphaC*T*T
;     V(P=0, T) = V(P=0, T=300K) * int(300, T) alpha dT
; elasticmodel: 
;  0->isotropic
;  1->anisotropic
; Parameters for isotropic elastic model
;  iG[]: G = iG[0] + iG[1] * P + iG[2] * P*P  + iG[3] * (T-300) + iG[4]* (T-300) * (T-300)
;      (P deduced from the data and EOS, T taken from input data)
; Parameters for anisotropic elastic model
;  Cij: Cij = Cij[i,j,0] + Cij[i,j,1] * P + Cij[i,j,2] * P * P
;                + Cij[i,j,3] * (T-300) + Cij[i,j,4] * (T-300) * (T-300)
;      (P deduced from the data and EOS, T taken from input data)
; 

PRO materialObject__DEFINE 
	struct = { materialObject, tmp: 0, name:'Not set', symmetry:'', V0:0.0, K0:0.0, dK0dP:0.0, dK0dT:0.0, alphaA:0.0, alphaB:0.0, alphaC:0.0, elasticmodel: 0, iG: fltarr(5), Cij: fltarr(7,7,5)}
END

function materialObject::Init
self.iG[*] = 0.
self.Cij[*,*,*] = 0.
return, 1
end

; *************************************************** Temporary variables **********************

; functions with the tmp variable: usefull to transmit information from actions
; with the object itself...
pro materialObject::setTmp, tmp
self.tmp = tmp
end

function materialObject::getTmp
return, self.tmp
end

; **************************************************** Elastic properties ***********************

pro materialObject::setIsotropicProp, g0, g1, g2, g3, g4
self.iG[0] = g0
self.iG[1] = g1
self.iG[2] = g2
self.iG[3] = g3
self.iG[4] = g4
self.elasticmodel=0
end

pro materialObject::setAnisElasticProp, cij
for i=0,6 do begin
	for j=0,6 do begin
		for k=0,4 do begin
			self.Cij[i,j,k] = cij[i,j,k]
		endfor
	endfor
endfor
self.elasticmodel=1
end


;  **************************************************** Set parameters **************************

pro materialObject::setSymmetryFromCode, code
case code  OF
	0: self.symmetry = 'cubic'
	1: self.symmetry = 'hexa'
	2: self.symmetry = 'ortho'
	3: self.symmetry = 'trig'
	else:
endcase
end

pro materialObject::setElasticModel, model
self.elasticmodel = model
end

pro materialObject::setName, name
self.name = name
end

pro materialObject::setEOSParameters, vo, ko, dkodp, dKodT
self.V0 = vo
self.K0 = ko
self.dK0dP = dKodp
self.dK0dT = dKodT
end

pro materialObject::setThemalExpansion, alphaA, alphaB, alphaC
self.alphaA = alphaA
self.alphaB = alphaB
self.alphaC = alphaC
end

; **************************************************** Information ******************************

function materialObject::refineUnitCell, latticestrain
cell = OBJ_NEW('unitCellObject', self.symmetry, latticestrain->getName())
if (latticestrain->getSet() eq 1) then begin
	if (self.symmetry eq 'ortho') then begin
		nuse = latticestrain->getnuse()
		d = latticestrain->getd()
		dd = latticestrain->getdd()
		h = latticestrain->geth()
		k = latticestrain->getk()
		l = latticestrain->getl()
		x = replicate({plane, h:0, k:0, l:0},nuse)
		for i=0,nuse-1 do begin
			x[i] = {plane, h[i], k[i], l[i]}
		endfor
		a = [1., 1., 1.]
		fit = MPFITFUN('dhklortho', x, d, dd, a, perror=perror, YFIT=dfit, /quiet)
		cell->setFit, [fit[0], perror[0], fit[1], perror[1], fit[2], perror[2]]
		txt = "\thkl    dm       dc      diff\n"
		for i=0,nuse-1 do begin
			txt += "\t" + STRTRIM(STRING(h[i],/PRINT),2)+ STRTRIM(STRING(k[i],/PRINT),2)+ STRTRIM(STRING(l[i],/PRINT),2) + ": " + fltformatA(d[i]) + " (+/-) " + fltformatA(dd[i]) + "     " + fltformatA(dfit[i]) + "    " + fltformatA(d[i]-dfit[i]) + "\n" 
		endfor
		cell->setDetails, txt
	endif else if ((self.symmetry eq 'hexa') or (self.symmetry eq 'trig')) then begin 
		nuse = latticestrain->getnuse()
		d = latticestrain->getd()
		dd = latticestrain->getdd()
		h = latticestrain->geth()
		k = latticestrain->getk()
		l = latticestrain->getl()
		x = replicate({plane, h:0, k:0, l:0},nuse)
		for i=0,nuse-1 do begin
			x[i] = {plane, h[i], k[i], l[i]}
		endfor
		a = [1., 1.6]
		fit = MPFITFUN('dhklhexa', x, d, dd, a, perror=perror, YFIT=dfit, /quiet)
		cell->setFit, [fit[0], perror[0], fit[1], perror[1]]
		txt = "\thkl    dm       dc      diff\n"
		for i=0,nuse-1 do begin
			txt += "\t" + STRTRIM(STRING(h[i],/PRINT),2)+ STRTRIM(STRING(k[i],/PRINT),2)+ STRTRIM(STRING(l[i],/PRINT),2) + ": " + fltformatA(d[i]) + " (+/-) " + fltformatA(dd[i]) + "     " + fltformatA(dfit[i]) + "    " + fltformatA(d[i]-dfit[i]) + "\n" 
		endfor
		cell->setDetails, txt
	endif else if (self.symmetry eq 'cubic') then begin 
		nuse = latticestrain->getnuse()
		d = latticestrain->getd()
		dd = latticestrain->getdd()
		h = latticestrain->geth()
		k = latticestrain->getk()
		l = latticestrain->getl()
		x = replicate({plane, h:0, k:0, l:0},nuse)
		for i=0,nuse-1 do begin
			x[i] = {plane, h[i], k[i], l[i]}
		endfor
		a = d[0]*sqrt(h[0]*h[0]+k[0]*k[0]+l[0]*l[0])
		fit = MPFITFUN('dhklcubic', x, d, dd, a, perror=perror, YFIT=dfit, /quiet)
		cell->setFit, [fit[0], perror[0]]
		txt = "\thkl    dm       dc      diff\n"
		for i=0,nuse-1 do begin
			txt += "\t" + STRTRIM(STRING(h[i],/PRINT),2)+ STRTRIM(STRING(k[i],/PRINT),2)+ STRTRIM(STRING(l[i],/PRINT),2) + ": " + fltformatA(d[i]) + " (+/-) " + fltformatA(dd[i]) + "     " + fltformatA(dfit[i]) + "    " + fltformatA(d[i]-dfit[i]) + "\n" 
		endfor
		cell->setDetails, txt
	endif
endif
return, cell
end

function materialObject::birch3VT, T
VT0 = self.V0 * exp(self.alphaA*(T-300.) + self.alphaB*(T*T-300.*300.)/2. - self.alphaC*(1./T-1./300.))
return, VT0
end

function materialObject::birch3KT, T
TC = T-300.
KT = self.K0+self.dK0dT*TC
return, KT
end

function materialObject::birch3, volume, T
VT0 = self->birch3VT(T)
KT = self->birch3KT(T)
dKT = self.dK0dP
v = volume/VT0
f = .5*(v^(-2./3.)-1.);
p0 = KT;
p1 = 1.5*KT*(dKT-4.);
FF = p0+p1*f;
p = FF*3.*f*(1.+2.*f)^2.5;
return, p
end

function materialObject::refinePressure, latticestrain, T
cell = self->refineUnitCell(latticestrain)
V = cell->getVolume()
P = self->birch3(V[0],T)
PP1 = self->birch3(V[0]+V[1],T)
PP2 = self->birch3(V[0]-V[1],T)
dP = 0.5*abs(PP1-PP2)
cell->setPressure, [P,dP]
cell->setTemperature, T
return, cell
end

function materialObject::refineVolume, latticestrain
cell = self->refineUnitCell(latticestrain)
return, cell
end

; **************************************************** Information ******************************

function materialObject::getName
return, self.name
end

function materialObject::getSymmetry
return, self.symmetry
end

function materialObject::getSymmetryFromCode, code
case code  OF
	0: return, 'cubic'
	1: return, 'hexa'
	2: return, 'ortho'
	3: return, 'trig'
	else: return, 10
endcase
return, 10
end

function materialObject::getSymmetryCode
case self.symmetry of
	'cubic': return, 0
	'hexa': return, 1
	'ortho': return, 2
	'trig': return, 3
	else: return, 10
endcase
return, 10
end

function materialObject::beartexCodeList
case self.symmetry of
	'cubic': return, {codelist: [7, 6], pg1:["O", "T"], pg2:[432, 23]}
	'hexa': return, {codelist: [11, 10], pg1:["D6", "C6"], pg2:[622, 6]}
	'ortho': return, {codelist: [3], pg1: ["D2"], pg2: [222]}
	'trig': return, {codelist: [9, 8], pg1: ["D3", "C3"], pg2: [32, 3]}
	else: return, 10
endcase
return, 10
end

function materialObject::getElasticModelCode
return, self.elasticmodel
end

function materialObject::getV0
return, self.V0
end

function materialObject::getK0
return, self.K0
end

function materialObject::getDK0DP
return, self.dK0dP
end

function materialObject::getDK0DT
return, self.dK0dT
end

function materialObject::getAlphaA
return, self.alphaA
end

function materialObject::getAlphaB
return, self.alphaB
end

function materialObject::getAlphaC
return, self.alphaC
end

function materialObject::getIG, i
return, self.iG[i]
end

function materialObject::getCij, i, j, k
return, self.Cij[i,j,k]
end

function materialObject::infoTxt
str = "Information about this material:\n"
str += "\tName: " + self.name + "\n"
str += "\tSymmetry: " + self.symmetry + "\n"
str += "\tEquation of state parameters: Vo=" +  STRTRIM(STRING(self.V0,/PRINT),2) +  " Ko=" +  STRTRIM(STRING(self.K0,/PRINT),2) +   " K'o=" +  STRTRIM(STRING(self.dK0dP,/PRINT),2) + "\n"
str += "\tThermal EOS parameters: dKo/dT = " + STRTRIM(STRING(self.dK0dT,/PRINT),2) + " ; alpha = " + STRTRIM(STRING(self.alphaA,/PRINT),2) + " + " + STRTRIM(STRING(self.alphaB,/PRINT),2) + " *T + "+ STRTRIM(STRING(self.alphaC,/PRINT),2) + " /(T*T)\n"   
if (self.elasticmodel eq 0) then begin
	str += "\tElastic model: isotropic\n"
	str += "\tG = " + STRTRIM(STRING(self.iG[0],/PRINT),2) + " + " + STRTRIM(STRING(self.iG[1],/PRINT),2) + "*P + " + STRTRIM(STRING(self.iG[2],/PRINT),2) + "*P*P + " + STRTRIM(STRING(self.iG[3],/PRINT),2) + "*T + " + STRTRIM(STRING(self.iG[4],/PRINT),2) + "*T*T\n"
endif else begin
	str += "\tElastic model: anisotropic\n"
	if (self.symmetry eq 'hexa') then begin
		nij = 5
		ijlist = intarr(nij,2)
		ijlist[0,*] = [1,1]
		ijlist[1,*] = [3,3]
		ijlist[2,*] = [4,4]
		ijlist[3,*] = [1,2]
		ijlist[4,*] = [1,3]
	endif else if (self.symmetry eq 'cubic') then begin
		nij = 3
		ijlist = intarr(nij,2)
		ijlist[0,*] = [1,1]
		ijlist[1,*] = [1,2]
		ijlist[2,*] = [4,4]
	endif else if (self.symmetry eq 'trig') then begin
		nij = 7
		ijlist = intarr(nij,2)
		ijlist[0,*] = [1,1]
		ijlist[1,*] = [3,3]
		ijlist[2,*] = [4,4]
		ijlist[3,*] = [1,2]
		ijlist[4,*] = [1,3]
		ijlist[5,*] = [1,4]
		ijlist[6,*] = [1,5]
	endif else if (self.symmetry eq 'ortho') then begin
		nij = 9
		ijlist = intarr(nij,2)
		ijlist[0,*] = [1,1]
		ijlist[1,*] = [2,2]
		ijlist[2,*] = [3,3]
		ijlist[3,*] = [4,4]
		ijlist[4,*] = [5,5]
		ijlist[5,*] = [6,6]
		ijlist[6,*] = [1,2]
		ijlist[7,*] = [1,3]
		ijlist[8,*] = [2,3]
	endif  else begin
		nij = 0
	endelse
	for cij=0,nij-1 do begin
		i = ijlist[cij,0]
		j = ijlist[cij,1]
		str += "\tC" + STRTRIM(STRING(i,/PRINT),2) + STRTRIM(STRING(j,/PRINT),2) + " = "
		str += STRTRIM(STRING(self.Cij[i,j,0],/PRINT),2) + " + "
		str += STRTRIM(STRING(self.Cij[i,j,1],/PRINT),2) + "*P + "
		str += STRTRIM(STRING(self.Cij[i,j,2],/PRINT),2) + "*P*P + \n\t\t\t"
		str += STRTRIM(STRING(self.Cij[i,j,3],/PRINT),2) + "*(T-300) + "
		str += STRTRIM(STRING(self.Cij[i,j,4],/PRINT),2) + "*(T-300)*(T-300)\n"
	endfor
endelse
return, str
end

function materialObject::labelPCSV
case self.symmetry of
	'cubic': return, "#" + STRING(9B) + "a"  + STRING(9B) + "da" + STRING(9B)+ "V" + STRING(9B) + "dV"  + STRING(9B) + "P" + STRING(9B) + "dP"
	'hexa': return, "#" + STRING(9B) + "a" + STRING(9B) + "da" + STRING(9B) + "c" + STRING(9B) + "dc"  + STRING(9B) + "V" + STRING(9B) + "dV" + STRING(9B) + "T" + STRING(9B) + "P" + STRING(9B) + "dP"
	'ortho': return, "#" + STRING(9B) + "a" + STRING(9B) + "da" + STRING(9B) + "b" + STRING(9B) + "db" + STRING(9B) + "c" + STRING(9B) + "dc" + STRING(9B) + "V" + STRING(9B) + "dV" + STRING(9B) + STRING(9B) + "T" + "P" + STRING(9B) + "dP"
	'trig': return, "#" + STRING(9B) + "a" + STRING(9B) + "da" + STRING(9B) + "c" + STRING(9B) + "dc"  + STRING(9B) + "V" + STRING(9B) + "dV" + STRING(9B) + STRING(9B) + "T" + "P" + STRING(9B) + "dP"
	else: return, 10
endcase
return, 10
end

; ***************************************************  cell parameter stuff ********

; returns an array of string with the name of the unit cell parameters
; e.g. a for cubic, a and c for hexagonal...
function materialObject::getCellParList
case self.symmetry of
	'cubic': return, ['a']
	'hexa': return, ['a', 'c', 'c/a']
	'trig': return, ['a', 'c', 'c/a']
	'ortho': return, ['a', 'b' ,'c']
	else: return, ['']
endcase
return, ['']
end

; returns the name of the unit cell parameters number i
; e.g. i=0, a for cubic, i=0, a and i=1, c for hexagonal...
function materialObject::getCellParName, i
case self.symmetry of
	'cubic': begin
		case i of
			0: return, 'a'
			else: return, ''
		endcase
		end
	'hexa':  begin
		case i of
			0: return, 'a'
			1: return, 'c'
			2: return, 'c/a'
			else: return, ''
		endcase
		end
	'ortho':  begin
		case i of
			0: return, 'a'
			1: return, 'b'
			2: return, 'c'
			else: return, ''
		endcase
		end
	'trig':  begin
		case i of
			0: return, 'a'
			1: return, 'c'
			2: return, 'c/a'
			else: return, ''
		endcase
		end
	else: return, ''
endcase
return, ''
end


; ***************************************************  stresses ******************

function materialObject::twoGReussOrtho, h, k, l, a, b, c, p, T
Cmatrix = fltarr(6,6)
TC = T - 300.
for i=1,6 do begin
	for j=1,6 do begin
		Cmatrix[i-1,j-1] = self.Cij[i,j,0] + p * self.Cij[i,j,1] + self.Cij[i,j,2] * p * p + TC * self.Cij[i,j,3] + TC*TC * self.Cij[i,j,4]
	endfor
endfor
S = INVERT(Cmatrix)
dhkl = 1./(sqrt(h*h/(a*a)+k*k/(b*b)+l*l/(c*c)))
l1 = h*dhkl/a
l2 = k*dhkl/b
l3 = l*dhkl/c
inv =  0.5*(-(S[0,1]+S[0,2]+S[1,2]) + l1*l1 *(S[1,2]-S[0,0])  $
		+ l2*l2 *(S[0,2]-S[1,1]) + l3*l3* (S[0,1]-S[2,2])  $
		+ 3. * (l1*l1*l1*l1*S[0,0] + l2*l2*l2*l2 * S[1,1]  + l3*l3*l3*l3* S[2,2]  $
		+ l1*l1*l2*l2 *(2.*S[0,1]+S[5,5]) + l2*l2*l3*l3 *(2.*S[1,2] + S[3,3]) $
		+ l3*l3*l1*l1 *(2.*S[0,2]+S[4,4]) ) )
; print, '2G' , 1./inv
return, 1./inv
end


function materialObject::errTwoGReussOrtho, h, k, l, a, b, c, p, T, da, db, dc, dp
d1 = (self->twoGReussOrtho(h, k, l, 1.01*a, b, c, p, T) - self->twoGReussOrtho(h, k, l, 0.99*a, b, c, p, T)) $
			/ (0.02 * a)
d2 = (self->twoGReussOrtho(h, k, l, a, 1.01*b, c, p, T) - self->twoGReussOrtho(h, k, l, a, 0.99*b, c, p, T)) $
			/ (0.02 * b)
d3 = (self->twoGReussOrtho(h, k, l, a, b, 1.01*c, p, T) - self->twoGReussOrtho(h, k, l, a, b, 0.99*c, p, T)) $
			/ (0.02 * c)
d4 = (self->twoGReussOrtho(h, k, l, a, b, c, 1.01*p, T) - self->twoGReussOrtho(h, k, l, a, b, c, 0.99*p, T)) $
			/ (0.02 * p)
err = sqrt( (d1*da)^2 + (d2*db)^2 + (d3*dc)^2  + (d4*dp)^2 )
return, err
end


function materialObject::twoGReussTrig, h, k, l, a, c, p, T
Cmatrix = fltarr(6,6)
TC = T - 300.
for i=1,6 do begin
	for j=1,6 do begin
		Cmatrix[i-1,j-1] = self.Cij[i,j,0] + p * self.Cij[i,j,1] + self.Cij[i,j,2] * p * p + TC * self.Cij[i,j,3] + TC*TC * self.Cij[i,j,4]
	endfor
endfor
S = INVERT(Cmatrix)
M = 4.*c*c*(h*h+h*k+k*k)+3.*a*a*l*l
l1 = sqrt(3.)*c*h/M
l2 = c*(h+2.*k)/M
l3 = sqrt(3.)*a*l/M
inv = 0.5 * (2.*S[0,0] - S[0,1] - S[0,2]) $
		+ l3*l3* (-5.*S[0,0] + S[0,1] + 5.*S[0,2] - S[2,2] + 3.*S[3,3]) $
		+ l3*l3*l3*l3* (3.*S[0,0] - 6.*S[0,2] + 3.*S[2,2] - 3.*S[3,3])  $
		+ 3.*l2*l3*(3.*l1*l1-l2*l2)*S[0,3]  $
		+ 3.*l1*l3*(3.*l2*l2-l1*l1)*S[1,4] 
; print, '2G' , 1./inv
return, 1./inv
end

function materialObject::errTwoGReussTrig, h, k, l, a, c, p, T, da, dc, dp
d1 = (self->twoGReussTrig(h, k, l, 1.01*a, c, p, T) - self->twoGReussTrig(h, k, l, 0.99*a, c, p, T)) $
			/ (0.02 * a)
d2 = (self->twoGReussTrig(h, k, l, a, 1.01*c, p, T) - self->twoGReussTrig(h, k, l, a, 0.99*c, p, T)) $
			/ (0.02 * c)
d3 = (self->twoGReussTrig(h, k, l, a, c, 1.01*p, T) - self->twoGReussTrig(h, k, l, a, c, 0.99*p, T)) $
			/ (0.02 * p)
err = sqrt( (d1*da)^2 + (d2*dc)^2 + (d3*dp)^2 )
return, err
end

function materialObject::twoGReussCubic, h, k, l, a, p, T
Cmatrix = fltarr(6,6)
TC = T - 300.
for i=1,6 do begin
	for j=1,6 do begin
		Cmatrix[i-1,j-1] = self.Cij[i,j,0] + p * self.Cij[i,j,1] + self.Cij[i,j,2] * p * p + TC * self.Cij[i,j,3] + TC*TC * self.Cij[i,j,4]
	endfor
endfor
; print, 'hkl a  p', h, k, l, a, p
; print, 'Cij', self.Cij[*,*,0]
; print, 'C', Cmatrix
S = INVERT(Cmatrix)
tmp1 = h*h + k*k + l*l
tmp2 = h*h*k*k + k*k*l*l + l*l*h*h
Gamma = 1.*tmp2/(tmp1*tmp1)
; print, 'Gamma', Gamma
inv = (S[0,0]-S[0,1]) - 3.*(S[0,0]-S[0,1]-0.5*S[3,3])*Gamma
; print, '2G' , 1./inv
return, 1./inv
end


function materialObject::twoGReussHexa, h, k, l, a, c, p, T
Cmatrix = fltarr(6,6)
TC = T - 300.
for i=1,6 do begin
	for j=1,6 do begin
		Cmatrix[i-1,j-1] = self.Cij[i,j,0] + p * self.Cij[i,j,1] + self.Cij[i,j,2] *p*p + TC * self.Cij[i,j,3] + TC*TC * self.Cij[i,j,4]
	endfor
endfor
; print, 'hkl a c p', h, k, l, a, c, p
; print, 'Cij', self.Cij[*,*,0]
; print, 'C', Cmatrix
S = INVERT(Cmatrix)
M = 4.*c*c*(h*h+h*k+k*k)+3.*a*a*l*l
ll = 3.*a*a*l*l/M
inv = 0.5 * (2.*S[0,0] - S[0,1] - S[0,2]) $
		+ ll* (-5.*S[0,0] + S[0,1] + 5.*S[0,2] - S[2,2] + 3.*S[3,3]) $
		+ ll*ll* (3.*S[0,0] - 6.*S[0,2] + 3.*S[2,2] - 3.*S[3,3])
; print, '2G' , 1./inv
return, 1./inv
end

function materialObject::errTwoGReussCubic, h, k, l, a, p, T, da, dp
d1 = (self->twoGReussCubic(h, k, l, 1.01*a, p, T) - self->twoGReussCubic(h, k, l, 0.99*a,p, T)) / (0.02 * a)
d3 = (self->twoGReussCubic(h, k, l, a,1.01*p, T) - self->twoGReussCubic(h, k, l, a, 0.99*p, T)) / (0.02 * p)
err = sqrt( (d1*da)^2 + (d3*dp)^2 )
return, err
end


function materialObject::errTwoGReussHexa, h, k, l, a, c, p, T, da, dc, dp
d1 = (self->twoGReussHexa(h, k, l, 1.01*a, c, p, T) - self->twoGReussHexa(h, k, l, 0.99*a, c, p, T)) $
			/ (0.02 * a)
d2 = (self->twoGReussHexa(h, k, l, a, 1.01*c, p, T) - self->twoGReussHexa(h, k, l, a, 0.99*c, p, T)) $
			/ (0.02 * c)
d3 = (self->twoGReussHexa(h, k, l, a, c, 1.01*p, T) - self->twoGReussHexa(h, k, l, a, c, 0.99*p, T)) $
			/ (0.02 * p)
err = sqrt( (d1*da)^2 + (d2*dc)^2 + (d3*dp)^2 )
return, err
end


; returns an array of string with the name of the unit cell parameters
; e.g. a for cubic, a and c for hexagonal...
function materialObject::getTwoG, h, k, l, cell, T
TC = T - 300.
if ((self.elasticmodel eq 0)) then begin
  p = cell->getPressure()
  twoG = 2.*(self.iG[0] + p*self.iG[1] + p*p*self.iG[2] + TC*self.iG[3] + TC*TC*self.iG[4] )
  return, twoG
endif else begin
  case self.symmetry of
	'cubic': begin
		a = cell->getCellParValue(0)
		p = cell->getPressure()
		return, self->twoGReussCubic(h, k, l, a, p, T)
	end
	'hexa': begin
		a = cell->getCellParValue(0)
		c = cell->getCellParValue(1)
		p = cell->getPressure()
		; print, 'hkl a c p', h, k, l, a, c, p
		return, self->twoGReussHexa(h, k, l, a, c, p, T)
	end
	'trig': begin
		a = cell->getCellParValue(0)
		c = cell->getCellParValue(1)
		p = cell->getPressure()
		; print, 'hkl a c p', h, k, l, a, c, p
		return, self->twoGReussTrig(h, k, l, a, c, p, T)
	end
	'ortho': begin
		a = cell->getCellParValue(0)
		b = cell->getCellParValue(1)
		c = cell->getCellParValue(2)
		p = cell->getPressure()
		; print, 'hkl a c p', h, k, l, a, c, p
		return, self->twoGReussOrtho(h, k, l, a, b, c, p, T)
	end
	else: return, 0.
  endcase
endelse
return, 0.
end

; returns an array of string with the name of the unit cell parameters
; e.g. a for cubic, a and c for hexagonal...
function materialObject::getErrTwoG, h, k, l, cell, T
if ((self.elasticmodel eq 0) or (self.symmetry eq 'ortho')) then return, 0.
case self.symmetry of
	'cubic': begin
		a = cell->getCellParValue(0)
		da = cell->getCellErrParValue(0)
		p = cell->getPressure()
		dp = cell->getErrPressure()
		return, self->errTwoGReussCubic(h, k, l, a, p, T, da, dp)
	end
	'hexa': begin
		a = cell->getCellParValue(0)
		c = cell->getCellParValue(1)
		da = cell->getCellErrParValue(0)
		dc = cell->getCellErrParValue(1)
		p = cell->getPressure()
		dp = cell->getErrPressure()
		return, self->errTwoGReussHexa(h, k, l, a, c, p, T, da, dc, dp)
	end
	'trig': begin
		a = cell->getCellParValue(0)
		c = cell->getCellParValue(1)
		da = cell->getCellErrParValue(0)
		dc = cell->getCellErrParValue(1)
		p = cell->getPressure()
		dp = cell->getErrPressure()
		; print, 'hkl a c p', h, k, l, a, c, p
		return, self->errTwoGReussTrig(h, k, l, a, c, p, T, da, dc, dp)
	end
	'ortho': begin
		a = cell->getCellParValue(0)
		b = cell->getCellParValue(1)
		c = cell->getCellParValue(2)
		da = cell->getCellErrParValue(0)
		db = cell->getCellErrParValue(1)
		dc = cell->getCellErrParValue(2)
		p = cell->getPressure()
		dp = cell->getErrPressure()
		return, self->errTwoGReussOrth(h, k, l, a, b, c, p, T, da, db, dc, dp)
	end
	else: return, 0.
endcase
return, 0.
end

; *************************************************** ASCII Import and Export ****************

function materialObject::saveToAscii, lun
printf, lun, '# Material properties'
printf, lun, '# Version'
printf, lun, 2
printf, lun, '# Name'
printf, lun, self.name
printf, lun, '# Symmetry'
printf, lun, self.symmetry
printf, lun, "# EOS stuff (v0, k0, dk0/P, dK0/dT)"
printf, lun, STRING(self.V0, /PRINT) + STRING(self.K0, /PRINT) + STRING(self.dK0dP, /PRINT) + STRING(self.dK0dT, /PRINT) 
printf, lun, '# Thermal expansion coefficients (a, b, c)'
printf, lun, STRING(self.alphaA, /PRINT) + STRING(self.alphaB, /PRINT) + STRING(self.alphaC, /PRINT)
printf, lun, '# Elastic model'
printf, lun, STRING(self.elasticmodel, /PRINT)
printf, lun, '# Parameters for isotropic elastic model (g0, g1, g2, g3, g4)'
printf, lun, '#   G = G0 + G1*P + G2*P*P + G3*(T-300) + G4*(T-300)*(T-300)'
printf, lun, STRING(self.iG[0], /PRINT) + STRING(self.iG[1], /PRINT) +  STRING(self.iG[2], /PRINT) + STRING(self.iG[3], /PRINT) + STRING(self.iG[4], /PRINT)
printf, lun, '# Parameters for anisotropic elastic model (Cij)'
for i=1,6 do begin
	line = ''
	for j=1,6 do begin
		line = line + STRING(self.Cij[i,j,0], /PRINT)
	endfor
	printf, lun, line
endfor
printf, lun, '# Parameters for anisotropic elastic model (dCij/dp)'
for i=1,6 do begin
	line = ''
	for j=1,6 do begin
		line = line + STRING(self.Cij[i,j,1], /PRINT)
	endfor
	printf, lun, line
endfor
printf, lun, '# Parameters for anisotropic elastic model (d2Cij/dp2)'
for i=1,6 do begin
	line = ''
	for j=1,6 do begin
		line = line + STRING(self.Cij[i,j,2], /PRINT)
	endfor
	printf, lun, line
endfor
printf, lun, '# Parameters for anisotropic elastic model (dCij/dT)'
for i=1,6 do begin
	line = ''
	for j=1,6 do begin
		line = line + STRING(self.Cij[i,j,3], /PRINT)
	endfor
	printf, lun, line
endfor
printf, lun, '# Parameters for anisotropic elastic model (d2Cij/dT2)'
for i=1,6 do begin
	line = ''
	for j=1,6 do begin
		line = line + STRING(self.Cij[i,j,4], /PRINT)
	endfor
	printf, lun, line
endfor
RETURN, 1
end


function materialObject::readFromAsciiV1, lun, name
on_ioerror, bad
; name
self.name = name
; symmetry
self.symmetry = STRTRIM(readascii(lun,com='#'),2)
; EOS stuff
row = strsplit(readascii(lun, com='#'), /extract)
self.V0 = float(row[0])
self.K0 = float(row[1])
self.dK0dP = float(row[2])
; elastic model
self.elasticmodel = fix(readascii(lun, com='#'))
; parameters for isotropic elastic model
row = strsplit(readascii(lun, com='#'), /extract)
for i=0,2 do self.iK[i] = row[i]
row = strsplit(readascii(lun, com='#'), /extract)
for i=0,2 do self.iG[i] = row[i]
; parameters for anisotropic elastic model
for k = 0, 2 do begin
	for i = 1,6 do begin
		row = strsplit(readascii(lun, com='#'), /extract)
		for j=1,6 do begin
			self.Cij[i,j,k] = row[j-1]
		endfor
	endfor
endfor
RETURN, 1
bad: return, !ERR_STRING
end

function materialObject::readFromAsciiV2, lun
on_ioerror, bad
; name
self.name = STRTRIM(readascii(lun,com='#'),2)
; symmetry
self.symmetry = STRTRIM(readascii(lun,com='#'),2)
; EOS stuff
row = strsplit(readascii(lun, com='#'), /extract)
self.V0 = float(row[0])
self.K0 = float(row[1])
self.dK0dP = float(row[2])
self.dK0dT = float(row[3])
; Thermal expansion stuff
row = strsplit(readascii(lun, com='#'), /extract)
self.alphaA = float(row[0])
self.alphaB = float(row[1])
self.alphaC = float(row[2])
; elastic model
self.elasticmodel = fix(readascii(lun, com='#'))
; parameters for isotropic elastic model
row = strsplit(readascii(lun, com='#'), /extract)
for i=0,4 do self.iG[i] = row[i]
; parameters for anisotropic elastic model
for k = 0, 4 do begin
	for i = 1,6 do begin
		;print, 'k = ', k,'; i = ', i
		row = strsplit(readascii(lun, com='#'), /extract)
		;print, row
		for j=1,6 do begin
			self.Cij[i,j,k] = row[j-1]
		endfor
	endfor
endfor
RETURN, 1
bad: return, !ERR_STRING
end

function materialObject::readFromAscii, lun
on_ioerror, bad
; Resetting variables
self.name = 'Not set'
self.symmetry = ''
self.V0 = 0.0
self.K0 = 0.0
self.dK0dP = 0.0
self.dK0dT = 0.0
self.alphaA = 0.0
self.alphaB = 0.0
self.alphaC = 0.0
self.elasticmodel = 0
self.iG[*] = 0.
self.Cij[*,*,*] = 0.0
; test on version
test = STRTRIM(readascii(lun,com='#'),2)
; print, "test is ", test
; print, "type of test is ", size(test,/type)
switch test OF
	'2': return, self->readFromAsciiV2(lun)
	else: return, readFromAsciiV1(lun,test) ; If not integer, it is version 1 and first line was the material name
endswitch
RETURN, 1
bad: return, !ERR_STRING
end
