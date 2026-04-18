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

options(scipen = 999)  # Avoid scientific notation

raw_data <- "/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment1_sixlets_anova.mat"
raw_data_read <- readMat(raw_data)

# 2) Extract numeric matrix and convert to data frame
raw_data_matrix <- raw_data_read$all.data.experiment1.sixlets.anova
raw_data_data_frame <- as.data.frame(raw_data_matrix)

# 3) Assign column names
colnames(raw_data_data_frame) <- c(
  "subject", "trial", "repetition", "block", "angle",
  "rt", "initiation_time", "movement_time",
  "condition", "context", "interference", "context_type"
)

# 4) Rename the dataset (optional)
combinedData <- raw_data_data_frame

# 1) Put in your DV and IVs
dependent_variable <- "angle"
independent_variables <- c("repetition", "context_type", "interference")

dv <- sym(dependent_variable)

# 1) Subject exclusions based on ANGLE1 (DV-independent)
bad_subjects <- combinedData %>%
  mutate(
    subject = factor(subject),
    angle_num = as.numeric(as.character(angle)),
    angle_abs = abs(((angle_num + 180) %% 360) - 180)
  ) %>%
  filter(is.finite(angle_abs), is.finite(rt), rt >= 0.3) %>% 
  group_by(subject) %>%
  summarize(mean_abs_angle = mean(angle_abs, na.rm = TRUE), .groups = "drop") %>%
  filter(mean_abs_angle > 45) 

message("Excluded subjects (mean abs circular error > 45°):")
print(bad_subjects)


# 2) Apply exclusion to the raw data
combinedData_sub <- combinedData %>%
  mutate(subject = factor(subject)) %>%
  filter(!(subject %in% bad_subjects$subject))

# Base preprocessing
combinedData_sub_base <- combinedData_sub %>%
  mutate(
    raw_outcome = as.numeric(as.character(!!dv)),
    outcome = if (dependent_variable %in% c("rt")) {
      raw_outcome
    } else {
      abs((((raw_outcome + 180) %% 360) - 180))
    },
    repetition_num = as.numeric(as.character(repetition)),
    context_num = as.numeric(as.character(context)),
    interference_num = as.numeric(as.character(interference))
  ) %>%
  filter(
    is.finite(outcome),
    is.finite(rt),
    rt >= 0.3
  )

# Full 1-6 repetition dataset
combinedData_sub_rep <- combinedData_sub_base %>%
  filter(repetition_num %in% 1:6) %>%
  mutate(
    repetition = factor(repetition_num, levels = 1:6, labels = c("1", "2", "3", "4", "5", "6")),
    subject = factor(subject)
  )

# Repetition 1 and 5 dataset with context and interference 
combinedData_sub_full <- combinedData_sub_base %>%
  filter(
    repetition_num %in% c(1, 5),
    context_num %in% c(0, 1),
    interference_num %in% c (0,1)
  ) %>%
  mutate(
    repetition = factor(repetition_num, levels = c(1, 5), labels = c("1", "5")),
    context = factor(context_num, levels = c(0, 1), labels = c("No Change", "Change")),
    interference = factor(interference_num, levels = c(0, 1), labels = c("No Interference", "Interference")),
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

rep_df$repetition <- factor(rep_df$repetition, levels = x_levels)

int_df$repetition <- factor(int_df$repetition, levels = x_levels)
int_df$context <- factor(int_df$context, levels = c("No Change", "Change"))
int_df$interference <- factor(
  int_df$interference,
  levels = c("No Interference", "Interference")
)

# Hide black points at reps 1 and 5
rep_df_for_points <- rep_df %>%
  filter(!repetition %in% c("1", "5")) %>%
  mutate(repetition = factor(repetition, levels = x_levels))

### HYBRID PLOT: interference as color, context as facet ----

ggplot() +
  geom_point(
    data = rep_df_for_points,
    aes(x = repetition, y = response),
    size = 3,
    color = "black"
  ) +
  geom_errorbar(
    data = rep_df_for_points,
    aes(x = repetition, ymin = asymp.LCL, ymax = asymp.UCL),
    width = 0.1,
    linewidth = 0.8,
    color = "black"
  ) +
  geom_point(
    data = int_df,
    aes(x = repetition, y = response, color = interference),
    size = 3
  ) +
  geom_errorbar(
    data = int_df,
    aes(x = repetition, ymin = asymp.LCL, ymax = asymp.UCL, color = interference),
    width = 0.1,
    linewidth = 0.8
  ) +
  facet_wrap(~ context) +
  scale_x_discrete(limits = x_levels) +
  scale_y_continuous(
    expand = expansion(mult = c(0.125, 0.15)),
    breaks = scales::breaks_width(1)
  ) +
  scale_color_manual(
    values = c(
      "No Interference" = "orange",
      "Interference" = "steelblue"
    )
  ) +
  labs(
    x = "Repetition",
    y = "Angular Error (°)",
    color = "Interference"
  ) +
  theme_classic() +
  theme(
    legend.title = element_blank(),
    legend.text = element_text(size = 10),
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    strip.background = element_blank(),
    panel.spacing = unit(1.2, "lines"),
    strip.text = element_text(
      face = "bold",
      size = 13
    ),
    axis.title.x = element_text(
      face = "bold",
      size = 16,
      margin = margin(t = 4)
    ),
    axis.title.y = element_text(
      face = "bold",
      size = 16,
      margin = margin(r = 12)
    ),
    axis.text.x = element_text(
      size = 14,
      margin = margin(t = 8),
      color = "black"
    ),
    axis.text.y = element_text(
      size = 14,
      margin = margin(r = 8),
      color = "black"
    ),
    axis.ticks.length = unit(0.2, "cm"),
    text = element_text(family = "Arial")
  )