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


FORWARD_FUNCTION experimentWindow

; ****************************************** about window **************

PRO aboutWindow_event, ev
WIDGET_CONTROL, ev.TOP, /DESTROY
END

pro aboutWindow, base
common fonts, titlefont, boldfont
basedialog = WIDGET_BASE(/COLUMN, /MODAL, GROUP_LEADER=base, Title='About Polydefix')
infobase =  WIDGET_BASE(basedialog,/COLUMN)
la = WIDGET_LABEL(infobase, VALUE='PolydefixED v0.4', /ALIGN_LEFT, font=titlefont)
la = WIDGET_LABEL(infobase, VALUE='', /ALIGN_LEFT)
la = WIDGET_LABEL(infobase, VALUE='Polydefix, Polycrystal Deformation using X-rays', /ALIGN_LEFT)
la = WIDGET_LABEL(infobase, VALUE='Energy dispersive version', /ALIGN_LEFT)
la = WIDGET_LABEL(infobase, VALUE='Build 13, 1 February 2012', /ALIGN_LEFT)
la = WIDGET_LABEL(infobase, VALUE='Copyright S. Merkel, Universite Lille 1, France', /ALIGN_LEFT)
la = WIDGET_LABEL(infobase, VALUE='http://merkel.ZoneO.net/Polydefix/', /ALIGN_LEFT)
la = WIDGET_LABEL(infobase, VALUE='', /ALIGN_LEFT)
buttons = WIDGET_BASE(basedialog,/ROW, /GRID_LAYOUT, /ALIGN_CENTER)
ok = WIDGET_BUTTON(buttons, VALUE='Ok', UVALUE='OK')
WIDGET_CONTROL, basedialog, /REALIZE
XMANAGER, 'aboutWindow', basedialog
end

; ************************************************************ setFitOptions ****************
; Functions to deal with offsets and fit options
;   new in 1.3, 01-2010

pro doChangeOptions, stash
common experimentwindow, set, experiment
widget_control, stash.bgroupOffset, GET_VALUE=fitoffset
WIDGET_CONTROL, stash.inputOffsetSt, GET_VALUE=offsetS
offset = FLOAT(offsetS[0])
experiment->setFitOffset, fitoffset
experiment->setOffset, offset
WIDGET_CONTROL, stash.baseOffset, SET_VALUE=strtrim(string(experiment->getOffset()),2)
if (experiment->getFitOffset() eq 1) then begin
	WIDGET_CONTROL, stash.baseFitOffset, SET_VALUE='Yes'
endif else WIDGET_CONTROL, stash.baseFitOffset, SET_VALUE='No'
logit, stash.log, "Changed fitting options and offset angle...\n"
WIDGET_CONTROL, stash.input, /DESTROY
end

PRO setFitOptions_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
CASE ev.id OF
	stash.inputOffsetSt:
	else: begin
		CASE uval OF
		'OK': doChangeOptions, stash
		'CANCEL': WIDGET_CONTROL, stash.input, /DESTROY
		else:
		ENDCASE
	endcase
endcase
END

pro setFitOptions, base, baseOffset, baseFitOffset, log
common experimentwindow, set, experiment
if (set eq 0) then begin
	tmp = DIALOG_MESSAGE("Error: you need to input some data first", /ERROR)
	return
endif
; Getting the number of peaks (we may get an error)
CATCH, Error_status
IF Error_status NE 0 THEN BEGIN 
	themessage = !ERROR_STATE.MSG 
	tmp = DIALOG_MESSAGE(themessage, /ERROR)
	return
