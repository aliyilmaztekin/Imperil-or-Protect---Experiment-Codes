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

# 1th column: Participant ID
# 2th column: Trial Number
# 3th column: Item Repetition
# 4th column: Block Number
# 5th column: Angular Deviation
# 6th column: Reaction Time
# 7th column: Initiation Time
# 8th column: Movement Time
# 9th column: Condition Codes
# 10th column: Context
# 11th column: Interference

# -----------------------------
# 1. Load MAT files
# -----------------------------

raw_data <- "/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment1_sixlets_anova.mat"
raw_data_read <- readMat(raw_data)

# Extract numeric matrix
raw_data_matrix <- raw_data_read$all.data.experiment1.sixlets.anova

# Confirm it's numeric and has dimensions
dim(raw_data_matrix)

# Convert to data frame
raw_data_data_frame <- as.data.frame(raw_data_matrix)

# Assign column names
colnames(raw_data_data_frame) <- c(
  "subject", "trial", "repetition", "block", "angle",
  "rt", "initiation_time", "movement_time",
  "condition", "context", "interference"
)

combinedData <- raw_data_data_frame

# -----------------------------
# 2. Filter for relevant IVs and compute DV
# -----------------------------
combinedData_sub <- combinedData %>%
  filter(
    repetition %in% c(1, 5),     # repetitions 1 and 5
    context %in% c(0, 1),    # contextChange 0 and 1
    interference %in% c(0, 1)     # interference 0 and 1
  ) %>%
  mutate(
    DV = log(angle + 1),
    repetition = factor(repetition), 
    context = factor(context),
    interference = factor(interference)
  ) %>%
  filter(!is.na(DV))     # remove NaN/timeout trials

# -----------------------------
# 2b. Remove outliers per participant (beyond 2.5 SD)
# -----------------------------
combinedData_sub <- combinedData_sub %>%
  group_by(subject) %>%
  mutate(mean_DV = mean(DV, na.rm = TRUE),
         sd_DV = sd(DV, na.rm = TRUE)) %>%
  ungroup() %>%
  filter(DV >= (mean_DV - 2.5 * sd_DV) &
           DV <= (mean_DV + 2.5 * sd_DV)) %>%
  select(-mean_DV, -sd_DV)   # drop temporary columns

# -----------------------------
# 3. Collapse to participant x condition means
# -----------------------------
combinedData_sub_means <- combinedData_sub %>%
  group_by(subject, repetition, context, interference) %>%
  summarize(DV = mean(DV, na.rm = TRUE), .groups = "drop")

# -----------------------------
# 4. Run repeated measures ANOVA
# -----------------------------
anova_res <- ezANOVA(
  data = combinedData_sub_means,
  dv = .(DV),
  wid = .(subject),
  within = .(repetition, context, interference),
  type = 3,
  detailed = TRUE
)

anova_clean <- anova_res$ANOVA %>%
  mutate(across(where(is.numeric), ~ round(.x, 3)))  # keep 3 decimals

# Fit repeated-measures ANOVA model with the new factor 'interference'
aov_model <- aov(
  DV ~ repetition * context * interference +
    Error(subject / (repetition * context * interference)),
  data = combinedData_sub_means
)

# Estimated marginal means for context, separately by repetition and interference
emm <- emmeans(aov_model, ~ interference | repetition * context, weights = "equal")


posthoc_comp <- contrast(emm, method = "pairwise", adjust = "none")  # or adjust="holm"
print(posthoc_comp)

