# Imperil or Protect - Experiment 4 - ANOVA/LMER analysis
# Coded by A.Y. 

### SETUP/PARAMETERS ----

library(afex)
afex_options(type = 3, check_contrasts = TRUE)
library(R.matlab)
library(dplyr)
library(ggplot2)
library(emmeans)
library(stringr)
library(lme4)
library(lmerTest)   # for Satterthwaite df + p-values
library(glmmTMB)
library(brms)
library(ggplot2)
library(rlang)

options(scipen = 999)  # Avoid scientific notation

base_dir <- "/Users/ali/Desktop/visual imperil project/imperil4materials/behavioral_data_exp4/"

files <- list.files(base_dir, pattern = "\\.mat$", full.names = TRUE)

dfs <- lapply(files, function(f) {
  mat <- R.matlab::readMat(f)
  as.data.frame(mat$outputMatrix)
})

combinedData <- bind_rows(dfs)
colnames(combinedData) <- c(
  "subject", "conditionUsed", "block", "trial", "repetition",
  "context", "contextCode", "primaryColor", "secondaryColor",
  "angle1", "initiation_time1", "movement_time1", "rt1",
  "angle2", "initiation_time2", "movement_time2", "rt2",
  "breakTaken", "conditions"
)

### PREPROCESSING ----

# # Specify participant IDs
# subjects_to_exclude <- c(13, 14, 15, 16, 17, 18, 19, 20, 22, 23, 25, 27, 28, 30, 31, 34, 37, 40, 43, 45, 62)   # example
# # or whatever IDs you want
# 
# # Make sure subject is numeric first
# combinedData <- combinedData %>%
#   mutate(subject = as.numeric(as.character(subject)))
# 
# # Version 1: dataset WITHOUT those participants
# combinedData_kept <- combinedData %>%
#   filter(!(subject %in% subjects_to_exclude))
# 
# # Version 2: dataset WITH ONLY those participants
# combinedData_excluded <- combinedData %>%
#   filter(subject %in% subjects_to_exclude)
# 
# combinedData <- combinedData_kept

# 1) Put in your DV and IVs
dependent_variable <- "angle1"
independent_variables <- c("repetition", "context")

dv <- sym(dependent_variable)

# 1) Subject exclusions based on ANGLE1 (DV-independent)
bad_subjects <- combinedData %>%
  mutate(
    subject = factor(subject),
    angle1_num = as.numeric(as.character(angle1)),
    angle1_abs = abs(((angle1_num + 180) %% 360) - 180)
  ) %>%
  filter(is.finite(angle1_abs), is.finite(rt1), rt1 >= 0.3) %>% 
  group_by(subject) %>%
  summarize(mean_abs_angle1 = mean(angle1_abs, na.rm = TRUE), .groups = "drop") %>%
  filter(mean_abs_angle1 > 45) 

message("Excluded subjects (mean abs circular error > 45°):")
print(bad_subjects)

# 2) Apply exclusion to the raw data
combinedData_sub <- combinedData %>%
  mutate(subject = factor(subject)) %>%
  filter(!(subject %in% bad_subjects$subject))

combinedData_sub <- combinedData_sub %>%
  mutate(
    raw_outcome = as.numeric(as.character(!!dv)),
    signed_error = (((raw_outcome + 180) %% 360) - 180),
    
    repetition = factor(repetition, levels = c(1, 5), labels = c("1", "5")),
    context = factor(context, levels = c(0, 1), labels = c("No Change", "Change")),
    
    target_color = secondaryColor, # Novel item color (number index from 0 to 359)
    other_color  = primaryColor, # Repeated item color
    
    other_direction = ((other_color - target_color + 180) %% 360) - 180, # Length of the shortest distance to the repeated item
    
    direction_sign = ifelse(other_direction >= 0, 1, -1), # Where is the repeated item relative to the novel one (+ = clockwise)
    
    attractive_bias = (-signed_error * direction_sign), # Where did the respond land on the way to the repeated item? 
    # (negative signed error because I save signed error in the experimen as target - response)
    
    normalized_attraction = attractive_bias / abs(other_direction)
  ) %>%
  filter(
    is.finite(attractive_bias),
    is.finite(rt1),
    rt1 >= 0.3,
    repetition %in% c("1","5"),
    context %in% c("No Change","Change")
  )


data_RMAnova <- combinedData_sub %>%
  group_by(subject, repetition, context) %>%
  summarize(outcome = mean(attractive_bias, na.rm = TRUE), .groups = "drop") %>%
  mutate(subject = factor(subject))


descriptives <- data_RMAnova %>%
  group_by(repetition, context) %>%
  summarize(
    mean = mean(outcome),
    sd = sd(outcome),
    n_subj = n_distinct(subject),
    se = sd / sqrt(n_subj),
    .groups="drop"
  )
print(descriptives)


afex_options(type = 3, check_contrasts = TRUE)
aov_mod <- aov_ez(
  id     = "subject",
  dv     = "outcome",
  within = c("repetition", "context"),
  data   = data_RMAnova,
  type   = 3
)

anova_tbl <- anova(aov_mod)

anova_tbl$pes <- with(
  anova_tbl,
  (F * `num Df`) / (F * `num Df` + `den Df`)
)

print(anova_tbl)


bias_mod <- lmer(
  attractive_bias ~ repetition * context + (1 | subject),
  data = combinedData_sub
)

summary(bias_mod)
emmeans(bias_mod, pairwise ~ context | repetition)

