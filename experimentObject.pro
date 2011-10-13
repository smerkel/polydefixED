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

; *************************************************** experimentObject ***********************
;
; Object to hold data for one experiment
; Variables
;   - set: is the object set?
;   - tmp: integer used to transmit information from actions within the object itself
;   - filename: name of data file
;   - ttheta: 2 theta angle for the detector
;   - ndetector: number of detector positions
;   - nhkl: number of diffraction lines fitted 
;   - nsteps: number of steps
;   - stepnames: array of string with names of each step
;   - steptimes: array of floats with times for each step
;	- stepstrains: array of floats with strains for each step
;   - steptemperatures: array of floats with temperature for each step
;   - materialSet: 1 of material properties have been set, 0 otherwise
;   - material: object with material properties
;	- fitoffset: fit direction with maximum stress, if 1, do it, if 0 do not do it
;	- offset: direction with maximum stress (starting value if adjusted), in degrees
;	- fitcenter: fit position of beam center, if 1, do it, if 0 do not do it
;   - usepeak: array of integer, usepeak[i]=1 if peak n. i should be used in analysis
;	- detangles: array of floats (angles for detector positoons)
;	- usedet: array of integer, 1 to use this detector, 0 for not
;   - hkl: array of integer, h, k, and l Miller indices
;   - dm: array of floats, measured d-spacings
;   - Im: array of floats, measured intensities
;   - fitstrainsset: array of integer of length 'last', fitstrainsset[i]=1 if lattice strains
;          have been fitted for file i
;   - fitstrains: array of latticestrainObject of length 'last', fitstrains[i]=1 holds
;          lattice strains fit results for file i
;   - expdata: holds the actual experimetal data so we do not read them from the disk all the time and can perform operations on it...
;   - expdataset: array that tells if expdata[i] is set...


PRO experimentObject__DEFINE 
	struct = { experimentObject, set: 0, tmp: 0, filename:'', nhkl:0, ndetector:0, ttheta:0.0, nsteps:0, materialSet:0, material: PTR_NEW(), fitoffset:0, offset: 0., usepeak: PTR_NEW(), usedet:PTR_NEW(), detangles:PTR_NEW(), hkl:PTR_NEW(), dm:PTR_NEW(), Im: PTR_NEW(), stepnames: PTR_NEW(), steptimes: PTR_NEW(), stepstrains: PTR_NEW(), steptemperatures: PTR_NEW(), fitstrainsset: PTR_NEW(), fitstrains: PTR_NEW()}
END

; ************************************************************** Init ************************

; Init function
; Parameters:
function experimentObject::Init
self.material = PTR_NEW(OBJ_NEW('materialObject'))
return, 1
end

; *************************************************** Reset fits ****************************
; Functions to reset fits if important parameters have been changed (wavelength, fit options, peak list...)
; Can not be used if changing fit files because it is using the number of files
;
pro experimentObject::resetFit
if (self.nsteps gt 0) then begin
	for i=0, self.nsteps-1 do $
		if ((*self.fitstrainsset)[i] eq 1) then OBJ_DESTROY, ((*self.fitstrains)[i])
	(*self.fitstrainsset)[*] = 0
endif
end


; *************************************************** Fitting options ***********************

; setFitOffset
;   - 1 to fit offsets, 0 otherwise
pro experimentObject::setFitOffset, fit
self.fitoffset = fit
self->resetFit
end

; getFitOffset
;   - 1 to fit offsets, 0 otherwise
function experimentObject::getFitOffset
return, self.fitoffset
end

; setOffset
;   - offset value in degrees
pro experimentObject::setOffset, offset
self.offset = offset
self->resetFit
end

; getOffset
;   - offset value in degrees
function experimentObject::getOffset
return, self.offset
end


; ***************************************** Temporary variable functions ***********************

; Temporary variable
; usefull to transmit information from actions within the object itself...
pro experimentObject::setTmp, tmp
self.tmp = tmp
end

function experimentObject::getTmp
return, self.tmp
end

; *************************************************** Material functions ***********************

function  experimentObject::materialset
return, self.materialSet
end

function experimentObject::getMaterial
return, (*self.material)
end

pro experimentObject::setMaterial, newmat
(*self.material) = newmat
self.materialSet = 1
self->resetFit
end

; *************************************************** Detectors operations  ***********************


; returns number of detectors
function experimentObject::getnumberDetectors
return, self.ndetector
end

; returns angle of detectors
function experimentObject::getDetectorAngles
return, (*self.detangles)
end

; returns use of detectors
function experimentObject::getDetectorUses
return, (*self.usedet)
end


; to change angle of detectors
pro experimentObject::setDetectorAngles, angles
(*self.detangles) = angles
self->resetFit
end

; to change use of detectors
pro experimentObject::setDetectorUses, use
(*self.usedet) = use
self->resetFit
end

; *************************************************** Datasets operations  ***********************

; returns number of pictures
function experimentObject::getnumberDatasets
return, self.nsteps
end


; Returns a list of available datasets
function experimentObject::getDatasetList
; if it is set, we return it
return, (*self.stepnames)
end

; Sets a new list of  datasets
pro experimentObject::setDatasetList, list
(*self.stepnames) = list
end


; Returns a list of temperatures for each datasets
function experimentObject::getTemperatures
; if it is set, we return it
return, (*self.steptemperatures)
end

; Returns a list of strains for each datasets
function experimentObject::getStrains
; if it is set, we return it
return, (*self.stepstrains)
end

; Sets a new list of temperatures
pro experimentObject::setTemperatures, list
(*self.steptemperatures) = list
end

; Sets a new list of strains
pro experimentObject::setStrains, list
(*self.stepstrains) = list
end

; Returns a list of time for each datasets
function experimentObject::getTimes
; if it is set, we return it
return, (*self.steptimes)
end


; Sets a new list of times
pro experimentObject::setTimes, list
(*self.steptimes) = list
end


