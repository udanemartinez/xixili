#++++++++++++++++++++++++++++++++++
# Precesado datos acusticos Glider
#++++++++++++++++++++++++++++++++++

#  creado por Udane Martinez 28/03/2023


# this script is for processing the simplified 8-bin glider data.
# these data were obtained during the Juvena 22 survey in the intensive radial of Bermeo.
# to obtain the Sv value of the 5 m sow we apply the formula of the article by Guihen et al.
# "Measurement of zooplankton from a glider".
#  the formula is:

# Sv =  RBV + 20 log R + 2 α R - (RR + SL) - 10* log ct/2 - 10 * log EBA -  C -  g

# where R is range (m), 
# RBV is the recorded count (20log10[signal level/1V peak-peak]), 
# RR is the transducer receiving (dB re 1 V/μPa), 
# and SL is the transducer source level(dB re 1 μPa at 1m) supplied by the manufacturer, 
# α is the absorption coefficient (dB m–1), 
# c is sound velocity (m s–1), 
# τ is pulse length (s), 
# EBA is the equivalent beam angle (steradians),
# C is a constant calculated during the calibration of the echosounder, 
# and g is the gain (dB)

#  Eba calculated aplication by information in
# A General Guide for Deriving Abundance Estimates from Hydroacoustic Data in website
# http://www2.dnr.cornell.edu/acoustics/AcousticBackground/SONARequation.html
# EBA = 10 * Log (Ψ)
# Ψ = 5.78/(Ka)^2
# a = 1.6/(k*sin(θ3dB/2)) where θ3dB is the value of BeamWidth = 10 from manufacturer
# k is the wave number [k=2π/λ] 
# and λ is the wavelength (m).


# 0. Load libraries and input data --------------
#++++++++++++++++++++++++++++++++++++++++++++++++

library(dplyr)
library(tidyr)
library(ggplot2)
library(tidyverse)  # incluye stringr
library(broom)  # tidy regressions
library(R.matlab)


# read data files:
# dir("datos/Datos_mission_24")
lista.archivos <- list.files("datos/Datos_mission_24", pattern = ".raw")  # terminados en ".raw"


#+++++++++++++++++++++++++++++++++++++++++++++
# 1. Unir archios en uno ---------------------
#+++++++++++++++++++++++++++++++++++++++++++++
# bucle para que abra archivos y los guarde uno detras de otro

i <- 1
for (i in seq_along(lista.archivos)){
  nombre <- lista.archivos[i]
  ruta <- paste("datos/Datos_mission_24", nombre, sep = "/")
  archivo <- read.delim(file = ruta,  header = TRUE, sep = ";" )
  write_csv(x = archivo, path = "datos/Glider.csv", na = "NA", append = T, 
            col_names = ifelse(i == 1, T, F))
  print(paste(i, length(lista.archivos), sep = "/"))

}

rm(archivo)
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# 2. Cargar archivo creado y añadirle valores para el calculos Sv ------------
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


all <- read.delim(file = "datos/Glider.csv", header = TRUE, sep = "," )

all <- all %>% 
  dplyr::mutate(
    date = stringr::str_sub(PLD_REALTIMECLOCK, start = 1, end = 10),
    hour = stringr::str_sub(PLD_REALTIMECLOCK, start = 12, end = -1),
    BeamWidth = 10 ,#from manufacturer
    SL = 210 , #from manufacturer
    RR = 180 ,#from manufacturer
    Pulse = 100 ,#from manufacturer
    C = 0 ,#calibration parameter
    g = 20 ,#gain
    alpha = 38.7 ,#absortion coeficiente based in simmons for 10º t and 35 salinity
    Lambda = 1500/120000 ,#sound velocity anf frecuency of transducer
    k = (2*pi)/Lambda ,#to calculate EBA
    a = 1.6/(k*sin((BeamWidth/2))), #to calculate EBA
    psi = 5.78/((k*a)^2),#to calculate EBA
    EBA = 10*log10(psi)
  )

#++++++++++++++++++++++++++++++++++++++++++++++++++++++
# 3. añadir posiciones del Glider ---------------------
#++++++++++++++++++++++++++++++++++++++++++++++++++++++
# he creado una tabla de matlab solo con los valores de latitud y longitud que calculo Ivan
Matdata <- R.matlab::readMat("datos//RAW_data_POS_CORRECTED_uda.mat")
# se cargan los datos matlab como lista y los paso a dataFrame
Glider_position<- dplyr::as_tibble(Matdata)
rm(Matdata)

#  Join the tables of position calculated By Ivan Manso in Matlab File
all_position <- all %>% 
  dplyr::bind_cols(Glider_position) 

#++++++++++++++++++++++++++++++++++++++++++++++++++++++
# 4. Calcular Sv por celdas---------------------
#++++++++++++++++++++++++++++++++++++++++++++++++++++++












