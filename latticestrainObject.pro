PRO latticeStrainObject__DEFINE 
	struct = { latticeSTrainObject, error:0, errormessage: '', set: 0, name: '', nhkl:0, h:PTR_NEW(), k:PTR_NEW(), l:PTR_NEW(), d0: PTR_NEW(), dd0: PTR_NEW(), Q: PTR_NEW(), dQ: PTR_NEW(), offsetcorrection: 0, offset: 0.0, doffset: 0.0}
END

function latticeStrainObject::Init
return, 1
end

pro latticeStrainObject::cleanup
if (self.set eq 1) then begin
PTR_FREE, self.h, self.k, self.l, self.d0, self.dd0, self.Q, self.dQ
endif
end

pro latticeStrainObject::setName, name
self.name=name
end

pro latticeStrainObject::setError, errmessage
self.error=1
self.errormessage=errmessage
end

function latticeStrainObject::getError
return, self.error
end

function latticeStrainObject::getErrorMessage
return, self.errormessage
end

pro latticeStrainObject::setFitResultsNoCorr, peaks, hkl, offset, fitresults
self.nhkl=N_ELEMENTS(peaks)
self.h = PTR_NEW(intarr(self.nhkl))
self.k = PTR_NEW(intarr(self.nhkl))
self.l = PTR_NEW(intarr(self.nhkl))
self.d0 =  PTR_NEW(fltarr(self.nhkl))
self.dd0 =  PTR_NEW(fltarr(self.nhkl))
self.Q =  PTR_NEW(fltarr(self.nhkl))
self.dQ =  PTR_NEW(fltarr(self.nhkl))
self.set = 1
self.offsetcorrection = 0
self.offset = offset
self.doffset = 0.
for i=0, self.nhkl-1 do begin
	(*self.h)[i] = hkl[peaks[i],0]
	(*self.k)[i] = hkl[peaks[i],1]
	(*self.l)[i] = hkl[peaks[i],2]
	(*self.d0)[i] = fitresults.fit[2*i]
	(*self.dd0)[i] = fitresults.perror[2*i]
	(*self.Q)[i] = fitresults.fit[2*i+1]
	(*self.dQ)[i] = fitresults.perror[2*i+1]
	; print, "h = ", (*self.h)[i], " k = ", (*self.k)[i], " l = ", (*self.l)[i], " d0 = ", (*self.d0)[i],  " dd0 = ", (*self.dd0)[i],  " Q = ", (*self.Q)[i],  " dQ = ", (*self.dQ)[i] 
endfor
end


pro latticeStrainObject::setFitResultsOffset, peaks, hkl, fitresults
self.nhkl=N_ELEMENTS(peaks)
self.h = PTR_NEW(intarr(self.nhkl))
self.k = PTR_NEW(intarr(self.nhkl))
self.l = PTR_NEW(intarr(self.nhkl))
self.d0 =  PTR_NEW(fltarr(self.nhkl))
self.dd0 =  PTR_NEW(fltarr(self.nhkl))
self.Q =  PTR_NEW(fltarr(self.nhkl))
self.dQ =  PTR_NEW(fltarr(self.nhkl))
self.set = 1
self.offsetcorrection = 1
self.offset = fitresults.fit[0]*180./!PI
self.doffset = fitresults.perror[0]*180./!PI
; print, "offet = ", self.offset, " +/- ", self.doffset
for i=0, self.nhkl-1 do begin
	(*self.h)[i] = hkl[peaks[i],0]
	(*self.k)[i] = hkl[peaks[i],1]
	(*self.l)[i] = hkl[peaks[i],2]
	(*self.d0)[i] = fitresults.fit[2*i+1]
	(*self.dd0)[i] = fitresults.perror[2*i+1]
	(*self.Q)[i] = fitresults.fit[2*i+2]
	(*self.dQ)[i] = fitresults.perror[2*i+2]
	; print, "h = ", (*self.h)[i], " k = ", (*self.k)[i], " l = ", (*self.l)[i], " d0 = ", (*self.d0)[i],  " dd0 = ", (*self.dd0)[i],  " Q = ", (*self.Q)[i],  " dQ = ", (*self.dQ)[i] 
endfor
end

function latticeStrainObject::getSet
return, self.set
end

function latticeStrainObject::getName
return, self.name
end

function latticeStrainObject::getnhkl
return, self.nhkl
end

function latticeStrainObject::getnuse
return, self.nhkl
end

function latticeStrainObject::getd
return, (*self.d0)
end

function latticeStrainObject::getdd
return, (*self.dd0)
end

function latticeStrainObject::getQ
return, (*self.Q)
end

function latticeStrainObject::getdQ
return, (*self.dQ)
end

function latticeStrainObject::geth
return, (*self.h)
end

function latticeStrainObject::getk
return, (*self.k)
end

function latticeStrainObject::getl
return, (*self.l)
end

function latticeStrainObject::getOffset
return, self.offset
end

function latticeStrainObject::getErrOffset
return, self.doffset
end

; returns the lattice strains as a function of delta, the azimuth
; angle on the image plate
function latticeStrainObject::getDvsPsi, psi, peakindex
offset = self.offset*!PI/180.
cospsi = cos(!PI*psi/180.-offset)
d = (*self.d0)[peakindex]*(1.+(*self.Q)[peakindex]*(1.-3.*cospsi*cospsi))
return, d
end