; Returns the index of a file, send the real index (between first and last), and it'll give you its index in the file list and index arrary (non existing files are removed, and it starts from 0)
function experimentObject::getRealFileIndex, i
if (self.filelistset eq 0) then return, -1
return, where((*self.fileindex) eq i)
end


; returns name for file index i
function experimentObject::getDatasetName, i
; if it is set, we return it
return, (*self.stepnames)[i]
end


;**************************************************** Setting azimuth angles files **********************************


; Returns a list of available azimuth
function experimentObject::getAngleList
return, (*self.detangles)
end

; returns name for angle index i
function experimentObject::getAngleName, i
return, (*self.detangles)[i]
end

; *************************************************** Setting and fetching HKL information *****

; There is a issue with peak numbering
; the internal arrays such as
;   - self.hkl[i,0] is h for peak i,  self.hkl[i,1] is k for peak i, 
;             self.hkl[i,2] is l for peak i
;   - self.used
; are numbered simply, with no trick.
;
; However, internal, many function need a peak number that does not count peaks that are not used...
; For instance, if you have
; npeaks = 3
; used[0] = 1, used[1] = 0, used[2] = 1
; h[0] = 1, h[1] = 1, h[2] = 1
; k[0] = 0, k[1] = 1, k[2] = 2
; l[0] = 0, l[1] = 1, l[2] = 2
; some function will want the miller indices of the second used peak, which corresponds to i=2
; and not i=1 (hkl for second used peak here is 122 while it is 111 for the second peak)
; therefore, all functions here have an option /USED
;
; With the above example
; - getK, 1 will return 1
; - getK, 1, /used will return 2


; Get number of HKL peaks
function experimentObject::getNHKL
return, self.nhkl
end

; Get information of peaks
; returns array[4,npeaks] with
;    - array[0,i]: use peak i (0/1)
;    - array[1,i]: h for peak i
;    - array[2,i]: k for peak i
;    - array[3,i]: l for peak i
function experimentObject::getHKLInfo 
hklInfo = intarr(4,self.nhkl)
for i=0, self.nhkl-1 do begin
	hklInfo[0,i] = (*self.usepeak)[i]
	hklInfo[1,i] = (*self.hkl)[i,0]
	hklInfo[2,i] = (*self.hkl)[i,1]
	hklInfo[3,i] = (*self.hkl)[i,2]
endfor
return, hklInfo
end

; Set information for peaks
; send array[4,npeaks] with
;    - array[0,i]: use peak i (0/1)
;    - array[1,i]: h for peak i
;    - array[2,i]: k for peak i
;    - array[3,i]: l for peak i
pro experimentObject::setHKLInfo, hklInfo
for i=0, self.nhkl-1 do begin
	if (hklInfo[0,i] gt 0) then (*self.usepeak)[i] = 1 else (*self.usepeak)[i] = 0
	(*self.hkl)[i,0] = hklInfo[1,i]
	(*self.hkl)[i,1] = hklInfo[2,i]
	(*self.hkl)[i,2] = hklInfo[3,i]
endfor
self->resetFit
end

; usedpeakindex
; peak indexing function, returns the real index of a peak indexed
; as used peak number (see explanations a few lines above)
function experimentObject::usedpeakindex, index
n = 0
for i=0, self.nhkl-1 do begin
	if ((*self.usepeak)[i] eq 1) then begin
		if (n eq index) then return, i
		n+=1
	endif
endfor
return, i
end

; Get peak name for peak i;
; returns a string with 'hkl'
function experimentObject::getPeakName, i, used = used
if ((i gt self.nhkl-1) or (i lt 0)) then return, ''
if KEYWORD_SET(used) then usei=self->usedpeakindex(i) else usei = i
return, strtrim(string((*self.hkl)[usei,0]),2) + strtrim(string((*self.hkl)[usei,1]),2) + strtrim(string((*self.hkl)[usei,2]),2)
end

; Get peaks names
; Returns an array of strings with
;    hklInfo[i] = hkl for peak i
function experimentObject::getPeakList, used = used
if KEYWORD_SET(used) then begin
	n = 0
	for i=0, self.nhkl-1 do if ((*self.usepeak)[i] eq 1) then n+=1
	hklInfo = strarr(n)
	j = 0
	for i=0, self.nhkl-1 do begin
		if ((*self.usepeak)[i] eq 1) then begin
			hklInfo[j] = strtrim(string((*self.hkl)[i,0]),2) + strtrim(string((*self.hkl)[i,1]),2) + strtrim(string((*self.hkl)[i,2]),2)
			j+=1
		endif
	endfor
	return, hklInfo
endif
hklInfo = strarr(self.nhkl)
for i=0, self.nhkl-1 do hklInfo[i] = strtrim(string((*self.hkl)[i,0]),2) + strtrim(string((*self.hkl)[i,1]),2) + strtrim(string((*self.hkl)[i,2]),2)
return, hklInfo
end

; Get h miller index
; returns h for peak i
function experimentObject::getH, i, used = used
if ((i gt self.nhkl-1) or (i lt 0)) then return, 0
if KEYWORD_SET(used) then usei=self->usedpeakindex(i) else usei = i
return, (*self.hkl)[usei,0]
end

; Get k miller index
; returns k for peak i
function experimentObject::getK, i, used = used
if ((i gt self.nhkl-1) or (i lt 0)) then return, 0
if KEYWORD_SET(used) then usei=self->usedpeakindex(i) else usei = i
return, (*self.hkl)[usei,1]
end

; Get l miller index
; returns l for peak i
function experimentObject::getL, i, used = used
if ((i gt self.nhkl-1) or (i lt 0)) then return, 0
if KEYWORD_SET(used) then usei=self->usedpeakindex(i) else usei=i
return, (*self.hkl)[usei,2]
end


; ****************************************** Lattice Strains Refinements *****************************

