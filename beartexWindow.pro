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
; export and print
; ***************************************************************************

; export to GIF function
pro doPlotBeartex_exportgif, event
common default, defaultdir
widget_control, event.top, get_uvalue=pstate
; fix the extension
filters = [['*.gif'], ['GIF']]
; pick a filename
filename = DIALOG_PICKFILE(dialog_parent = (*pstate).tlb, filter=filters, /write , TITLE='Save graphics as...', path=defaultdir, get_path = newdefaultdir);
; if OK was pressed
if (filename ne '') then begin
	; export the content of the active window to gif
	wset, (*pstate).w_id
	write_gif, filename, TVRD()
	; set the nez default path
	defaultdir = newdefaultdir
endif
end

; export to JPEG unction
pro doPlotBeartex_exportjpg, event
common default, defaultdir
widget_control, event.top, get_uvalue=pstate
; fix the extension
filters = [['*.jpg;*.jpeg'], ['JPEG']]
; pick a filename
filename = DIALOG_PICKFILE(dialog_parent = (*pstate).tlb, filter=filters, /write , TITLE='Save graphics as...', path=defaultdir, get_path = newdefaultdir);
; if OK was pressed
if (filename ne '') then begin
	; export the content of the active window to jpeg
	wset, (*pstate).w_id
	write_jpeg, filename, TVRD()
	; set the new default path
	defaultdir = newdefaultdir
endif
end

; export to postscript
pro doPlotBeartex_exportps, event
common default, defaultdir
; get the data in the window
widget_control, event.top, get_uvalue=pstate
; fix the extension
filters = [['*.ps'], ['PS']]
; pick a filename
filename = DIALOG_PICKFILE(dialog_parent = (*pstate).tlb, filter=filters, /write , TITLE='Save graphics as...', path=defaultdir, get_path = newdefaultdir);
; if OK was pressed
if (filename ne '') then begin
	; save current devide, set the device to postscript
	mydevice = !D.NAME
	set_plot, 'PS'
	device, filename = filename, /PORTRAIT, xsize = 15, ysize = 10, xoffset = 2.5, yoffset = 10, /color, bits_per_pixel=24
	; replot the data in the postscript device
	doPlotBeartex_doplot, pstate, postscript=1
	; close postscript devide, return to the old one
	device, /CLOSE
	set_plot, mydevice
	; set the new default path
	defaultdir = newdefaultdir
endif
end


; ***************************************************************************
; Replot the data 
; ***************************************************************************

; plot the data, send 'pstate', postscript = 1 if you are saving to a postscript file
pro doPlotBeartex_doplot, pstate, postscript=postscript
IF N_Elements(postscript) EQ 0 THEN postscript = 0
; find and fix plotting range
xmin = min([(*pstate).xmin,(*pstate).xmax])
xmax = max([(*pstate).xmin,(*pstate).xmax])
ymin = min([(*pstate).ymin,(*pstate).ymax])
ymax = max([(*pstate).ymin,(*pstate).ymax])
if (postscript eq 0) then begin ; plotting to screen
	; ensure that data are being plotted in the draw window
	wset, (*pstate).w_id
	; plot
	plot, (*pstate).anglesBeartex, (*pstate).intensitiesBeartex, background=255, color=0, xrange=[xmin,xmax], xstyle=1, xtickinterval=10, yrange=[ymin,ymax], linestyle=0, xtitle = (*pstate).xlabel, ytitle = (*pstate).ylabel, charsize=1.5
	oplot, (*pstate).anglesBeartex, (*pstate).intensitiesBeartex, psym=1, color=0
	oplot, (*pstate).anglesData, (*pstate).intensitiesData, color=20, psym=sym(5), symsize=1.5
	xyouts, 0.85, 0.8, (*pstate).legend, /NORMAL, color=0, charsize=1.8, charthick = 2.0
endif else begin ; postscript, simply plot the data
	plot, (*pstate).anglesBeartex, (*pstate).intensitiesBeartex, background=255, color=0, xrange=[xmin,xmax], xstyle=1, xtickinterval=10, yrange=[ymin,ymax], linestyle=0, xtitle = (*pstate).xlabel, ytitle = (*pstate).ylabel, charsize=1.5
	oplot, (*pstate).anglesBeartex, (*pstate).intensitiesBeartex, psym=1, color=0
	oplot, (*pstate).anglesData, (*pstate).intensitiesData, color=20, psym=sym(5), symsize=1.5
	xyouts, 0.8, 0.8, (*pstate).legend, /NORMAL, color=0, charsize=1.8, charthick = 2.0
endelse
end

; ***************************************************************************
; resize event
; ***************************************************************************

