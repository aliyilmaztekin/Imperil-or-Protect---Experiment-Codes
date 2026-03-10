# Imperil or Protect - Experiment 2 
# Coded by A.Y. 


### SETUP/PARAMETERS ----

library(afex)
# (Recommended) consistent Type-III tests for within factors
afex_options(type = 3, check_contrasts = TRUE)
library(R.matlab)
library(dplyr)
library(ggplot2)
library(emmeans)
library(stringr)
library(lme4)
library(lmerTest)   # for Satterthwaite df + p-values
library(glmmTMB)
library(brms)
library(ggplot2)
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
dependent_variable <- "rt2"
independent_variables <- c("repetition", "context")

dv <- sym(dependent_variable)

# 1) Subject exclusions based on ANGLE1 (DV-independent)
bad_subjects <- combinedData %>%
  mutate(
    subject = factor(subject),
    angle1_num = as.numeric(as.character(angle1)),
    angle1_abs = abs(((angle1_num + 180) %% 360) - 180)
  ) %>%
  filter(is.finite(angle1_abs), is.finite(rt1), rt1 >= 0.3) %>% 
  group_by(subject) %>%
  summarize(mean_abs_angle1 = mean(angle1_abs, na.rm = TRUE), .groups = "drop") %>%
  filter(mean_abs_angle1 > 45) 


message("Excluded subjects (mean abs circular error > 45°):")
print(bad_subjects)

# 2) Apply exclusion to the raw data
combinedData_sub <- combinedData %>%
  mutate(subject = factor(subject)) %>%
  filter(!(subject %in% bad_subjects$subject))

# --- (B) Mean of SUBJECT means for ANGLE1_ABS after exclusion (each subject equal weight)

angle1_clean <- combinedData_sub %>%
  mutate(
    angle1_num = as.numeric(as.character(angle1)),
    angle1_abs = abs(((angle1_num + 180) %% 360) - 180)
  ) %>%
  # use the SAME trial filter you used when computing bad_subjects
  filter(is.finite(angle1_abs), is.finite(rt1), rt1 >= 0.3)

grand_mean_angle1_abs_B <- angle1_clean %>%
  group_by(subject) %>%
  summarize(subj_mean_angle1_abs = mean(angle1_abs, na.rm = TRUE), .groups = "drop") %>%
  summarize(
    mean_angle1_abs = mean(subj_mean_angle1_abs),
    sd_angle1_abs   = sd(subj_mean_angle1_abs),
    n_subj          = n()
  )

message("Grand mean ANGLE1_ABS (mean of subject means) AFTER exclusion:")
print(grand_mean_angle1_abs_B)

# 3) Now do DV-specific preprocessing
combinedData_sub <- combinedData_sub %>%
  mutate(
    raw_outcome = as.numeric(as.character(!!dv)),
    outcome = if (dependent_variable %in% c("rt1", "rt2")) {
      raw_outcome
    } else {
      abs(((raw_outcome + 180) %% 360) - 180)
    },
    repetition = factor(repetition, levels = c(1, 5), labels = c("1", "5")),
    context = factor(context, levels = c(0, 1), labels = c("No Change", "Change"))
  ) %>%
  filter(is.finite(outcome), is.finite(rt1), rt1 >= 0.3) %>%
  filter(repetition %in% c("1","5"),
         context %in% c("No Change","Change"))


data_RMAnova <- combinedData_sub %>%
  group_by(subject, repetition, context) %>%
  summarize(outcome = mean(outcome, na.rm = TRUE), .groups = "drop") %>%
  mutate(subject = factor(subject))

descriptives <- data_RMAnova %>%
  group_by(repetition, context) %>%
  summarize(
    mean = mean(outcome),
    sd = sd(outcome),
    n_subj = n_distinct(subject),
    se = sd / sqrt(n_subj),
    .groups="drop"
  )
print(descriptives)

# If you want all the decimals
dput(descriptives$mean)
dput(descriptives$sd)


### RM-ANOVA (PRIMARY ANALYSIS) ----

afex_options(type = 3, check_contrasts = TRUE)

aov_mod <- aov_ez(
  id     = "subject",
  dv     = "outcome",
  within = c("repetition", "context"),
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
   outcome ~ repetition * context + (1 | subject),
   data = combinedData_sub,
   REML = TRUE
 )
 anova(lmm_mod, type = 3)

 summary(lmm_mod)


 emm_lmer <- emmeans(lmm_mod, ~ context | repetition)
 pairs(emm_lmer)

emm_anova <- emmeans(aov_mod, ~ context | repetition)
pairs(emm_anova)



## Plotting
emm_df <- as.data.frame(confint(emm_anova))
emm_df

ggplot(emm_df,
       aes(x = factor(repetition),
           y = emmean,
           color = context,
           group = context)) +
  geom_line(linewidth = 1) +
  geom_point(size = 3.5) +
  geom_errorbar(
    aes(ymin = lower.CL, ymax = upper.CL),
    width = 0.1,
    linewidth = 1
  ) +
  labs(
    x = "Repetition",
    y = "Angular Error (°)",
    color = "Context"
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0.125, 0.15)),
    breaks = scales::breaks_width(1)
  ) +
  theme_classic(base_size = 15) +
  theme(
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

ggsave(
  filename = "figure1_interaction.png",
  width = 6,
  height = 4,
  units = "in",
  dpi = 300
)