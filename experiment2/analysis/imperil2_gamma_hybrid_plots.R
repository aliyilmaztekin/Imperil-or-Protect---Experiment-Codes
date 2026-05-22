# Imperil or Protect - Experiment 4 - ANOVA/LMM/Gamma GLMM analysis
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
library(Rmisc)

options(scipen = 999)  # Avoid scientific notation

raw_data <- "/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment2_sixlets_anova.mat"
raw_data_read <- readMat(raw_data)

# 2) Extract numeric matrix and convert to data frame
raw_data_matrix <- raw_data_read$all.data.experiment2.sixlets.anova
raw_data_data_frame <- as.data.frame(raw_data_matrix)

# 3) Assign column names
colnames(raw_data_data_frame) <- c(
  "subject", "trial", "repetition", "block", "angle",
  "rt", "initiation_time", "movement_time",
  "condition", "context", "interference")

# 4) Rename the dataset
combinedData <- raw_data_data_frame

# 1) Put in your DV and IVs
dependent_variable <- "angle"
independent_variables <- c("repetition", "context_type", "interference")

# 1) Subject exclusions based on ANGLE
bad_subjects <- combinedData %>%
  dplyr::mutate(
    subject = factor(subject),
    angle_num = as.numeric(as.character(angle)),
    angle_abs = abs(((angle_num + 180) %% 360) - 180)
  ) %>%
  dplyr::filter(
    is.finite(angle_abs),
    is.finite(rt),
    rt >= 0.3
  ) %>%
  dplyr::group_by(subject) %>%
  dplyr::summarise(
    mean_abs_angle = mean(angle_abs, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  dplyr::filter(mean_abs_angle > 45)

message("Excluded subjects (mean abs circular error > 45°):")
print(bad_subjects)

# 2) Apply exclusion to the raw data
combinedData_sub <- combinedData %>%
  dplyr::mutate(subject = factor(subject)) %>%
  dplyr::filter(!(subject %in% bad_subjects$subject))

# Base preprocessing
combinedData_sub_base <- combinedData_sub %>%
  dplyr::mutate(
    raw_outcome = as.numeric(as.character(.data[[dependent_variable]])),
    outcome = if (dependent_variable %in% c("rt")) {
      raw_outcome
    } else {
      abs(((raw_outcome + 180) %% 360) - 180)
    },
    repetition_num = as.numeric(as.character(repetition)),
    context_num = as.numeric(as.character(context)),
    interference_num = as.numeric(as.character(interference))
  ) %>%
  dplyr::filter(
    is.finite(outcome),
    is.finite(rt),
    rt >= 0.3
  )

# Full 1-6 repetition dataset
combinedData_sub_rep <- combinedData_sub_base %>%
  dplyr::filter(repetition_num %in% 1:6) %>%
  dplyr::mutate(
    repetition = factor(
      repetition_num,
      levels = 1:6,
      labels = c("1", "2", "3", "4", "5", "6")
    ),
    subject = factor(subject)
  )

# Repetition 1 and 5 dataset with context and interference
combinedData_sub_full <- combinedData_sub_base %>%
  dplyr::filter(
    repetition_num %in% c(1, 5),
    context_num %in% c(0, 1),
    interference_num %in% c(0, 1)
  ) %>%
  dplyr::mutate(
    repetition = factor(
      repetition_num,
      levels = c(1, 5),
      labels = c("1", "5")
    ),
    context = factor(
      context_num,
      levels = c(0, 1),
      labels = c("No Change", "Change")
    ),
    interference = factor(
      interference_num,
      levels = c(0, 1),
      labels = c("No Interference", "Interference")
    ),
    subject = factor(subject)
  )

combinedData_gamma_rep <- combinedData_sub_rep %>%
  dplyr::filter(is.finite(outcome), outcome > 0)

combinedData_gamma_full <- combinedData_sub_full %>%
  dplyr::filter(is.finite(outcome), outcome > 0)

# Optional sanity checks
print(table(combinedData_sub_rep$repetition, useNA = "ifany"))
print(table(combinedData_sub_full$repetition, combinedData_sub_full$context, useNA = "ifany"))
print(table(combinedData_sub_full$repetition, combinedData_sub_full$context, combinedData_sub_full$interference, useNA = "ifany"))

### MODELS ----

# Repetition-only model across all 6 reps
glmm_mod_rep <- glmmTMB(
  outcome ~ repetition + (1 | subject),
  data = combinedData_gamma_rep,
  family = Gamma(link = "log")
)

summary(glmm_mod_rep)

# Context + interference model for repetitions 1 and 5 only
glmm_mod_full <- glmmTMB(
  outcome ~ repetition * context * interference + (1 | subject),
  data = combinedData_gamma_full,
  family = Gamma(link = "log")
)

summary(glmm_mod_full)

### EMMs ----

# Repetition-only EMMs across all 6 repetitions
emm_rep <- emmeans(glmm_mod_rep, ~ repetition, type = "response")
rep_df <- as.data.frame(emm_rep)

# Interference EMMs at reps 1 and 5, separately for each context
emm_int <- emmeans(glmm_mod_full, ~ interference | repetition * context, type = "response")
int_df <- as.data.frame(emm_int)

# Consistent x-axis ordering
x_levels <- c("1", "2", "3", "4", "5", "6")

rep_df <- rep_df %>%
  dplyr::mutate(repetition = factor(repetition, levels = x_levels))

int_df <- int_df %>%
  dplyr::mutate(
    repetition = factor(repetition, levels = x_levels),
    context = factor(context, levels = c("No Change", "Change")),
    interference = factor(
      interference,
      levels = c("No Interference", "Interference")
    )
  )

# Hide black points at reps 1 and 5
rep_df_for_points <- rep_df %>%
  dplyr::filter(!repetition %in% c("1", "5")) %>%
  dplyr::mutate(repetition = factor(repetition, levels = x_levels))

### PLOT AESTHETICS ----

legend_yes <- FALSE

if (legend_yes) {
  legend_pos <- "right"
  legend_text_size <- 20
} else {
  legend_pos <- "none"
  legend_text_size <- 20
}

if (dependent_variable == "angle") {
  step_size <- 3
  y_range <- c(0.125, 0.2)
  y_label <- "Angular Error (°)"
} else if (dependent_variable == "rt") {
  step_size <- 0.25 * 1000
  y_range <- c(0.125, 0.2)
  y_label <- "Response Time (ms)"
}

scale_factor <- ifelse(dependent_variable %in% c("rt"), 1000, 1)

### WITHIN-SUBJECT ERROR BARS ----

# 1) Repetition-only part: reps 1–6 collapsed across context and interference
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

# 2) Context and interference: only at Rep 1 and 5
ws_df_ctx_int <- combinedData_sub_full %>%
  dplyr::group_by(subject, repetition, context, interference) %>%
  dplyr::summarise(
    mean_error = mean(outcome * scale_factor, na.rm = TRUE),
    .groups = "drop"
  )

ws_summary_ctx_int <- Rmisc::summarySEwithin(
  data = ws_df_ctx_int,
  measurevar = "mean_error",
  withinvars = c("repetition", "context", "interference"),
  idvar = "subject",
  conf.interval = 0.95
)

ws_summary_ctx_int <- ws_summary_ctx_int %>%
  dplyr::mutate(
    repetition = factor(repetition, levels = x_levels),
    context = factor(context, levels = c("No Change", "Change")),
    interference = factor(
      interference,
      levels = c("No Interference", "Interference")
    )
  )

# 3) To avoid overplotting reps 1 and 5 twice
ws_summary_rep_for_points <- ws_summary_rep %>%
  dplyr::filter(!repetition %in% c("1", "5"))

### HYBRID PLOT: interference as color, context as facet ----

exp2_ws_hybrid_plot <- ggplot() +
  geom_point(
    data = ws_summary_rep_for_points,
    aes(x = repetition, y = mean_error),
    size = 4,
    color = "black"
  ) +
  geom_errorbar(
    data = ws_summary_rep_for_points,
    aes(
      x = repetition,
      ymin = mean_error - ci,
      ymax = mean_error + ci
    ),
    width = 0.3,
    linewidth = 1.0,
    color = "black"
  ) +
  geom_point(
    data = ws_summary_ctx_int,
    aes(x = repetition, y = mean_error, color = interference),
    size = 4
  ) +
  geom_errorbar(
    data = ws_summary_ctx_int,
    aes(
      x = repetition,
      ymin = mean_error - ci,
      ymax = mean_error + ci,
      color = interference
    ),
    width = 0.3,
    linewidth = 1.0
  ) +
  facet_wrap(~ context) +
  scale_x_discrete(limits = x_levels) +
  scale_y_continuous(
    expand = expansion(mult = y_range),
    breaks = scales::breaks_width(step_size)
  ) +
  scale_color_manual(
    values = c(
      "No Interference" = "orange",
      "Interference" = "steelblue"
    )
  ) +
  labs(
    x = NULL,
    y = y_label,
    color = "Interference"
  ) +
  theme_classic() +
  theme(
    legend.position = legend_pos,
    legend.title = element_blank(),
    legend.text = element_text(size = legend_text_size),
    
    strip.background = element_blank(),
    strip.text = element_text(
      size = 32,
      face = "bold",
      hjust = 0.5
    ),
    
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    panel.spacing = unit(1.2, "lines"),
    
    axis.title.x = element_text(face = "bold", size = 32, margin = margin(t = 4)),
    axis.title.y = element_text(face = "bold", size = 32, margin = margin(r = 12)),
    axis.text.x = element_text(size = 24, margin = margin(t = 8), color = "black"),
    axis.text.y = element_text(size = 24, margin = margin(r = 8), color = "black"),
    axis.ticks.length = unit(0.3, "cm"),
    text = element_text(family = "Arial")
  )

print(exp2_ws_hybrid_plot)


ggsave(
  filename = "exp2_ws_hybrid_plot.png",
  plot = exp2_ws_hybrid_plot,
  width = 12,
  height = 7,
  units = "in",
  dpi = 300
)


