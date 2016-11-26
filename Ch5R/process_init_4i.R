############################################################################################################
#load the nlme package
library(nlme)
library(plyr)
library(data.table)
library(psych)
############################################################################################################
#Integrate data from AWARE database:
variable_names <- c("dep", "indep", "third")
AWARE <- db
# omit ids: less then 9 answers at boredom - balanced (change)
omit_id <- c()#c(56,42,39,6) 

arousal_0 <- 0
arousal_1 <- 2

# calculate new variables with database (change)
#third:################################################################################################
# gender
AWARE$gender <- setDT(AWARE)[, gender := value[variable == "demographic_gender"], by = id]


# start preprocess (no change)
AWARE <- subset(AWARE,variable == "esm_boredom_stress" & (arousal == arousal_0 | arousal == arousal_1) & !(id %in% omit_id))
#describeBy(subset(AWARE, select=c("id")), group="id", mat=TRUE)
AWAREsub <- AWARE
AWAREsub[,"id_old"] <- AWAREsub$id


# configure variables from exiting variables (change)
#independent:##############################################################################################
AWAREsub$arousal_0_1 <- as.integer(ifelse(AWAREsub$arousal==arousal_0,0,1))

#dependent:################################################################################################
# usage_time 0:10 interval
AWAREsub$usage_time_0_10 <- AWAREsub$usage_time/max(AWAREsub$usage_time)*10
# usage_time metric
AWAREsub$usage_time <- AWAREsub$usage_time
# usage_freq 0:10 interval
AWAREsub$usage_freq_0_10 <- AWAREsub$usage_freq/max(AWAREsub$usage_freq)*10
# usage_freq metric
AWAREsub$usage_freq <- AWAREsub$usage_freq

#third:################################################################################################
# gender
AWAREsub$gender_female0_male1 <- as.integer(ifelse(as.character(AWAREsub$gender)=="Female",0,1))


# set variables:################################################################################################
AWAREsub$indep <- AWAREsub$arousal_0_1
AWAREsub$dep <- AWAREsub$usage_time_0_10 # usage_time
AWAREsub$third <- AWAREsub$gender_female0_male1


# set max number of measurement points
#nr_mea <- 60 #27 # automatic
nr_mea <- max(AWAREsub$interval) # automatic
# set max number of devices
#nr_par <- 57 #66 
nr_par <- length(unique(AWAREsub$id)) # automatic

# delete last devices if too much measurement points (no change)
AWAREsub <- transform(AWAREsub, id=match(id, unique(id)))
AWAREsub <- subset(AWAREsub, id <= nr_par)
# delete last measurement points if too much measurement points (no change)
AWAREsub <- ddply(AWAREsub, "id", function(x) head(x[order(x$timestamp_end_diff) , ],n=nr_mea))
# append NAs if not enough measurement points  (no change)
AWAREsub <- as.data.table(AWAREsub)[, lapply(.SD, `length<-`, nr_mea), by = id]
# extend to size nr_par*nr_mea  (no change)
AWAREsub <- as.data.table(AWAREsub)[, lapply(.SD, `length<-`, nr_mea*nr_par)]
# make new sequency of ids (no change)
AWAREsub[,"id"] <- rep(seq.int(from=1, to= nr_par, by=1), each = nr_mea)

process <- data.frame(id = integer(nr_par*nr_mea), time = integer(nr_par*nr_mea), time7c = numeric(nr_par*nr_mea), dep = numeric(nr_par*nr_mea), indep = numeric(nr_par*nr_mea), indepc = numeric(nr_par*nr_mea), indepcb = numeric(nr_par*nr_mea), indepcw = numeric(nr_par*nr_mea), third = integer(nr_par*nr_mea))
process[,"id"] <- as.integer(AWAREsub$id)
process[,"time"] <- as.integer(rep(seq.int(from=0, to= nr_mea-1, by=1), nr_par))
process[,"time7c"] <- (process[,"time"]-(84-1)/2)/7
process[,"dep"] <- AWAREsub$dep
process[,"indep"] <- AWAREsub$indep
#process[is.na(process)] <- 0
process[,"indepc"] <- process$indep-mean(process$indep, na.rm=TRUE) # not used later
process[,"indepcw"] <- process$indep-aggregate(process$indep, list(process$id), mean, na.rm=TRUE)[rep(seq_len(nrow(aggregate(process$indep, list(process$id), mean, na.rm=TRUE))), each=nr_mea),2]
process[,"indepcb"] <- process[,"indepc"] - process[,"indepcw"]
process[,"third"] <- AWAREsub$third #rep((sample.int(2,nr_par,replace=TRUE)-1), each = nr_mea)

