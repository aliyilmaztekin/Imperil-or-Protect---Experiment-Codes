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

# -----------------------------
# 1. Load MAT files
# -----------------------------
raw_data <- "/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment1_sixlets_anova.mat"
raw_data_read <- readMat(raw_data)

# Extract numeric matrix and convert to data frame
raw_data_matrix <- raw_data_read$all.data.experiment1.sixlets.anova
raw_data_data_frame <- as.data.frame(raw_data_matrix)

# Assign column names
colnames(raw_data_data_frame) <- c(
  "subject", "trial", "repetition", "block", "angle",
  "rt", "initiation_time", "movement_time",
  "condition", "context", "interference"
)

combinedData <- raw_data_data_frame

# -----------------------------
# 2. Filter relevant IVs and log-transform DV
# -----------------------------

dependent_variable <- "rt"

# Choose epsilon based on DV
epsilon <- ifelse(dependent_variable == "angle", 1e-6, 0)

combinedData_sub <- combinedData %>%
  mutate(
    DV = log(.data[[dependent_variable]] + epsilon),  # add epsilon only if needed
    repetition = factor(repetition),
    context = factor(context),
    interference = factor(interference)
  ) %>%
  filter(!is.na(DV))

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


# 4. Filter out the non-critical item repetitions
combinedData_sub <- combinedData_sub %>%
  filter(
    repetition %in% c(1, 5),
    context %in% c(0, 1),
    interference %in% c(0, 1)
  )


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


### To obtain descriptive statistics, you need to repeat the above pipeline with raw values

# Store the relevant data
combinedData_desc <- combinedData %>%
  mutate(
    DV_raw = .data[[dependent_variable]],   # <-- raw values
    repetition   = factor(repetition),
    context      = factor(context),
    interference = factor(interference)
  ) %>%
  filter(!is.na(DV_raw))

# Outlier rejection
combinedData_desc <- combinedData_desc %>%
  group_by(subject, repetition, context, interference) %>%
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
    repetition %in% c(1, 5),
    context %in% c(0, 1),
    interference %in% c(0, 1)
  )

# Compute descriptive stats for each condition (means and SDs)
descriptives <- combinedData_desc %>%
  group_by(repetition, context, interference) %>%
  summarize(
    mean_raw = mean(DV_raw, na.rm = TRUE),
    sd_raw   = sd(DV_raw, na.rm = TRUE),
    n        = n(),
    .groups = "drop"
  )

print(descriptives)

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




ggplot(data_RMAnova,
       aes(x = repetition,
           y = mean_DV,
           color = interference,
           group = interference)) +
  stat_summary(fun = mean, geom = "line", size = 1.2) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  facet_wrap(~ context) +
  labs(
    title = "Mean Log-Angle Deviation Across Conditions",
    x = "Repetition (1 vs 5)",
    y = "Mean DV (log-transformed angle)",
    color = "Interference"
  ) +
  theme_bw(base_size = 14)
