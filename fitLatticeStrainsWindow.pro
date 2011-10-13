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
; plot Q function
; plots Q(hkl) as a function of image number
; Add the /STRAIN parameter to plot vs. strain, will plot vs. step otherwise
; **************************************************************************

pro plotQ, log, base, selected, STRAIN = st
common experimentwindow, set, experiment
common default, defaultdir

; Use Count to get the number of nonzero elements:
use = WHERE(selected, nUse)
IF (nUse eq 0) THEN return
; Setting up the legend
legend=strarr(nUse)
for i=0, nUse-1 do legend[i] = 'Q('+experiment->getPeakName(use[i], /used)+')'
; preparing arrays
n = experiment->getnumberDatasets()
x = intarr(n)
Q = fltarr(nUse,n)
Q[*,*] = !VALUES.F_NAN
j = 0
progressBar = Obj_New("SHOWPROGRESS", message='Calculating Q(hkl), please wait...')
progressBar->Start
for i=0,n-1 do begin
	x[i] = i
	for k=0, nUse-1 do begin
		; print, 'Working on Q(', experiment->getPeakName(use[k], /used), ') for image ', i
		; print, 'File (',i,') index is ', fileindex[i]
		xx= experiment->latticeStrainQ(i, use[k], /used)
		if ((abs(xx) eq !VALUES.F_INFINITY) or (fix(xx*1000000000) eq 0)) then Q[k,i]=!VALUES.F_NAN else Q[k,i]=xx
	endfor
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
plotinteractive1D, base, x, Q, title = 'Q(hkl) vs. step number', xlabel=xlabel, ylabel='Q(hkl)', legend=legend
end

; ***************************************************************************
; refineQTxt
; verbose refinement of lattice strains parameters Q
; for each diffraction pattern:
;   -> fits d0(hkl) and Q(hkl) for all peaks
;   -> prints the results in the log window
; **************************************************************************

pro refineQTxt, log
common experimentwindow, set, experiment
n = experiment->getnumberDatasets()
logit, log, "Starting lattice strains refinements"
for i=0,n-1 do begin
	logit, log, experiment->summaryQ(i)
endfor
logit, log, "Finished..."
end


pro exportRefineQCSV, log
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
	text = experiment->summaryQCSVAll(progressBar)
	printascii, lun, text
	free_lun, lun
	progressBar->Destroy
	Obj_Destroy, progressBar
endif
end

pro fitLatticeStrainsWindow_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
CASE ev.id OF
	stash.input:
	else: begin
		CASE uval OF
		'REFINE': refineQTxt, stash.log
		'ASCII': exportRefineQCSV, stash.log
		'PLOTQ-STEP': BEGIN
			WIDGET_CONTROL, stash.plotwhatQ, GET_VALUE=selected
			plotQ, stash.log, stash.base, selected
		END
    'PLOTQ-STRAIN': BEGIN
      WIDGET_CONTROL, stash.plotwhatQ, GET_VALUE=selected
      plotQ, stash.log, stash.base, selected, /STRAIN
    END
		'DONE': WIDGET_CONTROL, stash.input, /DESTROY
		else:
		ENDCASE
	endcase
endcase
end


pro fitLatticeStrainsWindow, base
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
input = WIDGET_BASE(Title='Lattice strains refinements', /COLUMN, GROUP_LEADER=base)
inputLa = WIDGET_LABEL(input, VALUE='Lattice strains refinements', /ALIGN_CENTER, FONT=titlefont)
fit = WIDGET_BASE(input, /ROW, FRAME=1)
; buttons1
buttons1 = WIDGET_BASE(fit,/COLUMN, /ALIGN_CENTER)
refine = WIDGET_BUTTON(buttons1, VALUE='Show details', UVALUE='REFINE')
export = WIDGET_BUTTON(buttons1, VALUE='Export to ASCII', UVALUE='ASCII')
plotQ = WIDGET_BASE(buttons1,/COLUMN, /ALIGN_CENTER, /FRAME, XSIZE = 100)
values = experiment->getPeakList(/used)
plotwhatQ = CW_BGROUP(plotQ, values, /COLUMN, /NONEXCLUSIVE, LABEL_TOP='Q(hkl)', UVALUE='NOTHING')
plotit = WIDGET_BUTTON(plotQ, VALUE='Plot vs. step', UVALUE='PLOTQ-STEP')
plotit = WIDGET_BUTTON(plotQ, VALUE='Plot vs. strain', UVALUE='PLOTQ-STRAIN')
; log
log = WIDGET_TEXT(fit, XSIZE=75, YSIZE=30, /ALIGN_CENTER, /EDITABLE, /WRAP, /SCROLL)
; buttons2
buttons2 = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
close = WIDGET_BUTTON(buttons2, VALUE='Close window', UVALUE='DONE')
stash = {base: base, input: input, log: log, plotwhatQ:plotwhatQ}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'fitLatticeStrainsWindow', input
end