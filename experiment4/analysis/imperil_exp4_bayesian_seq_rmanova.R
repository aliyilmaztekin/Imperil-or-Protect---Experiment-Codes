# Imperil or Protect – Experiment 4
# Bayesian Sequential RMAnova
# Coded by A.Y.

### 0) SETUP
library(dplyr) 
library(R.matlab) # Data extraction
library(brms)
library(BayesFactor)
library(ggplot2) # Plotting

options(scipen = 999)  # Avoid scientific notation

# Pull the data and store in a data frame
base_dir <- "/Users/ali/Desktop/visual imperil project/imperil4materials/behavioral_data_exp4/"
files <- list.files(base_dir, pattern = "\\.mat$", full.names = TRUE)
dfs <- lapply(files, function(f) {
  mat <- R.matlab::readMat(f)
  as.data.frame(mat$outputMatrix)
})
combinedData <- bind_rows(dfs)

# Name the columns
colnames(combinedData) <- c(
  "subject", "conditionUsed", "block", "trial", "repetition",
  "context", "contextCode", "primaryColor", "secondaryColor",
  "angle1", "initiation_time1", "movement_time1", "rt1",
  "angle2", "initiation_time2", "movement_time2", "rt2",
  "breakTaken", "conditions"
)

# Enter dependent variable to analyze
DV <- "angle1"

# Extract only the data you wish to analyze
combinedData_sub <- combinedData %>% 
  mutate(
    subject    = factor(subject),
    repetition = factor(repetition),
    context    = factor(context),
    # Take the absolute form of your outcome measures
    outcome = abs(!!sym(DV))
  ) %>%
  filter(
    # Filter the data set down to the critical trials
    repetition %in% c("1", "5"),
    context %in% c("0", "1")
  ) %>%
  # Filter out missed probes
  filter(!is.na(outcome)) %>%
  droplevels()

bf <- anovaBF(
  outcome ~ repetition * context + subject,
  data = combinedData_sub,
  whichRandom = "subject"
)
bf


# ---- Sequential BF tracking ----

subjects_all <- combinedData_sub %>%
  pull(subject) %>%
  unique() %>%
  sort()

compute_bf <- function(data, subjects) {
  
  d <- data %>%
    filter(subject %in% subjects) %>%
    droplevels()
  
  # Fit model with interaction (full model)
  bf_full <- anovaBF(
    outcome ~ repetition * context + subject,
    data = d,
    whichRandom = "subject"
  )
  
  # Fit model without interaction (additive model)
  bf_additive <- anovaBF(
    outcome ~ repetition + context + subject,
    data = d,
    whichRandom = "subject"
  )
  
  # Extract BF values
  bf_full_val <- extractBF(bf_full)$bf
  bf_additive_val <- extractBF(bf_additive)$bf
  
  # BF for interaction = BF_full / BF_additive
  # This tells us how much more evidence there is for the model with interaction
  bf_full_val / bf_additive_val
}

test_bf <- compute_bf(
  data = combinedData_sub,
  subjects = subjects_all[1:25]
)

test_bf

min_N <- 20  # do not peek before this

BF_seq <- sapply(
  min_N:length(subjects_all),
  function(n) {
    compute_bf(
      data = combinedData_sub,
      subjects = subjects_all[1:n]
    )
  }
)

seq_df <- data.frame(
  N = min_N:length(subjects_all),
  BF = BF_seq
)







# Assuming combinedData_sub is prepared as before

# Define the brms model
# (1 | subject) indicates a random intercept for subject
# If you expect random slopes as well, you'd add something like (1 + repetition | subject)
brms_model <- brms::brm(
  outcome ~ repetition * context + (1 | subject),
  data = combinedData_sub,
  family = lognormal(),  # Using lognormal distribution for outcome
  chains = 4,           # Number of MCMC chains
  iter = 2000,          # Number of iterations per chain
  warmup = 1000,        # Warmup iterations
  cores = 4,            # Number of cores to use
  seed = 1234           # For reproducibility
)

# Summarize the model results
summary(brms_model)

# Test for interaction
hypothesis(brms_model, "repetition5:context1 = 0", class = "b", test = "BF")


reduced_model <- brm(
  outcome ~ repetition + context + (1 | subject),
  data = combinedData_sub,
  family = lognormal(),
  prior = c(
    prior(normal(0, 1), class = "b")
  )
)

bayes_factor(brms_model, reduced_model)


# Extract Bayes Factors from brms model (for specific hypotheses)
# You'd typically use hypothesis() function in brms for this
# Example for testing the interaction:
# hypothesis(brms_model, "repetition:context = 0")

# For sequential analysis with brms, it's more complex as you'd typically re-fit the model
# for each new subset of data. This can be computationally intensive but provides
# a more accurate sequential Bayes Factor for a full mixed model.

# Example of a simplified sequential approach with brms (conceptual, not full BF for interaction):
# You'd typically look at the posterior distribution of your fixed effects.
# If you want to track changes in a parameter estimate or its credible interval
# as you add more subjects, you would re-run brm for each subset.

# Sequential BFs in brms for complex models are often done by comparing
# evidence for different models (e.g., model with interaction vs. without)
# using bridge_sampling or loo_compare. This would involve fitting multiple models
# for each subset of data, which is computationally expensive.







# # Create alternative and null hypothesis models
# formula_full <- outcome ~ repetition * context + (1 | subject)
# formula_null <- outcome ~ 1 + (1 | subject)
# 
# priors_full <- c(
#   prior(normal(0, 0.3), class = "b"),
#   prior(student_t(3, 0, 0.5), class = "sd"),
#   prior(student_t(3, 0, 0.6), class = "sigma")
# )
# priors_null <- c(
#   prior(student_t(3, 0, 0.5), class = "sd"),
#   prior(student_t(3, 0, 0.6), class = "sigma")
# )
# 
# 
# fit_null <- brm(
#   formula = formula_null,
#   data = combinedData_sub,
#   family = lognormal(),
#   prior = priors_null,
#   chains = 4,
#   cores = 4,
#   iter = 4000,
#   save_pars = save_pars(all = TRUE)
# )
# 
# fit_full <- brm(
#   formula = formula_full,
#   data = combinedData_sub,
#   family = lognormal(),
#   prior = priors_full,
#   chains = 4,
#   cores = 4,
#   iter = 4000,
#   save_pars = save_pars(all = TRUE)
# )
# 
# summary(fit_full)
# 
# bf <- bayes_factor(fit_full, fit_null)
# bf
# 
# formula_main <- outcome ~ repetition + context + (1 | subject)
# 
# fit_main <- brm(
#   formula = formula_main,
#   data = combinedData_sub,
#   family = lognormal(),
#   prior = priors_full,   # includes b priors, which are needed here
#   chains = 4,
#   cores = 4,
#   iter = 4000,
#   save_pars = save_pars(all = TRUE)
# )
# 
# bf_interaction <- bayes_factor(fit_full, fit_main)
# bf_interaction
# 
# 
# conditional_effects(
#   fit_full,
#   effects = "repetition:context",
#   prob = 0.95
# )
# 
# 
