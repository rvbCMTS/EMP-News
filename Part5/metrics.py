import spekpy as sp # Import the SpekPy library for spectral calculations
from numpy import exp, sum, sqrt # import maths stuff from numpy

## Get attenuation coeff. data from SpekPy
MuData = sp.Spek().mu_data 

## function to return metrics for a specified tube, detector and geometry
def get_metrics(spk, det, geo, mas = None, kad = None, kar = None):
    """
    A function to calculate the outputs:
      contr; type, float; image contrast
      noise; type, float; image noise
      cnr; type, float; contrast-to-noise
      snr; type, float; signal-to-noise in background
      kar; type, float; reference air kerma
      kad; type, float; detector air kerma
      mas; type, float; electron charge (mAs)
      hvl; type, float; 1st half-value layer in mm Al 

    given the inputs:
      spk; type, spkModel dataclass; x-ray tube parameters
      det; type, detModel dataclass; detector parameters
      geo; type, geoModel dataclass; geometry parameters
    and (one of the following must be specified):
      mas; type, float; electron charge
      kad; type, float; detector air kerma
      kar; type, float; reference air kerma

    """

    # Check the spectrum normalization inputs
    if mas is not None and kad is None and kar is None:
        pass
    elif mas is None and kad is not None and kar is None:
        pass
    elif mas is None and kad is None and kar is not None:
        pass
    else:
        raise Exception("Please specifiy one of: mAs, kad or kar")

    # Apply the anti-scatter grid imputs
    if det.grid:
        tp = det.tp
    else:
        tp = 1.0

    # Define a detector element area
    a = det.pixw**2

    # Generate spectrum model for prior to patient
    s = sp.Spek(kvp=spk.potl,th=spk.thet,physics=spk.phys,targ=spk.targ)
    s.multi_filter(spk.filt) # Apply filtration

    # Get x-ray bin energies and bin width
    k = s.get_k()
    dk = k[1]-k[0]

    # Get mass attenuation coefficient for detector material
    mu_over_rho, rho = \
        MuData.get_mu_over_rho_composition(det.matl,k)

    # Estimate the quantum efficiency of detector
    # (assumes everything removed from the primary beam is absorbed)
    alpha = 1. - exp(-mu_over_rho*det.thid*det.dens)

    # Clone the incident spectrum and filter by the background tissue
    sb = sp.Spek.clone(s)
    sb.filter(geo.tis1,geo.thi1)

    # Clone the incident spectrum and filter by the signal tissue set
    ss = sp.Spek.clone(s)
    ss.filter(geo.tis1,geo.thi1-geo.thi2)
    ss.filter(geo.tis2,geo.thi2)

    # Determine mAs based on specified value (mAs, DAK or RAK)
    if kar is not None:
        kar_1mas = s.get_kerma(z=geo.dperp)*spk.effi
        mas = kar/kar_1mas
    elif kad is not None:
        kad_1mas = tp*sb.get_kerma(z=geo.sid)*spk.effi
        mas = kad/kad_1mas
    elif mas is not None:
        pass

    # Get the spectrum reaching detector after passing through background
    k, phib_k = sb.get_spectrum(z=geo.sid,mas=mas)

    # Apply the grid transmission and efficiency to background spectrum
    phib_k = tp*spk.effi*phib_k

    # Get the spectrum reaching detector after passing contrast signal
    k, phis_k = ss.get_spectrum(z=geo.sid,mas=mas)

    # Apply the grid transmission and efficiency to signal spectrum
    phis_k = tp*spk.effi*phis_k

    # Detector value (background)
    sigb = det.gain*det.fill*a*sum(phib_k*alpha*k)*dk

    # Detector value (contrast signal)
    sigs = det.gain*det.fill*a*sum(phis_k*alpha*k)*dk

    # Detector variance (background)
    varb = (det.gain**2)*det.fill*a*sum(phib_k*alpha*k**2)*dk
    
    # Detector relative noise (background)
    noise = sqrt(varb)/sigb

    # Relative contrast
    contr = (sigb-sigs)/sigb

    # Contrast-to-noise ratio (CNR)
    cnr = contr/noise

    # Background signal-to-noise (SNR)
    snr = sigb/sqrt(varb)

    # Reference air kerma at dperp [uGy]
    kar = s.get_kerma(z=geo.dperp,mas=mas)*spk.effi

    # Detector air kerma [uGy]
    kad = tp*sb.get_kerma(z=geo.sid,mas=mas)*spk.effi

    # 1st half-value layer of incident spectrum [mm Al]
    hvl = s.get_hvl1()

    return contr,noise,cnr,snr,kar,kad,mas,hvl

