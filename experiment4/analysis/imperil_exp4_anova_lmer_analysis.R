# Imperil or Protect - Experiment 4 - ANOVA/LMER analysis
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

# ============================================================
# KEEP ONLY FIRST 12 SUBJECTS
# ============================================================

# first_12_subjects <- combinedData %>%
#   mutate(subject = factor(subject)) %>%
#   distinct(subject) %>%
#   arrange(as.numeric(as.character(subject))) %>%
#   slice_head(n = 12) %>%
#   pull(subject)
# 
# combinedData <- combinedData %>%
#   mutate(subject = factor(subject)) %>%
#   filter(subject %in% first_12_subjects)
# 
# message("Analyzing only these first 12 subjects:")
# print(first_12_subjects)

### PREPROCESSING ----

# 1) Put in your DV and IVs
dependent_variable <- "angle1"
independent_variables <- c("repetition", "context")

dv <- sym(dependent_variable)

bad_subjects <- combinedData %>%
  mutate(
    subject = factor(subject),
    angle1_num = as.numeric(as.character(angle1)),
    angle1_abs = abs(((angle1_num + 180) %% 360) - 180)
  ) %>%
  filter(is.finite(angle1_abs), is.finite(rt1), rt1 >= 0.3, angle1_abs > 0) %>% 
  group_by(subject) %>%
  summarize(mean_abs_angle1 = mean(angle1_abs, na.rm = TRUE), .groups = "drop") %>%
  filter(mean_abs_angle1 > 45)

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
    outcome = if (dependent_variable %in% c("rt1", "rt2")) {
      raw_outcome
    } else {
      abs((((raw_outcome + 180) %% 360) - 180))
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

# RM-ANOVA

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


qqnorm(resid(aov_mod))
qqline(resid(aov_mod))
 
## Linear Mixed Modelling

 lmm_mod <- lmer(
   outcome ~ repetition * context + (1 | subject),
   data = combinedData_sub,
   REML = TRUE
 )
 # anova(lmm_mod, type = 3)
 
 summary(lmm_mod)
 
 
 
 ## Gamma GLMM
 combinedData_gamma <- combinedData_sub %>%
   filter(is.finite(outcome), outcome > 0)
 
 data_gamma <- combinedData_gamma %>%
   group_by(subject, repetition, context) %>%
   summarize(outcome = mean(outcome, na.rm = TRUE), .groups = "drop") %>%
   mutate(subject = factor(subject))
 
 descriptives_gamma <- data_gamma %>%
   group_by(repetition, context) %>%
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
 
 
 ## Conduct a gamma GLMM analysis
 
 glmm_mod <- glmmTMB(
   outcome ~ repetition * context + (1 | subject),
   data = combinedData_gamma,
   family = Gamma(link = "log")
 )
 
 # summary(glmm_mod)
 
 ## Edit the analysis output to include some useful classes of values
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
 
 ## To decompose the significant two-way interaction, estimate marginal means and contrast pair-wise
 emm_gamma <- emmeans(glmm_mod, ~ context | repetition, type = "response")
 pairs(emm_gamma)

 
 # PLOT GAMMA GLMM RESULTS
 emm_plot <- emmeans(
   glmm_mod,
   ~ repetition * context,
   type = "response"
 )
 
 emm_df <- as.data.frame(confint(emm_plot))
 
 plot2save <- ggplot(
   emm_df,
   aes(
     x = factor(repetition),
     y = response,
     color = context,
     group = context
   )
 ) +
   geom_line(linewidth = 0.8) +
   geom_point(size = 3) +
   geom_errorbar(
     aes(ymin = asymp.LCL, ymax = asymp.UCL),
     width = 0.1,
     linewidth = 0.8
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
   theme_classic() +
   theme(
     legend.title = element_blank(),
     legend.text = element_text(size = 10),
     plot.background = element_rect(fill = "white"),
     panel.background = element_rect(fill = "white"),
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
 
 plot2save
 # 
 ggsave(
   '/Users/ali/Desktop/plot2save.png',
   plot = plot2save,
   width = dev.size("in")[1],
   height = dev.size("in")[2],
   dpi = 300       # resolution
 )