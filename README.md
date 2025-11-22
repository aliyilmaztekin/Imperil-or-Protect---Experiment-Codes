"Imperil or Protect" is the internal codename for a set of experiments I conducted as my master's thesis. 

The official title of the study is "Memory in Focus: Unveiling the Impact of Reactivation on Memory Vulnerability". 

The main aim of the project was to see whether delay-period interference hurts memory performance for repeatedly studied images that were brought back to an active state in working memory following a change in the context associated with the item. 

Here, you can access various MATLAB and R codes I wrote over the years to run and analyse the study. 
Note that the general reability and quality of the coding thankfully gets better across experiments.

"common materials" contains the stimulus pool and the color wheel code/functions used in all experiments (courtesy of Tim Brady's UCSD Vision and Memory Lab: https://bradylab.ucsd.edu/resources.html). "preprocess_reshape" is a conversion code for Exps. 1, 2 and 3 that takes the data as saved by the experiment scripts and turns it into a format ready to be fed through RMAnova or Linear Mixed Modelling in RStudio, as well as implements some of the data exclusion bits I implemented to correct for the design mistakes I made. Data is saved in Exps. 4 and 5 as analysis-ready. 

The individual experiment folders contain the experiment scripts (suffixed "_main"), as well as the analysis codes. 

All the codes were written by me and substantial help was received from ChatGPT (although only in the form of consoltation, and hardly ever through copy-pasting). 