############################################################################################################
#Read a csv file containing the data
#process <- read.csv('C:/Users/Felix/Dropbox/Apps/Aware/Database/R Scripts/ch5R/process.csv')
colnames(process)[4] <- "dep"
colnames(process)[5] <- "indep"
colnames(process)[6] <- "indepc"
colnames(process)[7] <- "indepcb"
colnames(process)[8] <- "indepcw"
colnames(process)[9] <- "third"
process_pre <- process
############################################################################################################
#edit because of error
graphics.off()
############################################################################################################

#Figure 5.2: Time Course Plots for Intimacy for the Low Relationship Quality Group

#edit because of error
#pdf(file="lrq-intimacy-time.pdf", width=15, height=8)
par(mar=c(1,1,1,1))

par(mfrow=c(4,8))
for (i in process$id[process$time==0 & process$third==0]){
  print(i)
  plot(process$time[process$id==i], process$dep[process$id==i], 
       ylab="dep", xlab="Time", type="l", xlim=c(-1, 29), ylim=c(0,8), main=paste("id =", i, sep = " "))
}
mtext("Low Relationship Quality", side=3, outer=TRUE, line=-1.2)
#dev.off()

#Figure 5.2: Time Course Plots for Intimacy for the High Relationship Quality Group

#edit because of error
#pdf(file="hrq-intimacy-time.pdf", width=15, height=10)
par(mar=c(1,1,1,1))

par(mfrow=c(5,8))
for (i in process$id[process$time==0 & process$third==1]){
  plot(process$time[process$id==i], process$dep[process$id==i], 
       ylab="dep", xlab="Time", type="l", xlim=c(-1, 29), ylim=c(0,8), main=paste("id =", i, sep = " "))
}
mtext("High Relationship Quality", side=3, outer=TRUE, line=-1.2)
#dev.off()
############################################################################################################

############################################################################################################

#Figure 5.2: Time Course Plots for Conflict for the Low Relationship Quality Group

#edit because of error
#pdf(file="lrq-conflict-time.pdf", width=15, height=8)
par(mar=c(1,1,1,1))

par(mfrow=c(4,8))
for (i in process$id[process$time==0 & process$third==0]){
  plot(process$time[process$id==i], process$indep[process$id==i], 
       ylab="indep", xlab="Time", type="l", xlim=c(-1, 29), ylim=c(-0.1, 1.1), main=paste("id =", i, sep = " "))
}
mtext("Low Relationship Quality", side=3, outer=TRUE, line=-1.2)
#dev.off()

#Figure 5.2: Time Course Plots for Conflict for the High Relationship Quality Group

#edit because of error
#pdf(file="hrq-conflict-time.pdf", width=15, height=10)
par(mar=c(1,1,1,1))

par(mfrow=c(5,8))
for (i in process$id[process$time==0 & process$third==1]){
  plot(process$time[process$id==i], process$indep[process$id==i], 
       ylab="indep", xlab="Time", type="l", xlim=c(-1, 29), ylim=c(-0.1, 1.1), main=paste("id =", i, sep = " "))
}
mtext("High Relationship Quality", side=3, outer=TRUE, line=-1.2)
#dev.off()
############################################################################################################


############################################################################################################
#Run linear growth model with AR(1) errors 
cpmodel <- lme(fixed=dep ~ time7c + indepcw*third + indepcb*third, data=process, random=~indepcw | id, correlation = corAR1(),na.action=na.omit)#na.action=na.omit
summary(cpmodel)
summary_save <- summary(cpmodel)
############################################################################################################


############################################################################################################

