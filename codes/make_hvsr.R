#################################################################################################
#
# R script to calculate H/V spectral ratios from the New Zealand strong motion database flatfiles
#   Van Houtte, C., et al. (2017), The New Zealand Strong Motion Database, BNZSEE, 50(1), 1-20.
# 
# This script was used to aid with site classification in
#   Kaiser, A., et al. (2017), Site characterisation of GeoNet stations for the New Zealand
#   strong motion database, BNZSEE, 50(1), 39-49.
#
# This script requires downloading of the New Zealand strong motion database flatfiles from
#   http://info.geonet.org.nz/x/TQAdAQ
#
#################################################################################################
#
# Read in FAS flatfiles.
Hinname <- "NZdatabase_flatfile_FAS_horizontal_GeoMean.csv"
Vinname <- "NZdatabase_flatfile_FAS_vertical.csv"
horiz<-read.csv(Hinname, header=TRUE, row.names = NULL)
vert<-read.csv(Vinname, header=TRUE, row.names = NULL)

# Only use sites with at least five horizontal recordings
db.5sta<-0
for (j in 1:nrow(horiz)){
    if (sum(horiz$SiteCode == horiz$SiteCode[j])>=5){
      newrow = data.frame(horiz[j,], stringsAsFactors = FALSE)
      colnames(newrow)<-colnames(horiz) # make sensible headername
      db.5sta <- rbind(db.5sta, newrow) # add line to refined db
    }
}
db.5sta <- db.5sta[2:nrow(db.5sta),] # remove NA line
horiz.5sta <- db.5sta
sites <- as.character(horiz.5sta$SiteCode[!duplicated(horiz.5sta$SiteCode)])

# Calculate median and log standard deviation of HVSR, the save as XXXXdata.csv,
# where XXXX corresponds to the station code.
for (k in 1:length(sites)){
  horiz.site <- subset(horiz.5sta, horiz.5sta$SiteCode==sites[k])
  vert.site <- subset(vert, vert$SiteCode==sites[k])
  ip <- match(horiz.site$Record, vert.site$Record)
  useH <- subset(horiz.site, !is.na(ip))
  useV <- vert.site[ip, ]
  useV <- subset(useV, !is.na(useV$Record))

  ip <- match(useH$Record, useV$Record)
  V <- matrix(NA, nrow=length(ip), ncol=301)
  H <- matrix(NA, nrow=length(ip), ncol=301)
  HV <- matrix(NA, nrow=length(ip), ncol=301)
  # Initialise variables
  Vrec<-NA
  Hrec<-NA
  V[V<0]<-NA
  H[H<0]<-NA
  n <- 0
  medHV <- 0
  pl1HV <- 0
  mi1HV <- 0
  freq <- 10^seq(log10(0.1),log10(100),length=301)
  for (i in 1:length(ip)){
    # Change column numbers as necessary, this version uses 50:350 for the FAS amplitudes.
    V[i,] <- as.numeric(useV[i,50:350])
    H[i,] <- as.numeric(useH[ip[i],50:350])
    Vrec[i] <- as.character(useV$Record[i])
    Hrec[i] <- as.character(useH$Record[ip[i]])
  }
  for (i in 1:nrow(V)){
    HV[i,] <- H[i,]/V[i,]
  }
  for (j in 1:length(freq)){
    all <- HV[!is.na(HV[,j]), j]
    medHV[j] <- exp(median(log(all)))
    pl1HV[j] <- exp(log(medHV[j]) + sd(log(all)))
    mi1HV[j] <- exp(log(medHV[j]) - sd(log(all)))
    n[j] <- length(all)
  }
  # Save HVSR data to a csv file for plotting with gmt script.
  sta_data <- cbind(freq, medHV, pl1HV, mi1HV, n)
  outname<-paste0(sites[k], "data.csv")
  write.csv(sta_data, file = outname, row.names=F, na="0")
}
