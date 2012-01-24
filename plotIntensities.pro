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
pro plotIntensities_exportgif, event
  common default, defaultdir
  widget_control, event.top, get_uvalue=pstate
  ; fix the extension
  filters = [['*.gif'], ['GIF']]
  ; pick a filename
  filename = DIALOG_PICKFILE(dialog_parent = (*pstate).tlb, filter=filters, /write , TITLE='Save graphics as...', path=defaultdir, get_path = newdefaultdir);
  ; if OK was pressed
  if (filename ne '') then begin
    ; export the content of the active window to gif
    write_gif, filename, TVRD()
    ; set the nez default path
    defaultdir = newdefaultdir
  endif
end

; export to JPEG unction
pro plotIntensities_exportjpg, event
  common default, defaultdir
  widget_control, event.top, get_uvalue=pstate
  ; fix the extension
  filters = [['*.jpg;*.jpeg'], ['JPEG']]
  ; pick a filename
  filename = DIALOG_PICKFILE(dialog_parent = (*pstate).tlb, filter=filters, /write , TITLE='Save graphics as...', path=defaultdir, get_path = newdefaultdir);
  ; if OK was pressed
  if (filename ne '') then begin
    ; export the content of the active window to jpeg
    write_jpeg, filename, TVRD()
    ; set the new default path
    defaultdir = newdefaultdir
  endif
end

; export to postscript
pro plotIntensities_exportps, event
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
    plotTestLatticeStrains_doplot, pstate, postscript=1
    ; close postscript devide, return to the old one
    device, /CLOSE
    set_plot, mydevice
    ; set the new default path
    defaultdir = newdefaultdir
  endif
end

; export to ascii
pro plotIntensities_exportascii, event
  common experimentwindow, set, experiment
  common default, defaultdir
  widget_control, event.top, get_uvalue=pstate
  ; label
  if ((*pstate).nSets gt 1) then $
    txt = strarr(2*(*pstate).nUsePeak+3) $
  else txt = strarr((*pstate).nUsePeak+2)
  txt[0] = "You chose to export the plot data to ascii. You will have to choose"
  txt[1] = "a directory and we will save the files: "
  for j=0, (*pstate).nUsePeak-1 do begin
    txt[2+j] = " - " +  (*pstate).legend[0]+ "-i" + experiment->getPeakName((*pstate).peakIndex[j]) + ".dat"
  endfor
  if ((*pstate).nSets gt 1) then begin
    txt[2+(*pstate).nUsePeak] = " - " + " ... "
    for j=0, (*pstate).nUsePeak-1 do begin
      txt[3+(*pstate).nUsePeak+j] = " - " + (*pstate).legend[(*pstate).nSets-1] + "-i" + experiment->getPeakName((*pstate).peakIndex[j]) + ".dat"
    endfor
  endif
  Result = DIALOG_MESSAGE( txt, DIALOG_PARENT=event.top, /INFORMATION)
  directory = DIALOG_PICKFILE(dialog_parent = (*pstate).tlb, /write , TITLE='Choose directory...', /directory, path=defaultdir, get_path = newdefaultdir);
  ; if OK was pressed
  if (directory ne '') then begin
    defaultdir = newdefaultdir
    if ((*pstate).nUsePeak eq 1) then begin
      for i=0, (*pstate).nSets-1 do begin
        filename = directory + (*pstate).legend[i] + "-i" + experiment->getPeakName((*pstate).peakIndex[0]) + ".dat"
        txt = "# delta" + STRING(9B)  + "intensity\n"
        top = N_ELEMENTS(*(*pstate).xdata[i])
        for k = 0, top-1 do begin
          if (finite((*(*pstate).ydata[i])[k])) then $
              txt += fltformatB((*(*pstate).xdata[i])[k]) +   STRING(9B)  + fltformatC((*(*pstate).ydata[i])[k]) + "\n"
        endfor
        ; print, "filename", filename
        openw, lun, filename, /get_lun
        printascii, lun, txt
        free_lun, lun
      endfor
    endif else begin
       for i=0, (*pstate).nSets-1 do begin
          for j=0, (*pstate).nUsePeak-1 do begin
              filename = directory + (*pstate).legend[i] + "-i" + experiment->getPeakName((*pstate).peakIndex[j]) + ".dat"
              txt = "# delta" + STRING(9B)  + "intensity\n"
              top = N_ELEMENTS(*(*pstate).xdata[i,j])
              for k = 0, top-1 do begin
                if (finite((*(*pstate).ydata[i,j])[k])) then $
                    txt += fltformatB((*(*pstate).xdata[i,j])[k]) +   STRING(9B)  + fltformatC((*(*pstate).ydata[i,j])[k]) + "\n"
              endfor
              ; print, "filename", filename
              openw, lun, filename, /get_lun
              printascii, lun, txt
              free_lun, lun
          endfor
        endfor
    endelse
  endif
