; ***************************************************************************
; plot calibration and factor correction of the intensities (detectorintensity)
; plots Intensities as a function of image number or of deformation
;
; Caroline Bollinger, 10/01/11  (from fitLatticeStrainWindow.pro - S. Merkel)
; merged into main Polydefix code, S. Merkel, 19 oct 2011
; **************************************************************************
; Add the /STRAIN parameter to plot vs. strain, will plot vs. step otherwise
pro plotDetectorI, log, base, selected, referenceDet, STRAIN = st
common experimentwindow, set, experiment
common default, defaultdir

; Use Count to get the number of nonzero elements:
use = WHERE(selected, nUse)
;print, selected
;print, use
;print, nUse
IF (nUse eq 0) THEN return
; Setting up the legend
legend=strarr(nUse)
for i=0, nUse-1 do legend[i] = 'Fc('+experiment->getDetectorsName(use[i])+')'
; preparing arrays
n = experiment->getnumberDatasets()
x = fltarr(n) ; changed from intarr to fltarr to plot vs. def.
Ifactor = 1.0*fltarr(nUse,n)
Ifactor[*,*] = !VALUES.F_NAN
j = 0 ; ?????
progressBar = Obj_New("SHOWPROGRESS", message='Calculating Factor of Correction, please wait...')
progressBar->Start
for i=0,n-1 do begin
  x[i] = i+1
   ;IreferenceDet = experiment->getSumIDetref(i,referenceDet)   ;solution 1
  for k=0, nUse-1 do begin
    ; xx = experiment->getSumIDet(i,use[k])/IreferenceDet    ;solution 1
     xx = experiment->getFcIDet(i,use[k],referenceDet)      ;solution 2
      if ((abs(xx) eq !VALUES.F_INFINITY) or (fix(xx*1000000000) eq 0)) then Ifactor[k,i]=!VALUES.F_NAN else Ifactor[k,i]=xx
  endfor
  percent = 100.*i/n
  progressBar->Update, percent
endfor
xlabel = "Step number"
ylabel = 'Factor'
title = 'Factor of Correction vs. step number'
if KEYWORD_SET(st) then begin
  x = experiment->getStrains()
  xlabel = 'Strain'
  title = 'Factor of Correction vs. strain'
endif
progressBar->Destroy
Obj_Destroy, progressBar
; calling the plot window
plotinteractive1D, base, x, Ifactor, title=title , xlabel=xlabel, ylabel=ylabel, legend=legend
end


; ***************************************************************************
; CorrectIntensityTxt
; verbose calibration of the detectors
; for each diffraction pattern (or for all patterns: AllSteps, as a mean of the intensities):
;   -> Factor of correction (sum of intensities for all peaks for each detector
;   -> divided by the sum of intensities for all peaks for one reference detector)
;   -> prints the results in the log window
; **************************************************************************


pro detectorIntensityTxt, log, referenceDet
common experimentwindow, set, experiment
n = experiment->getnumberDatasets()
logit, log, "Starting Calibration of the Detectors"
logit, log, "For each step and each detector, sum of all peak intensities\n"
for i=0,n-1 do begin
  logit, log, "Step " + experiment->getDatasetName(i)
  logit, log, "Detector, Itot, Itot/Iref"
  logit, log, experiment->summaryDetectorIntensity(i,referenceDet)
endfor
logit, log, "Average calibration of the Detectors"
logit, log, "Detector, Itot, Itot/Iref"
logit, log, experiment->summaryDetectorIntensityAllSteps(referenceDet)
logit, log, "Finished..."
end

