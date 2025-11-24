# Assuming you have completed all the prior steps to lmer, like ...
# ... data import, level-assignment, etc, and your lmer model is ready.

# If yes ->

# Import simr 
# Some other libraries, like dplyr or emmeans could be needed. 
# If you're missing a library, the error output from the below operations will tell you. 
# Based on that, import whatever you need. 
library(simr)

# Enter here your current model
current_model <- lmer(log_outcome ~ repetition * context * interference + (1 | subject), data = subset_data_log)

# The function below calculates your power of finding an effect for whichever...
# ... fixed effect you plug in (it is "context1" here). 

# to see all the fixed effects in your model...
# ... type into the console "names(fixef(current_model)))"
# So, change the fixed effect to your choosing. 

# "t" is the type of statistical test you want the simulation to employ. 
# Make it "z" or whatever you need. 

# "nsim" is the number of simulations you want. 100 is usually set to get quick results. 
# You're advised to make it 1000 for reliability. 

powerSim(current_model, test = fixed("context1", "t"), nsim = 100)

# Currently, you're estimating power based on your own data. It's like doing...
# ... an a-posterior power calculation to see if you've collected enough data. 
# (You will likely receive an "observed data" warning. This simply means the ...
# ... power estimation is conducted based on your own data, without any changes in its ...
# ... parameters. Why is this a warning? People usually use simulations to calculate ...
# ... stuff that doesn't exist, like an effect size different from the one in your actual data). 
# More on this later.


# Check your results. You want your power to be above the conventional 80% cut-off. 

# If your power is lower than that, you can extend your current model ...
# ... to see how your current data would look like if you had more 
# ... participants. 

# To do that, execute the function below. "n" is how many participant you want. 
# My data had 53 people. I'll increase it to 100. 

extended_model <- extend(current_model, along = "subject", n = 100)

# Now, the extended_model is a hypothetical data-set with the same characteristics...
# ... as my original, only with double the sample size. 

# The function below creates a plot showing your power estimate changes the larger...
# ... your sample gets. You can change the fixed effect, test type and nsim as before.
# The line "breaks = seq(30, 100, by = 10)" creates a number vector starting from 30 ...
# ... to 100, incremented by 10 at every step. Make sure the upper boundary is the sample size...
# ... you extended your model to just above. If I plugged in 120, the function would crush ...
# ... because I extended the model to only 100 people. 

pc <- powerCurve(extended_model,
                 test = fixed("context1", "t"),
                 along = "subject",
                 breaks = seq(30, 100, by = 10),
                 nsim = 100)
plot(pc)

# You can also artificially change your effect size for a given fixed effect with the following:
fixef(current_model)["context1"] <- 0.15

# My actual effect size for context1 is sth like 0.05. The above line helps me how my...
# ... power calculation would look like if context change had a stronger effect. 
# People usually use that when they have no data collected at all and will...
# ... simulate artificial data to predict required sample size for their study. 
# 0.15, 0.20 is the usual effect size for interactions effects in cog. psyc. Change as needed.  

# Then, you just run the power estimation as before, now with the effect size. 
powerSim(current_model, test = fixed("context1", "t"), nsim = 100)

# You can also extend your curent model (which now has the changed effect size for context)...
# ... to plot power changes across sample sizes as before. 

extended_model2 <- extend(current_model, along = "subject", n = 100)

pc <- powerCurve(extended_model2,
                 test = fixed("context1", "t"),
                 along = "subject",
                 breaks = seq(30, 100, by = 10),
                 nsim = 100)
plot(pc)