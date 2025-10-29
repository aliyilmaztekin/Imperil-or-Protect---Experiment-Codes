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
library(rlang)
options(scipen = 999)  # Avoid scientific notation


# -----------------------------
# 1. Load MAT files
# -----------------------------
files <- c(
  "imperil4dataID13.mat",
  "imperil4dataID14.mat",
  "imperil4dataID15.mat",
  "imperil4dataID16.mat",
  "imperil4dataID17.mat",
  "imperil4dataID18.mat",
  "imperil4dataID19.mat",
  "imperil4dataID20.mat",
  "imperil4dataID21.mat",
  "imperil4dataID22.mat",
  "imperil4dataID23.mat",
  "imperil4dataID24.mat"
)

base_dir <- "/Users/ali/Desktop/visual imperil project/imperil4materials/pilot_data_2/"

dfs <- lapply(files, function(f) {
  mat <- readMat(file.path(base_dir, f))
  df <- as.data.frame(mat$outputMatrix)
  df
})

# Combine all participants
pilot_data <- bind_rows(dfs)

# Assign column names (make sure it matches your MATLAB matrix)
colnames(pilot_data) <- c(
  "subject", "conditionUsed", "block", "trial", "repetition",
  "context", "contextCode", "primaryColor", "secondaryColor",
  "angle1", "initiation_time1", "movement_time1", "rt1",
  "angle2", "initiation_time2", "movement_time2", "rt2",
  "breakTaken", "conditions"
)

pilot_data <- pilot_data[, !is.na(names(pilot_data))]

## Enter here the dependent variable to analyze

# -----------------------------
# Column reference
# -----------------------------
# 10th: angle1
# 11th: initiation_time1
# 12th: movement_time1
# 13th: rt1
# 14th: angle2
# 15th: initiation_time2
# 16th: movement_time2
# 17th: rt2

dv_col <- "angle1"

combinedData_sub <- pilot_data %>%
  filter(
    repetition %in% c(1, 5),
    context %in% c(0, 1)
  ) %>%
  mutate(
    DV = abs(!!sym(dv_col)),
    repetition = factor(repetition),
    context = factor(context)
  ) %>%
  filter(!is.na(DV))

# -----------------------------
# 2b. Remove outliers per participant (beyond 2.5 SD)
# -----------------------------
combinedData_sub <- combinedData_sub %>%
  group_by(subject) %>%
  mutate(
    mean_DV = mean(DV, na.rm = TRUE),
    sd_DV = sd(DV, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  filter(
    DV >= (mean_DV - 2.5 * sd_DV) &
      DV <= (mean_DV + 2.5 * sd_DV)
  ) %>%
  select(-mean_DV, -sd_DV)

# -----------------------------
# 2c. Apply log transform (after outlier removal)
# -----------------------------
combinedData_sub <- combinedData_sub %>%
  mutate(DV = log(DV + 1))  # +1 if your DV can ever be 0

skewness_value <- skewness(combinedData_sub$DV, na.rm = TRUE)


# -----------------------------
# 3. Collapse to participant × condition means
# -----------------------------
combinedData_sub_means <- combinedData_sub %>%
  group_by(subject, repetition, context) %>%
  summarize(DV = mean(DV, na.rm = TRUE), .groups = "drop")

# -----------------------------
# 4. Repeated-measures ANOVA
# -----------------------------
anova_res <- ezANOVA(
  data = combinedData_sub_means,
  dv = .(DV),
  wid = .(subject),
  within = .(repetition, context),
  type = 3,
  detailed = TRUE
)

# Fit the same repeated-measures model for emmeans
aov_model <- aov(DV ~ repetition * context + Error(subject/(repetition*context)), data = combinedData_sub_means)

# Estimated marginal means
emm <- emmeans(aov_model, ~ context | repetition)

# Pairwise contrasts: context change vs no-change, at each repetition level
posthoc_context <- contrast(emm, method = "pairwise", adjust = "none")
print(posthoc_context)

# -----------------------------
# 5. Plot results (log-transformed values)
# -----------------------------

# First, compute means and SE for plotting
plot_data <- combinedData_sub_means %>%
  group_by(repetition, context) %>%
  summarize(
    mean_DV = mean(DV, na.rm = TRUE),
    se_DV = sd(DV, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

# Make context labels nicer
plot_data$context <- factor(plot_data$context,
                            levels = c(0, 1),
                            labels = c("No-change", "Change"))

plot_data$repetition <- factor(plot_data$repetition,
                               levels = c(1, 5),
                               labels = c("1st repetition", "5th repetition"))

# Plot with ggplot
ggplot(plot_data,
       aes(x = repetition, y = mean_DV, color = context, group = context)) +
  geom_point(size = 3) +
  geom_line(linewidth = 1) +
  geom_errorbar(aes(ymin = mean_DV - se_DV, ymax = mean_DV + se_DV),
                width = 0.1, linewidth = 0.7) +
  theme_minimal(base_size = 14) +
  labs(
    title = "Log-transformed DV by Repetition and Context",
    x = "Repetition",
    y = "Mean log(DV)",
    color = "Context"
  ) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    legend.position = "right"
  )

# -----------------------------
# 9. Prepare data for JASP (wide format: log + raw)
# -----------------------------
library(tidyr)

# Compute both log-transformed and non-log-transformed means per subject × condition
combinedData_sub_means_both <- combinedData_sub %>%
  group_by(subject, repetition, context) %>%
  summarize(
    DV_log = mean(DV, na.rm = TRUE),                         # log-transformed mean
    DV_raw = mean(exp(DV) - 1, na.rm = TRUE),                # back-transformed mean (undo log(+1))
    .groups = "drop"
  )

# Prepare long → wide conversion labels
jasp_data_both <- combinedData_sub_means_both %>%
  mutate(
    context_label = ifelse(context == 0, "nochange", "change"),
    repetition_label = paste0("rep", repetition)
  ) %>%
  unite(condition, repetition_label, context_label, sep = "_") %>%
  pivot_wider(
    id_cols = subject,
    names_from = condition,
    values_from = c(DV_log, DV_raw),
    names_glue = "{condition}_{.value}"
  )

# Check result
head(jasp_data_both)

# Save to CSV for JASP
write.csv(
  jasp_data_both,
  "/Users/ali/Desktop/visual imperil project/imperil4materials/pilot_data_2/imperil4_JASP_ready.csv",
  row.names = FALSE
)