#Put the EBLUPs of the random effects into a separate dataet
cfs<-ranef(cpmodel)
cfs$id<-1:nrow(cfs) #Add in id numbers
#Fix the names of the EBLUPs
names(cfs) <- make.names(names(cfs))
names(cfs)[c(2,1)] <- c("ebslope","ebintercept")
#create a upper-level data frame with third and add to data frame with EBLUPs
cfs$third<-aggregate(third ~ id, data=process, mean)[, 2]
#Add the fixed effects to the EBLUPs
fix_Intercept <- as.numeric(summary_save[[4]]$fixed["(Intercept)"])
fix_third <- as.numeric(summary_save[[4]]$fixed["third"])
fix_indepcw <- as.numeric(summary_save[[4]]$fixed["indepcw"])
fix_indepcw_third <- as.numeric(summary_save[[4]]$fixed["indepcw:third"])
cfs$intercept<- (fix_Intercept + fix_third*cfs$third + cfs$ebintercept) 
cfs$fixinter<- (fix_Intercept + fix_third*cfs$third) #not used below
cfs$slope<- (fix_indepcw + fix_indepcw_third*cfs$third + cfs$ebslope)
cfs$fixslope<- (fix_indepcw + fix_indepcw_third*cfs$third) #not used below
############################################################################################################
process_temp <- process
#Merge upper-level variables with the process data frame
process <- merge(process, cfs, all=TRUE, by="id")
# added because of error if process.third(x) == cfs.third(y)  -> third
if(all(c(process$third.x==as.integer(process$third.y) & sum(process$third.x, na.rm = TRUE)== sum(process$third.y, na.rm = TRUE)))){
  warning("error 1")
  process[,"third"] <- process[,"third.x"]
  drops <- c("third.x","third.y")
  process <- process[ , !(names(process) %in% drops)]
} else {
  # added because of further error if process.third(x) != cfs.third(y)  -> third(x)
  warning("error 2")
  process[,"third"] <- process[,"third.x"]
  drops <- c("third.x","third.y")
  process <- process[ , !(names(process) %in% drops)]
}


#Create predicted values based on within-subject causal model (adjusting for time
#and removing between-subjects variation)
process$pred<-(process$intercept + process$slope*process$indep)

############################################################################################################

#To create graphs based on observed data only: Sort the dataset by relationship quality, ID, and daily conflict
ordprocess<-process[order(process$third, process$slope, process$id, process$indep),]
#Sort the upper-level data frame by relationship quality, conflict slope and ID
ordcfs<-cfs[order(cfs$third, cfs$slope, cfs$id),]

############################################################################################################

#Figure 5.4: Intimacy as a Function of Conflict: Raw Data and Model Predictions for the Low Relationship Quality Group
#Note: Confidence Bounds for Predictions are not Available for lme() models

#edit because of error
#pdf(file="lrq-pred-panels.pdf", width=14, height=8)
par(mar=c(1,1,1,1))
# edit to flex
third_0 <- unique(subset(process_pre, third==0)$id)

par(mfrow=c(4,8))
for (i in third_0){   #Subjects in low rq group
  plot(process$indep[process$id==i], process$dep[process$id==i], 
       ylab="dep", xlab="indep (0,1)", type="p", pch=1, xlim=c(-.2, 1.2), ylim=c(0,10), 
       main=paste(round(cfs$slope[cfs$id==i], digits=3)))
  lines(ordprocess$indep[ordprocess$id==i], ordprocess$pred[ordprocess$id==i]) 
}
mtext("Low Relationship Quality", side=3, outer=TRUE, line=-1.2)
#dev.off()


#Figure 5.4: Intimacy as a Function of Conflict: Raw Data and Model Predictions for the High Relationship Quality Group
#Note: Confidence Bounds for Predictions are not Available for lme() models

#edit because of error
#pdf(file="hrq-pred-panels.pdf", width=14, height=10)
par(mar=c(1,1,1,1))
# edit to flex
third_1 <- unique(subset(process_pre, third==1)$id)

par(mfrow=c(5,8))
for (i in third_1){ #Subjects in high rq group
  plot(process$indep[process$id==i], process$dep[process$id==i], 
       ylab="dep", xlab="indep (0,1)", type="p", pch=1, xlim=c(-.2, 1.2), ylim=c(0,10),
       main=paste(round(cfs$slope[cfs$id==i], digits=3)))
  lines(ordprocess$indep[ordprocess$id==i], ordprocess$pred[ordprocess$id==i])
}
mtext("High Relationship Quality", side=3, outer=TRUE, line=-1.2)
#dev.off()
############################################################################################################


############################################################################################################

#Figure 5.5: Spaghetti Plots for Low and High Relationship Quality Groups

#edit because of error
#pdf(file="spag.pdf", width=14, height=10)
par(mar=c(1,1,1,1))

par(mfcol=c(1,2))
par(lwd=.5)
#low third
plot(process$indep[process$third==0], process$dep[process$third==0], 
     ylab="dep", xlab="indep", type="n", ylim=c(0,8), main="Low Relationship Quality")
