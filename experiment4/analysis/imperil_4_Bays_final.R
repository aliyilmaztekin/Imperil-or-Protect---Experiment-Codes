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
library(ggplot2)
library(rlang)
library(BayesFactor)

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

# --- (B) Mean of SUBJECT means for ANGLE1_ABS after exclusion (each subject equal weight)

angle1_clean <- combinedData_sub %>%
  mutate(
    angle1_num = as.numeric(as.character(angle1)),
    angle1_abs = abs(((angle1_num + 180) %% 360) - 180)
  ) %>%
  # use the SAME trial filter you used when computing bad_subjects
  filter(is.finite(angle1_abs), is.finite(rt1), rt1 >= 0.3)

grand_mean_angle1_abs_B <- angle1_clean %>%
  group_by(subject) %>%
  summarize(subj_mean_angle1_abs = mean(angle1_abs, na.rm = TRUE), .groups = "drop") %>%
  summarize(
    mean_angle1_abs = mean(subj_mean_angle1_abs),
    sd_angle1_abs   = sd(subj_mean_angle1_abs),
    n_subj          = n()
  )

message("Grand mean ANGLE1_ABS (mean of subject means) AFTER exclusion:")
print(grand_mean_angle1_abs_B)

# 3) Now do DV-specific preprocessing
combinedData_sub <- combinedData_sub %>%
  mutate(
    raw_outcome = as.numeric(as.character(!!dv)),
    outcome = if (dependent_variable %in% c("rt1", "rt2")) {
      raw_outcome
    } else {
      abs(((raw_outcome + 180) %% 360) - 180)
    },
    repetition = factor(repetition, levels = c(1, 5), labels = c("1", "5")),
    context = factor(context, levels = c(0, 1), labels = c("No Change", "Change"))
  ) %>%
  filter(is.finite(outcome), is.finite(rt1), rt1 >= 0.3) %>%
  filter(repetition %in% c("1","5"),
         context %in% c("No Change","Change"))


data_RMAnova <- combinedData_sub %>%
  group_by(subject, repetition, context) %>%
  summarize(outcome = mean(outcome, na.rm = TRUE), .groups = "drop") %>%
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

# If you want all the decimals
dput(descriptives$mean)
dput(descriptives$sd)


### RM-ANOVA (PRIMARY ANALYSIS) ----

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

### Bayesian sequential RM-ANOVA: interaction vs additive ----

# Use the aggregated RM-ANOVA data
bf_data <- data_RMAnova %>%
  mutate(
    subject    = factor(subject),
    repetition = factor(repetition),
    context    = factor(context)
  )

# All subjects, in sorted order
subjects_all <- bf_data %>%
  dplyr::pull(subject) %>%
  unique() %>%
  sort()

# Helper to compute BF for the interaction (full vs additive model)
compute_bf_interaction <- function(data, subjects) {
  d <- data %>%
    dplyr::filter(subject %in% subjects) %>%
    droplevels()

  # Need at least 2 subjects and 2 levels in each within factor
  if (length(unique(d$subject)) < 2 ||
      nlevels(d$repetition) < 2 ||
      nlevels(d$context) < 2) {
    return(NA_real_)
  }

  # Fit all candidate models once
  bf_all <- anovaBF(
    outcome ~ repetition * context + subject,
    data        = d,
    whichRandom = "subject"
  )

  # Expected ordering:
  # [1] repetition + subject
  # [2] context + subject
  # [3] repetition + context + subject
  # [4] repetition + context + repetition:context + subject
  if (length(bf_all) < 4) {
    return(NA_real_)
  }

  # With onlybf = TRUE this is already a numeric vector
  bf_vals <- extractBF(bf_all, onlybf = TRUE)

  # BF for interaction = BF(full) / BF(additive)
  as.numeric(bf_vals[4] / bf_vals[3])
}

# Sequential BF trajectory parameters
min_N            <- 10      # first sample size at which to start tracking
step_size        <- 2       # step size in number of subjects
bf_threshold_H1  <- 10      # reference threshold for H1 (interaction present)
bf_threshold_H0  <- 1 / 10  # reference threshold for H0 (no interaction)

seq_results <- data.frame(
  n_subjects = integer(),
  BF10       = numeric(),
  stringsAsFactors = FALSE
)

# Track BF10 for every k from min_N up to the full sample in steps of `step_size`
for (k in seq(from = min_N, to = length(subjects_all), by = step_size)) {
  current_subjects <- subjects_all[1:k]
  bf_k <- compute_bf_interaction(bf_data, current_subjects)

  seq_results <- rbind(
    seq_results,
    data.frame(
      n_subjects = k,
      BF10       = bf_k,
      stringsAsFactors = FALSE
    )
  )
}

print(seq_results)

# Determine the smallest sample size giving strong evidence for H1 or H0
sample_size_H1 <- if (any(seq_results$BF10 >= bf_threshold_H1, na.rm = TRUE)) {
  min(seq_results$n_subjects[seq_results$BF10 >= bf_threshold_H1], na.rm = TRUE)
} else {
  NA_integer_
}

sample_size_H0 <- if (any(seq_results$BF10 <= bf_threshold_H0, na.rm = TRUE)) {
  min(seq_results$n_subjects[seq_results$BF10 <= bf_threshold_H0], na.rm = TRUE)
} else {
  NA_integer_
}

cat("\nEstimated sample size for strong evidence in favor of interaction (BF10 >=", 
    bf_threshold_H1, "):", sample_size_H1, "subjects\n")
cat("Estimated sample size for strong evidence for no interaction (BF10 <=", 
    bf_threshold_H0, "):", sample_size_H0, "subjects\n\n")

# Simple plot of BF trajectory across subjects
ggplot(seq_results, aes(x = n_subjects, y = BF10)) +
  geom_line() +
  geom_point() +
  geom_hline(yintercept = bf_threshold_H1, linetype = "dashed", color = "darkgreen") +
  geom_hline(yintercept = bf_threshold_H0, linetype = "dashed", color = "red") +
  scale_y_log10(
    breaks = c(0.1, 0.2, 0.5, 1, 2, 5, 10),
    labels = c("0.1", "0.2", "0.5", "1", "2", "5", "10")
  ) +
  labs(
    x = "Number of subjects",
    y = "Bayes factor BF10 (interaction vs additive)",
    title = "Sequential Bayes factor for repetition × context interaction"
  ) +
  theme_minimal()