end


; ***************************************************************************
; handling of mouse events
; ***************************************************************************

; handle mouse events in the plot window
pro plotIntensities_draw, event
  widget_control, event.top, get_uvalue=pstate
  if (event.type eq 0) then begin ; mouse is pressed
    if (event.clicks eq 2) then begin
      ; double-click: we autoscale the data
      (*pstate).scaling = 0
      (*pstate).xmin = 0
      (*pstate).xmax = 360
      (*pstate).ymin = (*pstate).ydatamin
      (*pstate).ymax = (*pstate).ydatamax
      plotIntensities_doplot, pstate
    endif else begin
      ; single click, scaling according to mouse, setting starting value and activating rectagle draw
      datac = convert_coord(event.x, event.y, /device, /to_data, /double)
      (*pstate).sc_xmin = datac[0]
      (*pstate).sc_ymin = datac[1]
      (*pstate).scaling = 1
    endelse
  endif else if (event.type eq 1) then begin ; mouse is released
    ; if we were scaling, end of scaling according to mouse
    if ((*pstate).scaling eq 1) then begin
      datac = convert_coord(event.x, event.y, /device, /to_data, /double)
      (*pstate).xmin = (*pstate).sc_xmin
      (*pstate).ymin = (*pstate).sc_ymin
      (*pstate).xmax = datac[0]
      (*pstate).ymax = datac[1]
      (*pstate).scaling = 0
      plotIntensities_doplot, pstate
    endif
  endif else if (event.type eq 2) then begin ; mouse is moved
    if ((*pstate).scaling eq 1) then begin
      ; if scaling according to mouse, drawing the rectangle
      datac = convert_coord(event.x, event.y, /device, /to_data, /double)
      (*pstate).sc_xmax = datac[0]
      (*pstate).sc_ymax = datac[1]
      plotIntensities_doplot, pstate
    endif else begin
      ; otherwise convert the data to a string and set it in the status variable of the widget
      datac = convert_coord(event.x, event.y, /device, /to_data, /double)
      statusstr = strtrim(datac[0],2) + ',' +  strtrim(datac[1],2)
      widget_control, (*pstate).status, set_value=statusstr
    endelse
  endif
end

; ***************************************************************************
; replot the data with or without scaling rectangle
; ***************************************************************************