endif
fitoffset = experiment->getFitOffset()
offset = experiment->getOffset()
; Prepare a gui
input = WIDGET_BASE(/COLUMN, Title='Fit options', /MODAL, GROUP_LEADER=base)
inputMacLa = WIDGET_LABEL(input, VALUE='Fit options', /ALIGN_CENTER, font=titlefont)
options = WIDGET_BASE(input, COLUMN=3, /GRID_LAYOUT, FRAME=1)
compLa = WIDGET_LABEL(options, VALUE='Azimuth of compression direction', /ALIGN_LEFT)
fitOffsetLa = WIDGET_LABEL(options, VALUE='Fit offset for compression', /ALIGN_LEFT)
inputOffsetSt = WIDGET_TEXT(options, VALUE=strtrim(string(offset),2), XSIZE=20, /EDITABLE)
values = ['No', 'Yes']
bgroupOffset = CW_BGROUP(options, values, /ROW, /EXCLUSIVE, SET_VALUE=fitoffset, UVALUE='OFFSET')
compLa2 = WIDGET_LABEL(options, VALUE='(in degrees)', /ALIGN_LEFT)
compLa2 = WIDGET_LABEL(options, VALUE='', /ALIGN_LEFT)
; Buttons
buttons = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
ok = WIDGET_BUTTON(buttons, VALUE='Ok', UVALUE='OK')
cancel = WIDGET_BUTTON(buttons, VALUE='Cancel', UVALUE='CANCEL')
; Finishing up
stash = {base: base, input: input, baseOffset: baseOffset, baseFitOffset: baseFitOffset,  log: log, inputOffsetSt:  inputOffsetSt, bgroupOffset: bgroupOffset}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'setFitOptions', input
end


; ************************************************************ setHKLPlanes ****************

PRO doSetHKLPlanes, input, table, peaksSt, log
common experimentwindow, set, experiment
WIDGET_CONTROL, table, GET_VALUE=hklInfo 
experiment->setHKLInfo, hklInfo
WIDGET_CONTROL, input, /DESTROY
WIDGET_CONTROL, peaksSt, SET_VALUE=experiment->infoHKLLine()
logit, log, experiment->infoHKLTxt()
END

PRO setHKLPlanes_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
CASE ev.id OF
	stash.input:
	stash.table:
	else: begin
		CASE uval OF
		'OK': doSetHKLPlanes, stash.input, stash.table, stash.peaksSt, stash.log
		'CANCEL': WIDGET_CONTROL, stash.input, /DESTROY
		else:
		ENDCASE
	endcase
endcase

END

PRO setHKLPlanes, base, peaksSt, log
common experimentwindow, set, experiment
if (set eq 0) then begin
	tmp = DIALOG_MESSAGE("Error: you need to load data first", /ERROR)
	return
endif
; Getting the number of peaks (we may get an error)
CATCH, Error_status
IF Error_status NE 0 THEN BEGIN 
	themessage = !ERROR_STATE.MSG 
	tmp = DIALOG_MESSAGE(themessage, /ERROR)
	return
endif
nhkl = experiment->getNHKL();
hklInfo = experiment->getHKLInfo();
; Prepare a gui to edit peak information
input = WIDGET_BASE(/COLUMN, Title='Peak information', /MODAL, GROUP_LEADER=base)
label = ['Use', 'h', 'k', 'l']   
rows = nhkl  
cols = 4  
rowlabels = strarr(nhkl)
for i=0, nhkl-1 do rowlabels[i] = "Peak " + STRTRIM(STRING(i + 1,/PRINT),2)
backgroundColors = MAKE_ARRAY( 3, cols, 2, /BYTE )  
backgroundColors[*,*,*] = 255   ; white  
table = WIDGET_TABLE(input, VALUE=hklInfo, /EDITABLE, COLUMN_LABELS=label, ROW_LABELS=rowlabels)
; BACKGROUND_COLOR=backgroundColors, )
; Buttons
buttons = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
ok = WIDGET_BUTTON(buttons, VALUE='Ok', UVALUE='OK')
cancel = WIDGET_BUTTON(buttons, VALUE='Cancel', UVALUE='CANCEL')
; Finishing up
stash = {base: base, input: input, table: table, peaksSt: peaksSt, log: log}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'setHKLPLanes', input
end


; ************************************************************ setStepList ****************

PRO doSetStepList, input, table, log
common experimentwindow, set, experiment
WIDGET_CONTROL, table, GET_VALUE=value
; Catching errors with conversion
CATCH, Error_status
IF Error_status NE 0 THEN BEGIN 
	themessage = !ERROR_STATE.MSG 
	tmp = DIALOG_MESSAGE(themessage, /ERROR)
	return
