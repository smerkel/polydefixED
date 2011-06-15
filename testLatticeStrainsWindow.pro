
; ***************************************************************************
; plot plotDspacVsChi function
; prepares a plot with a test of lattice strains fits
; **************************************************************************

pro plotDspacVsChi, base, globalbase, sets, peaks, dynamic, savemovie
common experimentwindow, set, experiment
common default, defaultdir
usePeak = WHERE(peaks, nUsePeak)
nSets = N_ELEMENTS(sets)
if ((sets[0] eq -1) or (nUsePeak eq 0)) then begin
  result = DIALOG_MESSAGE( "Error: no image or no diffraction line selected!", /CENTER , DIALOG_PARENT=base, /ERROR) 
  return
endif
; fitting data with lattice strain equations
progressBar = Obj_New("SHOWPROGRESS", message='Fitting data, please wait...')
progressBar->Start
for i=0, nSets-1 do begin
	tmp = experiment->latticeStrain(sets[i])
	if (tmp->getError()) then begin
		result = DIALOG_MESSAGE(tmp->getErrorMessage() , /CENTER , DIALOG_PARENT=base, /ERROR)
		progressBar->Destroy
		Obj_Destroy, progressBar
		return
	endif
	percent = 100.*i/nSets
	progressBar->Update, percent
endfor
progressBar->Destroy
Obj_Destroy, progressBar
; getting a	name for movie file, if needed
if (dynamic and savemovie) then begin
	if (N_ELEMENTS(defaultdir) eq 0) then defaultdir = experiment->getDirectory()
	filters = [['*.mpg;*.mpeg'], ['MPG']]
	filename = DIALOG_PICKFILE(dialog_parent = base, filter=filters, /write , TITLE='Save movie as...', path=defaultdir, get_path = newdefaultdir);
	if (filename ne '') then defaultdir = newdefaultdir else savemovie=0
endif
; calling actual plotting functions
; function will use the experiment object to get whatever it needs
plotTestLatticeStrains, base, sets, peaks, dynamic, savemovie, filename
end


; *********************************************************************** Interface ****************

pro testLatticeStrainsWindow_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
sets = WIDGET_INFO(stash.listSets, /LIST_SELECT)
WIDGET_CONTROL, stash.plotwhatPeak, GET_VALUE=peaks
if (WIDGET_INFO(stash.savemovie, /BUTTON_SET) eq 1) then savemovie = 1 else savemovie = 0
CASE ev.id OF
	stash.input:
	else: begin
		CASE uval OF
		'PLOT': plotDspacVsChi, stash.input, stash.base, sets, peaks, 0, savemovie
		'DYNAMICPLOT': plotDspacVsChi, stash.input, stash.base, sets, peaks, 1, savemovie
		'DONE': WIDGET_CONTROL, stash.input, /DESTROY
		else:
		ENDCASE
	endcase
endcase
end

pro testLatticeStrainsWindow, base
common experimentwindow, set, experiment
common fonts, titlefont, boldfont, mainfont
; base GUI
input = WIDGET_BASE(Title='Test of lattice strains refinements', /COLUMN, GROUP_LEADER=base)
inputLa = WIDGET_LABEL(input, VALUE='Test of lattice strains refinements', /ALIGN_CENTER, FONT=titlefont)
fit = WIDGET_BASE(input, /ROW, FRAME=0)
; listing datasets
flist = WIDGET_BASE(fit,/COLUMN, /ALIGN_CENTER, FRAME=1,XSIZE=200, YSIZE=400)
filelist = experiment->getDatasetList()
listLa = WIDGET_LABEL(flist, VALUE='Datasets', /ALIGN_CENTER)
listSets = Widget_List(flist, VALUE=filelist, UVALUE='NOTHING', /MULTIPLE, SCR_XSIZE=190, SCR_YSIZE=360)
; Options
right = WIDGET_BASE(fit,/COLUMN, /ALIGN_CENTER, FRAME=1, YSIZE=400, XSIZE=200)
label =  WIDGET_LABEL(right, VALUE='Options', /ALIGN_CENTER)
buttons = WIDGET_BASE(right,/COLUMN, /ALIGN_LEFT, /NonExclusive)
savemovie = WIDGET_BUTTON(buttons, VALUE='Save dynamic plot in mpeg', UVALUE='NOTHING')
; peaklist
values = experiment->getPeakList(/used)
plotwhatPeak = CW_BGROUP(right, values, /COLUMN, /NONEXCLUSIVE, LABEL_TOP='hkl', UVALUE='NOTHING', /SCROLL, Y_SCROLL_SIZE=250 )
; buttons2
buttons2 = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
plot1 = WIDGET_BUTTON(buttons2, VALUE='Plot', UVALUE='PLOT')
plot2 = WIDGET_BUTTON(buttons2, VALUE='Dynamic Plot', UVALUE='DYNAMICPLOT')
close = WIDGET_BUTTON(buttons2, VALUE='Close window', UVALUE='DONE')
stash = {base: base, input: input, plotwhatPeak:plotwhatPeak, listSets:listSets, savemovie: savemovie}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'testLatticeStrainsWindow', input
end