; returns experimental data for dataset number set
; array data(ndetector,npeaks,3)
; - data(det,peak,0): psi angle
; - data(det,peak,1): d
; - data(det,peak,2): i
function experimentObject::getExperimentalData, set
data = fltarr(self.ndetector,self.nhkl,3)
for i=0, self.nhkl-1 do begin
	data[*,i,0] = (*self.detangles)
	data[*,i,1] = (*self.dm)[set,i,*]
	data[*,i,2] = (*self.Im)[set,i,*]
end
return, data
end

; returns experimental psi angles for dataset number set and peak number peak
; if used is set as key word, we count peaks removing those that should not be used
; return array data(npsi)
function experimentObject::getPsiPeak, set, peak, used = used
if KEYWORD_SET(used) then usei=self->usedpeakindex(peak) else usei=peak
data = fltarr(self.ndetector)
data = (*self.detangles)
return, data
end

; returns experimental d-spacings for dataset number set and peak number peak
; if used is set as key word, we count peaks removing those that should not be used
; return array data(npsi)
function experimentObject::getDPeak, set, peak, used = used
if KEYWORD_SET(used) then usei=self->usedpeakindex(peak) else usei=peak
data = fltarr(self.ndetector)
data = (*self.dm)[set,usei,*]
return, data
end

; returns experimental intensity for dataset number set and peak number peak
; if used is set as key word, we count peaks removing those that should not be used
; return array data(npsi)
function experimentObject::getIPeak, set, peak, used = used
if KEYWORD_SET(used) then usei=self->usedpeakindex(peak) else usei=peak
data = fltarr(self.ndetector)
data = (*self.Im)[set,usei,*]
return, data
end


; returns experimental intensity for  peak number peak at angle number nangle
; if used is set as key word, we count peaks removing those that should not be used
; return array data(npsi)
function experimentObject::getIPeakVsSet, peak, nangle, used = used
if KEYWORD_SET(used) then usei=self->usedpeakindex(peak) else usei=peak
data = fltarr(self.ndetector)
data = (*self.Im)[*,usei,nangle]
return, data
end


; Refine lattice strains equations for file number index with a fixed offset
; should only be called from latticestrain in this object
function experimentObject::fitlatticestrainnocorr, index
common fitinfo, npeaks, npsi, offsetangle, costheta, countnan, nan
	fitobject = OBJ_NEW('latticeStrainObject')
	peaks = where( (*self.usepeak) eq 1)
	; Setting parameters up for the fitting
	offsetangle = !PI*self.offset/180.
	costheta = cos(!PI*self.ttheta/180.)
	npeaks = N_ELEMENTS(peaks)
	npsi = self.ndetector
	psi = fltarr(npeaks*self.ndetector) ; psi angle for each peak, one afer the other
	dm = fltarr(npeaks*self.ndetector)  ; measured d-spacings for each peak, one afer the other
	for i=0,npeaks-1 do begin
		offset = i*self.ndetector
		peak = peaks[i]
		for j=0,self.ndetector-1 do begin
      psi[offset+j] = !PI*(*self.detangles)[j]/180.
		  if ((*self.usedet)[j] eq 1) then $
			   dm[offset+j] = (*self.dm)[index,peak,j] $
			else dm[offset+j] = !VALUES.F_NAN 
		endfor
	endfor
	nan = where(finite(dm,/Nan), countnan)
	if (countnan gt 0) then dm[nan] = 0. ; Setting d-spacings to 0 where there is no data...
	guess = fltarr(2*npeaks)                        ; For each peak, we fit d0 and Q
	for i=0, npeaks-1 do begin
		peak = peaks[i]
		mean = mean((*self.dm)[index,peak,*],/NAN ) ; av(d) for peak i
		if (finite(mean, /nan)) then begin
			msg = "Error peak peak " + strtrim(string(i+1),2) + ": no data"
			fitobject->setError, msg
			return, fitobject
		endif
		guess[2*i] = mean
		guess[2*i+1] = 0.                           ; Q for peak i
	end
	sigma = fltarr(npeaks*self.ndetector)
	sigma[*] = max([0.0005*(dm[*]), 0.00000001])
	; print, psi
	; print, dm
	fit = MPFITFUN('LATTICESTRAINMULTIPLEPEAKSNOCORR', psi, dm, sigma, guess, perror = perror, /quiet)
	fitobject->setFitResultsNoCorr, peaks, (*self.hkl), self.offset, {fit:fit , perror: perror}
	return, fitobject
end

; Refine lattice strains equations for file number index with offset optimization
; should only be called from latticestrain in this object
function experimentObject::fitlatticestrainoffset, index
common fitinfo, npeaks, npsi, offsetangle, costheta, countnan, nan
	fitobject = OBJ_NEW('latticeStrainObject')
	peaks = where( (*self.usepeak) eq 1)
	; Setting parameters up for the fitting
	offsetangle = !PI*self.offset/180.
	costheta = cos(!PI*self.ttheta/180.)
	npeaks = N_ELEMENTS(peaks)
	npsi = self.ndetector
	psi = fltarr(npeaks*self.ndetector) ; psi angle for each peak, one afer the other
	dm = fltarr(npeaks*self.ndetector)  ; measured d-spacings for each peak, one afer the other
	for i=0,npeaks-1 do begin
		offset = i*self.ndetector
		peak = peaks[i]
		for j=0,self.ndetector-1 do begin
			psi[offset+j] = !PI*(*self.detangles)[j]/180.
      if ((*self.usedet)[j] eq 1) then $
         dm[offset+j] = (*self.dm)[index,peak,j] $
      else dm[offset+j] = !VALUES.F_NAN 
		endfor
	endfor
	nan = where(finite(dm,/Nan), countnan)
	if (countnan gt 0) then dm[nan] = 0. ; Setting d-spacings to 0 where there is no data...
	guess = fltarr(2*npeaks+1)                        ; For each peak, we fit d0 and Q + offset
	guess[0] = offsetangle
	for i=0, npeaks-1 do begin
		peak = peaks[i]
		mean = mean((*self.dm)[index,peak,*],/NAN ) ; av(d) for peak i
		if (finite(mean, /nan)) then begin
			msg = "Error peak peak " + strtrim(string(i+1),2) + ": no data"
			fitobject->setError, msg
			return, fitobject
		endif
		guess[2*i+1] = mean
		guess[2*i+2] = 0.                           ; Q for peak i
	end
	; print, "guess = ", guess
	sigma = fltarr(npeaks*self.ndetector)
	sigma[*] = max([0.0005*(dm[*]), 0.00000001])
	fit = MPFITFUN('LATTICESTRAINMULTIPLEPEAKSOFFSET', psi, dm, sigma, guess, perror = perror, /quiet)
	fitobject->setFitResultsOffset, peaks, (*self.hkl), {fit:fit , perror: perror}
	return, fitobject