endif
nsteps = experiment->getnumberDatasets();
names = strarr(nsteps);
times = fltarr(nsteps);
temperatures = fltarr(nsteps);
strains = fltarr(nsteps);
for i=0, nsteps-1 do begin
	names[i] = value[0,i]
	times[i] = float(value[1,i])
	temperatures[i] = float(value[2,i])
	strains[i] = float(value[3,i])
endfor
experiment->setDatasetList, names
experiment->setTemperatures, temperatures
experiment->setTimes, times
experiment->setStrains, strains
WIDGET_CONTROL, input, /DESTROY
logit, log, "Changed list of steps, temperatures, and times.\n"
END

PRO setStepList_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
CASE ev.id OF
	stash.input:
	stash.table:
	else: begin
		CASE uval OF
		'OK': doSetStepList, stash.input, stash.table, stash.log
		'CANCEL': WIDGET_CONTROL, stash.input, /DESTROY
		else:
		ENDCASE
	endcase
endcase
END

PRO setStepList, base, log
common experimentwindow, set, experiment
if (set eq 0) then begin
	tmp = DIALOG_MESSAGE("Error: you need to load data first", /ERROR)
	return
endif
; Getting the number of peaks (we may get an error)
CATCH, Error_status
IF Error_status NE 0 THEN BEGIN 
	themessage = !ERROR_STATE.MSG 
	tmp = DIALOG_MESSAGE(themessage, /ERROR)
	return
endif
nsteps = experiment->getnumberDatasets();
names = experiment->getDatasetList();
times = experiment->getTimes();
temperatures = experiment->getTemperatures();
strains = experiment->getStrains();
; Prepare a gui to edit peak information
input = WIDGET_BASE(/COLUMN, Title='Steps information', /MODAL, GROUP_LEADER=base)
label = ['name', 'time', 'temperature', 'strain']   
rows = nsteps
rowlabels = strarr(nsteps)
value = strarr(4,nsteps)
for i=0, nsteps-1 do begin
	value[0,i] = names[i]
	value[1,i] = STRTRIM(STRING(times[i],/PRINT),2)
	value[2,i] = STRTRIM(STRING(temperatures[i],/PRINT),2)
	value[3,i] = STRTRIM(STRING(strains[i],/PRINT),2)
endfor
for i=0, nsteps-1 do rowlabels[i] = "Step " + STRTRIM(STRING(i + 1,/PRINT),2)
table = WIDGET_TABLE(input, VALUE=value, /EDITABLE, COLUMN_LABELS=label, ROW_LABELS=rowlabels, Y_SCROLL_SIZE = 20, COLUMN_WIDTHS=[150,100,100,100] )
; Buttons
buttons = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
ok = WIDGET_BUTTON(buttons, VALUE='Ok', UVALUE='OK')
cancel = WIDGET_BUTTON(buttons, VALUE='Cancel', UVALUE='CANCEL')
; Finishing up
stash = {base: base, input: input, table: table, log: log}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'setStepList', input
end



; ************************************************************ setDetectors ****************

; Changed 10/2011 to allow for a change of reference intensity for each detector
PRO doSetDetectors, input, table, log
common experimentwindow, set, experiment
WIDGET_CONTROL, table, GET_VALUE=value
; Catching errors with conversion
CATCH, Error_status
IF Error_status NE 0 THEN BEGIN 
	themessage = !ERROR_STATE.MSG 
	tmp = DIALOG_MESSAGE(themessage, /ERROR)
	return
endif
ndetectors = experiment->getnumberDetectors();
angles = fltarr(ndetectors);
use = intarr(ndetectors);
intensities = fltarr(ndetectors);
for i=0, ndetectors-1 do begin
	angles[i] = float(value[0,i])
	use[i] = fix(value[1,i])
  intensities[i] = float(value[2,i])
