# Imperil or Protect - Experiment 4 - Alpha/Beta Analysis
# Cleaned pipeline: RM-ANOVA as primary, Gamma GLMM as robustness check

### SETUP ----
library(R.matlab)
library(dplyr)
library(ggplot2)
library(emmeans)
library(stringr)
library(afex)
library(glmmTMB)
library(patchwork)
library(writexl)
library(tidyr)

options(scipen = 999)

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

### PREPROCESSING
dependent_variable <- "angle1"
rt_vars <- c("rt1", "rt2")

combinedData_sub <- combinedData %>%
  mutate(
    DV = abs(.data[[dependent_variable]]),
    subject = factor(subject),
    repetition = factor(repetition, levels = c(1,5), labels = c("1","5")),
    context = factor(context, levels = c(0,1), labels = c("No Change","Change"))
  ) %>%
  # Filter out timed-out trials
  filter(is.finite(DV)) %>%
  # Filter out too rapid responses
  filter(rt1 >= .3) %>%
  # Filter down to critical repetitions
  filter(repetition %in% c("1","5"),
         context %in% c("No Change","Change"))

# Subject means BEFORE exclusion
subject_means_before <- combinedData_sub %>%
  group_by(subject) %>%
  summarize(mean_DV = mean(DV, na.rm = TRUE), .groups = "drop")

# Filter out people with too high an overall mean
bad_subjects <- subject_means_before %>%
  filter(mean_DV > 45)
combinedData_sub <- combinedData_sub %>%
  filter(!(subject %in% bad_subjects$subject))

# Subject means AFTER exclusion
subject_means_after <- combinedData_sub %>%
  group_by(subject) %>%
  summarize(mean_DV = mean(DV, na.rm = TRUE), .groups = "drop")

# Compute interaction values per participant
int_values <- combinedData_sub %>%
  group_by(subject, context, repetition) %>%
  summarise(mean_DV = mean(DV, na.rm = TRUE), .groups = "drop")

int_values_wide <- int_values %>%
  pivot_wider(
    names_from = c(context, repetition),
    values_from = mean_DV,
    names_sep = "_"
  )

int_values_final <- int_values_wide %>%
  mutate(
    d_R1 = `Change_1` - `No Change_1`,
    d_R5 = `Change_5` - `No Change_5`,
    interaction_value = d_R5 - d_R1
  )

interaction_vector <- int_values_final$interaction_value

write_xlsx(int_values_final, "interaction_jasp.xlsx")