end

; refine lattice strains equations for file number index
function experimentObject::latticestrain, index
; if it has not been refined yet, we do it...
if ((*self.fitstrainsset)[index] eq 0) then begin
	if (self.fitoffset eq 1) then begin
		(*self.fitstrains)[index] = self->fitlatticestrainoffset(index)
	endif else begin
		(*self.fitstrains)[index] = self->fitlatticestrainnocorr(index)
	endelse
	if (((*self.fitstrains)[index])->getSet()) then (*self.fitstrainsset)[index] = 1
	return, (*(self.fitstrains))[index]
endif
; if it has been done already, we return the previous resuls...
return, (*(self.fitstrains))[index]
end


; returns simulated lattice strains for set set and peak peak
; peak numbering is using the used peak option by default here...
; psi: array with psi values.
function experimentObject::latticeStrainDvsPsi, psi, set, peak, used = used
usei=peak
fit = self->latticeStrain(set)
data = fit->getDvsPsi(psi, usei)
return, data
end


; latticeStrainD0
; returns D0 for peak number peakindex at dataset number index
; index have to be used index (see explanations above) since the 
; latticeStrainObjects are indexed that way
function experimentObject::latticeStrainD0, index, peakindex, used=used
if (self.materialSet eq 0) then return, 0.
fit = self->latticeStrain(index)
; print, peakindex, fit->getD()
if (fit->getSet() eq 1) then d0 = (fit->getD())[peakindex] else d0 = 0.
return, d0
end

; latticeStrainErrD0
; returns D0 for peak number peakindex at dataset number index
; index have to be used index (see explanations above) since the 
; latticeStrainObjects are indexed that way
function experimentObject::latticeStrainErrD0, index, peakindex, used=used
if (self.materialSet eq 0) then return, 0.
fit = self->latticeStrain(index)
; print, peakindex, fit->getD()
if (fit->getSet() eq 1) then d0 = (fit->getdD())[peakindex] else d0 = 0.
return, d0
end

; latticeStrainQ
; returns Q for peak number peakindex at dataset number index
; index have to be used index (see explanations above) since the 
; latticeStrainObjects are indexed that way
function experimentObject::latticeStrainQ, index, peakindex, used=used
if (self.materialSet eq 0) then return, 0.
fit = self->latticeStrain(index)
; print, peakindex, fit->getD()
if (fit->getSet() eq 1) then Q = (fit->getQ())[peakindex] else Q = 0.
return, Q
end

; latticeStrainErrQ
; returns error on Q for peak number peakindex at dataset number index
; index have to be used index (see explanations above) since the 
; latticeStrainObjects are indexed that way
function experimentObject::latticeStrainErrQ, index, peakindex, used=used
if (self.materialSet eq 0) then return, 0.
fit = self->latticeStrain(index)
; print, peakindex, fit->getD()
if (fit->getSet() eq 1) then dQ = (fit->getdQ())[peakindex] else dQ = 0.
return, dQ
end

; latticeStrainOffset
; returns offset fitted (or imposed) for dataset number index
function experimentObject::latticeStrainOffset, index
if (self.materialSet eq 0) then return, [0.]
fit = self->latticeStrain(index)
if (fit->getSet() eq 1) then return, fit->getOffset()
return, [0.]
end

; latticeStrainErrOffset
; returns error on offset fitted (or imposed) for dataset number index
function experimentObject::latticeStrainErrOffset, index
if (self.materialSet eq 0) then return, [0.]
fit = self->latticeStrain(index)
if (fit->getSet() eq 1) then return, fit->getErrOffset()
return, [0.]
end


; refineUnitCell
; parameter:
;   - index: file index
; returns: cell object
; returns a unit cell object with the unit cell parameters fitted to the D0 
; obtained in the lattice strains fits
function experimentObject::refineUnitCell, index
fit = self->latticeStrain(index)
cell = (*self.material)->refineUnitCell(fit)
return, cell
end

; refineUnitCell
; parameter:
;   - index: file index
; returns: cell object
; returns a unit cell object with the unit cell parameters fitted to the D0
; obtained in the lattice strains fits, and pressure refined using the unit cell
; parameters and equation of state
function experimentObject::refinePressure, index
fit = self->latticeStrain(index)
T = (*self.steptemperatures)[index]
cell = (*self.material)->refinePressure(fit,T)
return, cell
end

; refineVolume
; parameter:
;   - index: file index
; returns: cell object
; returns a unit cell object with the unit cell parameters fitted to the D0
; obtained in the lattice strains fits, and volumes calculated using the unit cell
; parameters
function experimentObject::refineVolume, index
fit = self->latticeStrain(index)
cell = (*self.material)->refineVolume(fit)
return, cell
end

