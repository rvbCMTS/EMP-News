## Import utilities from standard libraries
from numpy import zeros, linspace, meshgrid, transpose, array # Import array stuff from NumPy 
from numpy import min, max, exp, log, round # Import maths stuff from NumPy
import matplotlib.pyplot as plt # Import PyPlot for plotting with matplotlib library
from dataclasses import dataclass # Import this feature for packaging up data neatly
## Import additional stuff from other libraries
import spekpy as sp # Import the SpekPy library for x-ray spectra calculations
from metrics import get_metrics # Import a function we have written

print('\nStarting more advanced calculations ... please be patient!\n')

## Define system parameters 
dperp = 65 # Focus-to-reference distance [cm]
sid = 100 # Focus to detector distance [cm]
pw = 10. # The pulse width/exposure time [ms]
dak = 0.025 # The detector air kerma (after grid) [uGy]
tal = 3. # Inherent filtration of x-ray tube [mmAl]

## Define material providing contrast
cm_name = 'Iodinated' # Contrast media name
composition='I' # Iodine specified by symbol
cm_density = 0.1 # Contrast density [g/cm^3 or equiv. gI/cc] 
sp.Spek.make_matl(matl_name=cm_name, matl_density=cm_density, 
    chemical_formula=composition) # This creates the material in the SpekPy database
tcm = 2. # Thickness of contrast material [mm]

## Define the background material
bg_name = 'Water' # Background material name
tbg = 250. # Thickness of background material [mm]

## Package input data into three dataclasses (for ease and neatness)
@dataclass
class spkModel: # dataclass containing spectrum parameters
    potl: float # Potential difference [kV]
    filt: list # Filtration (specified as list of tuples: see later)
    targ: str = 'W' # Target material ('W', 'Mo', or 'Rh')
    thet: float = 12. # Anode angle [degrees]
    effi: float = 1.0 # Efficiency of tube (output typically >70% of theory)
    phys: str = 'casim' # SpekPy physics model
@dataclass
class detModel: # dataclass containing detector parameters
    matl: str = 'Cesium Iodide' # Scintillator material (in SpekPy database)
    thid: float = 0.08 # Scintillator thickness [cm]
    dens: float = 4.51 # Scintillator density [g/cm^3]
    fill: float = 0.85 # Fill factor of detector 
    pixw: float = 0.02 # Pixel size of detector [cm]
    grid: bool = True # Whether grid is used
    tp: float = 0.75 # The primary transmission factor of the grid
    gain: float = 1. # Signal pixel value per keV deposited [keV^-2] (cancels out!)
@dataclass
class geoModel: # dataclass containing geometry parameters
    sid: float # Focus-to-detector distance [cm]
    dperp: float # Focus-to-reference distance [cm]
    tis1: float # Background tissue name
    tis2: float # Contrast materials name
    thi1: float # Thickness of background [mm] (Note mm not cm!)
    thi2: float # Thickness of contrast material [mm] (Note mm not cm!)

## Define the tube potentials and thicknesses of Cu to be investigated
kVArr = linspace(50,120,15) # Array of kV values
tcuArr = array([ 0.1, 0.2, 0.3, 0.4, 0.6, 0.9]) # Array of Cu thicknesses

## Define empty 2d arrays for outputs of calculations
nkV = len(kVArr) # Number of kV values
nCu = len(tcuArr) # Number of Cu thicknesses
contr = zeros([nkV,nCu])
noise = zeros([nkV,nCu])
cnr = zeros([nkV,nCu])
snr = zeros([nkV,nCu])
kar = zeros([nkV,nCu])
kad = zeros([nkV,nCu])
mas = zeros([nkV,nCu])
hvl = zeros([nkV,nCu])

## Loop through tube potentials and filtrations and perform calculations
j=0 # Loop through tube potentials
for kV in kVArr: 
    i=0 # Loop through tube potentials
    for tcu in tcuArr:
        print('Calculating for {} kV and {} mm Cu'.format(kV,tcu),end='\r')
        filters=[('Al',tal),('Cu',tcu)] # Define filtration as tuples (air ignored)
        spk = spkModel(potl=kV,filt=filters) # Create instance of spectrum dataclass
        det = detModel() # Create instance of detector dataclass
        geo = geoModel(sid=sid,dperp=dperp,tis1=bg_name,
            tis2=cm_name,thi1=tbg,thi2=tcm) # Create instance of spectrum dataclass
        # Get results using the imported get_metrics() function
        # Note that the three dataclasses are passed to the function along with
        # ... the value of detector air kerma (dak)
        contr[j,i], noise[j,i], cnr[j,i], snr[j,i], \
            kar[j,i], kad[j,i], mas[j,i], hvl[j,i]  \
            = get_metrics(spk, det, geo, kad = dak)
        i = i + 1 # Increment Cu thickness index
    j = j + 1 # Increment kV index


## The rest is plotting

# Create a figure for the subplots (Kad, mA, SNR^2/Kar, CNR^2/Kar)
fig1, ([[ax1,ax2],[ax3,ax4]]) \
    = plt.subplots(nrows=2,ncols=2) # Generate a figure with 2x2 subplots

