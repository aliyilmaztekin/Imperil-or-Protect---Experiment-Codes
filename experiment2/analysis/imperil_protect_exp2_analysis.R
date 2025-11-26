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
options(scipen = 999)  # Avoid scientific notation


### SET-UP

# 1) Load MAT files
raw_data <- "/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment2_sixlets_anova.mat"
raw_data_read <- readMat(raw_data)

# 2) Extract numeric matrix and convert to data frame
raw_data_matrix <- raw_data_read$all.data.experiment2.sixlets.anova
raw_data_data_frame <- as.data.frame(raw_data_matrix)

# 3) Assign column names
colnames(raw_data_data_frame) <- c(
  "subject", "trial", "repetition", "block", "angle",
  "rt", "initiation_time", "movement_time",
  "condition", "context", "interference"
)

# 4) Rename the dataset (optional)
combinedData <- raw_data_data_frame


### PREPROCESSING

# 1) Put in your DV and IVs
dependent_variable <- "angle"
independent_variables <- c("repetition", "context", "interference")

# 2) Log-transform your dependent variable? Check true if yes. 
log_me <- TRUE

# 3) Add a small epsilon value to your raw data before log-transform to avoid log(0)? 
epsilon_yes <- TRUE
epsilon <- if (epsilon_yes) 1e-6 else 0

# 4) Log-transform the data as requested, and turn IVs into factors
combinedData_sub <- combinedData %>%
  mutate(
    DV = ifelse(
      log_me,
      ifelse(
        epsilon_yes,
        log(.data[[dependent_variable]] + epsilon),
        log(.data[[dependent_variable]])
      ),
      .data[[dependent_variable]]
    ),
    across(all_of(independent_variables), factor)
  ) %>%
  filter(!is.na(DV))


# 5) Outlier rejection
combinedData_sub <- combinedData_sub %>%
  group_by(subject) %>%
  mutate(mean_DV = mean(DV, na.rm = TRUE),
         sd_DV   = sd(DV, na.rm = TRUE)) %>%
  ungroup() %>%
  filter(DV >= (mean_DV - 2.5 * sd_DV) &
           DV <= (mean_DV + 2.5 * sd_DV)) %>%
  select(-mean_DV, -sd_DV)  # drop temporary columns


# 6) Reduce the dataset down to the critical item repetitions (1st & 5th)
combinedData_sub <- combinedData_sub %>%
  filter(
    repetition %in% c(1, 5),
    context %in% c(0, 1),
    interference %in% c(0, 1)
  )


## ANALYSIS: 
# 1) Describe the data. This can't be done on log-transformed data.
# Thus, first store the raw version of your data

# Store the raw data, convert your IVs into factors
combinedData_desc <- combinedData %>%
  mutate(
    DV_raw = .data[[dependent_variable]],            
    across(all_of(independent_variables), factor)   
  ) %>%
  filter(!is.na(DV_raw))

# 2) Outlier rejection on the descriptive data
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

# 3) Filter the descriptive data down to the critical item repetitions
combinedData_desc <- combinedData_desc %>%
  filter(
    repetition %in% c(1, 5),
    context %in% c(0, 1),
    interference %in% c(0, 1)
  )

# 4) Finally, compute means and SDs for each condition. 
# These values should be reported in the Results section, and should be followed by ANOVA results 
descriptives <- combinedData_desc %>%
  group_by(repetition, context, interference) %>%
  summarize(
    mean_raw = mean(DV_raw, na.rm = TRUE),
    sd_raw   = sd(DV_raw, na.rm = TRUE),
    n        = n(),
    .groups = "drop"
  )

print(descriptives)


# -----------------------------
# 6. Create RM-ANOVA dataset (per-participant per-condition averages)
# -----------------------------
data_RMAnova <- combinedData_sub %>%
  group_by(subject, repetition, context, interference) %>%
  summarize(mean_DV = mean(DV), .groups = "drop")

anova_res <- ezANOVA(
  data = data_RMAnova,
  dv = mean_DV,             # <- use the actual column name
  wid = subject,
  within = .(repetition, context, interference),
  type = 3,
  detailed = TRUE
)

anova_clean <- anova_res$ANOVA %>%
  mutate(
    eta_p2 = SSn / (SSn + SSd)
  ) %>%
  mutate(across(where(is.numeric), ~ round(.x, 3)))

print(anova_clean)










# This is the same analysis as the one above, but now computed for each participant separately
descriptives_participant <- combinedData_desc %>%
  group_by(subject, repetition, context, interference) %>%
  summarize(mean_raw = mean(DV_raw), .groups = "drop") %>%
  group_by(repetition, context, interference) %>%
  summarize(
    grand_mean = mean(mean_raw),
    grand_sd   = sd(mean_raw),
    .groups = "drop"
  )










