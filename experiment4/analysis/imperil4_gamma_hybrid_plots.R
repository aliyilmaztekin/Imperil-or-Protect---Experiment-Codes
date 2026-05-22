# Imperil or Protect - Experiment 4 - Gamma GLMM analysis
# Coded by A.Y.

### SETUP/PARAMETERS ----

library(afex)
afex_options(type = 3, check_contrasts = TRUE)
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

# Subject exclusions based on ANGLE1 (DV-independent)
bad_subjects <- combinedData %>%
  dplyr::mutate(
    subject = factor(subject),
    angle1_num = as.numeric(as.character(angle1)),
    angle1_abs = abs(((angle1_num + 180) %% 360) - 180)
  ) %>%
  dplyr::filter(is.finite(angle1_abs), is.finite(rt1), rt1 >= 0.3) %>%
  dplyr::group_by(subject) %>%
  dplyr::summarise(mean_abs_angle1 = mean(angle1_abs, na.rm = TRUE), .groups = "drop") %>%
  dplyr::filter(mean_abs_angle1 > 45)
message("Excluded subjects (mean abs circular error > 45°):")
print(bad_subjects)

# Apply exclusion to raw data
combinedData_sub <- combinedData %>%
  mutate(subject = factor(subject)) %>%
  filter(!(subject %in% bad_subjects$subject))

# Base preprocessing
combinedData_sub_base <- combinedData_sub %>%
  dplyr::mutate(
    raw_outcome = as.numeric(as.character(.data[[dependent_variable]])),
    outcome = if (dependent_variable %in% c("rt1", "rt2")) {
      raw_outcome
    } else {
      abs((((raw_outcome + 180) %% 360) - 180))
    },
    repetition_num = as.numeric(as.character(repetition)),
    context_num = as.numeric(as.character(context))
  ) %>%
  dplyr::filter(
    is.finite(outcome),
    is.finite(rt1),
    rt1 >= 0.3
  )

# Full 1-6 repetition dataset
combinedData_sub_rep <- combinedData_sub_base %>%
  filter(repetition_num %in% 1:6) %>%
  mutate(
    repetition = factor(repetition_num, levels = 1:6, labels = c("1", "2", "3", "4", "5", "6")),
    subject = factor(subject)
  )

# Repetition 1 and 5 dataset with context manipulation
combinedData_sub_full <- combinedData_sub_base %>%
  filter(
    repetition_num %in% c(1, 5),
    context_num %in% c(0, 1)
  ) %>%
  mutate(
    repetition = factor(repetition_num, levels = c(1, 5), labels = c("1", "5")),
    context = factor(context_num, levels = c(0, 1), labels = c("No Change", "Change")),
    subject = factor(subject)
  )

combinedData_gamma_rep <- combinedData_sub_rep %>%
  filter(is.finite(outcome), outcome > 0)

combinedData_gamma_full <- combinedData_sub_full %>%
  filter(is.finite(outcome), outcome > 0)

# Optional sanity checks
print(table(combinedData_sub_rep$repetition, useNA = "ifany"))
print(table(combinedData_sub_full$repetition, combinedData_sub_full$context, useNA = "ifany"))

### MODELS ----

# Repetition-only model across all 6 reps
glmm_mod_rep <- glmmTMB(
  outcome ~ repetition + (1 | subject),
  data = combinedData_gamma_rep,
  family = Gamma(link = "log")
)

summary(glmm_mod_rep)

# Context model for repetitions 1 and 5 only
glmm_mod_full <- glmmTMB(
  outcome ~ repetition * context + (1 | subject),
  data = combinedData_gamma_full,
  family = Gamma(link = "log")
)

summary(glmm_mod_full)

### EMMs ----

# 1) Repetition-only EMMs across all 6 repetitions
emm_rep <- emmeans(glmm_mod_rep, ~ repetition, type = "response")
rep_df <- as.data.frame(emm_rep)

# 2) Context EMMs only at reps 1 and 5
emm_ctx <- emmeans(glmm_mod_full, ~ context | repetition, type = "response")
ctx_df <- as.data.frame(emm_ctx)