data_summary <- combinedData_sub_means %>%
  group_by(repetition, context, interference) %>%
  summarize(
    mean_DV = mean(DV, na.rm = TRUE),
    se_DV = sd(DV, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

# Rename context labels
data_summary$context <- factor(
  data_summary$context,
  levels = c(0, 1),
  labels = c("No Change", "Change")
)

# Rename interference labels
data_summary$interference <- factor(
  data_summary$interference,
  levels = c(0, 1),
  labels = c("No Interference", "Interference")
)


# -----------------------------
# 6. Extract p-values from ANOVA
# -----------------------------
anova_table <- anova_clean

p_repetition <- anova_table$p[anova_table$Effect == "repetition"]
p_context <- anova_table$p[anova_table$Effect == "context"]
p_interference <- anova_table$p[anova_table$Effect == "interference"]
p_repetition_context <- anova_table$p[anova_table$Effect == "repetition:context"]
p_repetition_interference <- anova_table$p[anova_table$Effect == "repetition:interference"]
p_context_interference <- anova_table$p[anova_table$Effect == "context:interference"]
p_three_way <- anova_table$p[anova_table$Effect == "repetition:context:interference"]

anova_labels <- c(
  paste0("Repetition p = ", signif(p_repetition, 3)),
  paste0("Context p = ", signif(p_context, 3)),
  paste0("Interference p = ", signif(p_interference, 3)),
  paste0("Rep × Context p = ", signif(p_repetition_context, 3)),
  paste0("Rep × Interf p = ", signif(p_repetition_interference, 3)),
  paste0("Context × Interf p = ", signif(p_context_interference, 3)),
  paste0("3-way p = ", signif(p_three_way, 3))
)


# -----------------------------
# Compute partial eta squared for each effect
# -----------------------------
anova_table <- anova_res$ANOVA %>%
  mutate(
    # partial eta squared = SSn / (SSn + SSd)
    eta_p2 = SSn / (SSn + SSd)
  ) %>%
  # Round numeric columns for readability
  mutate(across(where(is.numeric), ~ round(.x, 3)))

print(anova_table)

# -----------------------------
# Back-transform mean and SE
# -----------------------------
data_summary_bt <- data_summary %>%
  mutate(
    mean_DV_bt = exp(mean_DV) - 1,
    se_DV_bt = (exp(mean_DV + se_DV) - 1) - mean_DV_bt
  )

# -----------------------------
# Compute dynamic y-axis limits
# -----------------------------
y_max <- max(data_summary_bt$mean_DV_bt + data_summary_bt$se_DV_bt) * 1.1  # 10% extra space
y_min <- min(data_summary_bt$mean_DV_bt - data_summary_bt$se_DV_bt) * 0.9  # 10% extra space

# -----------------------------
# Plot
# -----------------------------
ggplot(data_summary_bt,
       aes(x = repetition, y = mean_DV_bt,
           color = interference, shape = interference, group = interference)) +
  geom_point(size = 3) +
  geom_line() +
  geom_errorbar(aes(ymin = mean_DV_bt - se_DV_bt, ymax = mean_DV_bt + se_DV_bt), width = 0.2) +
  labs(
    title = "Experiment 1: Repetition × Interference by Context",
    x = "Repetition",
    y = "DV (original scale)",
    color = "Interference",
    shape = "Interference"
  ) +
  theme_minimal(base_size = 14) +
  facet_wrap(~ context) +
  theme(strip.text = element_text(size = 12, face = "bold")) +
  scale_y_continuous(limits = c(y_min, y_max), breaks = scales::pretty_breaks(n = 6))


# Helper function to compute mean ± 95% CI in log space, then back-transform
compute_backtransformed_CI <- function(df, group_vars) {
  df %>%
    group_by(across(all_of(group_vars))) %>%
    summarize(
      mean_log = mean(DV, na.rm = TRUE),
      sd_log = sd(DV, na.rm = TRUE),
      n = n(),
      se_log = sd_log / sqrt(n),
      ci_lower_log = mean_log - qt(0.975, n-1) * se_log,
      ci_upper_log = mean_log + qt(0.975, n-1) * se_log,
      .groups = "drop"
    ) %>%
    mutate(
      mean = exp(mean_log) - 1,
      ci_lower = exp(ci_lower_log) - 1,
      ci_upper = exp(ci_upper_log) - 1
    ) %>%
    select(-mean_log, -sd_log, -se_log, -ci_lower_log, -ci_upper_log)
}

# -----------------------------
# Main effects
# -----------------------------
repetition_stats <- compute_backtransformed_CI(combinedData_sub_means, "repetition")
context_stats <- compute_backtransformed_CI(combinedData_sub_means, "context")
interference_stats <- compute_backtransformed_CI(combinedData_sub_means, "interference")

# -----------------------------
# Two-way interactions
# -----------------------------
rep_context_stats <- compute_backtransformed_CI(combinedData_sub_means, c("repetition", "context"))
rep_interference_stats <- compute_backtransformed_CI(combinedData_sub_means, c("repetition", "interference"))
context_interference_stats <- compute_backtransformed_CI(combinedData_sub_means, c("context", "interference"))

# -----------------------------
# Three-way interaction
# -----------------------------
three_way_stats <- compute_backtransformed_CI(combinedData_sub_means, c("repetition", "context", "interference"))

# # -----------------------------
# # Print tables
# # -----------------------------
# print("Main effect: Repetition")
# print(repetition_stats)
# 
# print("Main effect: Context")
# print(context_stats)
# 
# print("Main effect: Interference")
# print(interference_stats)
# 
# print("Interaction: Repetition × Context")
# print(rep_context_stats)
# 
# print("Interaction: Repetition × Interference")
# print(rep_interference_stats)
# 
# print("Interaction: Context × Interference")
# print(context_interference_stats)
# 
# print("Three-way interaction: Repetition × Context × Interference")
# print(three_way_stats)


