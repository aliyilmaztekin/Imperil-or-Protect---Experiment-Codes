# Imperil or Protect - Experiment 6 - Design Delta
# Coded by A.Y. 

### SETUP/PARAMETERS ----


library(R.matlab)
library(dplyr)
library(ggplot2)
library(emmeans)
library(stringr)
library(lme4)
library(lmerTest) 
library(glmmTMB)
library(brms)
library(ggplot2)
library(rlang)
library(pracma)

options(scipen = 999)  # Avoid scientific notation

base_dir <- '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/design_delta_output'

files <- list.files(base_dir, pattern = "\\.mat$", full.names = TRUE)

dfs <- lapply(files, function(f) {
  mat <- R.matlab::readMat(f)
  as.data.frame(mat$outputMatrix)
})

combinedData <- bind_rows(dfs)
colnames(combinedData) <- c(
  "subject", "conditionUsed", "block", "trial", "repetition",
  "context", "contextCode", "theta", "item1color", "item2color", "item3color",
  "item4color", "itemTested", "angle", "absAngle", "initiation_time", "movement_time", "rt",
  "click", "adj", "randAdd", "break", "cond"
)

### PREPROCESSING

# Put in your DV and IVs
dependent_variable <- "angle"
tested_item <- "novel" 
independent_variables <- c("repetition", "context")
dv <- sym(dependent_variable)

# Outlier rejection
bad_subjects <- combinedData %>%
 dplyr::mutate(
   subject = factor(subject),
   angle_num = as.numeric(as.character(angle)),
   angle_abs = abs(((angle_num + 180) %% 360) - 180)
 ) %>%
 dplyr::filter(is.finite(angle_abs), is.finite(rt), rt >= 0.3, angle_abs > 0) %>%
 dplyr::group_by(subject) %>%
 dplyr::summarize(mean_abs_angle = mean(angle_abs, na.rm = TRUE), .groups = "drop") %>%
 dplyr::filter(mean_abs_angle > 45)

combinedData_sub <- combinedData %>%
 dplyr::mutate(subject = factor(subject)) %>%
 dplyr::filter(!(subject %in% bad_subjects$subject))


# Compute error to non-target colors (for swap analysis)
combinedData_sub_swap <- combinedData_sub %>%
 mutate(
   nonTargetError1 = case_when(
     itemTested == 1 ~ ((item2color - adj) + 180) %% 360 - 180,
     itemTested == 2 ~ ((item1color - adj) + 180) %% 360 - 180,
     itemTested == 3 ~ ((item1color - adj) + 180) %% 360 - 180
   ),
   nonTargetError2 = case_when(
     itemTested == 1 ~ ((item4color - adj) + 180) %% 360 - 180,
     itemTested == 2 ~ ((item4color - adj) + 180) %% 360 - 180,
     itemTested == 3 ~ ((item2color - adj) + 180) %% 360 - 180
   )
 )

# Save data for mixture and swap model-fitting in MATLAB
# thirdpass_matrix <- data.matrix(combinedData_sub_swap)
# writeMat("/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment6/swap_model/combinedData_thirdpass6.mat",
#          thirdpass = thirdpass_matrix)

# Data trimming
combinedData_sub_full <- combinedData_sub %>%
  dplyr::mutate(
    raw_outcome = as.numeric(as.character(.data[[dependent_variable]])),
    
    outcome = if (dependent_variable == "rt") {
      raw_outcome
    } else {
      abs(((raw_outcome + 180) %% 360) - 180)
    },
    
    repetition = factor(
      repetition,
      levels = c(1, 5),
      labels = c("1", "5")
    ),
    
    context = factor(
      context,
      levels = c(0, 1),
      labels = c("No Change", "Change")
    ),
    
    itemTested = factor(
      itemTested,
      levels = c(1, 2, 3),
      labels = c("rep1", "rep2", "novel")
    )
  ) %>%
  dplyr::filter(
    is.finite(outcome),
    is.finite(rt),
    rt >= 0.3
  ) %>%
  dplyr::filter(
    repetition %in% c("1", "5"),
    context %in% c("No Change", "Change"),
    if (tested_item == "novel") {
      itemTested == "novel"
    } else {
      itemTested %in% c("rep1", "rep2")
    }
  )


## A reps-only copy of the same dataset (for plotting after analyses)
combinedData_sub_reps <- combinedData_sub %>%
  dplyr::mutate(
    raw_outcome = as.numeric(as.character(.data[[dependent_variable]])),

    outcome = if (dependent_variable == "rt") {
      raw_outcome
    } else {
      abs(((raw_outcome + 180) %% 360) - 180)
    },

    repetition = factor(
      repetition,
      levels = c(1, 2, 3, 4, 5, 6),
      labels = c("1","2","3","4","5","6")
    ),

    itemTested = factor(
      itemTested,
      levels = c(1, 2, 3),
      labels = c("rep1", "rep2", "novel")
    )
  ) %>%
  dplyr::filter(
    is.finite(outcome),
    is.finite(rt),
    rt >= 0.3
  ) %>%
  dplyr::filter(
    if (tested_item == "novel") {
      itemTested == "novel"
    } else {
      itemTested %in% c("rep1", "rep2")
    }
  )