endfor
experiment->setDetectorAngles, angles
experiment->setDetectorIntensities, intensities
experiment->setDetectorUses, use
WIDGET_CONTROL, input, /DESTROY
logit, log, "Changed detectors arrangement.\n"
END

PRO setDetectors_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
CASE ev.id OF
	stash.input:
	stash.table:
	else: begin
		CASE uval OF
		'OK': doSetDetectors, stash.input, stash.table, stash.log
		'CANCEL': WIDGET_CONTROL, stash.input, /DESTROY
		else:
		ENDCASE
	endcase
endcase
END

; Changed 10/2011 to allow for a change of reference intensity for each detector
PRO setDetectors, base, log
common experimentwindow, set, experiment
if (set eq 0) then begin
	tmp = DIALOG_MESSAGE("Error: you need to load data first", /ERROR)
	return
endif
; Getting the number of detectors (we may get an error)
CATCH, Error_status
IF Error_status NE 0 THEN BEGIN 
	themessage = !ERROR_STATE.MSG 
	tmp = DIALOG_MESSAGE(themessage, /ERROR)
	return
endif
ndetectors = experiment->getnumberDetectors();
angles = experiment->getDetectorAngles();
use = experiment->getDetectorUses();
intensities = experiment->getDetectorIntensities();
; Prepare a gui to edit peak information
input = WIDGET_BASE(/COLUMN, Title='Detectors information', /MODAL, GROUP_LEADER=base)
label = ['angle', 'use', 'intensity']   
rows = ndetectors
rowlabels = strarr(ndetectors)
value = strarr(3,ndetectors)
for i=0, ndetectors-1 do begin
	value[0,i] = STRTRIM(STRING(angles[i],/PRINT),2)
	value[1,i] = STRTRIM(STRING(use[i],/PRINT),2)
  value[2,i] = STRTRIM(STRING(intensities[i],/PRINT),2)
endfor
for i=0, ndetectors-1 do rowlabels[i] = "Detector " + STRTRIM(STRING(i + 1,/PRINT),2)
table = WIDGET_TABLE(input, VALUE=value, /EDITABLE, COLUMN_LABELS=label, ROW_LABELS=rowlabels, Y_SCROLL_SIZE = 20, COLUMN_WIDTHS=[150,150] )
; Buttons
buttons = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
ok = WIDGET_BUTTON(buttons, VALUE='Ok', UVALUE='OK')
cancel = WIDGET_BUTTON(buttons, VALUE='Cancel', UVALUE='CANCEL')
; Finishing up
stash = {base: base, input: input, table: table, log: log}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'setDetectors', input
end


; ************************************************************* SaveExpToAscii *************

PRO saveExpToAscii, base, log
common default, defaultdir
common experimentwindow, set, experiment
result=dialog_pickfile(title='Save experiment as', path=defaultdir, DIALOG_PARENT=base, DEFAULT_EXTENSION='.exp', FILTER=['*.exp'], /WRITE)
if (result ne '') then begin
	if (FILE_TEST(result) eq 1) then begin
		tmp = DIALOG_MESSAGE("File exists. Overwrite?", /QUESTION)
		if (tmp eq 'No') then return
	endif
	logit, log, "Saving current experiment in " + result
	FDECOMP, result, disk, dir, name, qual, version
	defaultdir = disk+dir
	setDefaultWorkDir, defaultdir
	openw, lun, result, /get_lun
	a = experiment->saveToAscii(lun)
	free_lun, lun
	if (a ne 1) then begin
		tmp = DIALOG_MESSAGE("Error: " + a, /ERROR)
		logit, log, "\tFailed!\n"
		return
	endif
	logit, log, "\tSuccessful!\n"
endif
END

; ************************************************************* doReadExpFromAscii ********

pro doReadExpFromAscii, base, peaksSt, matSt, offsetSt, fitOffsetSt, log
common experimentwindow, set, experiment
if (set eq 1) then begin
	tmp = DIALOG_MESSAGE("Anything done with the current experiment will be lost. Proceed?", /QUESTION)
	if (tmp eq 'No') then return