; plot the data, send 'pstate', postscript = 1 if you are saving to a postscript file
pro plotIntensities_doplot, pstate, postscript=postscript
  IF N_Elements(postscript) EQ 0 THEN postscript = 0
  ; find and fix plotting range
  xmin = min([(*pstate).xmin,(*pstate).xmax])
  xmax = max([(*pstate).xmin,(*pstate).xmax])
  ymin = min([(*pstate).ymin,(*pstate).ymax])
  ymax = max([(*pstate).ymin,(*pstate).ymax])
  if (postscript eq 0) then begin ; plotting to screen
    ; ensure that data are being plotted in the draw window
    wset, (*pstate).w_id
    ;print, "Here"
    ;print, (*pstate).nUsePeak
    ;print, (*pstate).nSets
    ;print, (*(*pstate).xdata[0])
    if ((*pstate).nUsePeak eq 1) then begin
      for i=0, (*pstate).nSets-1 do begin
        if (i eq 0) then $
          plot, (*(*pstate).xdata[i]), (*(*pstate).ydata[i]),  xrange = [xmin,xmax], yrange=[ymin,ymax], background=255, color=0, xtitle=(*pstate).xlabel, ytitle=(*pstate).ylabel, title=(*pstate).title, ystyle = 1, xstyle=1, PSYM=2 $
        else $
          oplot, (*(*pstate).xdata[i]), (*(*pstate).ydata[i]), color=0, PSYM=2
      endfor
    endif else begin
      for i=0, (*pstate).nSets-1 do begin
        for j=0, (*pstate).nUsePeak-1 do begin
          if (i eq 0) and (j eq 0) then $
            plot, (*(*pstate).xdata[i,j]), (*(*pstate).ydata[i,j]),  xrange = [xmin,xmax], yrange=[ymin,ymax], background=255, color=0, xtitle=(*pstate).xlabel, ytitle=(*pstate).ylabel, title=(*pstate).title, ystyle = 1, xstyle=1, PSYM=2 $
          else $
            oplot, (*(*pstate).xdata[i,j]), (*(*pstate).ydata[i,j]), color=0, PSYM=2
        endfor
      endfor
    endelse
    ; if we are scaling, plot a red rectangle
    if ((*pstate).scaling eq 1) then begin
      oplot, [(*pstate).sc_xmin,(*pstate).sc_xmax,(*pstate).sc_xmax,(*pstate).sc_xmin,(*pstate).sc_xmin], [(*pstate).sc_ymin,(*pstate).sc_ymin,(*pstate).sc_ymax,(*pstate).sc_ymax,(*pstate).sc_ymin], color=10
    endif
  ;	; add the legend, if necessary
  ;	if ((*pstate).plotlegend) then begin
  ;		x1 = xmax-0.2*(xmax-xmin)
  ;		x2 = xmax-0.15*(xmax-xmin)
  ;		x3 = xmax-0.13*(xmax-xmin)
  ;		y1 = ymax-0.05*(ymax-ymin)
  ;		oplot, [x1,x2], [y1,y1], color=0
  ;		xyouts, x3, y1, (*pstate).legend[0], color=0
  ;		if ((*pstate).ncolumns gt 1) then begin
  ;			for i=1, (*pstate).ncolumns-1 do begin
  ;				y1 = y1 - 0.05*(ymax-ymin)
  ;				oplot, [x1,x2], [y1,y1], color=10*i
  ;				xyouts, x3, y1, (*pstate).legend[i],  color=10*i
  ;			endfor
  ;		endif
  ;	endif
  endif else begin ; postscript, simply plot the data
    if ((*pstate).nUsePeak eq 1) then begin
      for i=0, (*pstate).nSets-1 do begin
        if (i eq 0) then $
          plot, (*(*pstate).xdata[i]), (*(*pstate).ydata[i]),  xrange = [xmin,xmax], yrange=[ymin,ymax], background=255, color=0, xtitle=(*pstate).xlabel, ytitle=(*pstate).ylabel, title=(*pstate).title, ystyle = 1, xstyle=1, PSYM=2 $
        else $
          oplot, (*(*pstate).xdata[i]), (*(*pstate).ydata[i]), color=0, PSYM=2
      endfor
    endif else begin
      for i=0, (*pstate).nSets-1 do begin
        for j=0, (*pstate).nUsePeak-1 do begin
          if (i eq 0) and (j eq 0) then $
            plot, (*(*pstate).xdata[i,j]), (*(*pstate).ydata[i,j]),  xrange = [xmin,xmax], yrange=[ymin,ymax], background=255, color=0, xtitle=(*pstate).xlabel, ytitle=(*pstate).ylabel, title=(*pstate).title, ystyle = 1, xstyle=1, PSYM=2 $
          else $
            oplot, (*(*pstate).xdata[i,j]), (*(*pstate).ydata[i,j]), color=0, PSYM=2
        endfor
      endfor
    endelse
  endelse
end

; ***************************************************************************
; dynamic plot
; ***************************************************************************