# Make sure repetition is ordered correctly
rep_df$repetition <- factor(rep_df$repetition, levels = c("1", "2", "3", "4", "5", "6"))
ctx_df$repetition <- factor(ctx_df$repetition, levels = c("1", "2", "3", "4", "5", "6"))

# Inspect tables
print(rep_df)
print(ctx_df)

### HYBRID PLOT ----

x_levels <- c("1", "2", "3", "4", "5", "6")

rep_df_for_points <- rep_df %>%
  filter(!repetition %in% c("1", "5")) %>%
  mutate(repetition = factor(repetition, levels = x_levels))

ctx_df <- ctx_df %>%
  mutate(repetition = factor(repetition, levels = x_levels))

error_plot <- ggplot() +
  geom_point(
    data = rep_df_for_points,
    aes(x = repetition, y = response),
    size = 6,
    color = "black"
  ) +
  geom_errorbar(
    data = rep_df_for_points,
    aes(x = repetition, ymin = asymp.LCL, ymax = asymp.UCL),
    width = 0.4,
    linewidth = 1.4,
    color = "black"
  ) +
  geom_point(
    data = ctx_df,
    aes(x = repetition, y = response, color = context),
    size = 6
  ) +
  geom_errorbar(
    data = ctx_df,
    aes(x = repetition, ymin = asymp.LCL, ymax = asymp.UCL, color = context),
    width = 0.4,
    linewidth = 1.4
  ) +
  scale_x_discrete(limits = x_levels) +
  scale_y_continuous(
    expand = expansion(mult = c(0.125, 0.15)),
    breaks = scales::breaks_width(1)
  ) +
  scale_color_manual(values = c("No Change" = "orange", "Change" = "steelblue")) +
  labs(
    x = "Repetition",
    y = "Angular Error (°)",
    color = "Context"
  ) +
  theme_classic() +
  theme(
    
    legend.title = element_blank(),
    plot.margin = margin(5, 5, 5, 5),
    legend.text = element_text(size = 32),
    
    legend.position = "right",
    
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    axis.title.x = element_text(
      face = "bold",
      size = 32,
      margin = margin(t = 4)
    ),
    axis.title.y = element_text(
      face = "bold",
      size = 32,
      margin = margin(r = 12)
    ),
    axis.text.x = element_text(
      size = 32,
      margin = margin(t = 8),
      color = "black"
    ),
    axis.text.y = element_text(
      size = 32,
      margin = margin(r = 8),
      color = "black"
    ),
    axis.ticks.length = unit(0.3, "cm"),
    text = element_text(family = "Arial")
  )

print(error_plot)

# ggsave(
#   filename = "error_plot.png",
#   plot = error_plot,
#   width = 10.48031,
#   height = 12.16142,
#   dpi = 300
# )


# Plot aesthetics 

legend_yes <- TRUE
if (legend_yes) {
  legend_pos = "right"
  legend_text_size = 20
  gg_title_pos = 0.6
} else {
  legend_pos = "none"
  legend_text_size = 20
  if (dependent_variable == "angle1") {
    gg_title_pos = 0.4
  } else if (dependent_variable == "angle2") {
    gg_title_pos = 0.5
  }
}

if (dependent_variable == "angle1") {
  # y axis settings:
  step_size <- c(1)
  y_range <- c(0.125, 0.2)
  # Plot title 
  ggtitle <- "Novel Item (Test 1)"
  y_label <- NULL
} else if (dependent_variable == "angle2") {
  # y axis settings:
  step_size <- c(2)
  y_range <- c(0.125, 0.2)
  # Plot title 
  ggtitle <- "Repeated Item (Test 2)"
  y_label <- "Angular Error (°)"
} else if (dependent_variable == "rt1") {
  # y axis settings:
  step_size <- c(0.25) * 100 # convert to ms
  y_range <- c(0.125, 0.3)
  # Plot title 
  ggtitle <- "Novel Item"
  y_label <- "Response Time (ms)"
} else if (dependent_variable == "rt2") {
  # y axis settings:
  step_size <- c(0.5) * 100 # convert to ms
  y_range <- c(0.125, 0.2)
  y_label <- "Response Time (ms)"
  # Plot title 
  ggtitle <- "Repeated Item"
}