; handle resize of window events (resize the plot)
pro doPlotBeartex_resize, event
; get the pstate pointer
widget_control, event.top, get_uvalue=pstate
; getting size available for the plot
tlbg = widget_info(event.top, /geometry)
newx = event.x - 2*tlbg.xpad
newy = event.y - 2*tlbg.ypad - 2*tlbg.space
; setting a new size
widget_control, (*pstate).draw, xsize=newx, ysize=newy
; replot
doPlotBeartex_doplot, pstate
end

; ***************************************************************************
; cleaning up
; ***************************************************************************

; if we come from an event (from the menu)
pro doPlotBeartex_cleanupmenu,event
widget_control, event.top, get_uvalue=pstate
IF Widget_Info((*pstate).tlb, /Valid_ID) THEN Widget_Control, (*pstate).tlb, /Destroy
ptr_free, pstate
end

; if we come from a window (window has been shut, by the user or the application)
pro doPlotBeartex_cleanup, tlb
widget_control, tlb, get_uvalue = pstate
IF Widget_Info((*pstate).tlb, /Valid_ID) THEN Widget_Control, (*pstate).tlb, /Destroy
ptr_free, pstate
end

; ***************************************************************************
; UI For plotting
; ***************************************************************************

pro doPlotBeartex, basewindow, peakname, anglesBeartex, intensitiesBeartex, anglesData, intensitiesData
; main window
tlb = widget_base(title = "Intensities for Beartex", /column, /tlb_size_events, MBAR=bar, GROUP_LEADER=basewindow)
; menu bar
file_menu = WIDGET_BUTTON(bar, VALUE='File', /MENU)
file_bttn1 = WIDGET_BUTTON(file_menu, VALUE='Export plot to GIF', event_pro = 'doPlotBeartex_exportgif', /SEPARATOR)
file_bttn2 = WIDGET_BUTTON(file_menu, VALUE='Export plot to JPEG', event_pro ='doPlotBeartex_exportjpg' )
file_bttn3 = WIDGET_BUTTON(file_menu, VALUE='Export plot to PS', event_pro = 'doPlotBeartex_exportps' )
file_bttn4 = WIDGET_BUTTON(file_menu, VALUE='Close window', event_pro = 'doPlotBeartex_cleanupmenu', /SEPARATOR)
; other
draw = widget_draw(tlb, xsize=500, ysize=300)
; build the UI
Widget_Control, tlb, /Realize
; get important information to communicate in the application
Widget_Control, draw, get_value=w_id
xmin = -5.
xmax = 95.
ymin = 0.
ymax =  max([max(intensitiesBeartex), max(intensitiesData)])
xlabel = "Angle to compression"
ylabel = "Intensity"
legend = peakname
state = {tlb: tlb, w_id:w_id, draw:draw, xlabel:xlabel, ylabel:ylabel, xmin:xmin, xmax:xmax, ymin:ymin, ymax:ymax, legend: legend, anglesBeartex: anglesBeartex, intensitiesBeartex: intensitiesBeartex, anglesData: anglesData, intensitiesData: intensitiesData}
; create a pointer to the state structure and put that pointer
; into the user value of the top-level base
pstate = ptr_new(state,/no_copy)
widget_control, tlb, set_uvalue=pstate
widget_control, draw, set_uvalue=pstate
widget_control, file_bttn1, set_uvalue=pstate
widget_control, file_bttn2, set_uvalue=pstate
widget_control, file_bttn3, set_uvalue=pstate
widget_control, file_bttn4, set_uvalue=pstate
; plot the data
doPlotBeartex_doplot, pstate
; Register with XMANAGER so you can receive events.
Widget_Control, tlb, Kill_Notify='doPlotBeartex_cleanup'
xmanager, 'doPlotBeartex', tlb, event_handler='doPlotBeartex_resize', cleanup='doPlotBeartex_cleanup'
end


; ***************************************************************************
; Calculate intensities for Beartex
; ***************************************************************************

function prepareBeartexIntensities, basewindow, peakname, angles, intensities, offset, range, lisser, plotit
nangles = n_elements(angles)
anglessimple = fltarr(nangles)
for i=0, nangles-1 do begin
	a = (angles[i]-offset)*!pi/180.
	anglessimple[i] = 180.*asin(sin(acos(cos(a))))/!pi
	; print, "Angle ", angles[i], " becomes ", anglessimple[i]
	; print, "I = ", intensities[i]
