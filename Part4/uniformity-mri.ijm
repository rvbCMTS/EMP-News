// This macro calculates the Uniformity for an example slice of the ACR MRI 
// ... accreditation phantom
// The DICOM data was made available by Sven Månsson:
// https://bitbucket.org/DRPWM/code/src/master/chapter17/

// To run this script in headless mode (without displaying ImageJ) you can
// ... use something like the following at the command line:
// ImageJ --headless -macro uniformity-mri.ijm
// where "ImageJ" Should be replaced with name of or path to ImageJ on
// .. your system 

// Choose the parameters to be returned by the "Analyze-Measure" command
run("Set Measurements...", "area mean min center redirect=None decimal=3");

// Open a DICOM MRI image
open("ACR_MRI_Phantom/RFA_ACRfantom_1_2018-08-03_SM1_20180803_ser0012_000007.ima");

// Get study date by dicom tag
studyDate=getInfo("0008,0020");

// Make a copy of image
run("Duplicate...", " ");

// Convert duplicate to a binary image ("Process-Binary-Make binary")
setOption("BlackBackground", true);
run("Convert to Mask");
// Fill in any holes in the binary image (value 0 or 255)
run("Fill Holes");

// Calculate measurments on the binary image ("Analyze-Measure")
run("Measure");
// Get the area from the measurements
Area=getResult("Area",0);
// Get the mean grayscale value
Mean=getResult("Mean",0);
// Get the pixel size
getPixelSize(unit, pw, ph, pd);
// Calculate the center-of-mass in pixel units
xc=getResult("XM",0)/pw;
yc=getResult("YM",0)/ph;
// Calculate the effective radius of the cylinder in pixels
Rad=sqrt((Mean/255)*(Area/(pw*ph))/PI);

// Move selection back to the original MRI image
selectWindow("RFA_ACRfantom_1_2018-08-03_SM1_20180803_ser0012_000007.ima");

// Apply a 3x3 median filter to the image (equiv. to 1.0 radius)  
run("Median...", "radius=1.0");

// Place a circular ROI at the COM with 65% the area of the phantom
Rad65=sqrt(0.65)*Rad
makeOval(xc-Rad65, yc-Rad65, 2*Rad65, 2*Rad65);

// Calculate measurements on the ROI
run("Measure");
// Get minimum and maximum value in the ROI
n=nResults; // Number of rows
Min=getResult("Min",n-1); // Note: indexing starts at zero, i.e., n-1 is last row
Max=getResult("Max",n-1);
// Calculate the Uniformity
Uni=100*(1-(Max-Min)/(Max+Min));

// Save data to a text file
f = File.open("uniformity_output.txt")
print(f,"Study date [yyyymmdd]: "+studyDate);
print(f,"Phantom radius [pixel]: "+d2s(Rad,3));
print(f,"Phantom centre [pixel]: "+d2s(xc,3)+" "+d2s(yc,3));
print(f,"Uniformity [%]: "+d2s(Uni,3));
// Print Uniformity to log window (or screen if run headless)
print("Study date [yyyymmdd]:",studyDate);
print("Phantom radius [pix]:",d2s(Rad,3));
print("Phantom centre [pix]:",d2s(xc,3)+" "+d2s(yc,3));
print("Uniformity [%]:",d2s(Uni,3));

// Infer if in headless mode. Exit ImageJ if true
if (nResults==1) {
    eval("script", "System.exit(0);");
}
