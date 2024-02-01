####load libraries####
library(dplyr) #used to modify dataframes
library(tidyverse) #used to modify dataframes
library(readr) #used to read csv files

####import data table####
#adjust for each experiment
platemap <-read.csv("platemaps/190703-Cteno.csv") 
df.image <-read.csv("data/190703_Image.csv") # needed for filter image quality
df.object<-read.csv("data/190703_Hoechst_Obj.csv") 
title.graph <- "190703"


####trim and merge data####
##create new df containing out of focus, Metadata and object measurement
#subset df.image
df.image <- subset(df.image, select=c(ImageNumber, 
                                          Metadata_Plate,
                                          Metadata_Well, 
                                          ImageQuality_FocusScore_Hoechst_Orig))
#subset df.object
df.object <- subset(df.object, select=c(ImageNumber:AreaShape_Area, 
                                            Intensity_MeanIntensity_Hoechst_Rescale,
                                            Intensity_MeanIntensity_Sytox_Rescale))

#add Cell_ID to sub.df.image and df.object
df.image <- df.image%>% 
  unite(Cell_ID, Metadata_Plate,Metadata_Well, sep="_", remove=FALSE)
df.object <- df.object%>% 
  unite(Cell_ID, Metadata_Plate,Metadata_Well, sep="_", remove=FALSE)

#merge sub.df.image with df.object and metadata
df <- merge(df.image,platemap, by="Cell_ID")
df <- merge(df, df.object, by="Cell_ID")


####remove out of focus images ####
## sort data by removing if out of focus data
#images out of focus, print summary to identify cutoff
summary.out.of.focus <-as.data.frame(unclass(summary(df$ImageQuality_FocusScore_Hoechst_Orig)))
summary.out.of.focus

#check summary.out.of.focus to choose a threshold, enter the threshold value in line 45 "thr.out.of.focus"
#remove images where out of focus images
thr.out.of.focus <- 0.2
df <-subset(df, ImageQuality_FocusScore_Hoechst_Orig<thr.out.of.focus)

#############################################################################
##### DECIDE IF DATA NEED TO BE SEPARATED BY ANIMALS OR REPLICATES ##### 
#IF DATA NEED TO BE SEPARATED BY ANIMALS, run line 53-80
#IF DATA NEED TO BE SEPARATED BY REPLICATE run line 82-109
############################################################################
##### keep only data for FACS plots and sub-setting per treatments ####
rm(df.image, df.object)
#keep column useful for FACS
df <- subset(df, select=c( AreaShape_Area,
                           Intensity_MeanIntensity_Hoechst_Rescale, 
                           Intensity_MeanIntensity_Sytox_Rescale, 
                          Metadata_Cells : Metadata_Condition))

#add column containing exp name
df <-mutate(df, exp=title.graph)

#create new column for unique ID
df <- df%>% 
  unite(UniqueID, Metadata_Cells, Metadata_Treatment, exp, sep="_", remove=FALSE)
#replace "+" by nothing
df <- df %>% 
  mutate(UniqueID = str_replace(UniqueID, fixed("+",TRUE) , ""))

##### create subset for each animal and treatments ####
UniqueID <-data.frame(UniqueID=unique(df$UniqueID))


# create subset per animal and condition
for( i in UniqueID$UniqueID){
  assign(i, df %>%
           filter(UniqueID==i) %>%
           select("AreaShape_Area", "Intensity_MeanIntensity_Hoechst_Rescale","Intensity_MeanIntensity_Sytox_Rescale"))
  }
################################################################################
##### keep only data for FACS plots and sub-setting per treatments ####
rm(df.image, df.object)
#keep column useful for FACS
df <- subset(df, select=c( AreaShape_Area,
                           Intensity_MeanIntensity_Hoechst_Rescale, 
                           Intensity_MeanIntensity_Sytox_Rescale, 
                          Metadata_Cells : Well_Replicates))

#add column containg exp name
df <-mutate(df, exp=title.graph)

#create new column for unique ID
df <- df%>% 
  unite(UniqueID, Metadata_Cells, Metadata_Treatment, Well_Replicates, exp, sep="_", remove=FALSE)
#replace "+" by nothing
df <- df %>% 
  mutate(UniqueID = str_replace(UniqueID, fixed("+",TRUE) , ""))

##### create subset for each animal and treatments ####
UniqueID <-data.frame(UniqueID=unique(df$UniqueID))


# create subset per animal and condition
for( i in UniqueID$UniqueID){
  assign(i, df %>%
           filter(UniqueID==i) %>%
           select("AreaShape_Area", "Intensity_MeanIntensity_Hoechst_Rescale","Intensity_MeanIntensity_Sytox_Rescale"))
  }
#################################################################################

##### write all .csv for import into FlowJo ####
# need to have a folder called "FACS" in the working directory
files <- mget(ls())
for (i in 1:length(files)){
  write.csv(files[[i]], paste("FACS/", names(files[i]), ".csv", sep = "",row.names=FALSE))
}