endfor
intensitiesBeartex = fltarr(19)
xx = fltarr(19)
; print, "Range for searching: ", range
for i=0, 18 do begin
	xx[i] = 5.*i
	use = where(abs(anglessimple-xx[i]) lt range, count)
	if (count eq 0) then begin
		; print, "For ", xx[i], " degrees, number of angle matches: ", count
		intensitiesBeartex[i] = 0.0
	endif else begin
		use2 = where(finite(intensities[use]), count)
		; print, "For ", xx[i], " degrees, number of angle matches with actual measurements: ", count
		use = use[use2]
		; print, use
		if (count eq 0) then begin
			intensitiesBeartex[i] = 0.0
		endif else if (count eq 1) then begin
			intensitiesBeartex[i] = intensities[use[0]]
		endif else begin
			x = anglessimple[use]
			y = intensities[use]
			; print, x
			; print, y
			result = linfit(x, y)
			; print, result
			intensitiesBeartex[i] = result[0] + xx[i] *  result[1]
			; print, intensitiesBeartex[i]
		endelse
	endelse
endfor
if (lisser eq 1) then intensitiesBeartex = SMOOTH(intensitiesBeartex, 2)
if (plotit eq 1) then begin
	doPlotBeartex, basewindow, peakname, xx, intensitiesBeartex, anglessimple, intensities
endif
return, intensitiesBeartex
end

; ***************************************************************************
; Plot Beartex data
; Changed 10/2011, option to normalize intensities
; ***************************************************************************

pro plotTestBeartex, base, globalbase, sets, peaks, range, lisser, correctintensity
common experimentwindow, set, experiment
common default, defaultdir
; Making sure there is someting to plot
usePeak = WHERE(peaks, nUsePeak)
if ((sets[0] eq -1) or (nUsePeak eq 0)) then begin
  result = DIALOG_MESSAGE( "Error: no image or no diffraction line selected!", /CENTER , DIALOG_PARENT=base, /ERROR) 
  return
endif
; Fetching experimental intensities for each hkl
offset = experiment->latticeStrainOffset(set)
for j=0, nUsePeak-1 do begin
	peak = usePeak[j]
	angles = experiment->getPsiPeak(sets,peak,/used)
	intensities = experiment->getIPeak(sets,peak,correctintensity,/used)
	peakname = experiment->getPeakName(peak,/used)
	test = prepareBeartexIntensities(base, peakname, angles, intensities, offset, range, lisser, 1)
endfor
end

; ***************************************************************************
; Save Beartex input file
; ; Changed 10/2011, option to normalize intensities
; ***************************************************************************

pro saveFileBeartex, base, globalbase, sets, peaks, range, lisser, symcode, correctintensity
common experimentwindow, set, experiment
common default, defaultdir
; Making sure there is someting to save
usePeak = WHERE(peaks, nUsePeak)
if ((sets[0] eq -1) or (nUsePeak eq 0)) then begin
  result = DIALOG_MESSAGE( "Error: no image or no diffraction line selected!", /CENTER , DIALOG_PARENT=base, /ERROR) 
  return
endif
; fix the extension
filters = [['*.xpe'], ['XPE']]
; pick a filename
filename = DIALOG_PICKFILE(dialog_parent = base, filter=filters, /write , TITLE='Save file as...', path=defaultdir, get_path = newdefaultdir);
; if OK was pressed
if (filename ne '') then begin
	if (FILE_TEST(filename) eq 1) then begin
		tmp = DIALOG_MESSAGE("File exists. Overwrite?", /QUESTION)
		if (tmp eq 'No') then return
	endif
	; set the new default path
	defaultdir = newdefaultdir
	; get main experiment data
	offset = experiment->latticeStrainOffset(set)
	codelist = experiment->beartexCodeList()
	code = codelist.codelist[symcode]
	; Beartex header
	header = experiment->beartexMaterialHeader(set,code)
	beartexTxt = ""
	for j=0, nUsePeak-1 do begin
		; headers
		peak = usePeak[j]
		beartexTxt += header
		beartexTxt += experiment->beartexPeakLine(peak, /used)
		angles = experiment->getPsiPeak(sets,peak,/used)
		intensities = experiment->getIPeak(sets,peak,correctintensity,/used)
		; intensities
		peakname = experiment->getPeakName(peak,/used)
		beartexIntensities = prepareBeartexIntensities(base, peakname, angles, intensities, offset, range, lisser, 0)
		maxi = max(beartexIntensities)
		beartexIntensities *= 500./maxi; rescaling intensities, max at 500
		for i=0, 18 do begin
			line = " "
			item = string(fix(beartexIntensities[i]),format='(I4)')
			for k=0, 17 do line += item
			beartexTxt += line + STRING(13B) +  STRING(10B)
			beartexTxt += line + STRING(13B) +  STRING(10B)
			beartexTxt += line + STRING(13B) +  STRING(10B)
			beartexTxt += line + STRING(13B) +  STRING(10B)
		endfor
		beartexTxt += STRING(13B) +  STRING(10B)
		openw, lun, filename, /get_lun
		printf, lun, beartexTxt, format='(A)'
		free_lun, lun
	endfor
	