endif
test = readExpFromAscii(base,log)
if (test->getTmp() ne 0) then begin
	experiment = test
	WIDGET_CONTROL, peaksSt, SET_VALUE=experiment->infoHKLLine()
	WIDGET_CONTROL, matSt, SET_VALUE=experiment->infoMaterialLine()
	WIDGET_CONTROL, offsetSt, SET_VALUE=strtrim(string(experiment->getOffset()),2)
	if (experiment->getFitOffset() eq 1) then begin
		WIDGET_CONTROL, fitOffsetSt, SET_VALUE='Yes'
	endif else WIDGET_CONTROL, fitOffsetSt, SET_VALUE='No'
	logit, log, experiment->infoTxt()
	set = 1
endif
end


; ************************************************************* EDITMAT ********************

pro editMat, base, log, matSt
common experimentwindow, set, experiment
if (set eq 0) then begin
	tmp = DIALOG_MESSAGE("Error: you need to set the FIT files first", /ERROR)
	return
endif
newmat = materialWindow(experiment->getMaterial(), base)
if (newmat->getTmp() eq 1) then begin
	experiment->setMaterial, newmat
	WIDGET_CONTROL, matSt, SET_VALUE=experiment->infoMaterialLine()
	logit,log, experiment->infoMaterialTxt()
end
end 


; ************************************************************* Main window ****************

PRO experimentWindow_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
CASE ev.id OF
	stash.base:
	stash.log:
	else: begin
		CASE uval OF
		'SAVE': saveExpToAscii, stash.base, stash.log
		'READ': doReadExpFromAscii, stash.base, stash.peaksSt, stash.matSt, stash.offsetSt, stash.fitOffsetSt, stash.log
		'EXIT': reallyquit, stash.base
		'MATERIAL':  editMat, stash.base, stash.log, stash.matSt
		'HKLPLANES': setHKLPlanes, stash.base, stash.peaksSt, stash.log
		'STEPLIST': setStepList, stash.base, stash.log
		'DETECTORS': setDetectors, stash.base, stash.log
		'FITOPTIONS': setFitOptions, stash.base, stash.offsetSt, stash.fitOffsetSt, stash.log
		'TESTLATTICESTRAINS': testLatticeStrainsWindow, stash.base
		'FITOFFSET': fitOffsetWindow, stash.base
		'FITUNITCELL': fitUnitCellWindow, stash.base
		'FITPRESSURE': fitPressureWindow, stash.base
		'FITLATTICESTRAINS': fitLatticeStrainsWindow, stash.base
		'FITSTRESS': fitStressWindow, stash.base
    'DETCALIB': detCalibWindow, stash.base
		'DIFFRINTENSITIES': diffIntensityWindow, stash.base
		'INTVSIMAGE': diffIntensityWindow2, stash.base
		'BEARTEX': beartexWindow, stash.base
		'ABOUT': aboutWindow, stash.base
		'NOTAVAILABLE': tmp = DIALOG_MESSAGE("This function is not implemented yet!", /ERROR)
		'FORBIDDEN': tmp = DIALOG_MESSAGE("You need to registered", /ERROR)
		else:
		ENDCASE
	endcase
endcase
END

