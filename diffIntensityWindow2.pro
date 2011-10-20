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
; plot plotDspacVsChi function
; prepares a plot with a test of lattice strains fits
; **************************************************************************
; 
; Changed 10/2011, allow plot vs. strain
; Changed 10/2011, option to normalize intensities
; if vswhat=0, plot vs. step number
;    vswhat=1, plot vs. strain
pro plotIntVsImage, base, globalbase, sets, peaks, correctintensity, vswhat
common experimentwindow, set, experiment
common default, defaultdir
usePeak = WHERE(peaks, nUsePeak)
nAngles = N_ELEMENTS(sets)
angleList = experiment->getAngleList()
if ((sets[0] eq -1) or (nUsePeak eq 0)) then begin
  result = DIALOG_MESSAGE( "Error: no image or no diffraction line selected!", /CENTER , DIALOG_PARENT=base, /ERROR) 
  return
endif
; fetching data to plot
nPattern = experiment->getnumberDatasets()
legend=strarr(nAngles*nUsePeak)
data = fltarr(nAngles*nUsePeak,nPattern)
x = intarr(nPattern)
progressBar = Obj_New("SHOWPROGRESS", message='Processing, please wait...')
progressBar->Start
if (vswhat eq 0) then begin 
  for i=0, nPattern-1 do x[i] = i
  xlabel = 'Dataset number'
  title = 'intensities vs. dataset number'
endif else begin
  for i=0,nPattern-1 do x[i] = experiment->getStepStrain(i) 
  xlabel = 'Strain'
  title = 'intensities vs. strain'
endelse
ylabel='Intensity'
for i=0, nAngles-1 do begin
	for j=0, nUsePeak-1 do begin
		data[i*nUsePeak+j,*] = (experiment->getIPeakVsSet(usePeak[j],sets[i],correctintensity,/used))[*]
		legend[i*nUsePeak+j] = strtrim(string(angleList[sets[i]]),2)+'-'+ experiment->getPeakName(usePeak[j],/used)
		percent = 100.*i/nAngles
		progressBar->Update, percent
	endfor
endfor
progressBar->Destroy
Obj_Destroy, progressBar
; calling the plot window
plotinteractive1D, base, x, data, title=title, xlabel=xlabel, ylabel=ylabel, legend=legend
end

; Changed 10/2011, option to normalize intensities
pro exportIntVsImageCSV, base, sets, peaks, correctintensity
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
	usePeak = WHERE(peaks, nUsePeak)
	nAngles = N_ELEMENTS(sets)
	nPattern = experiment->getnumberDatasets()
	angleList = experiment->getAngleList()
	data = fltarr(nAngles*nUsePeak,nPattern)
	legend=strarr(nAngles*nUsePeak)
	for i=0, nAngles-1 do begin
		for j=0, nUsePeak-1 do begin
			data[i*nUsePeak+j,*] = (experiment->getIPeakVsSet(usePeak[j],sets[i], correctintensity,/used))[*]
			legend[i*nUsePeak+j] = strtrim(string(angleList[sets[i]]),2)+'-'+ experiment->getPeakName(usePeak[j],/used)
		endfor
	endfor
	openw, lun, result, /get_lun
	printf, lun, "# Intensities as a function of image number for one peak and one orientation"
	line =  "# image name, strain, intensity for (angle-peak)"
	for i=0, nAngles*nUsePeak-1 do line += " " + legend[i]
  printf, lun, line
	for step=0,nPattern-1 do begin
		printf, lun, experiment->getDatasetName(step), STRING(9B), experiment->getStepStrain(step), STRING(9B), fltformatD(data[*,step])
	endfor
	free_lun, lun
	progressBar->Destroy
	Obj_Destroy, progressBar
endif
end

; *********************************************************************** Interface ****************

pro diffIntensityWindow2_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
sets = WIDGET_INFO(stash.listSets, /LIST_SELECT)
WIDGET_CONTROL, stash.plotwhatPeak, GET_VALUE=peaks
CASE ev.id OF
	stash.input:
	else: begin
    WIDGET_CONTROL, stash.plotwhat, GET_VALUE=correctintensity ;Caro 07/01/11
    WIDGET_CONTROL, stash.plotvswhat, GET_VALUE=vswhat ;Caro 20/01/11
		CASE uval OF
		'PLOT': plotIntVsImage, stash.input, stash.base, sets, peaks, correctintensity, vswhat
		'DONE': WIDGET_CONTROL, stash.input, /DESTROY
		'ASCII': exportIntVsImageCSV, stash.input, sets, peaks, correctintensity
		else:
		ENDCASE
	endcase
endcase
end

; Changed 10/2011, allow plot vs. strain
; Changed 10/2011, option to normalize intensities
pro diffIntensityWindow2, base
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
input = WIDGET_BASE(Title='Intensities vs image numbers', /COLUMN, GROUP_LEADER=base)
inputLa = WIDGET_LABEL(input, VALUE='Intensities vs image numbers', /ALIGN_CENTER, FONT=titlefont)
fit = WIDGET_BASE(input, /ROW, FRAME=0)
; listing datasets
alist = WIDGET_BASE(fit,/COLUMN, /ALIGN_CENTER, FRAME=1,XSIZE=200, YSIZE=400)
anglelist = experiment->getAngleList()
anglelistStr = STRING(anglelist)
listLa = WIDGET_LABEL(alist, VALUE='Datasets', /ALIGN_CENTER)
listSets = Widget_List(alist, VALUE=anglelistStr, UVALUE='NOTHING', /MULTIPLE, SCR_XSIZE=190, SCR_YSIZE=360)
; Options
right = WIDGET_BASE(fit,/COLUMN, /ALIGN_CENTER, FRAME=1, YSIZE=400)
; peak list
values = experiment->getPeakList(/used)
plotwhatPeak = CW_BGROUP(right, values, /COLUMN, /NONEXCLUSIVE, LABEL_TOP='hkl', UVALUE='NOTHING', /SCROLL, Y_SCROLL_SIZE=320, SET_VALUE=0)
; Options
buttons2 = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
values = ['Plot raw intensity', 'Plot corrected intensity']
plotwhat = CW_BGROUP(buttons2, values, /COLUMN, /EXCLUSIVE, UVALUE='NOTHING', SET_VALUE=0)
values2 = ['Plot vs. step', 'Plot vs. strain'] ;Caro 20/01/11
plotvswhat = CW_BGROUP(buttons2, values2, /COLUMN, /EXCLUSIVE, UVALUE='NOTHING', SET_VALUE=0) ;Caro 20/01/11
; buttons2
buttons2 = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
plot1 = WIDGET_BUTTON(buttons2, VALUE='Plot', UVALUE='PLOT')
close = WIDGET_BUTTON(buttons2, VALUE='Close window', UVALUE='DONE')
export = WIDGET_BUTTON(buttons2, VALUE='Export to ASCII', UVALUE='ASCII')
stash = {base: base, input: input, plotwhatPeak:plotwhatPeak, listSets:listSets, plotwhat:plotwhat, plotvswhat:plotvswhat}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'diffIntensityWindow2', input
end