; plot the data, send 'pstate'
pro plotIntensities_doplotdynamic, pstate, savemovie, filename
  if (savemovie) then mpegID = MPEG_OPEN([500, 300])
  ; find and fix plotting range
  xmin = min([(*pstate).xmin,(*pstate).xmax])
  xmax = max([(*pstate).xmin,(*pstate).xmax])
  ymin = min([(*pstate).ymin,(*pstate).ymax])
  ymax = max([(*pstate).ymin,(*pstate).ymax])
  ; ensure that data are being plotted in the draw window
  wset, (*pstate).w_id
  ; plot!!
  if  ((*pstate).nUsePeak eq 1) then begin
    for i=0, (*pstate).nSets-1 do begin
      plot, (*(*pstate).xdata[i]), (*(*pstate).ydata[i]),  xrange = [xmin,xmax], yrange=[ymin,ymax], background=255, color=0, xtitle=(*pstate).xlabel, ytitle=(*pstate).ylabel, title=(*pstate).title, ystyle = 1, xstyle=1, PSYM=2
      ; legend
      x3 = xmax-0.3*(xmax-xmin)
      y1 = ymax-0.07*(ymax-ymin)
      xyouts, x3, y1, (*pstate).legend[i], color=0, charsize=1.8, charthick=2
      if (savemovie) then MPEG_PUT, mpegID, window=(*pstate).w_id, FRAME=i*3, /ORDER
      wait, 0.3
    endfor
  endif else begin
    for i=0, (*pstate).nSets-1 do begin
      ; plot
      for j=0, (*pstate).nUsePeak-1 do begin
        if (j eq 0) then $
          plot, (*(*pstate).xdata[i,j]), (*(*pstate).ydata[i,j]),  xrange = [xmin,xmax], yrange=[ymin,ymax], background=255, color=0, xtitle=(*pstate).xlabel, ytitle=(*pstate).ylabel, title=(*pstate).title, ystyle = 1, xstyle=1, PSYM=2 $
        else oplot, (*(*pstate).xdata[i,j]), (*(*pstate).ydata[i,j]), color=0, PSYM=2
      endfor
      ; legend
      x3 = xmax-0.3*(xmax-xmin)
      y1 = ymax-0.07*(ymax-ymin)
      xyouts, x3, y1, (*pstate).legend[i], color=0, charsize=1.8, charthick=2
      if (savemovie) then MPEG_PUT, mpegID, window=(*pstate).w_id, FRAME=i*3, /ORDER
      wait, 0.3
    endfor
  endelse
  if (savemovie) then begin
    MPEG_SAVE, mpegID, FILENAME=filename
    MPEG_CLOSE, mpegID
  endif
end


; ***************************************************************************
; resize event
; ***************************************************************************

; handle resize of window events (resize the plot)
pro plotIntensities_resize, event
  ; get the pstate pointer
  widget_control, event.top, get_uvalue=pstate
  ; getting size available for the plot
  statusg = widget_info((*pstate).status, /geometry)
  tlbg = widget_info(event.top, /geometry)
  newx = event.x - 2*tlbg.xpad
  newy = event.y - statusg.scr_ysize - 2*tlbg.ypad - 2*tlbg.space
  ; setting a new size
  widget_control, (*pstate).draw, xsize=newx, ysize=newy
  ; replot
  plotIntensities_doplot, pstate
end

; ***************************************************************************
; cleaning up
; ***************************************************************************

; if we come from an event (from the menu)
pro plotIntensities_cleanupmenu,event
  widget_control, event.top, get_uvalue=pstate
  for i=0, (*pstate).nSets-1 do begin
    for j=0, (*pstate).nUsePeak-1 do begin
      PTR_Free, (*pstate).xdata[i,j]
      PTR_Free, (*pstate).ydata[i,j]
    endfor
  endfor
  IF Widget_Info((*pstate).tlb, /Valid_ID) THEN Widget_Control, (*pstate).tlb, /Destroy
  ptr_free, pstate
end

; if we come from a window (window has been shut, by the user or the application)
pro plotIntensities_cleanup, tlb
  widget_control, tlb, get_uvalue = pstate
  for i=0, (*pstate).nSets-1 do begin
    for j=0, (*pstate).nUsePeak-1 do begin
      PTR_Free, (*pstate).xdata[i,j]
      PTR_Free, (*pstate).ydata[i,j]
    endfor
  endfor
  IF Widget_Info((*pstate).tlb, /Valid_ID) THEN Widget_Control, (*pstate).tlb, /Destroy
  ptr_free, pstate
end

; ***************************************************************************
; setting up
; ***************************************************************************

