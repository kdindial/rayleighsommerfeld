;+
; NAME:
;    rs1d
;
; PURPOSE:
;    Computes Rayleigh-Sommerfeld back-propagation of
;    a normalized hologram along a specified axial line.
;
; CATEGORY:
;    Holographic microscopy
;
; CALLING SEQUENCE:
;    b = rs1d(a, z, rc)
;
; INPUTS:
;    a: hologram recorded as image data normalized
;        by a background image. 
;    z: displacement from the focal plane [pixels]
;        If z is an array of displacements, the field
;        is computed at rc for each height.
;    rc: [x,y] coordinates of center along which to compute
;        back-propagation [pixels]
;
; KEYWORDS:
;    lambda: Wavelength of light in medium [micrometers]
;        Default: 0.632 -- HeNe in air
;    mpp: Micrometers per pixel
;        Default: 0.135
;
; OUTPUTS:
;     b: complex field along line passing through rc in the plane
;        of the hologram.
;
; REFERENCES:
; 1. S. H. Lee and D. G. Grier, 
;   "Holographic microscopy of holographically trapped 
;   three-dimensional structures,"
;   Optics Express, 15, 1505-1512 (2007).
;
; 2. J. W. Goodman, "Introduction to Fourier Optics,"
;    (McGraw-Hill, New York 2005).
;
; 3. G. C. Sherman,
;   "Application of the convolution theory to Rayleigh's integral
;   formulas,"
;   Journal of the Optical Society of America 57, 546-547 (1967).
;
; PROCEDURE:
;    Convolution with Rayleigh-Sommerfeld propagator using
;    Fourier convolution theorem.
;
; MODIFICATION HISTORY:
; 06/22/2012 Written by David G. Grier, New York University
; 07/16/2012 DGG Correct floating point underflow errors
;
; Copyright (c) 2012 David G. Grier
;-
function rs1d, a, z, rc, $
               delta = delta, $
               lambda = lambda, $         ; wavelength of light
               mpp = mpp                  ; micrometers per pixel

COMPILE_OPT IDL2

umsg = 'USAGE: b = rs1d(a, z, rc)'
if n_params() ne 3 then begin
   message, umsg, /inf
   return, -1
endif

; hologram
if ~isa(a, /number, /array) then begin
   message, umsg, /inf
   message, 'a must be a numeric array', /inf
   return, -1
endif
sz = size(a)
ndim = sz[0]
if ndim ne 2 then begin
   message, umsg, /inf
   message, 'a must be two-dimensional', /inf
   return, -1
endif

nx = float(sz[1])
ny = float(sz[2])

; axial samples
if ~isa(z, /number) then begin
   message, umsg, /inf
   message, 'z must be a numeric data type', /inf
   return, -1
endif
nz = n_elements(z)              ; number of z planes

if ~isa(rc, /number, /array) || n_elements(rc) ne 2 then begin
   message, umsg, /inf
   message, 'rc must be a two element numeric array', /inf
   return, -1
endif

; parameters
if ~isa(lambda, /number, /scalar) then $
   lambda = 0.632               ; HeNe laser in air
if ~isa(mpp, /number, /scalar) then $
   mpp = 0.135                  ; Nikon rig

ci = complex(0., 1.)
k = 2.*!pi*mpp/lambda           ; wavenumber in radians/pixel

; phase factor for Rayleigh-Sommerfeld propagator in Fourier space
; Refs. [2] and [3]
qx = (2.*!pi/nx) * findgen(nx) - !pi
qy = (2.*!pi/ny) * findgen(1, ny) - !pi

qsq = rebin((qx/k)^2, nx, ny) + rebin((qy/k)^2, nx, ny)     ; (q/k)^2
qrc = rebin(rc[0] * qx, nx, ny) + rebin(rc[1] * qy, nx, ny) ; \vec{q} \cdot \vec{r}_c

qfac = k * sqrt(complex(1. - qsq)) - k ; \sqrt(k^2 - q^2) - k
ikappa = ci * real_part(qfac)
gamma = imaginary(qfac)
limit = abs(alog((machar()).eps))     ; largest exponent retaining precision

b = fft(complex(a - 1.), -1, /center) ; Fourier transform of input field
b *= exp(ci*qrc)                      ; center on rc
res = complexarr(nz, /nozero)
for j = 0, nz-1 do begin
   gz = gamma * abs(z[j])
   mask = gz lt limit
   gz *= mask
   Hqz = mask * exp(ikappa * z[j] - gz)
   res[j] = total(b * Hqz)
endfor

return, res

end