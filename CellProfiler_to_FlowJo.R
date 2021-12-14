#### Load libraries ####
library(dplyr) #used to subset and merge dataframes
library(tidyr) #necessary to use unite function
library(stringr) #necessary to use str_replace function
library(readr) #used to read csv files

#### Import CellProfiler output csv file per experiment as well as platemap ####

# WARNING : need to adjust file name for each experiment
platemap <-read.csv("./platemaps/190703-Cteno.csv") # Import platemap
df.image <-read.csv("./data/190703_Image.csv") # Import Image output from CellProfiler for OutOfFocus
df.object<-read.csv("./data/190703_Hoechst_Obj.csv") # Import object output from CellProfiler for intensities measurements
title.exp <- "190703" # Choose a name for experiment 


#### Create new df containing out of focus, Metadata and object measurement ####
#subset df.image
df.image <- subset(df.image, select=c(ImageNumber, 
                                          Metadata_Plate,
                                          Metadata_Well, 
                                          ImageQuality_FocusScore_Hoechst_Orig))
#subset df.object
df.object <- subset(df.object, select=c(ImageNumber:AreaShape_Area, 
                                            Intensity_MeanIntensity_Hoechst_Rescale,
                                            Intensity_MeanIntensity_Sytox_Rescale))

#add unique name per image (Cell_ID) to sub.df.image and df.object
df.image <- df.image%>% 
  unite(Cell_ID, Metadata_Plate,Metadata_Well, sep="_", remove=FALSE)
df.object <- df.object%>% 
  unite(Cell_ID, Metadata_Plate,Metadata_Well, sep="_", remove=FALSE)

#merge sub.df.image with df.object and metadata
df <- merge(df.image,platemap, by="Cell_ID")
df <- merge(df, df.object, by="Cell_ID")


#### Remove out of focus images ####
#print summary of ImageQuality_FocusScore to identify cutoff for out of focus images
summary.out.of.focus <-as.data.frame(unclass(summary(df$ImageQuality_FocusScore_Hoechst_Orig)))

#remove images with focus score higher than threshold for out of focus images
thr.out.of.focus <- 0.2 # define threshold for OutOfFocus images based on summary.out.of.focus
df <-subset(df, ImageQuality_FocusScore_Hoechst_Orig<thr.out.of.focus)

rm(df.image, 
   df.object, 
   summary.out.of.focus, 
   platemap) # cleaning to save memory

#### Keep only data for FACS plots and sub-setting per treatment ####
#keep only intensity of Hoechst and Sytox 
df <- subset(df, select=c(Intensity_MeanIntensity_Hoechst_Rescale, 
                           Intensity_MeanIntensity_Sytox_Rescale, 
                          Metadata_Cells : Well_Replicates))

#add column containing exp name
df <-mutate(df, exp=title.exp)
#create new column for unique ID
df <- df%>% 
  unite(UniqueID, Metadata_Cells, Metadata_Treatment, Well_Replicates, exp, sep="_", remove=FALSE)
#replace "+" by nothing
df <- df %>% 
  mutate(UniqueID = str_replace(UniqueID, fixed("+",TRUE) , ""))

#### Create subset for each animal and treatments ####
# list of all unique ID
UniqueID <-data.frame(UniqueID=unique(df$UniqueID))

# create subset per animal and condition
for( i in UniqueID$UniqueID){
  assign(i, df %>%
           filter(UniqueID==i) %>%
           select("Intensity_MeanIntensity_Hoechst_Rescale",
                  "Intensity_MeanIntensity_Sytox_Rescale"))
  }

#### Write all csv ####
rm(df,
   UniqueID, 
   thr.out.of.focus, 
   title.exp) # cleaning before saving csv for FACS plot

files <- mget(ls()) # list of all the files in environment

for (i in 1:length(files)){
  write.csv(files[[i]], paste("FACS/", names(files[i]), ".csv", sep = ""), row.names=FALSE)
}