for (i in cfs$id[cfs$third==0]){
  lines(ordprocess$indep[ordprocess$id==i], ordprocess$pred[ordprocess$id==i])
}
predl<-fix_Intercept + fix_indepcw*process$indep[process$third==0] #fixed line for low group
lines(process$indep[process$third==0], predl, col="Red", lwd=4)
#high third
plot(process$indep[process$third==1], process$dep[process$third==1], 
     ylab="dep", xlab="time", type="n", pch=4, ylim=c(0,8), main="High Relationship Quality")
for (i in cfs$id[cfs$third==1]){
  lines(ordprocess$indep[ordprocess$id==i], ordprocess$pred[ordprocess$id==i])
}
predh<-(fix_Intercept + fix_third) + (fix_indepcw + fix_indepcw_third)*process$indep[process$third==1]  #fixed line for high group
lines(process$indep[process$third==1], predh, col="Red", lwd=4)
#dev.off()

############################################################################################################



############################################################################################################
#Find percentiles for slope distribution for Low Relationship Quality Group
# edited to flex
quantile_0 <- quantile(cfs$slope[cfs$third==0], c(0.0, .05, .25, .50, .75, .95, 1.0), na.rm=TRUE) # edited na.rum=TRUE

############################################################################################################
# edited to flex
cfs_table = data.table(real.val = cfs$slope, cfs)
setkey(cfs_table, slope)
setattr(cfs_temp,"sorted","slope") 
cfs_table <- cfs_table[J(quantile_0), roll = "nearest"] 
quantile_0__5_25_75_95 <- c(cfs_table$id[2],cfs_table$id[3],cfs_table$id[4],cfs_table$id[5],cfs_table$id[6])
############################################################################################################

#Figure 2 of example write-up for Chapter 5: Panel plots for five selected IDs in Low RQ Group
#Note: In order to match the book, ID=48 is chosen for the 5th percentile, whereas the more correct
#choice would have been ID=45. Similarly ID=65 is chosen over ID=47 for the 50th percentile.

#edit because of error
#pdf(file="lrq-five.pdf", width=14, height=3)
par(mar=c(1,1,1,1))

# Error 2: change 65 to 47
par(mfcol=c(1,5))
for (i in quantile_0__5_25_75_95){
  plot(ordprocess$indep[ordprocess$id==i], ordprocess$dep[ordprocess$id==i], 
       ylab="dep", xlab="indep", type="p", pch=1, ylim=c(0,8), main=paste("id =", i, sep = " "))
  lines(ordprocess$indep[ordprocess$id==i], ordprocess$pred[ordprocess$id==i])
}
mtext("Low Relationship Quality", side=3, outer=TRUE, line=-1.2)
#dev.off()
############################################################################################################



############################################################################################################
#Find percentiles for slope distribution for High Relationship Quality Group

qunatile_1 <- quantile(cfs$slope[cfs$third==1], c(0.0, .05, .25, .50, .75, .95, 1.0), na.rum=TRUE) # edited na.rm=TRUE

############################################################################################################
# edited to flex
cfs_table = data.table(real.val = cfs$slope, cfs)
setkey(cfs_table, slope)
setattr(cfs_temp,"sorted","slope") 
cfs_table <- cfs_table[J(qunatile_1), roll = "nearest"] 
quantile_1__5_25_75_95 <- c(cfs_table$id[2],cfs_table$id[3],cfs_table$id[4],cfs_table$id[5],cfs_table$id[6])

############################################################################################################

#Figure 2 of example write-up for Chapter 5: Panel plots for five selected IDs in High Relationship Quality Group
#Note: In order to match the book, ID=11 is chosen for the 5th percentile, whereas the more correct
#choice would have been ID=59. Similarly ID=14 is chosen over ID=64 for the 50th percentile. Finally, ID=50 is
#chosen over ID=24 for the 75th percentile.

#edit because of error
#pdf(file="hrq-five.pdf", width=14, height=3)
par(mar=c(1,1,1,1))
#windows(14,3)

par(mfcol=c(1,5))
for (i in quantile_1__5_25_75_95){
  plot(ordprocess$indep[ordprocess$id==i], ordprocess$dep[ordprocess$id==i], 
       ylab="dep", xlab="indep", type="p", pch=1, ylim=c(0,8), main=paste("id =", i, sep = " "))
  lines(ordprocess$indep[ordprocess$id==i], ordprocess$pred[ordprocess$id==i])
}
mtext("High Relationship Quality", side=3, outer=TRUE, line=-1.2)
#dev.off()
############################################################################################################

describeBy(subset(AWARE, select=c("id")), group="id", mat=TRUE)
summary(cpmodel)
