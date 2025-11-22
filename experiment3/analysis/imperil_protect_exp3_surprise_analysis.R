# -----------------------------
# Libraries
# -----------------------------
library(R.matlab)
library(dplyr)
library(tidyr)
library(ez)
library(ggplot2)
library(moments)
library(emmeans)
library(lme4)
library(lmerTest)  # optional for p-values
options(scipen = 999)  # Avoid scientific notation

# -----------------------------
# 1. Load MAT files
# -----------------------------
raw_data <- "/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment3_surprise_anova.mat"
raw_data_read <- readMat(raw_data)

# Extract numeric matrix and convert to data frame
raw_data_matrix <- raw_data_read$all.data.experiment3.surprise.anova
raw_data_data_frame <- as.data.frame(raw_data_matrix)

# Assign column names
colnames(raw_data_data_frame) <- c(
  "subject", "trial", "repetition", "context", "interference",
  "angle", "rt", "initiation_time", "movement_time",
  "binary_acc"
)

combinedData <- raw_data_data_frame


# -----------------------------
# 2. Filter relevant IVs and log-transform DV
# -----------------------------

dependent_variable <- "angle"

# # Choose epsilon based on DV
epsilon <- 1e-6

combinedData_sub <- combinedData %>%
  mutate(
    DV = log(.data[[dependent_variable]] + epsilon),  # add epsilon only if needed
    subject = factor(subject),
    context = factor(context),
    interference = factor(interference)
  ) %>%
  filter(!is.na(DV))

print(nrow(combinedData_sub))

# -----------------------------
# 3. Remove outliers per participant (±2.5 SD)
# -----------------------------
combinedData_sub <- combinedData_sub %>%
  group_by(subject) %>%
  mutate(mean_DV = mean(DV, na.rm = TRUE),
         sd_DV   = sd(DV, na.rm = TRUE)) %>%
  ungroup() %>%
  filter(DV >= (mean_DV - 2.5 * sd_DV) &
           DV <= (mean_DV + 2.5 * sd_DV)) %>%
  select(-mean_DV, -sd_DV)  # drop temporary columns

print(nrow(combinedData_sub))


# trial-level data → RM ANOVA
anovaResult <- ezANOVA(
  data = combinedData_sub,
  dv = DV,
  wid = subject,
  within = .(context, interference),
  type = 3,
  detailed = TRUE
)

anova_clean <- anovaResult$ANOVA %>%
  mutate(across(where(is.numeric), ~ round(.x, 3)))  # keep 3 decimals

print(anova_clean)



combinedData_acc <- combinedData %>%
  mutate(
    subject = factor(subject),
    context = factor(context),
    interference = factor(interference),
    binary_acc = as.factor(binary_acc)
  )

# Fit logistic mixed model
model_acc <- glmer(
  binary_acc ~ context * interference + (1 | subject),
  data = combinedData_acc,
  family = binomial
)

summary(model_acc)

