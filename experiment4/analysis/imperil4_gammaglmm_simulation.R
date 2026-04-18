# Imperil or Protect - Experiment 4 - Gamma GLMM Sample Size Simulation
# Coded by A.Y. 

### SETUP/PARAMETERS ----

library(R.matlab)
library(dplyr)
library(ggplot2)
library(ggplot2)
library(rlang)
library(simr)
library(lme4)

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

# 3) Now do DV-specific pre-processing
combinedData_sub <- combinedData_sub %>%
  mutate(
    raw_outcome = as.numeric(as.character(!!dv)),
    outcome = if (dependent_variable %in% c("rt1", "rt2")) {
      raw_outcome
    } else {
      (abs(((raw_outcome + 180) %% 360) - 180))
    },
    repetition = factor(repetition, levels = c(1, 5), labels = c("1", "5")),
    context = factor(context, levels = c(0, 1), labels = c("No Change", "Change"))
  ) %>%
  filter(is.finite(outcome), is.finite(rt1), rt1 >= 0.3) %>%
  filter(repetition %in% c("1","5"),
         context %in% c("No Change","Change"))

combinedData_sub <- combinedData_sub %>%
  filter(is.finite(outcome), outcome > 0)

# Data subset to feed into the simulation
pilot_subjects <- levels(combinedData_sub$subject)[1:20]

simFeed <- combinedData_sub %>%
  filter(subject %in% pilot_subjects)

simFeed$subject <- droplevels(simFeed$subject)

pilot_mod <- glmer(
  outcome ~ repetition * context + (1 | subject),
  family = Gamma(link = "log"),
  data = simFeed
)

# model_extended <- extend(model_lme4, along = "subject", n = 100)
# 
# powerSim(
#   model_extended,
#   test = fixed("repetition5:contextChange", method = "z"),
#   nsim = 500
# )

small_mod <- pilot_mod
fixef(small_mod)["repetition5:contextChange"] <- 0.05

mid_mod <- pilot_mod
fixef(mid_mod)["repetition5:contextChange"] <- 0.09

large_mod <- pilot_mod
fixef(large_mod)["repetition5:contextChange"] <- 0.11

Ns <- c(10, 20, 40, 60, 80, 100, 120, 140)

# small_mod_ext <- extend(small_mod, along = "subject", n = max(Ns))
mid_mod_ext   <- extend(mid_mod,   along = "subject", n = max(Ns))
# large_mod_ext <- extend(large_mod, along = "subject", n = max(Ns))

# pc_small <- powerCurve(
#   small_mod_ext,
#   along = "subject",
#   breaks = Ns,
#   test = fixed("repetition5:contextChange", method = "z"),
#   nsim = 100
# )
# 
# pc_small
# 
pc_mid <- powerCurve(
  mid_mod_ext,
  along = "subject",
  breaks = Ns,
  test = fixed("repetition5:contextChange", method = "z"),
  nsim = 500
)
pc_mid

# pc_large <- powerCurve(
#   large_mod_ext,
#   along = "subject",
#   breaks = Ns,
#   test = fixed("repetition5:contextChange", method = "z"),
#   nsim = 500
# )
# 
# pc_large