scale_factor <- ifelse(dependent_variable %in% c("rt1", "rt2"), 1000, 1)


### WITHIN-SUBJECT HYBRID PLOT ----

library(Rmisc)

x_levels <- c("1", "2", "3", "4", "5", "6")

# 1) Repetition-only part: reps 1–6 collapsed across context
ws_df_rep <- combinedData_sub_rep %>%
  dplyr::group_by(subject, repetition) %>%
  dplyr::summarise(
    mean_error = mean(outcome * scale_factor, na.rm = TRUE),
    .groups = "drop"
  )

ws_summary_rep <- Rmisc::summarySEwithin(
  data = ws_df_rep,
  measurevar = "mean_error",
  withinvars = "repetition",
  idvar = "subject",
  conf.interval = 0.95
)

ws_summary_rep <- ws_summary_rep %>%
  dplyr::mutate(repetition = factor(repetition, levels = x_levels))

# 2) Context part: reps 1 and 5 only
ws_df_ctx <- combinedData_sub_full %>%
  dplyr::group_by(subject, repetition, context) %>%
  dplyr::summarise(
    mean_error = mean(outcome * scale_factor, na.rm = TRUE),
    .groups = "drop"
  )

ws_summary_ctx <- Rmisc::summarySEwithin(
  data = ws_df_ctx,
  measurevar = "mean_error",
  withinvars = c("repetition", "context"),
  idvar = "subject",
  conf.interval = 0.95
)

ws_summary_ctx <- ws_summary_ctx %>%
  dplyr::mutate(repetition = factor(repetition, levels = x_levels))

# 3) To avoid overplotting reps 1 and 5 twice
ws_summary_rep_for_points <- ws_summary_rep %>%
  dplyr::filter(!repetition %in% c("1", "5"))

# 4) Hybrid plot with identical styling to error_plot
ws_hybrid_plot <- ggplot() +
  geom_point(
    data = ws_summary_rep_for_points,
    aes(x = repetition, y = mean_error),
    size = 4,
    color = "black"
  ) +
  geom_errorbar(
    data = ws_summary_rep_for_points,
    aes(x = repetition, ymin = mean_error - ci, ymax = mean_error + ci),
    width = 0.3,
    linewidth = 1.0,
    color = "black"
  ) +
  geom_point(
    data = ws_summary_ctx,
    aes(x = repetition, y = mean_error, color = context),
    size = 4
  ) +
  geom_errorbar(
    data = ws_summary_ctx,
    aes(
      x = repetition,
      ymin = mean_error - ci,
      ymax = mean_error + ci,
      color = context
    ),
    width = 0.3,
    linewidth = 1.0
  ) +
  scale_x_discrete(limits = x_levels) +
  scale_y_continuous(
    expand = expansion(mult = y_range),
    breaks = scales::breaks_width(step_size)
  ) +
  scale_color_manual(values = c("No Change" = "orange", "Change" = "steelblue")) +
  labs(
    x = "Repetition",
    y = y_label,
    color = "Context",
  ) +
  ggtitle(ggtitle) +
  theme_classic() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 30),
    legend.title = element_blank(),
    plot.margin = margin(5, 5, 5, 5),
    legend.text = element_text(size = legend_text_size),
    
    legend.position = legend_pos,
    
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    axis.title.x = element_text(
      face = "bold",
      size = 30,
      margin = margin(t = 4)
    ),
    axis.title.y = element_text(
      face = "bold",
      size = 30,
      margin = margin(r = 12)
    ),
    axis.text.x = element_text(
      size = 24,
      margin = margin(t = 8),
      color = "black"
    ),
    axis.text.y = element_text(
      size = 24,
      margin = margin(r = 8),
      color = "black"
    ),
    axis.ticks.length = unit(0.3, "cm"),
    text = element_text(family = "Arial")
  )
print(ws_hybrid_plot)

ggsave(
  filename = "ws_hybrid_plot.png",
  plot = ws_hybrid_plot,
  width = 7.5,
  height = 9,
  dpi = 300
)