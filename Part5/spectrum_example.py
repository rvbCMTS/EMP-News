import spekpy as sp # Import the SpekPy toolkit
from matplotlib import pyplot as plt # Import a plotting library

# Generate unfiltered spectrum. Tube pot’l: 80 kV, anode angle: 12 deg.
s=sp.Spek(kvp=80,th=12)
# Filter the spectrum (3 mm Al, 0.1 mm Cu)
s.filter('Al',3.0).filter('Cu',0.1)
# Get energy values and fluence arrays (return values at bin-edges) and plot
k, f = s.get_spectrum(edges=True)
plt.plot(k, f)

# Add axis labels and title
plt.xlabel('Energy [keV]')
plt.ylabel('Differential fluence at 1 m' + 
    ' [photons$\cdot$cm$^{-2}$$\cdot$keV$^{-1}$$\cdot$mAs$^{-1}$]')
plt.title('An example x-ray spectrum')

# Show the figure
plt.show()

# When you close the figure the next snippet will run
hvl1 = s.get_hvl1() # 1st half-value layer for default material [mm Al]
hvl2 = s.get_hvl2(matl='Cu') # 2nd half-value layer for copper [mm Cu]
ftot = s.get_flu() # Total photon fluence at 1 m [cm^-2 mAs^-1]
ka = s.get_kerma() # Air kerma at 1 m [uGy mAs^-1]
print(hvl1, hvl2, ftot, ka) # Print the results to screen

# Or to limit decimal places printed (floating pt & exponential notation)
print("{:.2f} {:.2f} {:.4e} {:.2f}".format(hvl1, hvl2, ftot, ka))
