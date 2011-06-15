
; ********************************************** Isotropic elastic properties dialog **********

PRO doChgElPropIso, input, g0St, g1St, g2St, g3St, g4St
common materialwindow, material
WIDGET_CONTROL, g0St, GET_VALUE=g0S
WIDGET_CONTROL, g1St, GET_VALUE=g1S
WIDGET_CONTROL, g2St, GET_VALUE=g2S
WIDGET_CONTROL, g3St, GET_VALUE=g3S
WIDGET_CONTROL, g4St, GET_VALUE=g4S
g0 = float(g0S)
g1 = float(g1S)
g2 = float(g2S)
g3 = float(g3S)
g4 = float(g4S)
material->setIsotropicProp, g0, g1, g2, g3, g4
WIDGET_CONTROL, input, /DESTROY
END

PRO chgElPropIsoWindow_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
CASE ev.id OF
	stash.input:
	else: begin
		CASE uval OF
		'OK': doChgElPropIso, stash.input, stash.g0St, stash.g1St, stash.g2St, stash.g3St, stash.g4St
		'CANCEL': WIDGET_CONTROL, stash.input, /DESTROY
		else:
		ENDCASE
	endcase
endcase
END

PRO chgElPropIsoWindow, base
common materialwindow, material
common fonts, titlefont, boldfont, mainfont
; base GUI
input = WIDGET_BASE(Title='Isotropic elastic properties', /COLUMN, /MODAL, GROUP_LEADER=base)
inputLa = WIDGET_LABEL(input, VALUE='Isotropic elastic properties', /ALIGN_CENTER, font=titlefont)
; Material properties
mat = WIDGET_BASE(input, /COLUMN, FRAME=1)
; Main properties
main = WIDGET_BASE(mat, COLUMN=6, /GRID_LAYOUT, FRAME=0)
dummyLa = WIDGET_LABEL(main, VALUE='', /ALIGN_LEFT)
gLa = WIDGET_LABEL(main, VALUE='G', /ALIGN_LEFT)
dummyLa = WIDGET_LABEL(main, VALUE='G0', /ALIGN_LEFT)
g0St = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getIG(0),/PRINT),2), XSIZE=10, /EDITABLE)
dummyLa = WIDGET_LABEL(main, VALUE='dG0/dP', /ALIGN_LEFT)
g1St = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getIG(1),/PRINT),2), XSIZE=10, /EDITABLE)
dummyLa = WIDGET_LABEL(main, VALUE='d2G0/dP2', /ALIGN_LEFT)
g2St = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getIG(2),/PRINT),2), XSIZE=10,  /EDITABLE)
dummyLa = WIDGET_LABEL(main, VALUE='dG0/dT', /ALIGN_LEFT)
g3St = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getIG(3),/PRINT),2), XSIZE=10,  /EDITABLE)
dummyLa = WIDGET_LABEL(main, VALUE='d2G0/dT2', /ALIGN_LEFT)
g4St = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getIG(4),/PRINT),2), XSIZE=10,  /EDITABLE)
; Buttons
buttons = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
ok = WIDGET_BUTTON(buttons, VALUE='Ok', UVALUE='OK')
cancel = WIDGET_BUTTON(buttons, VALUE='Cancel', UVALUE='CANCEL')
; Finishing up
stash = {input: input, g0St: g0St,  g1St: g1St, g2St: g2St, g3St: g3St, g4St: g4St}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'chgElPropIsoWindow', input
END

; ********************************* Anisotropic elastic properties (cubic) dialog **********

