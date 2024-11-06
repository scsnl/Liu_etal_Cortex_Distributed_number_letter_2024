library("ggplot2")
library("BayesFactor")
library("tidyr")
library("dplyr")

# RSA results
setwd('<path to ROI based rsa read out files>')
Ansari_rsa_roi = read.csv2("<file name: eg., D-SD_VS_L-SL_rsa_Ansari_short.csv>",header=T,sep=',')
ttestBF(
  x = as.numeric(Ansari_rsa_roi$Left_AG),
  mu=0
)

setwd('<path to ROI based rsa read out files>')
Stanford_rsa_roi = read.csv2("file name: eg., letter-ctr_VS_numeral-ctr_rsa_scsnl_short.csv",header=T,sep=',')
ttestBF(
  x = as.numeric(Stanford_rsa_roi$Left_AG),
  mu=0
)


