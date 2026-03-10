# Imperil or Protect – Experiment 5
# Generalized Linear Mixed-Effects Analysis
# Coded by A.Y.

### 0) SETUP
library(dplyr) 
library(R.matlab) # Data extraction
library(lme4) # LMM/GLMM
library(lmerTest) # Mixed modelling effect sizes
library(emmeans) # EMMs
library(ggplot2) # Plotting
library(moments) # Skewness values
library(stringr)
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

### Enter DV of interest
DV <- "angle1"

### 1) PREPROCESSING
# Extract only the data you wish to analyze
combinedData_sub <- combinedData %>% 
  mutate(
    subject    = factor(subject),
    repetition = factor(repetition),
    context    = factor(context),
    # Take the absolute form of your outcome measures
    outcome = abs(!!sym(DV)), 
  ) %>%
  filter(
    # Filter the data set down to the critical trials
    repetition %in% c("1", "5"),
    context %in% c("0", "1")
  ) %>%
  # Filter out missed probes
  filter(!is.na(outcome)) %>%
  droplevels()

# Filter out the outliers
cleanedData <- combinedData_sub

### Log transform the data? 
log_me <- FALSE
if (log_me) {
  epsilon <- 1e-6
}

# Log-transform if log_me is TRUE
cleanedData <- cleanedData %>%
  mutate(
    outcome = if (log_me) log(outcome + epsilon) else outcome
  )

### 2) DESCRIPTIVE STATISTICS
# Reverse the log transformation if done 
cleanedData_desc <- cleanedData %>%
  mutate(
    outcome = if (log_me) exp(outcome) - epsilon else outcome
  )

# Compute descriptive parameters
descriptives <- cleanedData_desc %>%
  group_by(repetition, context) %>%
  summarize(
    mean = mean(outcome, na.rm = TRUE),
    sd   = sd(outcome, na.rm = TRUE),
    n        = n(),
    .groups = "drop"
  )

### 3) INFERENTIAL STATISTICS
# Do the test by building the formula  
test <- lmer(
  outcome ~ repetition * context + (1 | subject),
  data = cleanedData
)

# Store lmer results for further processing
lmer_results <- summary(test)

# GLMM for binary accuracy outcome
glmer(outcome ~ repetition * context + (1 | subject), data = cleanedData, family = binomial)