function experimentObject::summaryQ, step
if (self.materialSet eq 0) then return, "Not set\n"
cell = self->refinePressure(step)
p = cell->getPressure()
dp = cell->getErrPressure()
txt = cell->getName()
txt += (*self.stepnames)[step]
txt += "\nP = " + fltformatA(p) + " (+/-) "+ fltformatA(dp) + "\n"
OBJ_DESTROY, cell
values = self->getPeakList(/used)
for i=0, n_elements(values)-1 do begin
	txt += '   Q(' + values[i] + ') = ' + fltformatA(self->latticeStrainQ(step, i, /used)) + ' (+/-) ' + fltformatA(self->latticeStrainErrQ(step, i, /used)) + '\n'
endfor
return, txt + '\n'
end

function experimentObject::summaryOffset, step
if (self.materialSet eq 0) then return, "Not set\n"
txt = (*self.stepnames)[step] + '\n'
txt += '    offset = ' + fltformatC(self->latticeStrainOffset(step)) + ' (+/-) ' + fltformatC(self->latticeStrainErrOffset(step)) + '\n'
return, txt + '\n'
end

; *************************************************** stresses ********************


function experimentObject::refineTHKL, index, peakindex, used=used
if ((self.materialSet eq 0)) then return, 0.
fit = self->latticeStrain(index)
T = (*self.steptemperatures)[index]
cell = (*self.material)->refinePressure(fit, T)
if (fit->getSet() ne 1) then return, 0.
hh = self->getH(peakindex, /used)
kk = self->getK(peakindex, /used)
ll = self->getL(peakindex, /used)
Q = (fit->getQ())[peakindex]
TwoG = (*self.material)->getTwoG(hh, kk, ll, cell, T)
stress = 3.*Q*TwoG
; print, hh, kk, ll, Q, TwoG, t
return, stress
OBJ_DESTROY, cell
end


function experimentObject::summaryTHKL, index
if (self.materialSet eq 0) then return, "Not set\n"
fit = self->latticeStrain(index)
T = (*self.steptemperatures)[index]
cell = (*self.material)->refinePressure(fit, T)
txt = cell->getName()
txt += (*self.stepnames)[index]
p = cell->getPressure()
dp = cell->getErrPressure()
txt += "\nP = " + fltformatB(p) + " (+/-) "+ fltformatB(dp)
txt += "\nT = " + fltformatB(T)+ "\n"
peaks = self->getPeakList(/used)
stress = fltarr(n_elements(peaks))
dstress = fltarr(n_elements(peaks))
for peakindex=0, n_elements(peaks)-1 do begin
	if (fit->getSet() eq 1) then Q = (fit->getQ())[peakindex] else Q = 0.
	if (fit->getSet() eq 1) then dQ = (fit->getdQ())[peakindex] else dQ = 0.
	hh = self->getH(peakindex, /used)
	kk = self->getK(peakindex, /used)
	ll = self->getL(peakindex, /used)
	g = (*self.material)->getTwoG(hh, kk, ll, cell,T)
	dg = (*self.material)->getErrTwoG(hh, kk, ll, cell,T)
	stress[peakindex] = 3.*Q*g
	dstress[peakindex] = sqrt( (3.*Q*dg)^2 + (3.*g*dQ)^2)
	;print, "hkl Q, dQ, g, dG, t, dt", hh, kk, ll, Q, dQ, g, dg, t[peakindex], dt[peakindex]
	txt += '   t(' + peaks[peakindex] + ') = ' + fltformatA(stress[peakindex]) + ' (+/-) ' +  fltformatA(dstress[peakindex]) + '\n'
endfor
OBJ_DESTROY, cell
return, txt + '\n'
end


; ***************************************************  cell parameter stuff ********

; returns an array of string with the name of the unit cell parameters
; e.g. a for cubic, a and c for hexagonal...
function experimentObject::getCellParList
return, (*self.material)->getCellParList()
end

; returns the name of the unit cell parameters number i
; e.g. i=0, a for cubic, i=0, a and i=1, c for hexagonal...
function experimentObject::getCellParName, i
return, (*self.material)->getCellParName(i)
end


; refineCellPar
; parameter:
;   - index: file index
;   - selected: index of the unit cell parameter
; returns: the value of the unit cell parameter
; obtained in the lattice strains fits
function experimentObject::refineCellPar, index, selected
fit = self->latticeStrain(index)
cell = (*self.material)->refineUnitCell(fit)
return, cell->getCellParValue(selected)
end

; *************************************************** Text summaries and informations  ********


; function infoHKLLine
; returns
;   - list of hkl planes, on one line
function experimentObject::infoHKLLine
str = ""
for i=0, self.nhkl-1 do begin
	if ((*self.usepeak)[i] eq 1) then str += STRTRIM(STRING((*self.hkl)[i,0],/PRINT),2) + STRTRIM(STRING((*self.hkl)[i,1],/PRINT),2) + STRTRIM(STRING((*self.hkl)[i,2],/PRINT),2) + " " else str += "??? "
endfor
return, str
end

; function infoHKLTxt
; returns
;   - verbose list of hkl planes
function experimentObject::infoHKLTxt
str = 'Lattice planes information:\n'
for i=0, self.nhkl-1 do begin
	str += '\tPeak ' + STRTRIM(STRING(i+1,/PRINT),2) + ': ' 
	if ((*self.usepeak)[i] eq 0) then str += 'not used.\n' else str += STRTRIM(STRING((*self.hkl)[i,0],/PRINT),2) + STRTRIM(STRING((*self.hkl)[i,1],/PRINT),2) + STRTRIM(STRING((*self.hkl)[i,2],/PRINT),2) + ' \n'
endfor
return, str
end


; function infoTxt
; returns
;   - information about the experiment, all of it
function experimentObject::infoTxt
str = "Information about this experiment:\n"
str += self->infoHKLTxt()
str += self->infoMaterialTxt()
return, str
end

; function infoMaterialLine
; returns
;   - material name
function experimentObject::infoMaterialLine
if (self.materialSet eq 0) then return, "Not set"
str = (*self.material)->getName()
return, str
end

