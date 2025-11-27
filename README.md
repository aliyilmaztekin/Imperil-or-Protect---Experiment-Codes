"Imperil or Protect" is the internal codename for this set of experiments I've been conducting for master's thesis. 

The official title of the study is "Memory in Focus: Unveiling the Impact of Reactivation on Memory Vulnerability". 

The main aim of the project was to see whether delay-period interference impairs recall accuracy of repeatedly studied memory items brought back to an active representational state following a change in the background context. 

Here, you can access various MATLAB and R codes I wrote over the years to run and analyse the study. 
Note that the general readability and quality of the coding gets better with each experiment. 

"common materials" contains the stimulus pool and the color wheel code/functions in all experiments (courtesy of Tim Brady's UCSD Vision and Memory Lab: https://bradylab.ucsd.edu/resources.html). 

"preprocess_reshape" is a conversion code for Exps. 1, 2 and 3 that takes the data as saved by the experiment scripts and turns it into a format ready for an RMAnova or a Linear Mixed Modelling test in RStudio. It also includes some of the data exclusion bits I implemented to correct for the design mistakes I made. 
Data is saved in Exps. 4 and 5 analysis-ready. 

The individual experiment folders contain the experiment scripts (suffixed "_main"), as well as the analysis codes (soft-coded as could be). 

All the codes were written by me and substantial help was received from ChatGPT (although only in the form of consultation, and hardly ever through copy-pasting). 

