import spekpy as sp # Import the SpekPy toolkit
from matplotlib import pyplot as plt # Import a plotting library
from numpy import linspace, array, zeros, min, max # Import stuff from numpy 

print('\nStarting HVL calculations ... please be patient!\n')

## Define the tube potentials and thicknesses of Cu to be investigated
kVArr = linspace(50,120,15) # Array of kV values
tcuArr = array([ 0.1, 0.2, 0.3, 0.4, 0.6, 0.9]) # Array of Cu thicknesses

## Define tube parameters
tal = 3. # Thickness of aluminium filtration [mm]
theta = 12. # Anode angle [deg.]

## Define empty 2d array for outputs of calculations
nkV = len(kVArr) # Number of kV values
nCu = len(tcuArr) # Number of Cu thicknesses
hvl = zeros([nkV,nCu])

## Loop through tube potentials and filtrations and perform calculations
j=0 # Loop through tube potentials
for kV in kVArr: 
    i=0 # Loop through tube potentials
    for tcu in tcuArr:
        print('Calculating for {} kV and {} mm Cu'.format(kV,tcu),end='\r')
        filters=[('Al',tal),('Cu',tcu)] # Define filtration as tuples (air ignored)
        s = sp.Spek(kvp=kV,th=theta) # Generate spectrum model
        s.multi_filter(filters) # Apply total filtration
        hvl[j,i] = s.get_hvl1() # Get 1st half-value layer of incident spectrum [mm Al]
        i = i + 1 # Increment Cu thickness index
    j = j + 1 # Increment kV index

## The rest is plotting

## A figure with a half-value layer (HVL) contour plot
fig0, (ax0) = plt.subplots(nrows=1,ncols=1) # Generate a figure (single fig.)
levels = linspace(1,11,11) # Contour levels = 1, 2, ..., 11 mmAl 
for i in range(len(tcuArr)):
    ax0.plot(kVArr,hvl[:,i],label=str(round(tcuArr[i],1))+ ' mm')
ax0.legend(loc='upper left',ncol=1,fontsize=10,frameon=False)

## And axis labels to plots
ax0.set_xlabel('Tube potential [kV]',fontsize=10)
ax0.set_ylabel('HVL$_1$ [mm Al]',fontsize=10)
ax0.set_ylim([min(hvl)-1,max(hvl)+1])

## Optimize the plot layout
fig0.set_tight_layout(True)

## End message
print('\n\nFinished!')

## Display the plot
plt.show()