; function infoMaterialTxt
; returns
;   - all information on the material (name, symmetry, elastic properties...)
function experimentObject::infoMaterialTxt
if (self.materialSet eq 0) then return, "Material poperties not set\n"
str = (*self.material)->infoTxt()
return, str
end

; ***************************************************************** CVS export functions  ********

; refineAllPressuresCVS
; parameter:
;   - progressBar: widget ID of a progress bar object
; returns:
;   - string with CVS results
; Each line includes
;   - file number
;   - unit cell parameters fitted and errors
;   - volumes calculated from unit cell parameters and errors
;   - pressures calculated from unit cell parameters and errors
function experimentObject::refineAllPressuresCVS, progressBar
txt = (*self.material)->labelPCSV() + "\n"
n = self.nsteps
for i=0,n-1 do begin
	fit = self->latticeStrain(i)
	if (fit->getSet() eq 1) then begin
		cell = (*self.material)->refineUnitCell(fit)
		cell = self->refinePressure(i)
		txt += STRING((*self.stepnames)[i]) + STRING(9B) + cell->summaryPCSV() + "\n"
	endif
	percent = 100.*(i)/n
	progressBar->Update, percent
endfor
return, txt
end


function experimentObject::summaryQCSV, step
if (self.materialSet eq 0) then return, "Not set\n"
cell = self->refinePressure(step)
p = cell->getPressure()
dp = cell->getErrPressure()
txt = STRING((*self.stepnames)[step]) + STRING(9B) + fltformatA(p) + STRING(9B) + fltformatA(dp)
OBJ_DESTROY, cell
values = self->getPeakList(/used)
for i=0, n_elements(values)-1 do begin
	txt += STRING(9B) + fltformatA(self->latticeStrainQ(step, i, /used))  + STRING(9B) + fltformatA(self->latticeStrainErrQ(step, i, /used))
endfor
return, txt
end

function experimentObject::summaryQCSVAll, progressbar
if (self.materialSet eq 0) then return, "Not set\n"
values = self->getPeakList(/used)
txt = "#" + STRING(9B) + "P" + STRING(9B) + "dP"
for i=0, n_elements(values)-1 do txt += STRING(9B) + "Q(" + values[i] + ")" + STRING(9B) + "err"
txt += "\n"
n = self.nsteps
for step=0,n-1 do begin
	txt += self->summaryQCSV(step) + '\n'
	percent = 100.*step/n
	progressBar->Update, percent
endfor
return, txt
end


function experimentObject::summaryOffsetCSVAll, progressbar
if (self.materialSet eq 0) then return, "Not set\n"
txt = "#" + STRING(9B) + "Offset" + STRING(9B) + "Err Offset" + '\n'
n = self.nsteps
for step=0,n-1 do begin
	txt += STRING((*self.stepnames)[step]) + STRING(9B) + fltformatC(self->latticeStrainOffset(step)) + STRING(9B) +  fltformatC(self->latticeStrainErrOffset(step)) + '\n'
endfor
return, txt
end

function experimentObject::summaryTCSV, step
if (self.materialSet eq 0) then return, "Not set\n"
cell = self->refinePressure(step)
p = cell->getPressure()
dp = cell->getErrPressure()
temperature = (*self.steptemperatures)[step]
strain = (*self.stepstrains)[step]
txt = STRING((*self.stepnames)[step]) + STRING(9B) + fltformatA(p) + STRING(9B) + fltformatA(dp) + STRING(9B) + fltformatB(temperature) + STRING(9B) + fltformatA(strain) 
values = self->getPeakList(/used)
for i=0, n_elements(values)-1 do begin
	hh = self->getH(i, /used)
	kk = self->getK(i, /used)
	ll = self->getL(i, /used)
	Q = self->latticeStrainQ(step, i, /used)
	dQ = self->latticeStrainErrQ(step, i, /used)
	g = (*self.material)->getTwoG(hh, kk, ll, cell, temperature)
	dg = (*self.material)->getErrTwoG(hh, kk, ll, cell, temperature)
	t = 3.*Q*g
	dt = sqrt( (3.*Q*dg)^2 + (3.*g*dQ)^2)
	txt += STRING(9B) + fltformatA(t)  + STRING(9B) + fltformatA(dt)
endfor
OBJ_DESTROY, cell
return, txt
end

function experimentObject::summaryTCSVAll, progressbar
if (self.materialSet eq 0) then return, "Not set\n"
values = self->getPeakList(/used)
txt = "#" + STRING(9B) + "P" + STRING(9B) + "dP" + STRING(9B) + "T (K)" + STRING(9B) + "Strain"
for i=0, n_elements(values)-1 do txt += STRING(9B) + "t(" + values[i] + ")" + STRING(9B) + "err"
txt += "\n"
n = self.nsteps
for step=0,n-1 do begin
	txt += self->summaryTCSV(step) + '\n'
	percent = 100.*i/n
	progressBar->Update, percent
endfor
return, txt
end

function experimentObject::summaryUnitCellCSV, step
if (self.materialSet eq 0) then return, "Not set\n"
cell = self->refineUnitCell(step)
txt = STRING((*self.stepnames)[step]) + " "
peaks = self->getPeakList(/used)
for i=0, n_elements(peaks)-1 do begin
	hh = self->getH(i, /used)
	kk = self->getK(i, /used)
	ll = self->getL(i, /used)
	txt += STRING(9B) + fltformatA(self->latticeStrainD0(step, i, /used)) + STRING(9B) + fltformatA(self->latticeStrainErrD0(step, i, /used)) + STRING(9B) + fltformatA(cell->getDHKL(hh,kk,ll))
endfor
cellpar = (*self.material)->getCellParList()
for i=0, n_elements(cellpar)-1 do begin
	txt += STRING(9B) + fltformatA(cell->getCellParValue(i)) + STRING(9B) + fltformatA(cell->getCellErrParValue(i))
endfor
OBJ_DESTROY, cell
return, txt
end

