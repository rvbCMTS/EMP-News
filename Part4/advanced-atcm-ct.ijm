// This macro analyzes Noise and Tube Current for a CT scan of the
// ... ATCM phantom
// The DICOM data was made available by Patrik Nowik
// See: Hacking Medical Physics Part1, EMP News, Winter 2021
// Or: https://bitbucket.org/DRPWM/code/src/master/chapter11/

// Open sequence of DICOM files (ATCM phantom)
run("Image Sequence...", "open=../Part1/Phantom");

// Save the current ImageJ settings
saveSettings;

// Redefine the metrics to be evaluated under "Analyze-Measure" 
run("Set Measurements...", "center stack redirect=None decimal=3");

// Get the start point z-axis position and calculate slice separation
setSlice(1);
Zref=1.0*getInfo("0020,1041");
setSlice(2);
Zinc=1.0*getInfo("0020,1041")-Zref;

// Duplicate the stack of image, convert to binary images
// Erosion and dilation with 5 iterations is performed to remove couch
run("Duplicate...", "duplicate");
run("Make Binary", "method=Default background=Default calculate black");
run("Options...", "iterations=5 count=1 black");
run("Erode", "stack");
run("Dilate", "stack");

// Calculate the centre-of-mass (COM) of the phantom
setSlice(nSlices/2); // Use middle slice
run("Measure"); // Get measurements on binary image
getPixelSize(unit, pw, ph, pd); // Get pixel size
// Calculate the COM in pixel units
xc=getResult("XM",0)/pw;
yc=getResult("YM",0)/ph;
close(); // Close the binary stack

// Clear the Results window
run("Clear Results");

// Move the selection back to the original stack
selectWindow("Phantom");

// Redefine the metrics to be evaluated under "Analyze-Measure" 
run("Set Measurements...", "standard stack redirect=None decimal=3");

// Get the radius in pixels for a 25 mm radius
Rpix=25/pw;

// Add a circle based on the COM and radius
makeOval(xc-Rpix, yc-Rpix, 2*Rpix, 2*Rpix);

// Create empty arrays
Noise = newArray(nSlices);
Pos = newArray(nSlices);
Tub = newArray(nSlices);
// Open a text file for saving output
f = File.open("atcm_output.txt")
print(f,"Z [mm] StDev [HU]"); // Print to text file

// Iterate through the stack
for (n=1; n<=nSlices; n++) {
    // Run Measure on slice n
   	setSlice(n);
    run("Measure");
    // Assign Noise (stdev), Position (z) and Tube Current (mA)
    // ... values to the arrays
    Noise[n-1]=getResult("StdDev",n-1);
    Pos[n-1]=getResult("Slice",n-1)*Zinc-Zinc+Zref;
    Tub[n-1]=1.0*getInfo("0018,1151");
    // Print Position and Noise to the text file
    print(f,d2s(Pos[n-1],3)+' '+d2s(Noise[n-1],3));
}

// Now we've finished calculation, restore setting to earlier snapshot
restoreSettings;

// Generate graphs
// Find max and min values for assigning axis limits 
PosSort = Array.copy(Pos)
Array.sort(PosSort);
PosMin=PosSort[0];
PosMax=PosSort[nSlices-1];
NoiseSort=Array.copy(Noise);
Array.sort(NoiseSort);
NoiseMax=NoiseSort[nSlices-1];
TubSort=Array.copy(Tub);
Array.sort(TubSort);
TubMax=TubSort[nSlices-1];
// Plot Noise against position
Plot.create("Image Noise", "Z-axis position [mm]", "Image noise [HU]");
Plot.setLimits(PosMin,PosMax , 0, NoiseMax+5);
Plot.setLineWidth(2);
Plot.setColor("lightGray");
Plot.setColor("blue");
Plot.add("circles", Pos,Noise);
Plot.show()
// Plot Tube Current against position
Plot.create("Tube Current", "Z-axis position [mm]", "Tube current [mA]");
Plot.setLimits(PosMin,PosMax , 0, TubMax+5);
Plot.setLineWidth(2);
Plot.setColor("lightGray");
Plot.setColor("red");
Plot.add("circles", Pos,Tub);
Plot.show();