PRO doChgElPropCubicAnis, input, cijArraySt
common materialwindow, material
cij = fltarr(7,7,5)
for i=0, 4 do begin
	WIDGET_CONTROL, cijArraySt[1,1,i], GET_VALUE=c
	cij[1,1,i] = float(c)
	WIDGET_CONTROL, cijArraySt[1,2,i], GET_VALUE=c
	cij[1,2,i] = float(c)
	WIDGET_CONTROL, cijArraySt[4,4,i], GET_VALUE=c
	cij[4,4,i] = float(c)
	; effects of symmetry
	cij[2,2,i] = cij[1,1,i]
	cij[3,3,i] = cij[1,1,i]
	cij[2,3,i] = cij[1,2,i]
	cij[1,3,i] = cij[1,2,i]
	cij[3,1,i] = cij[1,2,i]
	cij[3,2,i] = cij[1,2,i]
	cij[2,1,i] = cij[1,2,i]
	cij[5,5,i] = cij[4,4,i]
	cij[6,6,i] = cij[4,4,i]
endfor
material->setAnisElasticProp, cij
WIDGET_CONTROL, input, /DESTROY
END

PRO chgElPropCubicAnis_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
CASE ev.id OF
	stash.input:
	else: begin
		CASE uval OF
		'OK': doChgElPropCubicAnis, stash.input, stash.cijArray
		'CANCEL': WIDGET_CONTROL, stash.input, /DESTROY
		else:
		ENDCASE
	endcase
endcase
END

PRO chgElPropCubicAnis, base
common materialwindow, material
common fonts, titlefont, boldfont, mainfont
; base GUI
input = WIDGET_BASE(Title='Anisotropic elastic properties', /COLUMN, /MODAL, GROUP_LEADER=base)
inputLa = WIDGET_LABEL(input, VALUE='Anisotropic elastic properties', /ALIGN_CENTER, font=titlefont)
; Material properties
mat = WIDGET_BASE(input, /COLUMN, FRAME=1)
; Main properties
main = WIDGET_BASE(mat, COLUMN=6, /GRID_LAYOUT, FRAME=0)
dummyLa = WIDGET_LABEL(main, VALUE='', /ALIGN_LEFT)
c11La = WIDGET_LABEL(main, VALUE='C11', /ALIGN_LEFT)
c12La = WIDGET_LABEL(main, VALUE='C12', /ALIGN_LEFT)
c44La = WIDGET_LABEL(main, VALUE='C44', /ALIGN_LEFT)

