######################################################################
#Start Program
######################################################################
library(tidyverse)
library(naniar)
library(visdat)
library(funModeling)
library(Hmisc)
library(ggplot2)
######################################################################
###To be put in Read function
##Read CSV
DATASET_FILENAME  <- "Scorecard.csv"
setwd("C:/Users/rhmou/OneDrive/Documents/Practical Business Analytics/Coursework/ScoreCardDataset")
#ScoreCardRawData <- read.csv(DATASET_FILENAME,encoding="UTF-8",stringsAsFactors = FALSE, na.strings = c("PrivacySuppressed", "NULL", "", " "))

##Choose fields
ChosenData <- ScoreCardRawData %>% select(median_hh_inc,
                    poverty_rate,
                    unemp_rate,
                    female,
                    md_faminc,
                    INSTNM,
                    STABBR,
                    PREDDEG,
                    CONTROL,
                    LOCALE,
                    locale2,
                    HIGHDEG,
                    SAT_AVG,
                    region,
                    CCBASIC,
                    ADM_RATE,
                    COSTT4_A,
                    COSTT4_P,
                    TUITIONFEE_IN,
                    TUITIONFEE_OUT,
                    TUITIONFEE_PROG,
                    TUITFTE,
                    INEXPFTE,
                    DEBT_MDN_SUPP,
                    sch_deg,
                    Year,
                    COMP_ORIG_YR2_RT,
                    COMP_4YR_TRANS_YR2_RT,
                    COMP_2YR_TRANS_YR2_RT,
                    INC_PCT_LO,
                    DEP_STAT_PCT_IND,
                    INC_PCT_M1,
                    INC_PCT_M2,
                    INC_PCT_H1,
                    INC_PCT_H2,
                    md_earn_wne_p6,
                    md_earn_wne_p8,
                    md_earn_wne_p10
 )

##Deallocate ScorecardRawData
# rm(ScoreCardRawData)
######################################################################

######################################################################
###To be put in Verifying Datatype function
##Looking at the data
print("Summary Before making Changes")
print(summary(ChosenData))

##Converting DEBT_MDN_SUPP, md_earn_wne_p6, md_earn_wne_p8, md_earn_wne_p10, median_hh_inc, poverty_rate, 
##unemp_rate, md_faminc, COMP_ORIG_YR2_RT, COMP_4YR_TRANS_YR2_RT, COMP_2YR_TRANS_YR2_RT, INC_PCT_LO
##DEP_STAT_PCT_IND, INC_PCT_M1, INC_PCT_M2, INC_PCT_H1, INC_PCT_H2 to numeric
ChosenData <- transform(ChosenData, DEBT_MDN_SUPP = as.numeric(DEBT_MDN_SUPP))
ChosenData <- transform(ChosenData, md_earn_wne_p6 = as.numeric(md_earn_wne_p6))
ChosenData <- transform(ChosenData, md_earn_wne_p8 = as.numeric(md_earn_wne_p8))
ChosenData <- transform(ChosenData, md_earn_wne_p10 = as.numeric(md_earn_wne_p10))
ChosenData <- transform(ChosenData, median_hh_inc = as.numeric(median_hh_inc))
ChosenData <- transform(ChosenData, poverty_rate = as.numeric(poverty_rate))
ChosenData <- transform(ChosenData, unemp_rate = as.numeric(unemp_rate))
ChosenData <- transform(ChosenData, md_faminc = as.numeric(md_faminc))
ChosenData <- transform(ChosenData, female = as.numeric(female))
ChosenData <- transform(ChosenData, COMP_ORIG_YR2_RT = as.numeric(COMP_ORIG_YR2_RT))
ChosenData <- transform(ChosenData, COMP_4YR_TRANS_YR2_RT = as.numeric(COMP_4YR_TRANS_YR2_RT))
ChosenData <- transform(ChosenData, COMP_2YR_TRANS_YR2_RT = as.numeric(COMP_2YR_TRANS_YR2_RT))
ChosenData <- transform(ChosenData, INC_PCT_LO = as.numeric(INC_PCT_LO))
ChosenData <- transform(ChosenData, DEP_STAT_PCT_IND = as.numeric(DEP_STAT_PCT_IND))
ChosenData <- transform(ChosenData, INC_PCT_M1 = as.numeric(INC_PCT_M1))
ChosenData <- transform(ChosenData, INC_PCT_M2 = as.numeric(INC_PCT_M2))
ChosenData <- transform(ChosenData, INC_PCT_H1 = as.numeric(INC_PCT_H1))
ChosenData <- transform(ChosenData, INC_PCT_H2 = as.numeric(INC_PCT_H2))

##Looking at the data
print("Summary after making Changes")
print(summary(ChosenData))
######################################################################

######################################################################
###To be put in Missing_Data function

#Removing records with NA in output fields and cost_of_education fields
NA_Summary <- aggregate(is.na(ChosenData), list(ChosenData$Year), mean)
print(NA_Summary)
Chosen_Years <- subset(NA_Summary, (md_earn_wne_p6 != 1 | md_earn_wne_p8 != 1 | md_earn_wne_p10 != 1) 
                       & (COSTT4_A != 1 | COSTT4_P != 1))
print(Chosen_Years)
ChosenData_Lesser_Missing_Values <- subset(ChosenData, (Year == 2009 | Year == 2011))

##Looking at the data
print("Summary after removing rows with lot of NAs")
print(summary(ChosenData_Lesser_Missing_Values))

##Counting NA Columnwise
print(colSums(is.na(ChosenData_Lesser_Missing_Values)))

##Removing fields that are completely NULL
ChosenData_Lesser_Fields <- ChosenData_Lesser_Missing_Values[, c(6:9, 12:14, 16:38)]

##Counting NA Columnwise
print(colSums(is.na(ChosenData_Lesser_Fields)))

##Combining the attendance cost fields from program year and academic year institutions into one field
##Populating 0 when COSTT4_A is available and COSTT4_P is NA and vice versa
ChosenData_Lesser_Fields$COSTT4_A[is.na(ChosenData_Lesser_Fields$COSTT4_A) 
                                          & !is.na(ChosenData_Lesser_Fields$COSTT4_P)] <- 0
ChosenData_Lesser_Fields$COSTT4_P[is.na(ChosenData_Lesser_Fields$COSTT4_P) 
                                          & !is.na(ChosenData_Lesser_Fields$COSTT4_A)] <- 0
ChosenData_Lesser_Fields <- ChosenData_Lesser_Fields %>% mutate(ATDCOST = COSTT4_A + COSTT4_P)

##Imputing Values
for(i in 1:ncol(ChosenData_Lesser_Fields)){
  ##Since the categorical fields do not have NA, we are imputing only for the numeric fields by populating the mean value
  if (is.numeric(ChosenData_Lesser_Fields[,i])) 
    ChosenData_Lesser_Fields[is.na(ChosenData_Lesser_Fields[,i]), i] <- mean(ChosenData_Lesser_Fields[,i], na.rm = TRUE)
}

#write.csv(ChosenData_Lesser_Fields, "Scorecard_Subset.csv")