# Generate Kar plot (reference air kerma) as 1st subplot
for i in range(len(tcuArr)): # Iterate through Cu thicknesses and plot
    ax1.plot(kVArr,kar[:,i],label=str(round(tcuArr[i],1))+ ' mm')
ax1.legend(loc='upper right',ncol=1,fontsize=10,frameon=False) # Add legend
ax1.set_ylim([min(kar)*0.5, max(kar)*2.]) # Set y-limits
ax1.set_yscale('log') # Make y-axis a log scale

# Generate mA plot (tube current) as 2nd subplot
mA = mas/(pw*1e-3) # Calculate mA based on mAs and pulse width/exposure time
for i in range(len(tcuArr)): # Iterate through Cu thicknesses and plot
    ax2.plot(kVArr,mA[:,i],label=str(round(tcuArr[i],1))+ ' mm')
ax2.plot([kVArr[0], kVArr[-1]],[100, 100],
    'k:',label='Tube limit') # Plot arbitrary tube limit
ax2.legend(loc='upper right',ncol=1,fontsize=10,frameon=False) # Add legend
ax2.set_ylim([min(mA)*0.5, max(mA)*2.]) # Set y-limits
ax2.set_yscale('log') # Make y-axis a log scale

# Generate SNR^2/Kar plot as 3rd subplot
FOM = snr**2/kar # Calculate SNR figure of merit
for i in range(len(tcuArr)): # Iterate through Cu thicknesses and plot
    ax3.plot(kVArr,FOM[:,i],label=str(round(tcuArr[i],1))+ ' mm')
ax3.legend(loc='lower right',ncol=1,fontsize=10,frameon=False) # Add legend
ax3.set_ylim([min(FOM)*0.5, max(FOM)*2.]) # Set y-limits
ax3.set_yscale('log') # Make y-axis a log scale

# Generate CNR^2/Kar plot as 4th subplot
FOM = cnr**2/kar
for i in range(len(tcuArr)): # Iterate through Cu thicknesses and plot
    ax4.plot(kVArr,FOM[:,i],label=str(round(tcuArr[i],1))+ ' mm')
ax4.legend(loc='upper right',ncol=1,fontsize=10,frameon=False) # Add legend
ax4.set_ylim([min(FOM)*0.5, max(FOM)*2.0]) # Set y-limts
ax4.set_yscale('log') # Make y-axis a log scale

## Add titles to plots
ax1.set_title('K$_{a,d}$ = '+str(dak)+' $\mu$Gy',fontsize=10)
ax2.set_title('K$_{a,d}$ = '+str(dak)+' $\mu$Gy; pw = '+str(pw)+' ms',fontsize=10)
ax3.set_title('Background signal: '+str(tbg)+' mm '+bg_name,fontsize=10)
ax4.set_title(cm_name+' contrast: '+str(tcm)+' mm, '+str(cm_density)+' g/cc',fontsize=10)

## Add overall figure title (gets messy!)
if det.grid:
    fig1.suptitle('Calculations for: ' + str(tbg) + ' mm patient (' + bg_name + '); ' \
        + str(tcm)+' mm of '+ cm_name + ' contrast ('+ str(cm_density) \
        + ' g/cc);\nK$_{a,d}$ = ' + str(dak) +' $\mu$Gy/fr; ' + str(pw) \
        + ' ms pulse width; d$_{PERP}$ = ' + str(dperp) + ' cm; SID = ' \
        + str(sid) + ' cm; grid present (T$_p$ = ' + str(det.tp) + ')', fontsize=10)
else:
    fig1.suptitle('Calculations for: '+ str(tbg) + ' mm patient (' + bg_name + '); ' \
        + str(tcm) + ' mm of ' + cm_name + ' contrast (' + str(cm_density) \
        +' g/cc);\nK$_{a,d}$ = ' + str(dak) + ' $\mu$Gy/fr; ' + str(pw) \
        + ' ms pulse width; d$_{PERP}$ = '+ str(dperp) + ' cm; SID = ' \
        + str(sid) + ' cm; grid absent', fontsize=10)

## And axis labels to plots
ax1.set_xlabel('Tube potential [kV]',fontsize=10)
ax1.set_ylabel('K$_{a,r}$ [$\mu$Gy]',fontsize=10)

ax2.set_xlabel('Tube potential [kV]',fontsize=10)
ax2.set_ylabel('Tube current [mA]',fontsize=10)

ax3.set_xlabel('Tube potential [kV]',fontsize=10)
ax3.set_ylabel('SNR$^2$/K$_{a,r}$ [$\mu$Gy$^{-1}$]',fontsize=10)

ax4.set_xlabel('Tube potential [kV]',fontsize=10)
ax4.set_ylabel('CNR$^2$/K$_{a,r}$ [$\mu$Gy$^{-1}$]',fontsize=10)

## Optimize the plot layout
fig1.set_tight_layout(True)

## End message
print('\n\nFinished!')

## Display the plot
plt.show()
