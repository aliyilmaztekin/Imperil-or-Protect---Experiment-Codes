library(R.matlab)
library(dplyr)
library(tidyr)
library(ggplot2)
library(emmeans)
library(lme4)
library(lmerTest)  # optional for p-values
library(glmmTMB)
library(DHARMa)
library(car)
options(scipen = 999)  # Avoid scientific notation

raw_data <- "/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment2_surprise.mat"
raw_data_read <- readMat(raw_data)

# Extract numeric matrix and convert to data frame
raw_data_matrix <- raw_data_read$all.data.experiment2.surprise
raw_data_data_frame <- as.data.frame(raw_data_matrix)

# Assign column names
colnames(raw_data_data_frame) <- c(
  "subject", "trial", "context", "interference", "interference_type",
  "binary_acc", "angle", "rt", "waitRT", "decisionTime")

### CHOOSE DV TO ANALYZE
combinedData <- raw_data_data_frame
dv <- "angle"

### PREPROCESSING
combinedData$raw_outcome <- combinedData[[dv]]

combinedData_sub <- combinedData %>%
  dplyr::mutate(
    raw_outcome = as.numeric(as.character(raw_outcome)),
    rt = as.numeric(as.character(rt)),
    
    outcome = if (dv %in% c("rt", "waitRT", "decisionTime", "binary_acc")) {
      raw_outcome
    } else {
      abs(((raw_outcome + 180) %% 360) - 180)
    },
    
    subject = factor(subject),
    context = factor(context, levels = c(0, 1), labels = c("No Change", "Change")),
    interference = factor(interference, levels = c(0, 1), labels = c("No Interference", "Interference"))
  ) %>%
  dplyr::filter(
    is.finite(outcome),
    is.finite(rt),
    rt >= 0.3,
    context %in% c("No Change", "Change"),
    interference %in% c("No Interference", "Interference")
  )

# Remove outlier participants
combinedData_sub <- combinedData_sub %>%
  dplyr::filter(!as.character(subject) %in% c("14", "33")) %>%
  droplevels()

### ANALYSIS

# Subject-level condition means
# This makes each subject x condition cell contribute equally,
# instead of giving more weight to conditions with more trials.
subject_means <- combinedData_sub %>%
  dplyr::group_by(subject, context, interference) %>%
  dplyr::summarise(
    outcome_mean = mean(outcome, na.rm = TRUE),
    n_trials = dplyr::n(),
    .groups = "drop"
  )

# Optional: check trial count imbalance at subject level
trial_count_summary <- subject_means %>%
  dplyr::group_by(context, interference) %>%
  dplyr::summarise(
    mean_trials = mean(n_trials),
    min_trials = min(n_trials),
    max_trials = max(n_trials),
    .groups = "drop"
  )

print(trial_count_summary)

### DESCRIPTIVE STATISTICS

# Trial counts per condition, from trial-level data
trial_counts <- combinedData_sub %>%
  dplyr::group_by(context, interference) %>%
  dplyr::summarise(
    n_trials = dplyr::n(),
    n_subjects_raw = dplyr::n_distinct(subject),
    .groups = "drop"
  )

if (dv == "binary_acc") {
  
  # First calculate accuracy separately for each subject in each condition
  subject_descriptives <- combinedData_sub %>%
    dplyr::group_by(subject, context, interference) %>%
    dplyr::summarise(
      acc = mean(outcome, na.rm = TRUE),
      n_trials_subject = dplyr::n(),
      .groups = "drop"
    )
  
  # Then summarize across subjects
  descriptives <- subject_descriptives %>%
    dplyr::group_by(context, interference) %>%
    dplyr::summarise(
      mean_acc = mean(acc, na.rm = TRUE) * 100,
      sd_acc = sd(acc, na.rm = TRUE) * 100,
      n_subjects = dplyr::n(),
      se_acc = sd(acc, na.rm = TRUE) / sqrt(n_subjects) * 100,
      mean_trials_per_subject = mean(n_trials_subject, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::left_join(trial_counts, by = c("context", "interference"))
  
  descriptives_display <- descriptives %>%
    dplyr::select(
      context,
      interference,
      mean_acc,
      sd_acc,
      se_acc,
      n_subjects,
      n_trials,
      mean_trials_per_subject
    ) %>%
    dplyr::mutate(
      mean_acc = sprintf("%.1f", mean_acc),
      sd_acc = sprintf("%.1f", sd_acc),
      se_acc = sprintf("%.1f", se_acc),
      mean_trials_per_subject = sprintf("%.1f", mean_trials_per_subject)
    )
  
} else {
  
  # For continuous outcomes, summarize participant-level condition means
  subject_descriptives <- combinedData_sub %>%
    dplyr::group_by(subject, context, interference) %>%
    dplyr::summarise(
      outcome_mean = mean(outcome, na.rm = TRUE),
      n_trials_subject = dplyr::n(),
      .groups = "drop"
    )
  
  descriptives <- subject_descriptives %>%
    dplyr::group_by(context, interference) %>%
    dplyr::summarise(
      AVG = mean(outcome_mean, na.rm = TRUE),
      SD = sd(outcome_mean, na.rm = TRUE),
      n_subjects = dplyr::n(),
      SE = SD / sqrt(n_subjects),
      mean_trials_per_subject = mean(n_trials_subject, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::left_join(trial_counts, by = c("context", "interference"))
  
  descriptives_display <- descriptives %>%
    dplyr::select(
      context,
      interference,
      AVG,
      SD,
      SE,
      n_subjects,
      n_trials,
      mean_trials_per_subject
    ) %>%
    dplyr::mutate(
      AVG = sprintf("%.3f", AVG),
      SD = sprintf("%.3f", SD),
      SE = sprintf("%.3f", SE),
      mean_trials_per_subject = sprintf("%.1f", mean_trials_per_subject)
    )
}
print(descriptives_display)

if (dv == "binary_acc") {
  
  mod_acc <- lme4::glmer(
    binary_acc ~ context * interference + (1 | subject),
    data   = combinedData_sub,
    family = binomial(link = "logit")
  )
  car::Anova(mod_acc, type = 2)   
  
  rep_emm <- emmeans(mod_acc, ~ context, type = "response")   # marginal means + ratio  ← the estimate you report
  rep_contrast <- contrast(rep_emm, method = "pairwise", infer= TRUE)
  print(rep_contrast)
  
} else {
  
  # LME
  formula <- as.formula("outcome ~ context * interference + (1 | subject)")
  
  lme_test <- lmerTest::lmer(formula, data = combinedData_sub)
  
  omnibus_test <- car::Anova(lme_test, type = 2, test.statistic = "F")
  print(omnibus_test)
  
  rep_emm <- emmeans(lme_test, ~ context | interference)   # marginal means + ratio  ← the estimate you report
  rep_contrast <- contrast(rep_emm, method = "pairwise", infer= TRUE)
  print(rep_contrast)
  
  
}
