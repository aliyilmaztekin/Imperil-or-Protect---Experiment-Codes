To run the experiment (_main), first generate condition files (via condition matrix generator). Some of the experiment functions are outside the main script, so make sure to keep them in the same directory when running the main script. The subject count is essentially there to engage the corresponding condition matrix (you can hardwire the code to engage a given matrix, which would render the sbj count obsolete).    

All the parameters you need to change to run the experiment as originally designed (the DIRs for the stimuli, condition matrices, output destinations, etc.) are at the beginning of the code. To make more fine-grained changes (e.g., trial durations), explore further down in the script.  

The analysis is done in R Studio. It works with the data output format in the main experiment code. So, simply change the data DIR at the top of the code to your data location to run the analysis. 

All the visual stimuli used in this study, as well as the color wheel test code, are the courtesy of Timothy Brady's UCSD Vision and Memory Lab (https://bradylab.ucsd.edu/). 