pro plotIntensities, base, sets, peaks, dynamic, savemovie, filename, correctintensity
  common experimentwindow, set, experiment
  title = "Diffraction intensities"
  xlabel = "Psi"
  ylabel = "Intensity"
  ; Setting a few usefull variables
  nSets = n_elements(sets)         ; number of datasets
  usePeak = WHERE(peaks, nPeaks)   ; peak list and number of peaks
  ; Setting legend
  legend=strarr(nSets)
  ; We cache the plot data, some pointers are cleared once the window is drawn
  xdata = PTRARR(nSets,nPeaks)
  ydata = PTRARR(nSets,nPeaks)
  ydatamin = 1.e100
  ydatamax = 0.
  for i=0, nSets-1 do begin
    set = sets[i]
    legend[i] = experiment->getDatasetName(sets[i])
    for j=0, nPeaks-1 do begin
      peak = usePeak[j]
      xdata[i,j] = PTR_NEW(experiment->getPsiPeak(set,peak,/used))
      ydata[i,j] = PTR_NEW(experiment->getIPeak(set,peak, correctintensity,/used))
      ydatamin = min([ydatamin,min(*(ydata[i,j]))])
      ydatamax = max([ydatamax,max(*(ydata[i,j]))])
    ;print, i, j
    ;print, *(xdata[i,j])
    ;print, *(ydata[i,j])
    endfor
  endfor
  ; main window
  tlb = widget_base(title = title, /column, /tlb_size_events, MBAR=bar, GROUP_LEADER=base)
  ; menu bar
  file_menu = WIDGET_BUTTON(bar, VALUE='File', /MENU)
  file_bttn0 = WIDGET_BUTTON(file_menu, VALUE='Export data to ASCII', event_pro ='plotIntensities_exportascii')
  file_bttn1 = WIDGET_BUTTON(file_menu, VALUE='Export plot to GIF', event_pro = 'plotIntensities_exportgif', /SEPARATOR)
  file_bttn2 = WIDGET_BUTTON(file_menu, VALUE='Export plot to JPEG', event_pro = 'plotIntensities_exportjpg' )
  file_bttn3 = WIDGET_BUTTON(file_menu, VALUE='Export plot to PS', event_pro = 'plotIntensities_exportps' )
  file_bttn4 = WIDGET_BUTTON(file_menu, VALUE='Close window', event_pro ='plotIntensities_cleanupmenu', /SEPARATOR)
  ; other
  status = widget_label(tlb, value=' ', /dynamic_resize)
  ; 10/2011, added RETAIN=2 so the plot does not get cleared by other windows.
  draw = widget_draw(tlb, xsize=500, ysize=300, /motion_events, /button_events, event_pro='plotIntensities_draw', RETAIN=2)
  ; build the UI
  Widget_Control, tlb, /Realize
  ; get important information to communicate in the application
  Widget_Control, draw, get_value=w_id
  xmin = 0.
  xmax = 360.
  ymin = ydatamin
  ymax = ydatamax
  state = {nSets: nSets, nUsePeak: nPeaks, peakindex: usePeak, xdata: xdata, ydata: ydata, tlb: tlb, w_id:w_id, draw:draw, status:status, xlabel:xlabel, ylabel:ylabel, title: title, xmin:xmin, xmax:xmax, ymin:ymin, ymax:ymax, ydatamin: ydatamin, ydatamax:  ydatamax,sc_xmin:0.0, sc_xmax:0.0, sc_ymin:0.0, sc_ymax:0.0, scaling:0, legend: legend}
  ; create a pointer to the state structure and put that pointer
  ; into the user value of the top-level base
  pstate = ptr_new(state,/no_copy)
  widget_control, tlb, set_uvalue=pstate
  widget_control, draw, set_uvalue=pstate
  widget_control, file_bttn1, set_uvalue=pstate
  widget_control, file_bttn2, set_uvalue=pstate
  widget_control, file_bttn3, set_uvalue=pstate
  widget_control, file_bttn4, set_uvalue=pstate
  if (dynamic eq 1) then begin
    ; run a dynamic plot, if wanted
    plotIntensities_doplotdynamic, pstate, savemovie, filename
    ; close everything
    plotIntensities_cleanup, tlb
  endif else begin
    ; plot the data
    plotIntensities_doplot, pstate
    ; Register with XMANAGER so you can receive events.
    Widget_Control, tlb, Kill_Notify='plotIntensities_cleanup'
    xmanager, 'plotIntensities', tlb, event_handler='plotIntensities_resize', cleanup='plotIntensities_cleanup'
  endelse
end
