
; ***************************************************************************
; plot BC function
; plots beam center position as a function of image number
; **************************************************************************

pro plotOffset, log, base
common experimentwindow, set, experiment
common default, defaultdir
; Setting up the legend
legend = ['Maximum stress direction']
; preparing arrays
n = experiment->getnumberDatasets()
x = intarr(n)
BC = fltarr(1,n)
BC[*,*] = !VALUES.F_NAN
j = 0
progressBar = Obj_New("SHOWPROGRESS", message='Calculating maximum stress directions, please wait...')
progressBar->Start
for i=0, n-1 do begin
	index = 0
	x[i] = i
	BC[0,i] = experiment->latticeStrainOffset(i)
	percent = 100.*i/n
	progressBar->Update, percent
endfor
;print, BC
progressBar->Destroy
Obj_Destroy, progressBar
plotinteractive1D, base, x, BC, title = 'Maximum stress direction vs. image number', xlabel='Dataset number', ylabel='Maximum stress direction', legend=legend
end

; ***************************************************************************
; refineQTxt
; verbose refinement of lattice strains parameters Q
; for each diffraction pattern:
;   -> fits d0(hkl) and Q(hkl) for all peaks
;   -> prints the results in the log window
; **************************************************************************

pro refineOffsetTxt, log
common experimentwindow, set, experiment
n = experiment->getnumberDatasets()
logit, log, "Maximum stress direction refinements"
for i=0,n-1 do begin
	logit, log, experiment->summaryOffset(i)
endfor
logit, log, "Finished..."
end


pro exportOffsetCSV, log
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
	text = experiment->summaryOffsetCSVAll(progressBar)
	printascii, lun, text
	free_lun, lun
	progressBar->Destroy
	Obj_Destroy, progressBar
endif
end

pro fitOffsetWindow_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
CASE ev.id OF
	stash.input:
	else: begin
		CASE uval OF
		'REFINE': refineOffsetTxt, stash.log
		'ASCII': exportOffsetCSV, stash.log
		'PLOT': plotOffset, stash.log, stash.base
		'DONE': WIDGET_CONTROL, stash.input, /DESTROY
		else:
		ENDCASE
	endcase
endcase
end


pro fitOffsetWindow, base
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
input = WIDGET_BASE(Title='Maximum stress direction refinements', /COLUMN, GROUP_LEADER=base)
inputLa = WIDGET_LABEL(input, VALUE='Maximum stress direction refinements', /ALIGN_CENTER, FONT=titlefont)
fit = WIDGET_BASE(input, /ROW, FRAME=1)
; buttons1
buttons1 = WIDGET_BASE(fit,/COLUMN, /ALIGN_CENTER)
refine = WIDGET_BUTTON(buttons1, VALUE='Show details', UVALUE='REFINE')
export = WIDGET_BUTTON(buttons1, VALUE='Export to ASCII', UVALUE='ASCII')
plotit = WIDGET_BUTTON(buttons1, VALUE='Plot', UVALUE='PLOT')
; log
log = WIDGET_TEXT(fit, XSIZE=75, YSIZE=30, /ALIGN_CENTER, /EDITABLE, /WRAP, /SCROLL)
; buttons2
buttons2 = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
close = WIDGET_BUTTON(buttons2, VALUE='Close window', UVALUE='DONE')
stash = {base: base, input: input, log: log}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'fitOffsetWindow', input
end