pro exportDetectorIntensityCSV, log, referenceDet
common experimentwindow, set, experiment
common default, defaultdir
result=dialog_pickfile(title='Save results as', path=defaultdir, DIALOG_PARENT=base, DEFAULT_EXTENSION='.csv', FILTER=['*.csv'], /WRITE, get_path = newdefaultdir)
if (result ne '') then begin
  defaultdir = newdefaultdir
  if (FILE_TEST(result) eq 1) then begin
    tmp = DIALOG_MESSAGE("File exists. Overwrite?", /QUESTION)
    if (tmp eq 'No') then return
  endif
  openw, lun, result, /get_lun
  text = experiment->summaryDetectorIntensityAll(referenceDet)
  printascii, lun, text
  free_lun, lun
endif
end

pro DetCalibWindow_event, ev
; Get the 'stash' structure.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval
CASE ev.id OF
  stash.input:
  else: begin
    WIDGET_CONTROL, stash.referenceDet, GET_VALUE=referenceDet
    CASE uval OF
    'REFINE': detectorIntensityTxt, stash.log, referenceDet
    'ASCII': exportDetectorIntensityCSV, stash.log, referenceDet
    'PLOTDetectorIntensity-VS-STEP': BEGIN
      WIDGET_CONTROL, stash.plotwhatDet, GET_VALUE=selected
      plotDetectorI, stash.log, stash.base, selected, referenceDet
    END
    'PLOTDetectorIntensity-VS-DEF': BEGIN
      WIDGET_CONTROL, stash.plotwhatDet, GET_VALUE=selected
      plotDetectorI, stash.log, stash.base, selected, referenceDet, /STRAIN
    END
    'DONE': WIDGET_CONTROL, stash.input, /DESTROY
    else:
    ENDCASE
  endcase
endcase
end


pro DetCalibWindow, base
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
input = WIDGET_BASE(Title='Factor of Correction for the Intensities', /COLUMN, GROUP_LEADER=base)
inputLa = WIDGET_LABEL(input, VALUE='Factor of Correction for the Intensities', /ALIGN_CENTER, FONT=titlefont)
fit = WIDGET_BASE(input, /ROW, FRAME=1)
; buttons1
buttons1 = WIDGET_BASE(fit,/COLUMN, /ALIGN_CENTER)
refine = WIDGET_BUTTON(buttons1, VALUE='Show details', UVALUE='REFINE')
export = WIDGET_BUTTON(buttons1, VALUE='Export to ASCII', UVALUE='ASCII')
plotDetectorI = WIDGET_BASE(buttons1,/COLUMN, /ALIGN_CENTER, /FRAME, XSIZE = 250)
detPanel = WIDGET_BASE(plotDetectorI,/ROW, /ALIGN_CENTER, /FRAME, XSIZE = 250)
values = experiment->getDetectorsNames()
referenceDet = CW_BGROUP(detPanel, values, /COLUMN, /EXCLUSIVE, LABEL_TOP='Reference detector', UVALUE='NOTHING', SET_VALUE=0)
plotwhatDet = CW_BGROUP(detPanel, values, /COLUMN, /NONEXCLUSIVE, LABEL_TOP='Detector to plot', UVALUE='NOTHING')
plotit1 = WIDGET_BUTTON(plotDetectorI, VALUE='Plot vs. step', UVALUE='PLOTDetectorIntensity-VS-STEP')
plotit2 = WIDGET_BUTTON(plotDetectorI, VALUE='Plot vs. def', UVALUE='PLOTDetectorIntensity-VS-DEF') 
; log
log = WIDGET_TEXT(fit, XSIZE=75, YSIZE=30, /ALIGN_CENTER, /EDITABLE, /WRAP, /SCROLL)
; buttons2
buttons2 = WIDGET_BASE(input,/ROW, /ALIGN_CENTER, /GRID_LAYOUT)
close = WIDGET_BUTTON(buttons2, VALUE='Close window', UVALUE='DONE')
stash = {base: base, input: input, log: log, plotwhatDet:plotwhatDet, referenceDet:referenceDet}
WIDGET_CONTROL, input, SET_UVALUE=stash
WIDGET_CONTROL, input, /REALIZE
XMANAGER, 'DetCalibWindow', input
end