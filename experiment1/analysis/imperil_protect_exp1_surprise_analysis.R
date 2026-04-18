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
library(afex)

# -----------------------------
# 1. Load MAT files
# -----------------------------
raw_data <- "/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment1_surprise_anova.mat"
raw_data_read <- readMat(raw_data)

# Extract numeric matrix and convert to data frame
raw_data_matrix <- raw_data_read$all.data.experiment1.surprise.anova
raw_data_data_frame <- as.data.frame(raw_data_matrix)

# Assign column names
colnames(raw_data_data_frame) <- c(
  "subject", "trial", "context", "context_type", "interference",
  "binary_acc", "angle", "rt")

combinedData <- raw_data_data_frame
dv <- "binary_acc"

combinedData_sub <- combinedData %>%
  mutate(
    raw_outcome = .data[[dv]],
    outcome = if (dv %in% c("rt", "binary_acc")) {
      raw_outcome
    } else {
      abs(((raw_outcome + 180) %% 360) - 180)
    },
    context = factor(context, levels = c(0, 1), labels = c("No Change", "Change")),
    interference = factor(interference, levels = c(0, 1), labels = c("No Interference", "Interference"))
  ) %>%
  filter(is.finite(outcome), is.finite(rt), rt >= 0.3) %>%
  filter(
    context %in% c("No Change", "Change"),
    interference %in% c("No Interference", "Interference")
  )

data_RMAnova <- combinedData_sub %>%
  group_by(subject, context, interference) %>%
  summarize(outcome = mean(outcome, na.rm = TRUE), .groups = "drop") %>%
  mutate(subject = factor(subject))

descriptives <- data_RMAnova %>%
  group_by(context, interference) %>%
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
  within = c("context", "interference"),
  data   = data_RMAnova,
  type   = 3
)

anova_tbl <- anova(aov_mod)

anova_tbl$pes <- with(
  anova_tbl,
  (F * `num Df`) / (F * `num Df` + `den Df`)
)

print(anova_tbl)


combinedData_gamma <- combinedData_sub %>%
  filter(is.finite(outcome), outcome != 0)

glmm_mod <- glmmTMB(
  outcome ~  context * interference + (1 | subject),
  data = combinedData_gamma,
  family = Gamma(link = "log")
)

summary(glmm_mod)

combinedData_acc <- combinedData_sub %>%
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


acc_summary <- combinedData_acc %>%
  group_by(context, interference) %>%
  summarise(
    mean_acc = mean(as.numeric(as.character(binary_acc))),  # convert factor → numeric
    n = n(),                                                # number of trials in cell
    .groups = "drop"
  ) %>%
  mutate(
    percent_acc = round(mean_acc * 100, 2)
  )

print(acc_summary)


overall_acc <- combinedData_acc %>%
  summarise(
    overall = mean(as.numeric(as.character(binary_acc))),
    percent = round(overall * 100, 2)
  )

print(overall_acc)

### Descriptive statistics: 

combinedData_desc <- combinedData %>%
  mutate(
    DV_raw = .data[[dependent_variable]],  # add epsilon only if needed
    subject = factor(subject),
    context = factor(context),
    interference = factor(interference)
  ) %>%
  filter(!is.na(DV_raw))

# Outlier rejection
combinedData_desc <- combinedData_desc %>%
  group_by(subject) %>%
  mutate(
    mean_raw = mean(DV_raw, na.rm = TRUE),
    sd_raw   = sd(DV_raw, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  filter(
    DV_raw >= (mean_raw - 2.5 * sd_raw) &
      DV_raw <= (mean_raw + 2.5 * sd_raw)
  ) %>%
  select(-mean_raw, -sd_raw)

# Subset the data down to the critical trials
combinedData_desc <- combinedData_desc %>%
  filter(
    context %in% c(0, 1),
    interference %in% c(0, 1)
  )

# Compute descriptive stats for each condition (means and SDs)
descriptives <- combinedData_desc %>%
  group_by(context, interference) %>%
  summarize(
    mean_raw = mean(DV_raw, na.rm = TRUE),
    sd_raw   = sd(DV_raw, na.rm = TRUE),
    n        = n(),
    .groups = "drop"
  )

print(descriptives)


#estimatedmarginalmeans

emm_acc <- emmeans(model_acc, ~ context * interference, type = "response")
emm_acc
pairs(emm_acc)


lmm_angle <- lmer(
  DV ~ context * interference + (1 | subject),
  data = combinedData_sub
)
emm_angle <- emmeans(lmm_angle, ~ context * interference)
emm_angle


