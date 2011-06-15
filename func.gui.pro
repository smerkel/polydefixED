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

; ****************************************** changeDir *********************************
PRO changeDir, base, widget
WIDGET_CONTROL, widget, GET_VALUE=start
if (start eq '') then begin 
	result=dialog_pickfile(/DIRECTORY,title='Select directory', path=GETENV('HOME'), DIALOG_PARENT=base)
endif else begin
	result=dialog_pickfile(/DIRECTORY,title='Select directory', path=start, DIALOG_PARENT=base)
endelse
if (result ne '') then begin
    directory = result
    WIDGET_CONTROL, widget, SET_VALUE=directory
endif
END


; ****************************************** REALLYQUIT *********************************

PRO reallyquit, widget
	tmp = DIALOG_MESSAGE("Really quit?", /QUESTION)
	if (tmp eq 'No') then return
    WIDGET_CONTROL, widget, /DESTROY
end

; ******************************************************************
; Saves and reads basic information about multifit in hidden file for future
; uses
;

function readDefaultFile
common default, defaultdir
defaultdir = GETENV('HOME')
; If we are using UNIX, try to see if we saved a default file
if (STRUPCASE(!VERSION.OS_FAMILY) eq 'UNIX') then begin
	default = GETENV('HOME') + "/" + ".polydefixED"
	if (file_test(default)) then begin
		openr, lun, default, /get_lun
		while ~ EOF(lun) do begin
			row = ""
			readf, lun, row
			word = strsplit(row, COUNT=nn, /EXTRACT)
			if (nn gt 1) then begin
				label = STRUPCASE(word[0])
				CASE label OF
					"WORK_DIRECTORY:": defaultdir = word[1]
					else:
				endcase
			endif
		endwhile
		free_lun, lun
	endif else begin
		openw, lun, default, /get_lun
		printf, lun, '# Default information for stresstrain'
		free_lun, lun
	endelse
endif
return, defaultdir
end

pro setDefaultFileItem, item, value
if (STRUPCASE(!VERSION.OS_FAMILY) eq 'UNIX') then begin
	default = GETENV('HOME') + "/" + ".polydefixED"
	if (file_test(default)) then begin
		str = ""
		done = 0
		openr, lun, default, /get_lun
		while ~ EOF(lun) do begin
			row = ""
			readf, lun, row
			word = strsplit(row, COUNT=nn, /EXTRACT)
			label = STRUPCASE(word[0])
			CASE label OF
				item: begin
					str = str + item + " " + value + "|"
					done = 1
				end
				else: str = str + row + "|"
			endcase
		endwhile
		free_lun, lun
		if (done eq 0) then str = str + item + " " + value + "|"
		; print, "Trying to write " + str
		openw, lun, default, /get_lun
		word = strsplit(str, "|", COUNT=nn, /EXTRACT)
		for i=0,nn-1 do printf, lun, word[i]
		free_lun, lun
	endif
endif
end

pro setDefaultWorkDir, dir
setDefaultFileItem, "WORK_DIRECTORY:", dir
end

; ****************************************** LOAD_DEFAULTS *********************************

PRO load_defaults
common fonts, titlefont, boldfont, mainfont
; default color palette
OS   = strupcase(!VERSION.OS)
OS   = strmid(OS,0,3)
if (OS ne 'WIN') then device, true_color=24
device, decomposed=0
loadct, 15
; Directory
test = readDefaultFile()
; Fonts
if (OS ne 'WIN') then begin
	mainfont = '-*-courier-medium-r-*-*-12-*-*-*-*-*-*-*'
	titlefont = '-*-helvetica-bold-r-*-*-18-*-*-*-*-*-*-*'
	boldfont = '-*-helvetica-bold-r-*-*-12-*-*-*-*-*-*-*'
endif else begin
	titlefont = 'helvetica*bold*18'
	boldfont = 'helvetica*bold*12'
	mainfont = 'helvetica*12'
endelse
end

; ****************************************** READEXPFROMASCII *********************************

FUNCTION readExpFromAscii, base, log
common default, defaultdir
testExp = OBJ_NEW('experimentObject')
testExp->setTmp, 0
result=dialog_pickfile(title='Select experiment file', path=defaultdir, DIALOG_PARENT=base, DEFAULT_EXTENSION='.exp', FILTER=['*.exp','*.txt','*.csv','*.*'], /READ)
if (result ne '') then begin
 	FDECOMP, result, disk, dir, name, qual, version
 	logit, log, "Reading experiment data from " + result
 	defaultdir = disk+dir
 	setDefaultWorkDir, defaultdir
 	openr, lun, result, /get_lun
 	a = testExp->readFromAscii(lun, log)
 	free_lun, lun
 	if (a ne 1) then begin
 		tmp = DIALOG_MESSAGE("Error: " + a, /ERROR)
 		logit, log, "\tFailed!\n"
 		return, testExp
 	endif
 	testExp->setTmp, 1
 	logit, log, "\tSuccessful!\n"
 	return, testExp
 endif
return, testExp
END

; ****************************************** LOGIT *********** *********************************

PRO logit, log, txt
row = strsplit(txt, '\\n', /extract, /REGEX, /PRESERVE_NULL)
for i=0, N_ELEMENTS(row)-1 do begin
	col = strsplit(row[i], '\\t', /extract, /REGEX, /PRESERVE_NULL )
	text = ""
	for j=0, N_ELEMENTS(col)-1 do begin
		text += col[j]
		if (j lt N_ELEMENTS(col)-1) then text += "    "
	endfor
	WIDGET_CONTROL, log, SET_VALUE=text, /APPEND
endfor
END
