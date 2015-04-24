# PolydefixED

© Sébastien Merkel, Université Lille 1, France  
Since June 2011, polydefix is open source software, licensed under the GPL Version 2.  
Multifit/Polydefix homepage is at http://merkel.zoneo.net/Multifit-Polydefix/

## Multifit/Polydefix

Multifit/Polydefix is an open-source IDL software package for an efficient 
processing of diffraction data obtained in deformation apparatuses at 
synchrotron beamlines. Multifit allows users to decompose two-dimensional 
diffraction images into azimuthal slices, fit peak positions, half-widths, 
and intensities, and propagate the results to other azimuth and images. 
Polydefix is for analyzes of deformation experiments. Starting from 
output files created in Multifit or other packages, it will extract elastic 
lattice strains, evaluate sample pressure and differential stress,
and prepare input files for further texture analysis.

Multifit/Polydefix homepage is at http://merkel.zoneo.net/Multifit-Polydefix/

## About PolydefixED

PolydefixED is for lattice strains, pressure, stress, and texture analysis for experiments in energy dispersive geometry. 
It will start from the output iles created in Multifit and extract the information required
for establishing the rheological behavior of the sample.

Multifit/Polydefix is written in the Interactive Data Language (IDL) provided 
by Exelis Visual Information Solutions (Boulder, Colorado). It is an 
open-source software package, licensed under GNU General Public License that 
runs within the IDL Virtual Machine, as provided at no-cost by Exelis Visual 
Information. It will run on any platform with an IDL Virtual Machine,
Windows, OS X, Linux, and Solaris. The IDL Virtual Machine does not require a 
license to run. An IDL license is required, however, for developing, compiling, 
and adding new features.

## Development with IDL

IDL comes with a complex eclipse-based development environment in a graphical user 
interface (gui) for editing projects. Over the years the gui became more and more 
complex. It is a complete overkill for what we are doing here. Moreover, each upgrade 
of IDL comes with technical issues and, recently, it simply stopped working on my 
computers. Therefore, I decided to completely quit using the IDL gui for developing 
applications and develop multifit/polydefix in text mode only. You are welcome to try 
using the gui if you want, but I will not help you with it. 

## Compiling, editing, and playing with the code

Once you downloaded the latest version of the code, you can simply open the 
files in your favorite text editor. I use kate, one of the KDE text editor. 
It does have a specific mode for coloring IDL codes (select Tools -> Highlighting 
-> Sources -> RSI IDL).

To compile and run the code, you should move into the folder with your source, 
start IDL in the command line, and type `@build`:
```
  cd ~/IDL/Polydefix
  idl
  @build
```
You can then test your changes by typing
```
  polydefix
```
in the command line. It will start the latest version you compiled.

Once you're done, if you want to quit IDL, simply type `exit` in the IDL command line.

I do not recommend the IDL development environment. On the other hand, the online help 
is extremely helpful. To start the help from the command line, simply type idlhelp. 

## File descriptions


*****************************************************
Build
*****************************************************
Build instructions are in file "build"
To build, type 
	@build
in IDL command prompt.

*****************************************************
UI Components
*****************************************************

- main.pro
	program start, calls experimentWindow.pro
- experimentWindow.pro
	main UI
	functions to set the wavelength, fit files, set HKL planes, show about...
- fitLatticeStrainsWindow.pro
	UI and functions to test lattice strains fits
- fitPressureWindow.pro
	UI and functions to test pressure fits
- fitUnitCellWindow.pro
	UI and functions to test cell parameters fits
- materialWindow.pro
	UI and function to set material properties (name, symmetry, EOS, elasticity)
- plotinteractive1D.pro
	UI to have a plot
- plotTestLatticeStrains.pro
	UI that with the lattice strain tests
- showprogress.pro
	UI for a progress bar
- diffIntensityWindow.pro
	UI for intensity vs. orientation for diffent images
- diffIntensityWindow2.pro
	UI for intensity vs. image for diffent orientations

*****************************************************
Data classes
*****************************************************

- experimentObject.pro
	Main experiment data: where is it stored, wavelength, material, and all functions
	to work on it
- materialObject.pro
	Material data + functions on EOS and elasticity
- unitCellObject.pro
	unit cell function, get dhkl or volumes from unit cell parameters
- fitPatternObject.pro
	holds all fitSubPatternObject objects, knows how to fit lattice strains equations
- fitSubPatternObject.pro
	holds data for one subpattern (2theta, intensity vs azimuth and such) 
- latticestrainObject.pro
	holds a lattice strain fit

*****************************************************
Utils
*****************************************************

- fdecomp.pro
- func.gui.pro
- func.pro
- latticeStrainMultiplePeaksCenter.pro
	equations for lattice strain fits with center correction, called from a fitPatternObject
- latticestrain.pro
	equations for for lattice strain fits with NO center correction, called from a fitSubPatternObject
- line.pro
	other type of lattice strain fits, not called
- mpfitfun.pro
	non linear fitting
- mpfit.pro
	non linear fitting
