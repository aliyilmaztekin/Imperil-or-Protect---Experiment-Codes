# Pre-processing
library(R.matlab)
library(dplyr)
# ANOVA
library(afex)
library(emmeans)
# LME
library(lme4)
library(lmerTest)
# Within-subject error bars
library(Rmisc)
# Plotting
library(ggplot2)
library(cowplot)
library(grid)
library(showtext)
library(sysfonts)


## Enter outcome variable to test
outcome <- "novel" # "novel" or "repeat"

## Data Wrangling:
# Reps x Context model:

file <- "/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment6/design_delta/TCC/imperil6_TCC_full_model_dprime.mat"
mat <- R.matlab::readMat(file)
combinedData <- as.data.frame(mat$finalMatrix)

colnames(combinedData) <- c(
  "subject", "repetition", "context", "dp1", "dp2"
)

combinedData_sub <- combinedData %>%
  mutate(
    subject = factor(subject),
    repetition = factor(repetition, levels = c(1, 5), labels = c("1", "5")),
    context = factor(context, levels = c(0, 1), labels = c("No Change", "Change"))
  )

# Reps only model:
file2 <- "/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment6/design_delta/TCC/imperil6_TCC_reps_only_dprime.mat"
mat2 <- R.matlab::readMat(file2)
combinedData2 <- as.data.frame(mat2$finalMatrix)

colnames(combinedData2) <- c(
  "subject", "repetition", "dp1", "dp2"
)

combinedData2_sub <- combinedData2 %>%
  mutate(
    subject = factor(subject),
    repetition = factor(repetition, levels = c(1:6), labels = c("1", "2","3","4","5","6"))
  )


desc_data<- combinedData_sub %>%
  dplyr::group_by(subject, repetition, context) %>%
  dplyr::summarize(dprime = mean(if (outcome == "novel") dp1 else dp2, na.rm = TRUE), .groups = "drop") %>%
  dplyr::mutate(subject = factor(subject))

descriptives <- desc_data %>%
  dplyr::group_by(repetition, context) %>%
  dplyr::summarize(
    mean = mean(dprime),
    sd = sd(dprime),
    n_subj = n_distinct(subject),
    se = sd / sqrt(n_subj),
    .groups="drop"
  )
print(descriptives)



## Linear Mixed Effects
if (outcome == "novel") {
  
  # Full Model:
  lmm_dp1 <- lmer(
    dp1 ~ repetition * context + (1 | subject),
    data = combinedData_sub
  )
  
  summary(lmm_dp1)
  anova(lmm_dp1)
  
  emm_lme <- emmeans(lmm_dp1, ~ context | repetition)
  pairs(emm_lme)
  
  emm_plot <- emmeans(lmm_dp1, ~ repetition * context)
  
  # Reps-Only Model:
  lmm_dp1_reps <- lmer(
    dp1 ~ repetition + (1 | subject),
    data = combinedData2_sub
  )
  
  summary(lmm_dp1_reps)
  anova(lmm_dp1_reps)
  
  emm_lme_reps <- emmeans(lmm_dp1_reps, ~  repetition)
  pairs(emm_lme_reps)
  
  emm_plot_reps <- emmeans(lmm_dp1_reps, ~ repetition)
  
} else if (outcome == "repeat") {
  
  # Full Model:
  lmm_dp2 <- lmer(
    dp2 ~ repetition * context + (1 | subject),
    data = combinedData_sub
  )
  
  summary(lmm_dp2)
  anova(lmm_dp2)
  
  emm_lme <- emmeans(lmm_dp2, ~ context | repetition)
  pairs(emm_lme)
  
  emm_plot <- emmeans(lmm_dp2, ~ repetition * context)
  
  # Reps-Only Model:
  lmm_dp2_reps <- lmer(
    dp2 ~ repetition + (1 | subject),
    data = combinedData2_sub
  )
  
  summary(lmm_dp2_reps)
  anova(lmm_dp2_reps)
  
  emm_lme_reps <- emmeans(lmm_dp2_reps, ~ repetition)
  pairs(emm_lme_reps)
  
  emm_plot_reps <- emmeans(lmm_dp2_reps, ~ repetition)
}


## Plot the results
emm_df <- as.data.frame(confint(emm_plot))
emm_df_reps <- as.data.frame(confint(emm_plot_reps))


font_add(
  family = "Arial",
  regular = "/System/Library/Fonts/Supplemental/Arial.ttf",
  bold    = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
)

showtext_auto()

## Within-subjects variability in condition means

