# Automated ETosis and death quantification in invertebrates 

# Description
This is a semi-automated pipeline to quantify simultaneously the percentage of cells undergoing ETosis and cell death. 
We developed a semi-automated imaging analysis approach to measure Hoescht and SytoxGreen labeling in individual cell nuclei and accurately quantify both ETosis and cell death simultaneously 
We used a combination of the two DNA dyes: Hoechst, which is a membrane-permeable dye that labels DNA in both live cells and dead cells, and SytoxGreen, a non-permeable cell stain that selectively labels DNA in cells with compromised cell membranes, as observed in cells undergoing cell death. Both DNA dyes label ETs and ETotic cells have both diffuse gradients of Hoechst and Sytox staining. This allowed for the identification of three distinct populations: Hoechst high/ SytoxGreen low live cells that show no DNA release and intact cell membranes; Hoechst low/ SytoxGreen low cells which display diffuse extracellular Hoechst and SytoxGreen fluorescence, representing ETotic cells; and SytoxGreen high cells with a range of Hoescht staining, which are dead or dying non-ETotic cells.

# Publication
Extracellular DNA traps in a ctenophore demonstrate conserved immune cell behaviors in a non-bilaterian 
Lauren E. Vandepas, Caroline Stefani, Nikki Traylor-Knowles, Frederick W. Goetz, William E. Browne, Adam Lacy-Hulbert
bioRxiv 2020.06.09.141010; doi: https://doi.org/10.1101/2020.06.09.141010

# Usage

This package is based on the output files from CellProfiler.

## Running CellProfiler cellular analysis

## Transforming CellProfiler outputs in FLowJo compatible files
### Prepare Metadata file
Before running R program, you'll need to prepare a Metadata file. This file can be created in Excel, and should be saved in the 'comma-separated values (.csv)' format.

This file should contain 7 columns:
* `Metadata_Plate` for the plate name (eg: "Plate 1") 	
* `Metadata_Well`	for the well name (eg: "A1") 	
* `Metadata_Cells` for the name of the cell type or organism use for the analysis (eg: "Cteno") 	
* `Metadata_Treatment` for the name of the treatment (eg: "PMA") 	
* `Metadata_Condition` combining the information of columns `Metadata_Cells` and `Metadata_Treatment` separated by `_` (eg: "Cteno_PMA") 
* `Cell_ID`	combining the information of columns `Metadata_Plate` and `Metadata_Well` separated by `_` (eg: "Plate 1_A1") 
* `Well_Replicates` for the sample repeat number (eg: "1") 	


Example "platemap.csv": 

|Metadata_Plate|Metadata_Well|Metadata_Cells|Metadata_Treatment|Metadata_Condition|Cell_ID|Well_Replicates|
|--------------|-------------|--------------|------------------|------------------|-------|---------------|
|Plate 1|A1|Cteno|PMA|Cteno_PMA|Plate 1_A1|1|
|Plate 1|B12|Oyster|Nig|Oyster_Nig|Plate 1_B12|3|
|--|--|--|--|--|--|--|

### Tidying data
```R 
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
```


### Defining threshold for out of focus images
This section allow to identify threshold for out of focus images and to remove out of focus images from the analysis
```R
####remove out of focus images ####
## sort data by removing if out of focus data
#images out of focus, print summary to identify cutoff
summary.out.of.focus <-as.data.frame(unclass(summary(df$ImageQuality_FocusScore_Hoechst_Orig)))
summary.out.of.focus

#check summary.out.of.focus to choose a threshold, enter the threshold value in line 45 "thr.out.of.focus"
#remove images where out of focus images
thr.out.of.focus <- 0.2
df <-subset(df, ImageQuality_FocusScore_Hoechst_Orig<thr.out.of.focus)
```

### Keeping only data for FACS plots and sub-setting
Data could be subsetted by animal or per replicates

#### Subsetting per animal
```R
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
```
#### Subsetting per replicate
```R
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
```
### Export .csv file for import into FLowJo
```R
##### write all .csv for import into FlowJo ####
# need to have a folder called "FACS" in the working directory
files <- mget(ls())
for (i in 1:length(files)){
  write.csv(files[[i]], paste("FACS/", names(files[i]), ".csv", sep = "",row.names=FALSE))
}
```
