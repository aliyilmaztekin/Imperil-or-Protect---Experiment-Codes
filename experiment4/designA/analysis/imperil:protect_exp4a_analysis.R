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
  "imperil4dataID1.mat",
  "imperil4dataID2.mat",
  "imperil4dataID3.mat",
  "imperil4dataID4.mat",
  "imperil4dataID5.mat",
  "imperil4dataID6.mat",
  "imperil4dataID7.mat",
  "imperil4dataID8.mat",
  "imperil4dataID9.mat",
  "imperil4dataID10.mat",
  "imperil4dataID11.mat",
  "imperil4dataID12.mat"
)

base_dir <- "/Users/ali/Desktop/visual imperil project/imperil4materials/pilot_data_1/data_files/"

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

dv_col <- "initiation_time1"

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
skewness_value

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

anova_clean <- anova_res$ANOVA %>%
  mutate(across(where(is.numeric), ~ round(.x, 3)))

# Fit the same repeated-measures model for emmeans
aov_model <- aov(DV ~ repetition * context + Error(subject/(repetition*context)), data = combinedData_sub_means)

# Estimated marginal means
emm <- emmeans(aov_model, ~ context | repetition)

# Pairwise contrasts: context change vs no-change, at each repetition level
posthoc_context <- contrast(emm, method = "pairwise", adjust = "none")
print(posthoc_context)

# -----------------------------
# 5. Compute condition means & SE for plotting
# -----------------------------
plot_data <- combinedData_sub_means %>%
  group_by(repetition, context) %>%
  summarize(
    mean_DV = mean(DV),
    se_DV = sd(DV) / sqrt(n()),
    .groups = "drop"
  )

plot_data$context <- factor(
  plot_data$context,
  levels = c(0, 1),
  labels = c("No Change", "Change")
)

# Back-transform the log-transformed means
plot_data <- plot_data %>%
  mutate(
    mean_DV_log = mean_DV,  # store original log means
    mean_DV = exp(mean_DV_log) - 1,
    se_DV = (exp(mean_DV_log + se_DV) - exp(mean_DV_log))  # approximate SE in original space
  )

# -----------------------------
# 6. Extract p-values from ANOVA
# -----------------------------
anova_table <- anova_res$ANOVA
p_repetition <- anova_table$p[anova_table$Effect == "repetition"]
p_context <- anova_table$p[anova_table$Effect == "context"]
p_interaction <- anova_table$p[anova_table$Effect == "repetition:context"]

anova_labels <- c(
  paste0("Repetition p = ", signif(p_repetition, 3)),
  paste0("Context p = ", signif(p_context, 3)),
  paste0("Interaction p = ", signif(p_interaction, 3))
)

# -----------------------------
# 7. Compute dynamic label positions
# -----------------------------
max_y_data <- max(plot_data$mean_DV + plot_data$se_DV)
y_range <- max_y_data - min(plot_data$mean_DV - plot_data$se_DV)
spacing <- y_range * 0.1  # 10% of range between stacked labels

# Create a dynamic y-axis label
y_label <- switch(dv_col,
                  "angle1" = "Angular Deviation (Back-Transformed): Test 1",
                  "angle2" = "Angular Deviation (Back-Transformed): Test 2",
                  "initiation_time1" = "Mouse Onset (Back-Transformed): Test 1",
                  "initiation_time2" = "Mouse Onset (Back-Transformed): Test 2",
                  "rt1" = "Reaction Time (Back-Transformed): Test 1",
                  "rt2" = "Reaction Time (Back-Transformed): Test 2"
)
# -----------------------------
# 8. Plot results
# -----------------------------
ggplot(plot_data,
       aes(x = repetition, y = mean_DV, color = context, group = context)) +
  geom_point(size = 3) +
  geom_line() +
  geom_errorbar(aes(ymin = mean_DV - se_DV, ymax = mean_DV + se_DV), width = 0.2) +
  labs(
    title = "Experiment 4: Repetition × Context Change Interaction",
    x = "Repetition",
    y = y_label,
    color = "Context"
  ) +
  theme_minimal(base_size = 14) +
  annotate("text",
           x = mean(as.numeric(plot_data$repetition)),
           y = max_y_data + 3 * spacing,
           label = anova_labels[3], size = 5, hjust = 0.5) +
  annotate("text",
           x = mean(as.numeric(plot_data$repetition)),
           y = max_y_data + 2 * spacing,
           label = anova_labels[1], size = 4, hjust = 0.5) +
  annotate("text",
           x = mean(as.numeric(plot_data$repetition)),
           y = max_y_data + spacing,
           label = anova_labels[2], size = 4, hjust = 0.5) +
  expand_limits(y = max_y_data + 4 * spacing)

# -----------------------------
# 9. Compute within-participant difference scores
# -----------------------------
within_sd <- combinedData_sub_means %>%
  spread(context, DV) %>%
  mutate(diff = `1` - `0`) %>%
  group_by(repetition) %>%
  summarize(
    mean_diff = mean(diff, na.rm = TRUE),
    sd_diff = sd(diff, na.rm = TRUE),
    n = n(),
    se_diff = sd_diff / sqrt(n),
    dz = mean_diff / sd_diff
  )
print(within_sd)

# -----------------------------
# 10. Compute partial eta squared
# -----------------------------
anova_table <- anova_res$ANOVA %>%
  mutate(eta_p2 = SSn / (SSn + SSd))
print(anova_table)

# -----------------------------
# 11. Descriptive stats
# -----------------------------
repetition_stats <- combinedData_sub_means %>%
  group_by(repetition) %>%
  summarize(M = mean(DV), SD = sd(DV), n = n(), .groups = "drop")

context_stats <- combinedData_sub_means %>%
  group_by(context) %>%
  summarize(M = mean(DV), SD = sd(DV), n = n(), .groups = "drop")

interaction_stats <- combinedData_sub_means %>%
  group_by(repetition, context) %>%
  summarize(M = mean(DV), SD = sd(DV), n = n(), .groups = "drop")

# print(repetition_stats)
# print(context_stats)
# print(interaction_stats)

# -----------------------------
# 9. Prepare data for JASP (wide format)
# -----------------------------
library(tidyr)

# Convert to wide format for JASP
jasp_data <- combinedData_sub_means %>%
  mutate(
    # Rename numeric codes for clarity
    context = ifelse(context == 0, "nochange", "change"),
    repetition = paste0("rep", repetition)
  ) %>%
  unite(condition, repetition, context, sep = "_") %>%
  pivot_wider(names_from = condition, values_from = DV)

# Check the reshaped data
head(jasp_data)

# Save to CSV (change path if you want)
write.csv(jasp_data,
          "/Users/ali/Desktop/visual imperil project/imperil4materials/pilot_data_1/data_files/imperil4_JASP_ready.csv",
          row.names = FALSE)