function experimentObject::summaryUnitCellCSVAll, progressbar
if (self.materialSet eq 0) then return, "Not set\n"
peaks = self->getPeakList(/used)
txt = "#"
for i=0, n_elements(peaks)-1 do txt += STRING(9B) + "dm0(" + peaks[i] + ")" + STRING(9B) +"err"+ STRING(9B) + " dr0(" + peaks[i] + ")"
cellpar = (*self.material)->getCellParList()
for i=0, n_elements(cellpar)-1 do txt += STRING(9B)  + cellpar[i] + STRING(9B) + "err"
txt += "\n"
n = self.nsteps
for step=0,n-1 do begin
	txt += '' + self->summaryUnitCellCSV(step) + '\n'
	percent = 100.*step/n
	progressBar->Update, percent
endfor
return, txt
end

; ********************************************************** Beartex functions ****************

function experimentObject::beartexCodeList
return, (*self.material)->beartexCodeList()
end

function experimentObject::beartexMaterialHeader, step, symcode
header = "                                                                               #"+ STRING(13B) +  STRING(10B)
header += "Material: " + (*self.material)->getName() + ", symmetry: " + (*self.material)->getSymmetry() + STRING(13B) +  STRING(10B)
header += "Step " + strtrim(string(step), 2) + ": " + (*self.stepnames)[step] + STRING(13B) +  STRING(10B)
header +=   STRING(13B) +  STRING(10B)
header +=   STRING(13B) +  STRING(10B)
cell = self->refineUnitCell(step)
header += cell->getBeartexLine(symcode) + STRING(13B) +  STRING(10B)
return, header
end

function experimentObject::beartexPeakLine, i, used = used
if ((i gt self.nhkl-1) or (i lt 0)) then return, ''
if KEYWORD_SET(used) then usei=self->usedpeakindex(i) else usei = i
h = (*self.hkl)[usei,0]
k = (*self.hkl)[usei,1]
l = (*self.hkl)[usei,2]
return, " " + string(h, k, l,format='(3I3)') + "   .0 90.0  5.0   .0360.0  5.0 1 1" + STRING(13B) +  STRING(10B)
end

; *************************************************** ASCII Import and Export ****************

function experimentObject::saveToAscii, lun
printf, lun, '# Experiment analysis file, to be used with PolydefixED'
printf, lun, '# For more information: http://merkel.zoneo.net/Polydefix/'
printf, lun, '# File version'
printf, lun, '1'
printf, lun, '# 2 theta angle (in degrees)'
printf, lun, STRING(self.ttheta, /PRINT)
printf, lun, '# Number of detector positions'
printf, lun, STRING(self.ndetector, /PRINT)
printf, lun, '# Angles for detector positions, number, use (1/0), angle'
for i=0, self.ndetector-1 do printf, lun, STRING(i+1, /PRINT, STRING((*self.usedet)[i])), STRING((*self.detangles)[i])
printf, lun, '# Number of peaks'
printf, lun, STRING(self.nhkl, /PRINT)
printf, lun, '# Peak information'
printf, lun, '# Number, use (1/0), h, k, l)'
for i=0, self.nhkl-1 do printf, lun, STRING(i+1, /PRINT), STRING((*self.usepeak)[i], /PRINT) + STRING((*self.hkl)[i,0], /PRINT) + STRING((*self.hkl)[i,1], /PRINT) + STRING((*self.hkl)[i,2], /PRINT)
printf, lun, '# Fit offset for maximum stress 1 for yes, 0 for no'
printf, lun, STRING(self.fitoffset, /PRINT)
printf, lun, '# Starting offset value, in degrees'
printf, lun, STRING(self.offset, /PRINT)
printf, lun, '# Material properties set (1/0)'
printf, lun, STRING(self.materialSet, /PRINT)
if (self.materialSet eq 1) then begin
	noerror = (*self.material)->saveToAscii(lun)
	if (noerror ne 1) then return, noerror
endif
printf, lun, '# Number of time steps in the experiment'
printf, lun, STRING(self.nsteps, /PRINT)
printf, lun, '# Information on time step'
printf, lun, '# Step number, step name, step time, step temperature (K), strain'
for i=0, self.nsteps-1 do begin
    printf, lun, STRING(i+1, /PRINT) + "   " + (*self.stepnames)[i] + STRING((*self.steptimes)[i], /PRINT) + STRING((*self.steptemperatures)[i], /PRINT)+ STRING((*self.stepstrains)[i], /PRINT)
endfor
printf, lun, '# Experimental data'
printf, lun, '# Peak number, h, k, l, d-spacing, intensity, detector number, step number'
for i=0, self.nsteps-1 do begin
	for j=0,self.nhkl-1 do begin
		for k=0, self.ndetector-1 do begin
			if (not finite((*self.dm)[i,j,k],/Nan)) then printf, lun, STRING(j+1, /PRINT) + STRING((*self.hkl)[j,0], /PRINT) + STRING((*self.hkl)[j,1], /PRINT) + STRING((*self.hkl)[j,2], /PRINT) + STRING((*self.dm)[i,j,k], /PRINT) + STRING((*self.Im)[i,j,k], /PRINT) + STRING(k+1, /PRINT) + STRING(i+1, /PRINT) 
		endfor
	endfor
endfor
RETURN, 1
end



function experimentObject::readFromAsciiV1, lun, log
on_ioerror, bad
logit, log, "\tParsing file version 1"
; 2 theta
logit, log, "\t2 theta"
self.ttheta = float(readascii(lun,  com="#"))
; Number of detector positions and corresponding angles
logit, log, "\tNumber of detectors"
self.ndetector = fix(readascii(lun,  com="#"))
if (self.ndetector lt 1) then return, "Number of detector positions can not be lower than one!"
self.detangles = PTR_NEW(fltarr(self.ndetector))
self.usedet = PTR_NEW(intarr(self.ndetector))
logit, log, "\tDetectors positions"
for i=0, self.ndetector-1 do begin
	row = strsplit(readascii(lun,  com='#'), /extract)
	(*self.detangles)(fix(row[0])-1) = float(row[2])
	(*self.usedet)(fix(row[0])-1) = fix(row[1])
