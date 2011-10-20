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

; ***************************************************************************
; pressure and unit cell functions
; Deal with calculations related to
; - pressure
; - unit cell parameters
; as a function of file number
;  **************************************************************************

; ***************************************************************************
; plot pressure function
; Add the /STRAIN parameter to plot vs. strain, will plot vs. step otherwise
; **************************************************************************

pro plotpressure, log, base, STRAIN = st
common experimentwindow, set, experiment
common default, defaultdir
n = experiment->getnumberDatasets()
p = fltarr(n)
p[*] = !VALUES.F_NAN
x = intarr(n)
progressBar = Obj_New("SHOWPROGRESS", message='Calculating pressures, please wait...')
progressBar->Start
for i=0,n-1 do begin
	;print, i, j
	x[i] = i
	cell = experiment->refinePressure(i)
	pp = cell->getPressure()
	if ((abs(pp) eq !VALUES.F_INFINITY) or (fix(pp*1000) eq 0)) then p[i]=!VALUES.F_NAN else p[i]=pp
	OBJ_DESTROY, cell
	percent = 100.*i/n
	progressBar->Update, percent
endfor
xlabel = 'Step number'
ylabel = 'Pressure'
title = 'Pressure vs. step number'
if KEYWORD_SET(st) then begin
  x = experiment->getStrains()
  xlabel = 'Strain'
  title = 'Pressure vs. strain'
endif
progressBar->Destroy
Obj_Destroy, progressBar
plotinteractive1D, base, x, p, title=title, xlabel=xlabel, ylabel=ylabel
end

; ***************************************************************************
; plot volume function
; Add the /STRAIN parameter to plot vs. strain, will plot vs. step otherwise
; **************************************************************************

pro plotvolume, log, base, STRAIN = st
common experimentwindow, set, experiment
common default, defaultdir
n = experiment->getnumberDatasets()
v = fltarr(n)
v[*] = !VALUES.F_NAN
x = intarr(n)
progressBar = Obj_New("SHOWPROGRESS", message='Calculating volumes, please wait...')
progressBar->Start
for i=0,n-1 do begin
	x[i] = i
	cell = experiment->refineVolume(i)
	vv = cell->getVolumeNoError()
	if ((abs(vv) eq !VALUES.F_INFINITY) or (fix(vv*1000) eq 0)) then v[i]=!VALUES.F_NAN else v[i]=vv
	OBJ_DESTROY, cell
	percent = 100.*i/n
	progressBar->Update, percent
endfor
xlabel = 'Step number'
if KEYWORD_SET(st) then begin
  x = experiment->getStrains()
  xlabel = 'Strain'
endif
progressBar->Destroy
Obj_Destroy, progressBar
plotinteractive1D, base, x, v, title = 'Volume vs. step number', xlabel=xlabel, ylabel='Volume'
end


; ***************************************************************************
; refine pressure and unit cell parameters function
; ***************************************************************************

pro startRefinePressure, log
common experimentwindow, set, experiment
n = experiment->getnumberDatasets()
logit, log, "Starting unit cell refinements"
for i=0,n-1 do begin
	logit, log, experiment->getDatasetName(i)
	cell = experiment->refinePressure(i)
	logit, log, cell->summaryPressure()
	OBJ_DESTROY, cell
endfor
logit, log, "Finished..."
end

; ***************************************************************************
; export and unit cell parameters pressure function
; ***************************************************************************

pro exportPressure, log
common experimentwindow, set, experiment
common default, defaultdir
result=dialog_pickfile(title='Save results as', path=defaultdir, DIALOG_PARENT=base, DEFAULT_EXTENSION='.csv', FILTER=['*.csv'], /WRITE, get_path = newdefaultdir)
if (result ne '') then begin
	defaultdir = newdefaultdir
	if (FILE_TEST(result) eq 1) then begin
		tmp = DIALOG_MESSAGE("File exists. Overwrite?", /QUESTION)
		if (tmp eq 'No') then return
	endif
	progressBar = Obj_New("SHOWPROGRESS", message='Calculating, please wait...')
	progressBar->Start
	openw, lun, result, /get_lun
	text = experiment->refineAllPressuresCVS(progressBar)
	printascii, lun, text
	free_lun, lun
	progressBar->Destroy
	Obj_Destroy, progressBar
endif
end

; ***************************************************************************
; main interface
; ***************************************************************************

pro fitPressureWindow_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
CASE ev.id OF
	stash.input:
	else: begin
		CASE uval OF
		'REFINE': startRefinePressure, stash.log
		'EXPORT': exportPressure, stash.log
		'PLOT-STEP': BEGIN
			WIDGET_CONTROL, stash.plotwhat, GET_VALUE=selected
			if (selected eq 1) then  plotVolume, stash.log, stash.base else plotPressure, stash.log, stash.base
		END
    'PLOT-STRAIN': BEGIN
      WIDGET_CONTROL, stash.plotwhat, GET_VALUE=selected
      if (selected eq 1) then  plotVolume, stash.log, stash.base, /STRAIN else plotPressure, stash.log, stash.base, /STRAIN
    END
		'DONE': WIDGET_CONTROL, stash.input, /DESTROY
		else:
		ENDCASE
	endcase
endcase
end

pro fitPressureWindow, base
common experimentwindow, set, experiment
common fonts, titlefont, boldfont, mainfont
; check if experiment material properties are set
if (set eq 0) then begin
	result = DIALOG_MESSAGE( "Error: you have to input some data first!", /CENTER , DIALOG_PARENT=base, /ERROR) 
	return
endif
if (experiment->materialset() eq 0) then begin
	result = DIALOG_MESSAGE( "Error: you have to set some material properties first!", /CENTER , DIALOG_PARENT=base, /ERROR) 
	return
endif
; base GUI
input = WIDGET_BASE(Title='Pressure refinements', /COLUMN, GROUP_LEADER=base)
inputLa = WIDGET_LABEL(input, VALUE='Pressure refinements', /ALIGN_CENTER, font=titlefont)
fit = WIDGET_BASE(input, /ROW, FRAME=1)
; buttons1
buttons1 = WIDGET_BASE(fit,/COLUMN, /ALIGN_TOP, FRAME=0)
refine = WIDGET_BUTTON(buttons1, VALUE='Refine pressures', UVALUE='REFINE')
export = WIDGET_BUTTON(buttons1, VALUE='Export results', UVALUE='EXPORT')
plotPV = WIDGET_BASE(buttons1,/COLUMN, /ALIGN_CENTER, /FRAME, XSIZE = 100)
values = ['Pressure', 'Volume']
plotwhat = CW_BGROUP(plotPV, values, /COLUMN, /EXCLUSIVE, LABEL_TOP='Plots', UVALUE='NOTHING', SET_VALUE=0)
plotit = WIDGET_BUTTON(plotPV, VALUE='Plot vs. step', UVALUE='PLOT-STEP')
plotit = WIDGET_BUTTON(plotPV, VALUE='Plot vs. strain', UVALUE='PLOT-STRAIN')
; log
log = WIDGET_TEXT(fit, XSIZE=75, YSIZE=30, /ALIGN_CENTER, /EDITABLE, /WRAP, /SCROLL)
; buttons2
buttons2 = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
close = WIDGET_BUTTON(buttons2, VALUE='Close window', UVALUE='DONE')
stash = {input: input, log: log, base: base, plotwhat:plotwhat}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'fitPressureWindow', input
end