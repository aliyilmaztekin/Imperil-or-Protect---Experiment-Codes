# Imperil or Protect - Experiment 2 - Analysis
# Coded by A.Y. 

### SETUP/PARAMETERS

# Install/load libraries
library(R.matlab)
library(dplyr)
library(tidyr)
library(ez)
library(ggplot2)
library(moments)
library(emmeans)
library(stringr)
library(afex)
library(glmmTMB)
options(scipen = 999)  # Avoid scientific notation

# 1) Load MAT files
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


### PREPROCESSING

# 1) Put in your DV and IVs
dependent_variable <- "rt"
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

# 3) Now do DV-specific pre-processing
combinedData_sub <- combinedData_sub %>%
  mutate(
    raw_outcome = as.numeric(as.character(!!dv)),
    outcome = if (dependent_variable %in% c("rt")) {
      raw_outcome
    } else {
      (abs((((raw_outcome + 180) %% 360) - 180)))
    },
    repetition = factor(repetition, levels = c(1, 5), labels = c("1", "5")),
    context = factor(context, levels = c(0, 1), labels = c("No Change", "Change")), # Pooled change
    context_type = factor(context_type, levels = c(0, 1, 2), labels = c("No Change", "Within", "Across")), # Categorized change
    interference = factor(interference, levels = c(0, 1), labels = c("No Interference", "Interference"))
  ) %>%
  filter(is.finite(outcome), is.finite(rt), rt >= 0.3) %>%
  filter(repetition %in% c("1","5"),
         context %in% c("No Change", "Change"),
         context_type %in% c("No Change","Within", "Across"),
         interference %in% c("No Interference", "Interference"))


data_RMAnova <- combinedData_sub %>%
  group_by(subject, repetition, context, interference) %>%
  summarize(outcome = mean(outcome, na.rm = TRUE), .groups = "drop") %>%
  mutate(subject = factor(subject))

descriptives <- data_RMAnova %>%
  group_by(repetition, context, interference) %>%
  summarize(
    mean = mean(outcome),
    sd = sd(outcome),
    n_subj = n_distinct(subject),
    se = sd / sqrt(n_subj),
    .groups="drop"
  )
print(descriptives)

afex_options(type = 3, check_contrasts = TRUE)
aov_mod <- aov_ez(
  id     = "subject",
  dv     = "outcome",
  within = c("repetition", "context", "interference"),
  data   = data_RMAnova,
  type   = 3
)

anova_tbl <- anova(aov_mod)

anova_tbl$pes <- with(
  anova_tbl,
  (F * `num Df`) / (F * `num Df` + `den Df`)
)

print(anova_tbl)

lmm_mod <- lmer(
  outcome ~ repetition * context  * interference + (1 | subject),
  data = combinedData_sub,
  REML = TRUE
)
# anova(lmm_mod, type = 3)

summary(lmm_mod)


combinedData_gamma <- combinedData_sub %>%
  filter(is.finite(outcome), outcome != 0)

data_gamma <- combinedData_gamma %>%
  group_by(subject, repetition, context, interference) %>%
  summarize(outcome = mean(outcome, na.rm = TRUE), .groups = "drop") %>%
  mutate(subject = factor(subject))

descriptives_gamma <- data_gamma %>%
  group_by(repetition, context, interference) %>%
  summarize(
    mean = (mean(outcome)),
    sd = (sd(outcome)),
    n_subj = n_distinct(subject),
    se = (sd / sqrt(n_subj)),
    .groups="drop"
  )
print(descriptives_gamma)
dput(descriptives_gamma$mean)
dput(descriptives_gamma$sd)

glmm_mod <- glmmTMB(
  outcome ~ repetition * context * interference + (1 | subject),
  data = combinedData_gamma,
  family = Gamma(link = "log")
)

summary(glmm_mod)

coef_df <- as.data.frame(summary(glmm_mod)$coefficients$cond)
coef_df$error_ratio <- exp(coef_df$Estimate)
coef_df$percent_change <- (exp(coef_df$Estimate) - 1) * 100
coef_df$sig <- ifelse(coef_df$`Pr(>|z|)` < .001, "***",
                      ifelse(coef_df$`Pr(>|z|)` < .01, "**",
                             ifelse(coef_df$`Pr(>|z|)` < .05, "*", "")))
coef_df$`Pr(>|z|)` <- round(coef_df$`Pr(>|z|)`, 5)
coef_df$baseline_deg <- NA
coef_df$baseline_deg[1] <- exp(coef_df$Estimate[1])

coef_df <- coef_df[, c(
  "baseline_deg",
  "Estimate",
  "error_ratio",
  "percent_change",
  "Pr(>|z|)",
  "sig",
  "Std. Error",
  "z value"
)]
coef_df

emm_gamma <- emmeans(glmm_mod, ~ context * interference | repetition, type = "response")
pairs(emm_gamma)

emm_plot <- emmeans(
  glmm_mod,
  ~ context * interference | repetition,
  type = "response"
)

emm_df <- as.data.frame(confint(emm_plot))

ggplot(
  emm_df,
  aes(
    x = factor(repetition),
    y = response,
    color = interference,
    group = interference
  )
) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 3) +
  geom_errorbar(
    aes(ymin = asymp.LCL, ymax = asymp.UCL),
    width = 0.1,
    linewidth = 0.8
  ) +
  facet_wrap(~ context) + 
  labs(
    x = "Repetition",
    y = "Angular Error (°)",
    color = "Context"
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0.125, 0.15)),
    breaks = scales::breaks_width(1)
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
      size = 13,
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