end
; Number of diffraction lines and peak information
logit, log, "\tNumber of diffraction lines"
row = readascii(lun,  com="#")
self.nhkl = fix(row)
if (self.nhkl lt 1) then return, "Number of measured reflections can not be lower than one!"
self.hkl = PTR_NEW(intarr(self.nhkl,3))
self.usepeak = PTR_NEW(intarr(self.nhkl))
logit, log, "\tInformation for each diffraction line"
for i=0, self.nhkl-1 do begin
	row = strsplit(readascii(lun,  com='#'), /extract)
	(*self.usepeak)(i) = fix(row[1])
	(*self.hkl)(i,0) = fix(row[2])
	(*self.hkl)(i,1) = fix(row[3])
	(*self.hkl)(i,2) = fix(row[4])
endfor
; Offset fitting and value
logit, log, "\tOffset information"
row = readascii(lun,  com="#")
self.fitoffset = fix(row)
row = readascii(lun,  com="#")
self.offset = float(row)
; Material properties set?
logit, log, "\tMaterial properties"
row = readascii(lun,  com="#")
self.materialSet = fix(row)
if (self.materialSet eq 1) then begin
	noerror = (*self.material)->readFromAscii(lun)
	if (noerror ne 1) then return, noerror
endif
; Number of deformation steps
logit, log, "\tNumber of deformation steps"
row = readascii(lun,  com="#")
self.nsteps = fix(row)
if (self.nsteps lt 1) then return, "Number of steps can not be lower than one!"
self.stepnames = PTR_NEW(strarr(self.nsteps))
self.steptimes = PTR_NEW(fltarr(self.nsteps))
self.steptemperatures = PTR_NEW(fltarr(self.nsteps))
self.stepstrains = PTR_NEW(fltarr(self.nsteps))
self.dm = PTR_NEW(fltarr(self.nsteps,self.nhkl,self.ndetector))
self.Im = PTR_NEW(fltarr(self.nsteps,self.nhkl,self.ndetector))
(*self.dm)[*,*,*] = !VALUES.F_NAN
(*self.Im)[*,*,*] = !VALUES.F_NAN
logit, log, "\tParsing step information"
for i=0, self.nsteps-1 do begin
	line = readascii(lun,  com="#")
	row = strsplit(line,/extract)
	step = fix(row[0])-1
	if ((step lt 0) or (step ge self.nsteps ))then begin
		logit, log, "\tError with line\n\t\t" + line + "\n\tstep number is larger than expected"
		return, "Error with input data"
	endif
	(*self.stepnames)[step] = row[1]
	(*self.steptimes)[step] = float(row[2])
	(*self.steptemperatures)[step] = float(row[3])
	if (n_elements(row) eq 4) then (*self.stepstrains)[step] = 0. else (*self.stepstrains)[step] = float(row[4])
endfor
; Loop until EOF is found: 
logit, log, "\tParsing data"
while ~ EOF(lun) do begin  
	line = readascii(lun,  com='#')
	if ((strtrim(line,2) ne "") and (line ne 'EOF')) then begin
		row = strsplit(line ,/extract, count=count)
		if (count lt 8) then begin
			logit, log, "\tError with line\n\t\t" + line + "\n\tsome columns are missing"
			return, "Error with input data"
		endif
		peak = fix(row[0])-1
		h = fix(row[1])
		k = fix(row[2])
		l = fix(row[3])
		d = float(row[4])
		i = float(row[5])
		det = fix(row[6]) - 1
		step = fix(row[7]) - 1
		if ((h ne (*self.hkl)(peak,0)) or (k ne (*self.hkl)(peak,1)) or (l ne (*self.hkl)(peak,2))) then begin
			logit, log, "\tError with line\n\t\t" + line + "\n\th, k, l or l do not match for this peak number"
			return, "Error with input data"
		endif
		if ((step lt 0) or (step ge self.nsteps))then begin
			logit, log, "\tError with line\n\t\t" + line + "\n\tstep number is larger than expected"
			return, "Error with input data"
		endif
		if ((det lt 0) or (det ge self.ndetector))then begin
			logit, log, "\tError with line\n\t\t" + line + "\n\tdetector number is larger than expected"
			return, "Error with input data"
		endif
		;print, d, ' ', row[4], ' ', double(row[4])
		;print, row
		(*self.dm)[step,peak,det] = d
		(*self.Im)[step,peak,det] = i
	endif
endwhile
; Setting other arrays up
self.fitstrains = PTR_NEW(OBJARR(self.nsteps))
self.fitstrainsset = PTR_NEW(intarr(self.nsteps));
(*self.fitstrainsset)[*] = 0
RETURN, 1
bad: return, !ERR_STRING
end

function experimentObject::readFromAscii, lun, log
on_ioerror, bad
if (self.set gt 0) then begin
	for i=0, self.last do $
		if ((*self.fitstrainsset)[i] eq 1) then OBJ_DESTROY, ((*self.fitstrains)[i])
	PTR_FREE, self.fitstrains
	PTR_FREE, self.fitstrainsset
	PTR_FREE, self.usepeak
	PTR_FREE, self.hkl
	PTR_FREE, self.dm
	PTR_FREE, self.Im
	PTR_FREE, self.stepnames
	PTR_FREE, self.detangles
	PTR_FREE, self.usedet
endif
self.set = 0
self.ndetector = 0
self.materialSet = 0
self.fitoffset = 0
self.offset = 0.0
; file version
version = fix(readascii(lun, com="#"))
switch version OF
	1: return, self->readFromAsciiV1(lun, log)
	else: return, 'Sorry, we can only read file format 1 at this time'
endswitch
RETURN, 1
bad: return, !ERR_STRING
end
