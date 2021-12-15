# ETosis-and-death-automated-pipeline

# Description
This is a semi-automated pipeline to quantify simultaneously the percentage of cells undergoing ETosis and cell death. 

# Publication
Ctenophore immune cells produce chromatin traps in response to pathogens and NADPH-independent stimulus
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

### Defining threshold for out of focus images
