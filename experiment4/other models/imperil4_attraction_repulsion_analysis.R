# Imperil or Protect - Experiment 4 - Attraction-Repulsion Analysis
# Coded by A.Y.

### SETUP/PARAMETERS ----

library(R.matlab)
library(dplyr)
library(ggplot2)
library(emmeans)
library(stringr)
library(lme4)
library(lmerTest)
library(glmmTMB)
library(brms)
library(rlang)
library(cowplot)
library(grid)
library(showtext)
library(sysfonts)
library(car)
library(ggtext)
library(pracma)
library(afex)

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

# Enter the analysis DV # Either "angle1" or "angle2"
dependent_variable    <- "angle2"

## Trial-level trimming
# Based on RT

lower <- 0.3

if (dependent_variable == "angle1" || dependent_variable == "rt1") {
  combinedData_firstpass <- combinedData %>%
    dplyr::filter(!is.na(rt1), rt1 > lower, !is.na(angle1), angle1 != 0)
} else if (dependent_variable == "angle2" || dependent_variable == "rt2") {
  combinedData_firstpass <- combinedData %>%
    dplyr::filter(!is.na(rt2), rt2 > lower, !is.na(angle2), angle2 != 0)
}

## Subject-level trimming
# Based on global angular error (at Test 1 specifically)

bad_subjects <- combinedData_firstpass %>%
  # Determine outlier subjects
  dplyr::group_by(subject) %>%
  dplyr::summarise(global_angle = mean(abs(angle1), na.rm = TRUE), .groups = "drop") %>%
  dplyr::filter(global_angle > 45)

message("Excluded subjects (mean abs circular error > 45 deg):")
print(bad_subjects)

combinedData_secondpass <- combinedData_firstpass %>%
  dplyr::mutate(subject = factor(subject)) %>%
  dplyr::filter(!(subject %in% bad_subjects$subject))

# Base preprocessing
combinedData_sub <- combinedData_secondpass %>%
  dplyr::mutate(
    outcome = abs(.data[[dependent_variable]]),
    raw_outcome = .data[[dependent_variable]],
    repetition_num   = as.numeric(as.character(repetition)),
    context_num      = as.numeric(as.character(context)),
  )

# Repetition 1 and 5 dataset with context and interference
combinedData_sub_full <- combinedData_sub %>%
  dplyr::filter(
    repetition_num   %in% c(1, 5),
    context_num      %in% c(0, 1)
  ) %>%
  dplyr::mutate(
    repetition   = factor(repetition_num, levels = c(1, 5), labels = c("1", "5")),
    context      = factor(context_num, levels = c(0, 1),
                          labels = c("No Change", "Change")),
    subject = factor(subject)
  )

combinedData_gamma_full  <- combinedData_sub_full  %>% dplyr::filter(is.finite(outcome), outcome > 0)


# Bias computation:

# Find bias magnitude + bias type
# x = target 1 color, y = target 2 color, and z = reported color
# If target 1 is tested
# abs(z-x) = bias magnitude

ang_diff <- function(a, b) ((a - b + 180) %% 360) - 180

combinedData_gamma_bias <- combinedData_gamma_full %>%
  mutate(
    tested = if (dependent_variable == "angle1") secondaryColor else primaryColor,
    other  = if (dependent_variable == "angle1") primaryColor   else secondaryColor,
    error   = -ang_diff(raw_outcome, 0),   # MATLAB stores target - response
    d_other = ang_diff(other, tested),     # signed direction of the other item
    dist    = abs(d_other),
    bias    = error * sign(d_other)        # >0 attraction, <0 repulsion
  ) %>%
  filter(
    abs(error) <= 90,    # trim on ERROR, not on bias
    dist >= 5,
    dist <= 170
  )


data_RMAnova <- combinedData_gamma_bias %>%
  dplyr::group_by(subject, repetition, context) %>%
  dplyr::summarize(bias = mean(bias, na.rm = TRUE), .groups = "drop") %>%
  dplyr::mutate(subject = factor(subject))

descriptives <- data_RMAnova %>%
  dplyr::group_by(repetition, context) %>%
  dplyr::summarize(
    mean = mean(bias),
    sd = sd(bias),
    n_subj = n_distinct(subject),
    se = sd / sqrt(n_subj),
    .groups="drop"
  )
print(descriptives)


# Test whether there's a bias effect
# Aggregate to one value. A mean bias statistic collapsed across conditions

subj_bias <- combinedData_gamma_bias %>%
  group_by(subject) %>%
  summarise(bias = mean(bias, na.rm = TRUE), .groups = "drop")

t.test(subj_bias$bias, mu = 0)





# RM-ANOVA

afex_options(type = 3, check_contrasts = TRUE)
aov_mod <- aov_ez(
  id     = "subject",
  dv     = "bias",
  within = c("repetition", "context"),
  data   = data_RMAnova
)

anova_tbl <- anova(aov_mod)

anova_tbl$pes <- with(
  anova_tbl,
  (F * `num Df`) / (F * `num Df` + `den Df`)
)

print(anova_tbl)

emm <- emmeans(aov_mod, ~ context | repetition)
print(contrast(emm, method = "pairwise", infer = TRUE))

### LINEAR MIXED MODEL ----

library(lme4)
library(lmerTest)

# Trial-level data, with sum contrasts so the intercept is the grand mean
model_data <- combinedData_gamma_bias %>%
  dplyr::mutate(
    repetition = C(droplevels(factor(repetition)), contr.sum),
    context    = C(droplevels(factor(context)),    contr.sum),
    subject    = droplevels(factor(subject))
  )

lmm_bias <- lmer(bias ~ repetition * context + (1 | subject), data = model_data)

fixef(lmm_bias)[1]   # should now be ~0.83, not ~1.36
VarCorr(lmm_bias)    # check between-subject variance in the bias

car::Anova(lmm_bias, type = 3, test.statistic = "F")

emm <- emmeans(lmm_bias, ~ repetition)
print(contrast(emm, method = "pairwise", infer=TRUE))