labels = ["Cij", "dCij/dP", "d2Cij/dP2", "dCij/dT", "d2Cij/dT2"]
cijArray = intarr(7,7,5)
for i=0,4 do begin
	dummyLa = WIDGET_LABEL(main, VALUE=labels[i], /ALIGN_LEFT)
	cijArray[1,1,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(1,1,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[1,2,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(1,2,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[4,4,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(4,4,i),/PRINT),2), XSIZE=10, /EDITABLE)
endfor

; Buttons
buttons = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
ok = WIDGET_BUTTON(buttons, VALUE='Ok', UVALUE='OK')
cancel = WIDGET_BUTTON(buttons, VALUE='Cancel', UVALUE='CANCEL')
; Finishing up
stash = {input: input, cijArray: cijArray}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'chgElPropCubicAnis', input
END


; ********************************* Anisotropic elastic properties (hexagonal) dialog **********

PRO doChgElPropHexaAnis, input, cijArraySt
common materialwindow, material
cij = fltarr(7,7,5)
for i=0, 4 do begin
	WIDGET_CONTROL, cijArraySt[1,1,i], GET_VALUE=c
	cij[1,1,i] = float(c)
	WIDGET_CONTROL, cijArraySt[3,3,i], GET_VALUE=c
	cij[3,3,i] = float(c)
	WIDGET_CONTROL, cijArraySt[1,2,i], GET_VALUE=c
	cij[1,2,i] = float(c)
	WIDGET_CONTROL, cijArraySt[1,3,i], GET_VALUE=c
	cij[1,3,i] = float(c)
	WIDGET_CONTROL, cijArraySt[4,4,i], GET_VALUE=c
	cij[4,4,i] = float(c)
	; effects of symmetry
	cij[2,3,i] = cij[1,3,i]
	cij[3,1,i] = cij[1,3,i]
	cij[3,2,i] = cij[2,3,i]
	cij[2,1,i] = cij[1,2,i]
	cij[2,2,i] = cij[1,1,i]
	cij[5,5,i] = cij[4,4,i]
	cij[6,6,i] = 0.5*(cij[1,1,i]-cij[1,2,i])
endfor
material->setAnisElasticProp, cij
WIDGET_CONTROL, input, /DESTROY
END

PRO chgElPropHexaAnis_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
CASE ev.id OF
	stash.input:
	else: begin
		CASE uval OF
		'OK': doChgElPropHexaAnis, stash.input, stash.cijArray
		'CANCEL': WIDGET_CONTROL, stash.input, /DESTROY
		else:
		ENDCASE
	endcase
endcase
END

PRO chgElPropHexaAnis, base
common materialwindow, material
common fonts, titlefont, boldfont, mainfont
; base GUI
input = WIDGET_BASE(Title='Anisotropic elastic properties', /COLUMN, /MODAL, GROUP_LEADER=base)
inputLa = WIDGET_LABEL(input, VALUE='Anisotropic elastic properties', /ALIGN_CENTER, font=titlefont)
; Material properties
mat = WIDGET_BASE(input, /COLUMN, FRAME=1)
; Main properties
main = WIDGET_BASE(mat, COLUMN=6, /GRID_LAYOUT, FRAME=0)
dummyLa = WIDGET_LABEL(main, VALUE='', /ALIGN_LEFT)
c11La = WIDGET_LABEL(main, VALUE='C11', /ALIGN_LEFT)
c33La = WIDGET_LABEL(main, VALUE='C33', /ALIGN_LEFT)
c12La = WIDGET_LABEL(main, VALUE='C12', /ALIGN_LEFT)
c13La = WIDGET_LABEL(main, VALUE='C13', /ALIGN_LEFT)
c44La = WIDGET_LABEL(main, VALUE='C44', /ALIGN_LEFT)

labels = ["Cij", "dCij/dP", "d2Cij/dP2", "dCij/dT", "d2Cij/dT2"]
cijArray = intarr(7,7,5)
for i=0,4 do begin
	dummyLa = WIDGET_LABEL(main, VALUE=labels[i], /ALIGN_LEFT)
	cijArray[1,1,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(1,1,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[3,3,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(3,3,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[1,2,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(1,2,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[1,3,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(1,3,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[4,4,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(4,4,i),/PRINT),2), XSIZE=10, /EDITABLE)
endfor
; Buttons
buttons = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
ok = WIDGET_BUTTON(buttons, VALUE='Ok', UVALUE='OK')
cancel = WIDGET_BUTTON(buttons, VALUE='Cancel', UVALUE='CANCEL')
; Finishing up
stash = {input: input, cijArray:cijArray}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'chgElPropHexaAnis', input
END

; ********************************* Anisotropic elastic properties (trigonal) dialog **********

PRO doChgElPropTrigAnis, input, cijArraySt
common materialwindow, material
cij = fltarr(7,7,5)
for i=0, 4 do begin
	WIDGET_CONTROL, cijArraySt[1,1,i], GET_VALUE=c
	cij[1,1,i] = float(c)
	WIDGET_CONTROL, cijArraySt[3,3,i], GET_VALUE=c
	cij[3,3,i] = float(c)
	WIDGET_CONTROL, cijArraySt[4,4,i], GET_VALUE=c
	cij[4,4,i] = float(c)
	WIDGET_CONTROL, cijArraySt[1,2,i], GET_VALUE=c
	cij[1,2,i] = float(c)
	WIDGET_CONTROL, cijArraySt[1,3,i], GET_VALUE=c
	cij[1,3,i] = float(c)
	WIDGET_CONTROL, cijArraySt[1,4,i], GET_VALUE=c
	cij[1,4,i] = float(c)
	WIDGET_CONTROL, cijArraySt[1,5,i], GET_VALUE=c
	cij[1,5,i] = float(c)
	; effects of symmetry
	cij[2,3,i] = cij[1,3,i]
	cij[3,1,i] = cij[1,3,i]
	cij[3,2,i] = cij[2,3,i]
	cij[2,1,i] = cij[1,2,i]
	cij[2,2,i] = cij[1,1,i]
	cij[5,5,i] = cij[4,4,i]
	cij[6,6,i] = 0.5*(cij[1,1,i]-cij[1,2,i])
	cij[2,4,i] = -cij[1,4,i]
	cij[5,6,i] = cij[1,4,i]
	cij[2,5,i] = -cij[1,5,i]
	cij[4,6,i] = -cij[1,5,i]
	cij[4,1,i] = cij[1,4,i]
	cij[4,2,i] = cij[2,4,i]
	cij[6,5,i] = cij[5,6,i]
	cij[5,1,i] = cij[1,5,i]
	cij[5,2,i] = cij[2,5,i]
	cij[6,4,i] = cij[4,6,i]
endfor
material->setAnisElasticProp, cij
WIDGET_CONTROL, input, /DESTROY
END

PRO chgElPropTrigAnis_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
CASE ev.id OF
	stash.input:
	else: begin
		CASE uval OF
		'OK': doChgElPropTrigAnis, stash.input, stash.cijArray
		'CANCEL': WIDGET_CONTROL, stash.input, /DESTROY
		else:
		ENDCASE
	endcase
endcase
END

PRO chgElPropTrigAnis, base
common materialwindow, material
common fonts, titlefont, boldfont, mainfont
; base GUI
input = WIDGET_BASE(Title='Anisotropic elastic properties', /COLUMN, /MODAL, GROUP_LEADER=base)
inputLa = WIDGET_LABEL(input, VALUE='Anisotropic elastic properties', /ALIGN_CENTER, font=titlefont)
; Material properties
mat = WIDGET_BASE(input, /COLUMN, FRAME=1)
; Main properties
main = WIDGET_BASE(mat, COLUMN=6, /GRID_LAYOUT, FRAME=0)
dummyLa = WIDGET_LABEL(main, VALUE='', /ALIGN_LEFT)
cLa = WIDGET_LABEL(main, VALUE='C11', /ALIGN_LEFT)
cLa = WIDGET_LABEL(main, VALUE='C33', /ALIGN_LEFT)
cLa = WIDGET_LABEL(main, VALUE='C44', /ALIGN_LEFT)
cLa = WIDGET_LABEL(main, VALUE='C12', /ALIGN_LEFT)
cLa = WIDGET_LABEL(main, VALUE='C13', /ALIGN_LEFT)
cLa = WIDGET_LABEL(main, VALUE='C14', /ALIGN_LEFT)
cLa = WIDGET_LABEL(main, VALUE='C15', /ALIGN_LEFT)

labels = ["Cij", "dCij/dP", "d2Cij/dP2", "dCij/dT", "d2Cij/dT2"]
cijArray = intarr(7,7,5)
for i=0,4 do begin
	dummyLa = WIDGET_LABEL(main, VALUE=labels[i], /ALIGN_LEFT)
	cijArray[1,1,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(1,1,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[3,3,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(3,3,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[4,4,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(4,4,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[1,2,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(1,2,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[1,3,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(1,3,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[1,4,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(1,4,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[1,5,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(1,5,i),/PRINT),2), XSIZE=10, /EDITABLE)
endfor
; Buttons
buttons = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
ok = WIDGET_BUTTON(buttons, VALUE='Ok', UVALUE='OK')
cancel = WIDGET_BUTTON(buttons, VALUE='Cancel', UVALUE='CANCEL')
; Finishing up
stash = {input: input, cijArray:cijArray}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'chgElPropTrigAnis', input
END


; ********************************* Anisotropic elastic properties (trigonal) dialog **********

PRO doChgElPropOrthoAnis, input, cijArraySt
common materialwindow, material
cij = fltarr(7,7,5)
for i=0, 4 do begin
	WIDGET_CONTROL, cijArraySt[1,1,i], GET_VALUE=c
	cij[1,1,i] = float(c)
	WIDGET_CONTROL, cijArraySt[2,2,i], GET_VALUE=c
	cij[2,2,i] = float(c)
	WIDGET_CONTROL, cijArraySt[3,3,i], GET_VALUE=c
	cij[3,3,i] = float(c)
	WIDGET_CONTROL, cijArraySt[4,4,i], GET_VALUE=c
	cij[4,4,i] = float(c)
	WIDGET_CONTROL, cijArraySt[5,5,i], GET_VALUE=c
	cij[5,5,i] = float(c)
	WIDGET_CONTROL, cijArraySt[6,6,i], GET_VALUE=c
	cij[6,6,i] = float(c)
	WIDGET_CONTROL, cijArraySt[1,2,i], GET_VALUE=c
	cij[1,2,i] = float(c)
	WIDGET_CONTROL, cijArraySt[1,3,i], GET_VALUE=c
	cij[1,3,i] = float(c)
	WIDGET_CONTROL, cijArraySt[2,3,i], GET_VALUE=c
	cij[2,3,i] = float(c)
	; effects of symmetry
	cij[2,1,i] = cij[1,2,i]
	cij[3,1,i] = cij[1,3,i]
	cij[3,2,i] = cij[2,3,i]
endfor
material->setAnisElasticProp, cij
WIDGET_CONTROL, input, /DESTROY
END

PRO chgElPropOrthoAnis_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
CASE ev.id OF
	stash.input:
	else: begin
		CASE uval OF
		'OK': doChgElPropOrthoAnis, stash.input, stash.cijArray
		'CANCEL': WIDGET_CONTROL, stash.input, /DESTROY
		else:
		ENDCASE
	endcase
endcase
END

PRO chgElPropOrthoAnis, base
common materialwindow, material
common fonts, titlefont, boldfont, mainfont
; base GUI
input = WIDGET_BASE(Title='Anisotropic elastic properties', /COLUMN, /MODAL, GROUP_LEADER=base)
inputLa = WIDGET_LABEL(input, VALUE='Anisotropic elastic properties', /ALIGN_CENTER, font=titlefont)
; Material properties
mat = WIDGET_BASE(input, /COLUMN, FRAME=1)
; Main properties
main = WIDGET_BASE(mat, COLUMN=6, /GRID_LAYOUT, FRAME=0)
dummyLa = WIDGET_LABEL(main, VALUE='', /ALIGN_LEFT)
cLa = WIDGET_LABEL(main, VALUE='C11', /ALIGN_LEFT)
cLa = WIDGET_LABEL(main, VALUE='C22', /ALIGN_LEFT)
cLa = WIDGET_LABEL(main, VALUE='C33', /ALIGN_LEFT)
cLa = WIDGET_LABEL(main, VALUE='C44', /ALIGN_LEFT)
cLa = WIDGET_LABEL(main, VALUE='C55', /ALIGN_LEFT)
cLa = WIDGET_LABEL(main, VALUE='C66', /ALIGN_LEFT)
cLa = WIDGET_LABEL(main, VALUE='C12', /ALIGN_LEFT)
cLa = WIDGET_LABEL(main, VALUE='C13', /ALIGN_LEFT)
cLa = WIDGET_LABEL(main, VALUE='C23', /ALIGN_LEFT)

labels = ["Cij", "dCij/dP", "d2Cij/dP2", "dCij/dT", "d2Cij/dT2"]
cijArray = intarr(7,7,5)
for i=0,4 do begin
	dummyLa = WIDGET_LABEL(main, VALUE=labels[i], /ALIGN_LEFT)
	cijArray[1,1,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(1,1,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[2,2,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(2,2,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[3,3,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(3,3,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[4,4,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(4,4,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[5,5,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(5,5,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[6,6,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(6,6,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[1,2,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(1,2,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[1,3,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(1,3,i),/PRINT),2), XSIZE=10, /EDITABLE)
	cijArray[2,3,i] = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getCij(2,3,i),/PRINT),2), XSIZE=10, /EDITABLE)
endfor
; Buttons
buttons = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
ok = WIDGET_BUTTON(buttons, VALUE='Ok', UVALUE='OK')
cancel = WIDGET_BUTTON(buttons, VALUE='Cancel', UVALUE='CANCEL')
; Finishing up
stash = {input: input, cijArray:cijArray}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'chgElPropOrthoAnis', input
END



; ******************************************************************** Main dialog *************

PRO chgElasticProp, base, elasticSt, symSt
common materialwindow, material
symCode = WIDGET_INFO(symSt, /DROPLIST_SELECT)
elasticModel = WIDGET_INFO(elasticSt, /DROPLIST_SELECT)
sym = material->getSymmetryFromCode(symCode)
if (elasticModel eq 0) then begin
	chgElPropIsoWindow, base
endif else begin
	if (sym eq 'hexa') then chgElPropHexaAnis, base
	if (sym eq 'cubic') then chgElPropCubicAnis, base
	if (sym eq 'trig') then chgElPropTrigAnis, base
	if (sym eq 'ortho') then chgElPropOrthoAnis, base
endelse
END

PRO saveMatProp, input, elasticSt, symSt, nameSt, voSt, koSt, dKodpSt, dKodTSt,alphaASt, alphaBSt, alphaCSt
common materialwindow, material
symCode = WIDGET_INFO(symSt, /DROPLIST_SELECT)
elasticModel = WIDGET_INFO(elasticSt, /DROPLIST_SELECT)
WIDGET_CONTROL, nameSt, GET_VALUE=name
WIDGET_CONTROL, voSt, GET_VALUE=voS
WIDGET_CONTROL, koSt, GET_VALUE=koS
WIDGET_CONTROL, dkodpSt, GET_VALUE=dkodpS
WIDGET_CONTROL, dkodTSt, GET_VALUE=dkodTS
WIDGET_CONTROL, alphaASt, GET_VALUE=alphaAS
WIDGET_CONTROL, alphaBSt, GET_VALUE=alphaBS
WIDGET_CONTROL, alphaCSt, GET_VALUE=alphaCS
vo = float(voS)
ko = float(koS)
dkodp = float(dkodpS)
dkodT = float(dkodTS)
alphaA = float(alphaAS)
alphaB = float(alphaBS)
alphaC = float(alphaCS)
material->setSymmetryFromCode, symCode
material->setElasticModel, elasticModel
material->setName, name
material->setEOSParameters, vo, ko, dkodp, dkodT
material->setThemalExpansion, alphaA, alphaB, alphaC
material->setTmp, 1
WIDGET_CONTROL, input, /DESTROY
END

pro updateElasticChoices, symSt, elasticSt
symCode = WIDGET_INFO(symSt, /DROPLIST_SELECT)
if (symCode gt 10) then begin
  WIDGET_CONTROL, elasticSt, SET_DROPLIST_SELECT=0
  WIDGET_CONTROL, elasticSt, sensitive=0
endif else begin
  WIDGET_CONTROL, elasticSt, sensitive=1
endelse
end

PRO materialWindow_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
CASE ev.id OF
	stash.input:
	stash.symSt: updateElasticChoices, stash.symSt, stash.elasticSt
	stash.elasticSt:
	else: begin
		CASE uval OF
		'ELPROP': chgElasticProp, stash.input, stash.elasticSt, stash.symSt
		'OK': saveMatProp, stash.input, stash.elasticSt, stash.symSt, stash.nameSt, stash.voSt, stash.koSt, stash.dkodpSt, stash.dkodTSt, stash.alphaASt, stash.alphaBSt, stash.alphaCSt
		'CANCEL': WIDGET_CONTROL, stash.input, /DESTROY
		else:
		ENDCASE
	endcase
endcase
END

function materialWindow, theMat, base
common materialwindow, material
common fonts, titlefont, boldfont, mainfont
material = theMat
material->setTmp, 0
; base GUI
input = WIDGET_BASE(Title='Material properties', /COLUMN, /MODAL, GROUP_LEADER=base)
inputLa = WIDGET_LABEL(input, VALUE='Material properties', /ALIGN_CENTER, font=titlefont)
; Material properties
mat = WIDGET_BASE(input, /COLUMN, FRAME=1)
; Main properties
main = WIDGET_BASE(mat, COLUMN=2, /GRID_LAYOUT, FRAME=0)
nameLa = WIDGET_LABEL(main, VALUE='Name', /ALIGN_LEFT)
symLa = WIDGET_LABEL(main, VALUE='Symmetry', /ALIGN_LEFT)
voLa = WIDGET_LABEL(main, VALUE='V0', /ALIGN_LEFT)
koLa = WIDGET_LABEL(main, VALUE='K0', /ALIGN_LEFT)
dkoLa = WIDGET_LABEL(main, VALUE="dK0/dP", /ALIGN_LEFT)
dkoLa = WIDGET_LABEL(main, VALUE="dK0/dT", /ALIGN_LEFT)
dkoLa = WIDGET_LABEL(main, VALUE="alpha_a", /ALIGN_LEFT)
dkoLa = WIDGET_LABEL(main, VALUE="alpha_b", /ALIGN_LEFT)
dkoLa = WIDGET_LABEL(main, VALUE="alpha_c", /ALIGN_LEFT)
nameSt = WIDGET_TEXT(main, VALUE=material->getName(), XSIZE=10, /EDITABLE)
symList = ["cubic","hexagonal","orthorhombic","trigonal"]
symSt = WIDGET_DROPLIST(main, VALUE=symList)
select  = fix(material->getSymmetryCode())
WIDGET_CONTROL, symSt, SET_DROPLIST_SELECT=select
voSt = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getV0(),/PRINT),2), XSIZE=10, /EDITABLE)
koSt = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getK0(),/PRINT),2), XSIZE=10, /EDITABLE)
dkodpSt = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getDK0DP(),/PRINT),2), XSIZE=10, /EDITABLE)
dkodTSt = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getDK0DT(),/PRINT),2), XSIZE=10, /EDITABLE)
alphaASt = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getAlphaA(),/PRINT),2), XSIZE=10, /EDITABLE)
alphaBSt = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getAlphaB(),/PRINT),2), XSIZE=10, /EDITABLE)
alphaCSt = WIDGET_TEXT(main, VALUE=STRTRIM(STRING(material->getAlphaC(),/PRINT),2), XSIZE=10, /EDITABLE)
; Elastic model
elastic = WIDGET_BASE(mat, /ROW, FRAME=0)
elLa = WIDGET_LABEL(elastic, VALUE='Elastic model', /ALIGN_LEFT)
elList = ["isotropic","anisotropic"]
elasticSt = WIDGET_DROPLIST(elastic, VALUE=elList)
; symmetries other than cubic and hexagonal are always isotropic
if (fix(material->getSymmetryCode()) gt 10) then begin
  WIDGET_CONTROL, elasticSt, SET_DROPLIST_SELECT=0
  WIDGET_CONTROL, elasticSt, sensitive=0
endif else begin
  select =  fix(material->getElasticModelCode())
  WIDGET_CONTROL, elasticSt, SET_DROPLIST_SELECT=select
endelse
inputFilesDirChg = WIDGET_BUTTON(elastic, VALUE='Options', UVALUE='ELPROP')
; Buttons
buttons = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
ok = WIDGET_BUTTON(buttons, VALUE='Ok', UVALUE='OK')
cancel = WIDGET_BUTTON(buttons, VALUE='Cancel', UVALUE='CANCEL')
; Finishing up
stash = {input: input, symSt: symSt, voSt: voSt, nameSt: nameSt, koSt: koSt, dkodpSt: dkodpSt, dkodTSt: dkodTSt, alphaASt: alphaASt,  alphaBSt: alphaBSt,  alphaCSt: alphaCSt, elasticSt: elasticSt}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'materialWindow', input
RETURN, material
end