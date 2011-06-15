
; ***************************************************************************
; plot T function
; plots t(hkl) as a function of image number
; **************************************************************************

pro plotT, log, base, selected
common experimentwindow, set, experiment
common default, defaultdir

; Use Count to get the number of nonzero elements:
use = WHERE(selected, nUse)
IF (nUse eq 0) THEN return
; Setting up the legend
legend=strarr(nUse)
for i=0, nUse-1 do legend[i] = 't('+experiment->getPeakName(use[i], /used)+')'
; preparing arrays
n = experiment->getnumberDatasets()
x = intarr(n)
t = fltarr(nUse,n)
t[*,*] = !VALUES.F_NAN
progressBar = Obj_New("SHOWPROGRESS", message='Calculating t(hkl), please wait...')
progressBar->Start
for i=0,n-1 do begin
	x[i] = i
	for k=0, nUse-1 do begin
		xx= experiment->refineTHKL(i, use[k], /used)
		if ((abs(xx) eq !VALUES.F_INFINITY) or (fix(xx*1000000000) eq 0)) then t[k,i]=!VALUES.F_NAN else t[k,i]=xx
	endfor
	percent = 100.*i/n
	progressBar->Update, percent
endfor
progressBar->Destroy
Obj_Destroy, progressBar
plotinteractive1D, base, x, t, title = 't(hkl) vs. step number', xlabel='Step number', ylabel='t(hkl)', legend=legend
end

; ***************************************************************************
; refineTTxt
; verbose refinement of lattice strains parameters Q
; for each diffraction pattern:
;   -> fits d0(hkl) and Q(hkl) for all peaks
;   -> Uses the elastic properties to get stresses
;   -> prints the results in the log window
; **************************************************************************

pro refineTTxt, log
common experimentwindow, set, experiment
n = experiment->getnumberDatasets()
logit, log, "Starting lattice strains refinements"
for i=0,n-1 do begin
	logit, log, experiment->summaryTHKL(i)
endfor
logit, log, "Finished..."
end


pro exportRefineTCSV, log
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
	text = experiment->summaryTCSVAll(progressBar)
	printascii, lun, text
	free_lun, lun
	progressBar->Destroy
	Obj_Destroy, progressBar
endif
end

pro fitStressWindow_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
CASE ev.id OF
	stash.input:
	else: begin
		CASE uval OF
		'REFINE': refineTTxt, stash.log
		'ASCII': exportRefineTCSV, stash.log
		'PLOTT': BEGIN
			WIDGET_CONTROL, stash.plotwhatT, GET_VALUE=selected
			plotT, stash.log, stash.base, selected
		END
		'DONE': WIDGET_CONTROL, stash.input, /DESTROY
		else:
		ENDCASE
	endcase
endcase
end


pro fitStressWindow, base
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
input = WIDGET_BASE(Title='Stress refinements', /COLUMN, GROUP_LEADER=base)
inputLa = WIDGET_LABEL(input, VALUE='Stress refinements', /ALIGN_CENTER, FONT=titlefont)
fit = WIDGET_BASE(input, /ROW, FRAME=1)
; buttons1
buttons1 = WIDGET_BASE(fit,/COLUMN, /ALIGN_CENTER)
refine = WIDGET_BUTTON(buttons1, VALUE='Show details', UVALUE='REFINE')
export = WIDGET_BUTTON(buttons1, VALUE='Export to ASCII', UVALUE='ASCII')
plotT = WIDGET_BASE(buttons1,/COLUMN, /ALIGN_CENTER, /FRAME, XSIZE = 100)
values = experiment->getPeakList(/used)
plotwhatT = CW_BGROUP(plotT, values, /COLUMN, /NONEXCLUSIVE, LABEL_TOP='t(hkl)', UVALUE='NOTHING')
plotit = WIDGET_BUTTON(plotT, VALUE='Plot', UVALUE='PLOTT')
; log
log = WIDGET_TEXT(fit, XSIZE=75, YSIZE=30, /ALIGN_CENTER, /EDITABLE, /WRAP, /SCROLL)
; buttons2
buttons2 = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
close = WIDGET_BUTTON(buttons2, VALUE='Close window', UVALUE='DONE')
stash = {base: base, input: input, log: log, plotwhatT:plotwhatT}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'fitStressWindow', input
end