PRO experimentWindow
common experimentwindow, set, experiment
common fonts, titlefont, boldfont, mainfont
set = 0
load_defaults
experiment = OBJ_NEW('experimentObject')
; base GUI
base = WIDGET_BASE(Title='Stess and strain analysis',/COLUMN, MBAR=bar, /TLB_SIZE_EVENTS)
; File menu
file_menu = WIDGET_BUTTON(bar, VALUE='File', /MENU)
file_bttn1 = WIDGET_BUTTON(file_menu, VALUE='Open experiment', UVALUE='READ')
file_bttn2 = WIDGET_BUTTON(file_menu, VALUE='Save experiment', UVALUE='SAVE')
file_bttn3 = WIDGET_BUTTON(file_menu, VALUE='Exit', UVALUE='EXIT', /SEPARATOR)
; Experiment menu
exp_menu = WIDGET_BUTTON(bar, VALUE='Experiment', /MENU) 
exp_bttn2 = WIDGET_BUTTON(exp_menu, VALUE='Material properties', UVALUE='MATERIAL')
exp_bttn3 = WIDGET_BUTTON(exp_menu, VALUE='Lattice planes', UVALUE='HKLPLANES')
exp_bttn3 = WIDGET_BUTTON(exp_menu, VALUE='Step list', UVALUE='STEPLIST')
exp_bttn3 = WIDGET_BUTTON(exp_menu, VALUE='Detectors', UVALUE='DETECTORS')
exp_bttn5 = WIDGET_BUTTON(exp_menu, VALUE='Fit options', UVALUE='FITOPTIONS')
; Fit menu
fit_menu = WIDGET_BUTTON(bar, VALUE='Stress and strain', /MENU)
fit_bttn1 = WIDGET_BUTTON(fit_menu, VALUE='Test fit quality', UVALUE='TESTLATTICESTRAINS')
fit_bttn1 = WIDGET_BUTTON(fit_menu, VALUE='Maximum stress direction', UVALUE='FITOFFSET')
fit_bttn1 = WIDGET_BUTTON(fit_menu, VALUE='Unit cells', UVALUE='FITUNITCELL')
fit_bttn2 = WIDGET_BUTTON(fit_menu, VALUE='Pressures', UVALUE='FITPRESSURE')
fit_bttn3 = WIDGET_BUTTON(fit_menu, VALUE='Lattice strains', UVALUE='FITLATTICESTRAINS')
fit_bttn4 = WIDGET_BUTTON(fit_menu, VALUE='Stresses', UVALUE='FITSTRESS')
; Texture menu
texture_menu = WIDGET_BUTTON(bar, VALUE='Texture', /MENU)
texture_bttn1 = WIDGET_BUTTON(texture_menu, VALUE='Calibration of Detectors', UVALUE='DETCALIB')
texture_bttn1 = WIDGET_BUTTON(texture_menu, VALUE='Diffraction intensities', UVALUE='DIFFRINTENSITIES')
texture_bttn2 = WIDGET_BUTTON(texture_menu, VALUE='Intensity vs image', UVALUE='INTVSIMAGE')
texture_bttn2 = WIDGET_BUTTON(texture_menu, VALUE='Input file for Beartex', UVALUE='BEARTEX')
; About menu 
about_menu = WIDGET_BUTTON(bar, VALUE='About...', /MENU, /ALIGN_RIGHT) 
about_bttn1 = WIDGET_BUTTON(about_menu, VALUE='About this program', UVALUE='ABOUT')
; top container
top = WIDGET_BASE(base,/ROW)
summary =  WIDGET_BASE(top,/COLUMN, FRAME=1)
matLa = WIDGET_LABEL(summary, VALUE='Material', /ALIGN_LEFT)
matSt = WIDGET_TEXT(summary,  VALUE='Not set', XSIZE=10)
peaksLa = WIDGET_LABEL(summary, VALUE='Peaks', /ALIGN_LEFT)
peaksSt = WIDGET_TEXT(summary,  VALUE='Not set', XSIZE=10)
compLa = WIDGET_LABEL(summary, VALUE='Compression direction', /ALIGN_LEFT)
offsetSt = WIDGET_TEXT(summary,  VALUE='Not set', XSIZE=10)
fitOffsetLa = WIDGET_LABEL(summary, VALUE='Fit compression direction', /ALIGN_LEFT)
fitOffsetSt = WIDGET_TEXT(summary,  VALUE='Not set', XSIZE=10)
log = WIDGET_TEXT(top, XSIZE=75, YSIZE=40, /ALIGN_CENTER, /EDITABLE, /WRAP, /SCROLL)
stash = {base: base, log:log, matSt: matSt, peaksSt: peaksSt, offsetSt: offsetSt, fitOffsetSt: fitOffsetSt}
WIDGET_CONTROL, base, SET_UVALUE=stash
WIDGET_CONTROL, base, /REALIZE
XMANAGER, 'experimentWindow', base
END