endif
end

; ***************************************************************************
; Main Beartex user interface
; ; Changed 10/2011, option to normalize intensities
; ***************************************************************************

pro beartexWindow_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
sets = WIDGET_INFO(stash.listSets, /LIST_SELECT)
WIDGET_CONTROL, stash.plotwhatPeak, GET_VALUE=peaks
widget_control, stash.smoothButton, GET_VALUE=lisser
widget_control, stash.symcodeButton, GET_VALUE=symcode
WIDGET_CONTROL, stash. rangeInput, GET_VALUE=rangeS
range = float(rangeS[0])
CASE ev.id OF
	stash.input:
	else: begin
    WIDGET_CONTROL, stash.plotwhat, GET_VALUE=correctintensity ;Caro 07/01/11
		CASE uval OF
		'PLOT': plotTestBeartex, stash.input, stash.base, sets, peaks, range, lisser, correctintensity
		'ASCII': saveFileBeartex, stash.input, stash.base, sets, peaks, range, lisser, symcode, correctintensity
		'DONE': WIDGET_CONTROL, stash.input, /DESTROY
		else:
		ENDCASE
	endcase
	else:
endcase
end

; Changed 10/2011, option to normalize intensities
pro beartexWindow, base
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
input = WIDGET_BASE(Title='Prepare input file for Beartex', /COLUMN, GROUP_LEADER=base)
inputLa = WIDGET_LABEL(input, VALUE='Prepare input file for Beartex', /ALIGN_CENTER, FONT=titlefont)
fit = WIDGET_BASE(input, /ROW, FRAME=0)
; listing datasets
flist = WIDGET_BASE(fit,/COLUMN, /ALIGN_CENTER, FRAME=1,XSIZE=200, YSIZE=400)
filelist = experiment->getDatasetList()
listLa = WIDGET_LABEL(flist, VALUE='Datasets', /ALIGN_CENTER)
listSets = Widget_List(flist, VALUE=filelist, UVALUE='NOTHING', SCR_XSIZE=190, SCR_YSIZE=360)
; Options
right = WIDGET_BASE(fit,/COLUMN, /ALIGN_CENTER, FRAME=1, YSIZE=400)
; peak list
values = experiment->getPeakList(/used)
plotwhatPeak = CW_BGROUP(right, values, /COLUMN, /NONEXCLUSIVE, LABEL_TOP='hkl', UVALUE='NOTHING', /SCROLL, Y_SCROLL_SIZE=320)
; range
range = WIDGET_BASE(input,/ROW, /ALIGN_LEFT)
rangeLa = WIDGET_LABEL(range, VALUE='Angle for intensity fitting')
rangeInput = WIDGET_TEXT(range,  VALUE='20', XSIZE=10, /EDITABLE)
; smooth
smooth = WIDGET_BASE(input,/ROW, /ALIGN_LEFT)
smoothla = WIDGET_LABEL(smooth, VALUE='Smooth fitted intensities')
values = ['No', 'Yes']
smoothButton = CW_BGROUP(smooth, values, /ROW, /EXCLUSIVE, SET_VALUE=0, UVALUE='SMOOTH')
; Beartex symmetry codes
symcode = WIDGET_BASE(input,/ROW, /ALIGN_LEFT)
codela = WIDGET_LABEL(symcode, VALUE='Symmetry code')
codelist = experiment->beartexCodeList()
values = strarr(n_elements(codelist.pg1))
for i=0, n_elements(codelist.pg1)-1 do values[i] = codelist.pg1[i] + " - " + strtrim(string(codelist.pg2[i]),2)
symcodeButton = CW_BGROUP(symcode, values, /ROW, /EXCLUSIVE, SET_VALUE=0, UVALUE='SYM')
; correctintensity = normalize intensities
buttons2 = WIDGET_BASE(input,/ROW, /ALIGN_LEFT, /GRID_LAYOUT)
values = ['Raw intensities', 'Corrected intensities']
plotwhat = CW_BGROUP(buttons2, values, /COLUMN, /EXCLUSIVE, UVALUE='NOTHING', SET_VALUE=0)
; buttons2
buttons2 = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
plot1 = WIDGET_BUTTON(buttons2, VALUE='Plot', UVALUE='PLOT')
close = WIDGET_BUTTON(buttons2, VALUE='Close window', UVALUE='DONE')
export = WIDGET_BUTTON(buttons2, VALUE='Export to Beartex', UVALUE='ASCII')
stash = {base: base, input: input, plotwhatPeak:plotwhatPeak, listSets:listSets, rangeInput: rangeInput,smoothButton:smoothButton, symcodeButton:symcodeButton, plotwhat:plotwhat}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'beartexWindow', input
end