# Descriptive statistics
data_desc <- combinedData_sub_full %>%
  dplyr::group_by(subject, repetition, context) %>%
  dplyr::summarize(outcome = mean(outcome, na.rm = TRUE), .groups = "drop") %>%
  dplyr::mutate(subject = factor(subject))

descriptives <- data_desc %>%
  dplyr::group_by(repetition, context) %>%
  dplyr::summarize(
    mean = mean(outcome),
    sd = sd(outcome),
    n_subj = n_distinct(subject),
    se = sd / sqrt(n_subj),
    .groups="drop"
  )

# # If you want all the decimals
# dput(descriptives$mean)
# dput(descriptives$sd)


## Linear Mixed Effects Model

lmm_mod <- lmer(
  outcome ~ repetition * context + (1 | subject),
  data = combinedData_sub_full
)
anova(lmm_mod, type = 3)

## Gamma GLMM
combinedData_gamma_full <- combinedData_sub_full %>%
  dplyr::filter(is.finite(outcome), outcome > 0)

combinedData_gamma_reps <- combinedData_sub_reps %>%
  filter(is.finite(outcome), outcome > 0)


## Gamma Generalized Liner Mixed Effects Model
glmm_mod <- glmmTMB(
  outcome ~ repetition * context + (1 | subject),
  data = combinedData_gamma_full,
  family = Gamma(link = "log")
)

car::Anova(glmm_mod, type = "III")

emm_full <- emmeans(glmm_mod, ~ context | repetition, type = "response")
pairs(emm_full)
emm_df_full <- as.data.frame(emm_full)


# Repetition-only model across all 6 reps
glmm_mod_reps <- glmmTMB(
  outcome ~ repetition + (1 | subject),
  data = combinedData_gamma_reps,
  family = Gamma(link = "log")
)

emm_reps <- emmeans(glmm_mod_reps, ~ repetition, type = "response")
emm_df_reps <- as.data.frame(emm_reps)


## Within-subjects variability in condition means

# Full Model:
ws_var_full <- Rmisc::summarySEwithin(
  data = combinedData_gamma_full,
  measurevar = "outcome",
  withinvars = c("repetition", "context"),
  idvar = "subject",
  conf.interval = 0.95
) %>%
  dplyr::select(
    repetition,
    context,
    ws_mean = outcome,
    ws_ci = ci
  )

# Add the results into the existing data frame
emm_df_full <- emm_df_full %>%
  left_join(ws_var_full, by = c("repetition", "context")) %>%
  mutate(
    ws_lower = response - ws_ci,
    ws_upper = response + ws_ci
  )

# Reps-only Model:
ws_var_reps <- Rmisc::summarySEwithin(
  data = combinedData_gamma_reps,
  measurevar = "outcome",
  withinvars = c("repetition"),
  idvar = "subject",
  conf.interval = 0.95
) %>%
  dplyr::select(
    repetition,
    ws_mean = outcome,
    ws_ci = ci
  )

# Add the results into the existing data frame
emm_df_reps <- emm_df_reps %>%
  left_join(ws_var_reps, by = c("repetition")) %>%
  mutate(
    ws_lower = response - ws_ci,
    ws_upper = response + ws_ci
  )


## PLOTTING

emm_df_reps[c(1, 5), c("response", "ws_lower", "ws_upper")] <- NA

color_names <- c(
  "Repetition Only" = "black",
  "Change" = "steelblue",
  "No Change" = "orange"
)

hybrid_plot <- ggplot() +
  geom_point(data = emm_df_reps, aes(x = repetition, y = response, color = "Repetition Only"), size = 3) +
  geom_line(data = emm_df_reps, aes(x = repetition, y = response), show.legend = FALSE) +
  geom_errorbar(data = emm_df_reps, aes(x = repetition, ymin = ws_lower, ymax = ws_upper), width= 0.5, show.legend = FALSE) +
  geom_point(data = emm_df_full, aes(x = repetition, y = response, color = context), size = 3) +
  geom_line(data = emm_df_full, aes(x = repetition, y = response), show.legend = FALSE) +
  geom_errorbar(data = emm_df_full, aes(x = repetition, ymin = ws_lower, ymax = ws_upper, color = context), width = 0.5, show.legend = FALSE) +
  scale_color_manual(values = color_names, breaks = c("Repetition Only","No Change","Change")) +
  labs(x = "Repetition", y = if(dependent_variable == "angle") "Angular Error (°)" else "Reaction Time (s)") +
  coord_cartesian(ylim = if(dependent_variable == "angle") c(25, 45) else c(1.9,2.3)) +
  scale_y_continuous(breaks = if(dependent_variable == "angle") seq(25, 45, by = 2) else seq(1.9,2.3, by = 0.05)) +
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
print(descriptives)
car::Anova(glmm_mod, type = "III")
emm_full <- emmeans(glmm_mod, ~ context | repetition, type = "response")
pairs(emm_full)