if (outcome == "novel") {
  
  # Full Model:
  ws_var_dp1 <- Rmisc::summarySEwithin(
    data = combinedData_sub,
    measurevar = "dp1",
    withinvars = c("repetition", "context"),
    idvar = "subject",
    conf.interval = 0.95
  ) %>%
    dplyr::select(
      repetition,
      context,
      ws_mean = dp1,
      ws_ci = ci
    )
  
  # Add the results into the existing data frame
  emm_df <- emm_df %>%
    left_join(ws_var_dp1, by = c("repetition", "context")) %>%
    mutate(
      ws_lower = emmean - ws_ci,
      ws_upper = emmean + ws_ci
    )
  
  # Reps-only Model:
  ws_var_dp1_reps <- Rmisc::summarySEwithin(
    data = combinedData2_sub,
    measurevar = "dp1",
    withinvars = c("repetition"),
    idvar = "subject",
    conf.interval = 0.95
  ) %>%
    dplyr::select(
      repetition,
      ws_mean = dp1,
      ws_ci = ci
    )
  
  # Add the results into the existing data frame
  emm_df_reps <- emm_df_reps %>%
    left_join(ws_var_dp1_reps, by = c("repetition")) %>%
    mutate(
      ws_lower = emmean - ws_ci,
      ws_upper = emmean + ws_ci
    )
  
} else if (outcome == "repeat") {
  
  # Full Model:
  ws_var_dp2 <- Rmisc::summarySEwithin(
    data = combinedData_sub,
    measurevar = "dp2",
    withinvars = c("repetition", "context"),
    idvar = "subject",
    conf.interval = 0.95
  ) %>%
    dplyr::select(
      repetition,
      context,
      ws_mean = dp2,
      ws_ci = ci
    )
  
  emm_df <- emm_df %>%
    left_join(ws_var_dp2, by = c("repetition", "context")) %>%
    mutate(
      ws_lower = emmean - ws_ci,
      ws_upper = emmean + ws_ci
    )
  
  #Reps-Only Model:
  
  ws_var_dp2_reps <- Rmisc::summarySEwithin(
    data = combinedData2_sub,
    measurevar = "dp2",
    withinvars = c("repetition"),
    idvar = "subject",
    conf.interval = 0.95
  ) %>%
    dplyr::select(
      repetition,
      ws_mean = dp2,
      ws_ci = ci
    )
  
  # Add the results into the existing data frame
  emm_df_reps <- emm_df_reps %>%
    left_join(ws_var_dp2_reps, by = c("repetition")) %>%
    mutate(
      ws_lower = emmean - ws_ci,
      ws_upper = emmean + ws_ci
    )
}

## PLOTTING

emm_df_reps[c(1, 5), c("emmean", "ws_lower", "ws_upper")] <- NA

color_names <- c(
  "Repetition Only" = "black",
  "Change" = "steelblue",
  "No Change" = "orange"
)

hybrid_plot <- ggplot() +
  geom_point(data = emm_df_reps, aes(x = repetition, y = emmean, color = "Repetition Only"), size = 3) +
  geom_line(data = emm_df_reps, aes(x = repetition, y = emmean), show.legend = FALSE) +
  geom_errorbar(data = emm_df_reps, aes(x = repetition, ymin = ws_lower, ymax = ws_upper), width= 0.5, show.legend = FALSE) +
  geom_point(data = emm_df, aes(x = repetition, y = emmean, color = context), size = 3) +
  geom_line(data = emm_df, aes(x = repetition, y = emmean), show.legend = FALSE) +
  geom_errorbar(data = emm_df, aes(x = repetition, ymin = ws_lower, ymax = ws_upper, color = context), width = 0.5, show.legend = FALSE) +
  scale_color_manual(values = color_names, breaks = c("Repetition Only","No Change","Change")) +
  labs(x = "Repetition", y = "Memory Strength (d')") +
  coord_cartesian(ylim = c(1.4, 2.4)) +
  theme_classic() +
  theme(
    axis.title.x = element_text(size = 16, margin = margin(t = 5), face = "bold"),
    axis.title.y = element_text(size = 16, margin = margin(r = 5), face = "bold"),
    axis.text.x = element_text(size = 14, margin = margin(t = 5)),
    axis.text.y = element_text(size = 14, margin = margin(r = 5)),
    axis.ticks.length = unit(0.2, "cm"),
    legend.title = element_blank(),
    legend.text = element_text(size = 14),
    legend.position = "bottom"
  )

hybrid_plot
