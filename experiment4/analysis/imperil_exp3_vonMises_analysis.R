# Imperil or Protect - Experiment 2 
# Coded by A.Y. 


### SETUP/PARAMETERS ----

library(afex)
# (Recommended) consistent Type-III tests for within factors
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

options(scipen = 999)  # Avoid scientific notation

raw_data <- "/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment3_sixlets_anova.mat"
raw_data_read <- readMat(raw_data)

# 2) Extract numeric matrix and convert to data frame
raw_data_matrix <- raw_data_read$all.data.experiment3.sixlets.anova
raw_data_data_frame <- as.data.frame(raw_data_matrix)

# 3) Assign column names
colnames(raw_data_data_frame) <- c(
  "subject", "trial", "repetition", "block", "angle",
  "rt", "initiation_time", "movement_time",
  "condition", "context", "interference"
)

# 4) Rename the dataset (optional)
combinedData <- raw_data_data_frame

### PREPROCESSING ----

# 1) Put in your DV and IVs
dependent_variable <- "angle"
independent_variables <- c("repetition", "context", "interference")

combinedData_sub <- combinedData %>%
  mutate(
    err_deg = ((angle + 180) %% 360) - 180,
    DV = err_deg * pi/180,
    abs_err_deg = abs(err_deg),
    DV_abs = abs_err_deg,
    subject = factor(subject),
    repetition = factor(repetition, levels = c(1,5), labels = c("1","5")),
    context = factor(context, levels = c(0,1), labels = c("No Change","Change")),
    interference = factor(interference, levels = c(0,1), labels = c("No Interference", "Interference"))
  ) %>%
  filter(is.finite(DV_abs), rt >= .3) %>%
  filter(repetition %in% c("1","5"),
         context %in% c("No Change","Change"),
         interference %in% c("No Interference", "Interference"))


bad_subjects <- combinedData_sub %>%
  group_by(subject) %>%
  summarize(mean_abs_err_deg = mean(DV_abs, na.rm = TRUE), .groups = "drop") %>%
  filter(mean_abs_err_deg > 60)


combinedData_sub <- combinedData_sub %>%
  filter(!(subject %in% bad_subjects$subject))

message("Excluded subjects (mean abs error > 45°):")
print(bad_subjects)

data_RMAnova <- combinedData_sub %>%
  group_by(subject, repetition, context, interference) %>%
  summarize(mean_DV_abs = mean(DV_abs, na.rm = TRUE), .groups = "drop") %>%
  mutate(subject = factor(subject))

descriptives <- data_RMAnova %>%
  group_by(repetition, context, interference) %>%
  summarize(
    mean = mean(mean_DV_abs),
    sd = sd(mean_DV_abs),
    n_subj = n(),
    se = sd / sqrt(n_subj),
    .groups="drop"
  )
print(descriptives)


### RM-ANOVA (PRIMARY ANALYSIS) ----

afex_options(type = 3, check_contrasts = TRUE)

aov_mod <- aov_ez(
  id     = "subject",
  dv     = "mean_DV_abs",
  within = c("repetition", "context", "interference"),
  data   = data_RMAnova,
  type   = 3
)
anova_tbl <- anova(aov_mod)

lmm_mod <- lmer(
  DV_abs ~ repetition * context * interference + (1 | subject),
  data = combinedData_sub,
  REML = FALSE
)
anova(lmm_mod, type = 3)

summary(lmm_mod)

glmm_gamma <- glmmTMB(
  DV_abs ~ repetition * context * interference + (1 | subject),
  data = combinedData_sub %>% filter(DV_abs > 0),
  family = Gamma(link="log")
)
summary(glmm_gamma)

vm_mod_kappa <- brm(
  bf(
    DV ~ repetition * context * interference + (1 | subject),
    kappa ~ repetition * context * interference
  ),
  data = combinedData_sub,
  family = von_mises(),
  chains = 4,
  cores = 4,
  iter = 4000
)

summary(vm_mod_kappa)




